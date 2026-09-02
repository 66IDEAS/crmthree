# frozen_string_literal: true

class SLABreachCheckJob < ApplicationJob
  queue_as :default

  def perform(at: Time.current)
    system = UserProfile.find(Crm::Seeds::SYSTEM_PROFILE_ID)
    Ticket.where.not(sla_id: nil).find_each do |ticket|
      snapshot = ticket.sla_snapshot(at:)
      publish(ticket, system, "response") if snapshot.response == :breached
      publish(ticket, system, "resolution") if snapshot.resolution == :breached
    end
  end

  private

  def publish(ticket, actor, kind)
    recipient = ticket.assignee || ticket.owner
    return unless recipient&.active?

    Crm::DomainEvents.publish_after_commit(Crm::DomainEvents::Event.new(
      id: SecureRandom.uuid,
      name: "ticket.sla_breached", record_type: "Ticket", record_id: ticket.id,
      actor_id: actor.id, payload: {"kind" => kind, "recipient_id" => recipient.id}
    ))
  end
end
