# frozen_string_literal: true

module Crm
  module Workspace
    class Actions
      def initialize(identity:)
        @identity = identity
      end

      def close_deal_room(room)
        locked_update(room, status: "Closed")
      end

      def update_deal_stage(room, stage_id:)
        return Result.failure(:closed, errors: ["Closed Deal Rooms are read-only."]) if room.status_closed?

        locked_update(room.opportunity, stage_id:)
      end

      def update_ticket_status(ticket, status_id:, resolution: nil)
        attributes = {status_id:}
        attributes[:resolution] = resolution if resolution.present?
        locked_update(ticket, attributes)
      end

      def link_knowledge_article(ticket, article_id:)
        authorize!(ticket, :relationship?)
        result = RelationshipLinker.new(object_type: "Ticket", record: ticket,
          relationship_name: "knowledge_articles", identity:).link(related_id: article_id, junction_attributes: {})
        broadcast(ticket) if result.success?
        result
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      private

      attr_reader :identity

      def locked_update(record, attributes)
        authorize!(record, :update?)
        lock = RecordLocks.acquire(object_type: record.class.name, record_id: record.id, holder: identity.profile)
        return lock if lock.failure?

        update_record(record, attributes)
      ensure
        RecordLocks.release(object_type: record.class.name, record_id: record.id, holder: identity.profile) if lock&.success?
      end

      def update_record(record, attributes)
        result = Data::LocalActiveRecordAdapter.new(object_type: record.class.name, identity:).update(record.id, attributes)
        broadcast(record) if result.success?
        result
      end

      def authorize!(record, query)
        raise Pundit::NotAuthorizedError unless Pundit.policy!(identity, record).public_send(query)
      end

      def broadcast(record)
        WorkspaceChannel.broadcast_to("#{record.class.name}:#{record.id}", {
          "action" => "refresh", "actor_id" => identity.profile.id
        })
      end
    end
  end
end
