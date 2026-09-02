# frozen_string_literal: true

class RecordChannel < ApplicationCable::Channel
  def subscribed
    object_type = params.fetch("object_type")
    record = Crm::ModelRegistry.model_for(object_type).find(params.fetch("record_id"))
    identity = Crm::AuthorizationContext.for_profile(current_profile)
    return reject unless Pundit.policy!(identity, record).stream?

    stream_for "#{object_type}:#{record.id}"
  rescue ActiveRecord::RecordNotFound, KeyError, Crm::ModelRegistry::UnknownObject
    reject
  end
end
