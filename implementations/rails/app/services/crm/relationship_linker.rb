# frozen_string_literal: true

module Crm
  class RelationshipLinker
    def initialize(object_type:, record:, relationship_name:, identity:)
      @object_type = object_type
      @record = record
      @identity = identity
      @relationship = ModelRegistry.fetch(object_type).fetch("relationships").find do |candidate|
        candidate.fetch("name") == relationship_name.to_s && candidate.fetch("type") == "many-to-many"
      end
      raise ModelRegistry::UnknownObject, "Unknown linkable relationship" unless @relationship
    end

    def link(related_id:, junction_attributes: {})
      attributes = {
        parent_field.fetch("name") => record.id,
        target_field.fetch("name") => related_id
      }.merge(junction_attributes.to_h.stringify_keys.slice(*junction_attribute_names))
      junction_adapter.create(attributes)
    end

    def unlink(related_id:)
      junction = Pundit.policy_scope!(identity, junction_model).find_by!(
        parent_field.fetch("name") => record.id,
        target_field.fetch("name") => related_id
      )
      junction_adapter.delete(junction.id)
    end

    def junction_fields
      fields = ModelRegistry.writable_fields(relationship.fetch("through")).reject { |field| field.fetch("type") == "reference" }
      fields.reject { |field| field.fetch("name") == "linked_at" } if relationship.fetch("through") == "TicketKnowledgeArticle"
      fields
    end

    private

    attr_reader :object_type, :record, :identity, :relationship

    def junction_model
      @junction_model ||= ModelRegistry.model_for(relationship.fetch("through"))
    end

    def junction_adapter
      @junction_adapter ||= DataSourceRouter.for(object_type: relationship.fetch("through"), identity: identity).value
    end

    def references
      @references ||= ModelRegistry.fetch(relationship.fetch("through")).fetch("specific_fields")
        .select { |field| field.fetch("type") == "reference" }
    end

    def parent_field
      @parent_field ||= references.find { |field| field.fetch("target") == object_type }
    end

    def target_field
      @target_field ||= references.find { |field| field.fetch("target") == relationship.fetch("target") }
    end

    def junction_attribute_names
      junction_fields.map { |field| field.fetch("name") }
    end
  end
end
