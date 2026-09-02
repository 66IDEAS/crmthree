# frozen_string_literal: true

module Crm
  module DomainEvents
    Event = ::Data.define(:id, :name, :record_type, :record_id, :actor_id, :payload)

    mattr_accessor :subscribers, default: []

    module_function

    def subscribe(&block)
      self.subscribers += [block]
    end

    def publish_after_commit(event)
      raise ArgumentError, "Expected a typed domain event" unless event.is_a?(Event)

      ActiveRecord.after_all_transactions_commit do
        Crm::Service::NotificationHandler.call(event)
        Crm::Gamification::EventHandler.call(event)
        subscribers.each { |subscriber| subscriber.call(event) }
      end
    end

    def reset!
      self.subscribers = []
    end
  end
end
