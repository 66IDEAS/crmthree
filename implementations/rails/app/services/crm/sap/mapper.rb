# frozen_string_literal: true

module Crm
  module SAP
    class Mapper
      def self.schema(object_type)
        ModelRegistry.fetch(object_type).fetch("fields").filter_map do |field|
          next unless field["sap_field"]
          {crm_field: field.fetch("name"), sap_field: field.fetch("sap_field"), sap_type: field.fetch("sap_type"),
            required: field.fetch("required", false), length: field["length"], precision: field["precision"], scale: field["scale"]}
        end
      end

      def self.export(object_type, record)
        schema(object_type).to_h do |definition|
          field = ModelRegistry.field(object_type, definition.fetch(:crm_field))
          value = export_value(record, field)
          [definition.fetch(:sap_field), format(value, field.fetch("sap_type"))]
        end
      end

      def self.import(object_type, payload)
        fields = ModelRegistry.fetch(object_type).fetch("fields").select { |field| field["sap_field"] }
        fields.to_h do |field|
          raw = payload[field.fetch("sap_field")] || payload[field.fetch("sap_field").to_sym]
          [field.fetch("name"), parse(raw, field)]
        end.compact
      end

      def self.export_value(record, field)
        value = record.public_send(field.fetch("name"))
        return value unless field.fetch("type") == "reference" && value.present?

        target = ModelRegistry.model_for(field.fetch("target"))
        key = ModelRegistry.fetch(field.fetch("target"))["auto_number_field"]
        key ? target.find_by(id: value)&.public_send(key) : value
      end
      private_class_method :export_value

      def self.format(value, type)
        return nil if value.nil?
        kind, dimensions = type.split(" ", 2)
        case kind
        when "NUMC" then value.to_s.rjust(dimensions.to_i, "0")
        when "DATS" then value.to_date.strftime("%Y%m%d")
        when "CURR", "QUAN"
          scale = dimensions.to_s.split(".").last.to_i
          Kernel.format("%.#{scale}f", value.to_d)
        else value.to_s
        end
      end
      private_class_method :format

      def self.parse(value, field)
        return nil if value.nil?
        if field.fetch("type") == "reference"
          target = ModelRegistry.model_for(field.fetch("target"))
          key = ModelRegistry.fetch(field.fetch("target"))["auto_number_field"]
          return key ? target.find_by(key => value.to_s)&.id : value
        end

        case field.fetch("type")
        when "date" then Date.strptime(value.to_s, "%Y%m%d")
        when "currency", "decimal" then value.to_d
        when "integer" then value.to_i
        else value.to_s
        end
      rescue Date::Error
        nil
      end
      private_class_method :parse
    end
  end
end
