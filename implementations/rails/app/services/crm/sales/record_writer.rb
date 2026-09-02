# frozen_string_literal: true

module Crm
  module Sales
    class RecordWriter
      def initialize(identity:)
        @identity = identity
      end

      def create!(model, attributes, authorize: true)
        record = model.new(attributes)
        authorize!(record, :create?) if authorize
        record.save!
        audit_and_publish(record, :create, record.previous_changes)
        record
      end

      def update!(record, attributes, authorize: true)
        authorize!(record, :update?) if authorize
        record.assign_attributes(attributes)
        record.save!
        audit_and_publish(record, :update, record.previous_changes)
        record
      end

      def destroy!(record, authorize: true)
        authorize!(record, :destroy?) if authorize
        AuditWriter.record!(record:, action: :delete)
        record.destroy!
        publish(record, :delete, [])
        record
      end

      def authorize!(record, query)
        raise Pundit::NotAuthorizedError unless Pundit.policy!(identity, record).public_send(query)
      end

      private

      attr_reader :identity

      def audit_and_publish(record, action, changes)
        AuditWriter.record!(record:, action:, changes:)
        publish(record, action, changes.keys)
      end

      def publish(record, action, fields)
        DomainEvents.publish_after_commit(DomainEvents::Event.new(
          id: SecureRandom.uuid,
          name: "#{record.class.name.underscore}.#{action}",
          record_type: record.class.name,
          record_id: record.id,
          actor_id: identity.profile.id,
          payload: {"changed_fields" => fields}
        ))
      end
    end
  end
end
