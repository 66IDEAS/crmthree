# frozen_string_literal: true

module Crm
  module Service
    module TicketBehavior
      extend ActiveSupport::Concern

      included do
        before_validation :crm_assign_sla
        before_validation :crm_apply_sla_deadlines
        before_validation :crm_apply_status_timestamps
        validate :crm_status_is_available
        validate :crm_closed_status_is_terminal, on: :update
        validate :crm_resolution_is_present
        validate :crm_references_match_account
        validate :crm_service_contract_is_active
        validate :crm_sla_is_available
        validate :crm_assignee_is_active
        after_create_commit :crm_publish_initial_assignment, if: -> { assigned_to.present? }
        after_update_commit :crm_publish_assignment, if: :saved_change_to_assigned_to?
        after_update_commit :crm_publish_status_change, if: :saved_change_to_status_id?
      end

      def sla_snapshot(at: Time.current)
        Crm::Service::SLAState.new(self, at:).snapshot
      end

      private

      def crm_assign_sla
        self.sla ||= Crm::Service::SLAMatcher.call(self)
      end

      def crm_apply_sla_deadlines
        if sla.blank?
          self.sla_response_deadline = nil if will_save_change_to_sla_id?
          self.sla_resolution_deadline = nil if will_save_change_to_sla_id?
          return
        end
        return unless new_record? || will_save_change_to_sla_id? || sla_response_deadline.blank? || sla_resolution_deadline.blank?

        origin = created_at || Time.current
        self.sla_response_deadline = Crm::Service::BusinessHours.deadline(
          from: origin, hours: sla.response_time_hours, business_hours_only: sla.business_hours_only?
        )
        self.sla_resolution_deadline = Crm::Service::BusinessHours.deadline(
          from: origin, hours: sla.resolution_time_hours, business_hours_only: sla.business_hours_only?
        )
      end

      def crm_apply_status_timestamps
        return unless status

        now = Time.current
        if crm_first_response_status? && first_response_at.blank?
          self.first_response_at = now
        end
        if status.is_resolved?
          self.resolved_at ||= now
        elsif will_save_change_to_status_id?
          self.resolved_at = nil
        end
        if status.is_closed?
          self.closed_at ||= now
        elsif will_save_change_to_status_id?
          self.closed_at = nil
        end
      end

      def crm_first_response_status?
        return false unless will_save_change_to_status_id?

        initial_order = TicketStatus.where(active: true).minimum(:sort_order)
        initial_order.present? && status.sort_order > initial_order
      end

      def crm_status_is_available
        return unless new_record? || will_save_change_to_status_id?

        errors.add(:status, "must be active") unless status&.active?
      end

      def crm_closed_status_is_terminal
        return unless will_save_change_to_status_id?

        previous = TicketStatus.find_by(id: status_id_in_database)
        errors.add(:status, "cannot change after the ticket is closed") if previous&.is_closed?
      end

      def crm_resolution_is_present
        errors.add(:resolution, "is required when a ticket is resolved") if status&.is_resolved? && resolution.blank?
      end

      def crm_references_match_account
        if contact && !crm_contact_belongs_to_account?
          errors.add(:contact, "must belong to the selected account")
        end
        errors.add(:asset, "must belong to the selected account") if asset && asset.account_id != account_id
        if service_contract && service_contract.account_id != account_id
          errors.add(:service_contract, "must belong to the selected account")
        end
      end

      def crm_contact_belongs_to_account?
        contact.account_id == account_id || ContactAccount.exists?(contact_id: contact.id, account_id: account_id)
      end

      def crm_service_contract_is_active
        return unless service_contract
        return if service_contract.active_on?(Date.current)

        errors.add(:service_contract, "must be active and cover today's date")
      end

      def crm_sla_is_available
        return unless sla

        errors.add(:sla, "must be active") unless sla.active?
        return if service_contract&.sla_id == sla_id || sla.applies_to?(priority_before_type_cast)

        errors.add(:sla, "does not apply to the selected priority")
      end

      def crm_assignee_is_active
        errors.add(:assignee, "must be active") if assignee && !assignee.active?
      end

      def crm_publish_initial_assignment
        crm_publish_assignment_event(nil, assigned_to)
      end

      def crm_publish_assignment
        crm_publish_assignment_event(*saved_change_to_assigned_to)
      end

      def crm_publish_assignment_event(from, to)
        return if to.blank?

        crm_publish_event("ticket.assigned", {"from_user_id" => from, "to_user_id" => to})
      end

      def crm_publish_status_change
        from, to = saved_change_to_status_id
        crm_publish_event("ticket.status_changed", {"from_status_id" => from, "to_status_id" => to})
      end

      def crm_publish_event(name, payload)
        Crm::DomainEvents.publish_after_commit(Crm::DomainEvents::Event.new(
          id: SecureRandom.uuid, name:, record_type: self.class.name, record_id: id,
          actor_id: Current.profile&.id || updated_by, payload:
        ))
      end
    end
  end
end
