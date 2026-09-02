# frozen_string_literal: true

require "csv"

module Crm
  class CSVExport
    def initialize(object_type:, records:, fields:, identity:)
      @object_type = object_type
      @records = records
      @fields = fields
      @identity = identity
      @reference_maps = build_reference_maps
    end

    def each_line
      return enum_for(__method__) unless block_given?

      yield CSV.generate_line(fields.map { |field| translated_field_label(field) })
      records.find_each(batch_size: 250) do |record|
        yield CSV.generate_line(fields.map { |field| safe_spreadsheet_value(value_for(record, field)) })
      end
    end

    private

    attr_reader :object_type, :records, :fields, :identity, :reference_maps

    def build_reference_maps
      fields.select { |field| field.fetch("type") == "reference" && field["target"] }.to_h do |field|
        ids = records.where.not(field.fetch("name") => nil).distinct.pluck(field.fetch("name"))
        model = ModelRegistry.model_for(field.fetch("target"))
        scope = Pundit.policy_scope!(identity, model).where(id: ids)
        [field.fetch("name"), scope.to_h { |record| [record.id, RecordPresentation.display_name(record)] }]
      end
    end

    def value_for(record, field)
      name = field.fetch("name")
      value = record.public_send(name)
      return "" if value.nil?
      return NumberCounter.display(value) if field["auto_generated"]

      case field.fetch("type")
      when "reference" then reference_maps.fetch(name, {}).fetch(value, "")
      when "enum" then translated_enum_label(record.class, name, value)
      when "date", "datetime" then value.iso8601
      when "boolean" then value ? translated("ui.yes", "Yes") : translated("ui.no", "No")
      when "json" then JSON.generate(value)
      else value.to_s
      end
    end

    def translated_enum_label(model, name, value)
      mapping = model.defined_enums.fetch(name, {})
      raw = mapping.fetch(value.to_s, value.to_s)
      translated("enum.#{raw}", raw)
    end

    def translated_field_label(field)
      fallback = field.fetch("description", field.fetch("name").humanize)
      translated("field.#{object_type}.#{field.fetch("name")}", fallback)
    end

    def translated(key, fallback)
      TranslationService.translate(key, fallback:, profile: identity.profile)
    end

    def safe_spreadsheet_value(value)
      text = value.to_s
      text.match?(/\A[=+\-@]/) ? "'#{text}" : text
    end
  end
end
