# frozen_string_literal: true

require "csv"

module Crm
  class CSVImport
    class << self
      def preview(file:, object_type:, actor:)
        validate_file!(file)
        source = file.read.to_s.dup.force_encoding(Encoding::UTF_8)
        raise ArgumentError, "CSV must be valid UTF-8" unless source.valid_encoding?

        table = CSV.parse(source, headers: true)
        headers = table.headers.compact.map(&:to_s)
        raise ArgumentError, "CSV needs a header row" if headers.empty?

        run = ImportRun.create!(
          user_profile: actor, object_type:, filename: file.original_filename.to_s,
          source_csv: source, headers:, preview_rows: table.first(5).map(&:to_h),
          mapping: auto_mapping(object_type:, headers:, actor:), total_rows: table.length,
          idempotency_key: SecureRandom.uuid, status: "Preview"
        )
        Result.success(run, code: :previewed)
      rescue CSV::MalformedCSVError, ArgumentError, ActiveRecord::RecordInvalid => error
        Result.failure(:invalid_csv, errors: [error.message], status: :unprocessable_entity)
      end

      def queue(run:, mapping:)
        errors = mapping_errors(run.object_type, mapping)
        return Result.failure(:invalid_mapping, errors:) if errors.any?

        run.update!(mapping:, status: "Queued")
        ImportRecordsJob.perform_later(run.id)
        Result.success(run, code: :queued)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def mapped_attributes(run:, row:, actor:)
        model = ModelRegistry.model_for(run.object_type)
        definitions = ModelRegistry.writable_fields(run.object_type).index_by { |field| field.fetch("name") }
        run.mapping.to_h.each_with_object({}) do |(name, rule), attributes|
          field = definitions[name]
          next unless field

          rule = rule.to_h.stringify_keys
          next if rule["mode"] == "skip"

          raw = rule["mode"] == "fixed" ? rule["value"] : row[rule["value"]]
          attributes[name] = cast(raw, field:, model:)
        end.tap { |attributes| add_actor_defaults!(attributes, definitions:, actor:) }
      end

      def mapping_errors(object_type, mapping)
        definitions = ModelRegistry.writable_fields(object_type)
        definitions.filter_map do |field|
          next unless field["required"]
          next if field["default"].present? || actor_default_field?(field.fetch("name"))

          rule = mapping[field.fetch("name")].to_h.stringify_keys
          "#{field.fetch("description", field.fetch("name").humanize)} must be mapped" if rule["mode"].blank? || rule["mode"] == "skip"
        end
      end

      private

      def validate_file!(file)
        raise ArgumentError, "Select a CSV file" unless file.respond_to?(:read)
        raise ArgumentError, "CSV files are limited to 5 MB" if file.size.to_i > ImportRun::MAX_BYTES
        raise ArgumentError, "The selected file must use a .csv extension" unless File.extname(file.original_filename.to_s).casecmp?(".csv")
      end

      def auto_mapping(object_type:, headers:, actor:)
        normalized_headers = headers.index_by { |header| normalize(header) }
        ModelRegistry.writable_fields(object_type).to_h do |field|
          name = field.fetch("name")
          match = normalized_headers[normalize(name)] || normalized_headers[normalize(field.fetch("description", ""))]
          rule = if match
            {"mode" => "column", "value" => match}
          elsif actor_default_field?(name)
            {"mode" => "fixed", "value" => actor.id}
          elsif field.key?("default")
            {"mode" => "fixed", "value" => field["default"].to_s}
          else
            {"mode" => "skip", "value" => ""}
          end
          [name, rule]
        end
      end

      def normalize(value)
        value.to_s.downcase.gsub(/[^a-z0-9]/, "")
      end

      def actor_default_field?(name)
        name.in?(%w[owner_id author_id uploaded_by linked_by user_id])
      end

      def add_actor_defaults!(attributes, definitions:, actor:)
        definitions.each_key do |name|
          attributes[name] = actor.id if actor_default_field?(name) && attributes[name].blank?
        end
      end

      def cast(value, field:, model:)
        return nil if value.blank? && !field["required"]

        case field.fetch("type")
        when "integer" then value.to_i
        when "decimal", "currency" then BigDecimal(value.to_s)
        when "boolean" then ActiveModel::Type::Boolean.new.cast(value)
        when "date" then Date.iso8601(value.to_s)
        when "datetime" then Time.zone.parse(value.to_s)
        when "json" then value.is_a?(String) ? JSON.parse(value) : value
        when "enum" then enum_value(model, field.fetch("name"), value)
        else value
        end
      end

      def enum_value(model, field, value)
        mapping = model.defined_enums.fetch(field, {})
        mapping.key?(value.to_s) ? value.to_s : (mapping.key(value.to_s) || value)
      end
    end
  end
end
