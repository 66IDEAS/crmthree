# frozen_string_literal: true

module Crm
  class ReferenceCatalog
    MAX_OPTIONS = 250

    def initialize(object_type:, identity:)
      @definition = ModelRegistry.fetch(object_type)
      @identity = identity
    end

    def for_records(records)
      fields.to_h do |field|
        ids = records.filter_map { |record| record.public_send(field.fetch("name")) }.uniq
        [field.fetch("name"), labels_for(field, ids: ids)]
      end
    end

    def form_options
      fields.to_h do |field|
        labels = labels_for(field)
        [field.fetch("name"), labels.sort_by { |_id, label| label.to_s.downcase }]
      end
    end

    private

    attr_reader :definition, :identity

    def fields
      definition.fetch("specific_fields").select { |field| field.fetch("type") == "reference" }
    end

    def labels_for(field, ids: nil)
      model = ModelRegistry.model_for(field.fetch("target"))
      scope = Pundit.policy_scope!(identity, model)
      if ids.nil?
        scope = scope.where(active: true) if field.fetch("target").in?(%w[PipelineStage TicketStatus SLA UserProfile])
        scope = scope.where(status: "Active") if field.fetch("target").in?(%w[ServiceContract Asset])
      end
      scope = scope.where(id: ids) if ids
      scope.limit(MAX_OPTIONS).to_h { |record| [record.id, RecordPresentation.display_name(record)] }
    rescue Pundit::NotAuthorizedError
      {}
    end
  end
end
