# frozen_string_literal: true

module Crm
  class ListSort
    Setting = ::Data.define(:object_type, :sort_by, :direction, :field, :missing_count)

    def self.for(object_type)
      definition = ModelRegistry.fetch(object_type)
      preference = ListSortSetting.find_by(object_type: object_type)
      sort_by = preference&.sort_by || "Number"
      direction = preference&.direction || "Asc"
      field = resolve_field(definition, sort_by)
      missing_count = definition["auto_number_field"] ? ModelRegistry.model_for(object_type).where(definition.fetch("auto_number_field") => [nil, ""]).count : 0
      Setting.new(object_type: object_type, sort_by: sort_by, direction: direction, field: field, missing_count: missing_count)
    end

    def self.update(object_type:, sort_by:, direction:, actor:)
      record = ListSortSetting.find_or_initialize_by(object_type: object_type)
      action = record.new_record? ? :create : :update
      record.assign_attributes(sort_by: sort_by, direction: direction)
      Current.set(profile: actor) do
        ApplicationRecord.transaction do
          changes = record.changes
          record.save!
          AuditWriter.record!(record: record, action: action, changes: changes)
        end
      end
      Result.success(record, code: action)
    rescue StandardError => error
      ErrorMapper.call(error)
    end

    def self.resolve_field(definition, sort_by)
      if sort_by == "Name"
        definition.fetch("display_name_fields").first || definition["auto_number_field"] || "created_at"
      else
        definition["auto_number_field"] || "created_at"
      end
    end
    private_class_method :resolve_field
  end
end
