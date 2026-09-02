# frozen_string_literal: true

module Crm
  module Data
    class LocalActiveRecordAdapter
      MAX_PAGE_SIZE = 100

      def initialize(object_type:, identity:)
        @object_type = object_type.to_s
        @identity = identity
        @model = ModelRegistry.model_for(@object_type)
      end

      def list(limit: 25, offset: 0, sort: "id", direction: "asc", query: nil, filters: {})
        sort_field = allowed_sort(sort)
        ordering = {sort_field => allowed_direction(direction)}
        ordering["id"] = :asc unless sort_field == "id"
        relation = sortable_scope(filtered_scope(query, filters), sort_field).order(ordering)
          .limit([[limit.to_i, 1].max, MAX_PAGE_SIZE].min).offset([offset.to_i, 0].max)
        Result.success(relation)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def count(query: nil, sort: nil, filters: {})
        scope = filtered_scope(query, filters)
        scope = sortable_scope(scope, allowed_sort(sort)) if sort
        Result.success(scope.count)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def search(term, limit: 25)
        Result.success(searchable_scope(term).limit([[limit.to_i, 1].max, MAX_PAGE_SIZE].min))
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def export_scope(query: nil, filters: {})
        Result.success(filtered_scope(query, filters).order(:id))
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def dashboard_scope = export_scope
      def ai_context_scope = export_scope

      def related(id, relationship_name)
        record = authorized_scope.find(id)
        authorize!(record, :show?)
        relationship = model.crm_definition.fetch("relationships").find do |candidate|
          candidate.fetch("name") == relationship_name.to_s
        end
        raise ModelRegistry::UnknownObject, "Unknown relationship" unless relationship

        target = ModelRegistry.model_for(relationship.fetch("target"))
        related_scope = record.association(relationship_name.to_sym).scope
        Result.success(Pundit.policy_scope!(identity, target).where(id: related_scope.select(:id)))
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def import(rows, idempotency_key:)
        Idempotency.run(operation: "#{object_type}.import", key: idempotency_key, actor: identity.profile) do
          Transaction.run do
            records = []
            failure = nil
            rows.each do |attributes|
              result = create(attributes)
              if result.failure?
                failure = result
                break
              end
              records << result.value
            end
            failure || Result.success(records, code: :imported)
          end
        end
      end

      def find(id)
        record = authorized_scope.find(id)
        authorize!(record, :show?)
        Result.success(record)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def create(attributes)
        record = model.new(allowed_attributes(attributes))
        authorize!(record, :create?)
        persist(record, :create)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def update(id, attributes)
        record = authorized_scope.find(id)
        authorize!(record, :update?)
        record.assign_attributes(allowed_attributes(attributes))
        persist(record, :update)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def delete(id)
        record = authorized_scope.find(id)
        authorize!(record, :destroy?)
        with_actor do
          ApplicationRecord.transaction do
            AuditWriter.record!(record: record, action: :delete)
            record.destroy!
          end
        end
        Result.success(record)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def authorize_capability(id, capability)
        record = authorized_scope.find(id)
        authorize!(record, capability)
        Result.success(record)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      private

      attr_reader :object_type, :identity, :model

      def authorized_scope
        Pundit.policy_scope!(identity, model)
      end

      def searchable_scope(term)
        return authorized_scope if term.to_s.strip.blank?

        fields = model.crm_definition.fetch("searchable_fields") & model.column_names
        return authorized_scope.none if fields.empty?

        escaped = ActiveRecord::Base.sanitize_sql_like(term.to_s.strip)
        table = model.connection.quote_table_name(model.table_name)
        conditions = fields.map do |field|
          "#{table}.#{model.connection.quote_column_name(field)} LIKE :query ESCAPE '\\'"
        end
        authorized_scope.where(conditions.join(" OR "), query: "%#{escaped}%")
      end

      def filtered_scope(term, filters)
        filters.to_h.reduce(searchable_scope(term)) do |scope, (field, value)|
          next scope unless model.column_names.include?(field.to_s)

          values = Array(value).compact_blank
          values.any? ? scope.where(field => values) : scope
        end
      end

      def sortable_scope(scope, field)
        return scope if field == "id"

        scope.where.not(field => [nil, ""])
      end

      def authorize!(record, query)
        raise Pundit::NotAuthorizedError unless Pundit.policy!(identity, record).public_send(query)
      end

      def persist(record, action, changes: nil)
        with_actor do
          ApplicationRecord.transaction do
            record.save!
            audit_changes = changes || record.previous_changes
            AuditWriter.record!(record: record, action: action, changes: audit_changes)
            DomainEvents.publish_after_commit(DomainEvents::Event.new(
              id: SecureRandom.uuid,
              name: "#{record.class.name.underscore}.#{action}",
              record_type: record.class.name,
              record_id: record.id,
              actor_id: identity.profile.id,
              payload: {"changed_fields" => audit_changes.keys}
            ))
          end
        end
        Result.success(record, code: action)
      end

      def with_actor(&block)
        Current.set(profile: identity.profile, api_token: identity.api_token, &block)
      end

      def allowed_attributes(attributes)
        allowed = ModelRegistry.writable_fields(object_type).map { |field| field.fetch("name") }
        attributes.to_h.stringify_keys.slice(*allowed)
      end

      def allowed_sort(value)
        model.column_names.include?(value.to_s) ? value.to_s : "id"
      end

      def allowed_direction(value)
        value.to_s.downcase == "desc" ? :desc : :asc
      end
    end
  end
end
