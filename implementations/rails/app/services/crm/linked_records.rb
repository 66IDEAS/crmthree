# frozen_string_literal: true

module Crm
  class LinkedRecords
    ParentCard = ::Data.define(:field, :object_type, :record_id, :label)
    ChildCard = ::Data.define(:relationship, :records, :total_count, :references, :junctions, :link_options)
    EXCLUDED_PARENTS = %w[owner_id author_id uploaded_by linked_by user_id].freeze
    CARD_LIMIT = 5

    def initialize(object_type:, record:, identity:, references:)
      @object_type = object_type
      @record = record
      @identity = identity
      @references = references
      @definition = ModelRegistry.fetch(object_type)
    end

    def parents
      reference_fields.filter_map do |field|
        id = record.public_send(field.fetch("name"))
        next if id.blank? || field.fetch("name").in?(EXCLUDED_PARENTS)

        label = references.dig(field.fetch("name"), id)
        ParentCard.new(field: field, object_type: field.fetch("target"), record_id: id, label: label || id)
      end
    end

    def children
      definition.fetch("relationships", []).filter_map do |relationship|
        result = source_adapter.related(record.id, relationship.fetch("name"))
        next unless result.success?

        scope = result.value
        records = relationship.fetch("target") == "LineItem" ? scope.to_a : scope.limit(CARD_LIMIT).to_a
        ChildCard.new(
          relationship: relationship,
          records: records,
          total_count: scope.count,
          references: ReferenceCatalog.new(object_type: relationship.fetch("target"), identity: identity).for_records(records),
          junctions: junctions_for(relationship, records),
          link_options: link_options_for(relationship, scope)
        )
      end
    end

    private

    attr_reader :object_type, :record, :identity, :references, :definition

    def reference_fields
      definition.fetch("specific_fields").select { |field| field.fetch("type") == "reference" }
    end

    def source_adapter
      @source_adapter ||= DataSourceRouter.for(object_type: object_type, identity: identity).value
    end

    def junctions_for(relationship, records)
      return {} unless relationship.fetch("type") == "many-to-many"

      junction_model = ModelRegistry.model_for(relationship.fetch("through"))
      parent_field, target_field = junction_reference_fields(relationship)
      scope = Pundit.policy_scope!(identity, junction_model).where(parent_field.fetch("name") => record.id)
        .where(target_field.fetch("name") => records.map(&:id))
      scope.to_h { |junction| [junction.public_send(target_field.fetch("name")), junction] }
    end

    def link_options_for(relationship, related_scope)
      return [] unless relationship.fetch("type") == "many-to-many"

      target = ModelRegistry.model_for(relationship.fetch("target"))
      existing_ids = related_scope.select(:id)
      Pundit.policy_scope!(identity, target).where.not(id: existing_ids).limit(ReferenceCatalog::MAX_OPTIONS)
        .map { |candidate| [candidate.id, RecordPresentation.display_name(candidate)] }
        .sort_by { |_id, label| label.to_s.downcase }
    end

    def junction_reference_fields(relationship)
      fields = ModelRegistry.fetch(relationship.fetch("through")).fetch("specific_fields")
        .select { |field| field.fetch("type") == "reference" }
      [fields.find { |field| field.fetch("target") == object_type }, fields.find { |field| field.fetch("target") == relationship.fetch("target") }]
    end
  end
end
