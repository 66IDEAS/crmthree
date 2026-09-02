# frozen_string_literal: true

module Crm
  module Service
    class NotificationHandler
      class << self
        def call(event)
          case event.name
          when "ticket.assigned" then ticket_assigned(event)
          when "ticket.sla_breached" then sla_breached(event)
          when "opportunity.stage_changed" then opportunity_stage_changed(event)
          when "lead.assigned" then lead_assigned(event)
          end
        rescue StandardError => error
          Rails.logger.error("Notification handler failed for #{event.name}: #{error.class}: #{error.message}")
        end

        private

        def ticket_assigned(event)
          recipient = UserProfile.find_by(id: event.payload["to_user_id"], active: true)
          return unless recipient && recipient.id != event.actor_id
          return unless enabled?(recipient, "TicketAssigned")

          ticket = Ticket.find_by(id: event.record_id)
          return unless ticket

          create_notification(
            recipient:, actor_id: event.actor_id, type: "TicketAssigned", title: "Ticket assigned",
            message: "#{ticket.ticket_number.to_i}: #{ticket.subject}", record: ticket
          )
        end

        def sla_breached(event)
          ticket = Ticket.find_by(id: event.record_id)
          recipient = UserProfile.find_by(id: event.payload["recipient_id"], active: true)
          return unless ticket && recipient
          return unless enabled?(recipient, "SLABreach")

          kind = event.payload.fetch("kind").to_s.humanize.downcase
          title = "SLA #{kind} breached"
          return if Notification.exists?(user_id: recipient.id, type: "SLABreach", link_type: "Ticket", link_id: ticket.id, title:)

          create_notification(
            recipient:, actor_id: event.actor_id, type: "SLABreach", title:,
            message: "#{ticket.ticket_number.to_i}: #{ticket.subject}", record: ticket
          )
        end

        def opportunity_stage_changed(event)
          opportunity = Opportunity.find_by(id: event.record_id)
          recipient = opportunity&.owner
          return unless recipient&.active? && recipient.id != event.actor_id
          return unless enabled?(recipient, "DealStageChange")

          create_notification(
            recipient:, actor_id: event.actor_id, type: "DealStageChange", title: "Opportunity stage changed",
            message: "#{opportunity.name} moved to #{opportunity.stage.name}", record: opportunity
          )
        end

        def lead_assigned(event)
          lead = Lead.find_by(id: event.record_id)
          recipient = UserProfile.find_by(id: event.payload["to_user_id"], active: true)
          return unless lead && recipient && recipient.id != event.actor_id
          return unless enabled?(recipient, "LeadAssigned")

          create_notification(
            recipient:, actor_id: event.actor_id, type: "LeadAssigned", title: "Lead assigned",
            message: RecordPresentation.display_name(lead), record: lead
          )
        end

        def create_notification(recipient:, actor_id:, type:, title:, message:, record:)
          actor = UserProfile.find_by(id: actor_id) || UserProfile.find(Crm::Seeds::SYSTEM_PROFILE_ID)
          Current.set(profile: actor) do
            Notification.create!(
              user: recipient, type:, title:, message:, read: false,
              link_type: record.class.name, link_id: record.id,
              send_email: email_enabled?(recipient), email_sent: false
            )
          end
        end

        def enabled?(profile, type)
          Crm::NotificationPreferences.enabled?(profile, type)
        end

        def email_enabled?(profile)
          Crm::NotificationPreferences.email?(profile)
        end
      end
    end
  end
end
