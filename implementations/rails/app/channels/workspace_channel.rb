# frozen_string_literal: true

class WorkspaceChannel < ApplicationCable::Channel
  ALLOWED_TYPES = {"DealRoom" => DealRoom, "Ticket" => Ticket}.freeze

  def subscribed
    model = ALLOWED_TYPES.fetch(params.fetch("workspace_type"))
    record = model.find(params.fetch("workspace_id"))
    identity = Crm::AuthorizationContext.for_profile(current_profile)
    return reject unless Pundit.policy!(identity, record).stream?

    stream_for "#{record.class.name}:#{record.id}"
  rescue ActiveRecord::RecordNotFound, KeyError
    reject
  end
end
