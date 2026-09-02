# frozen_string_literal: true

module Crm
  module Replication
    class Runner
      MAX_RECORDS = 5_000

      def initialize(run:, identity:, transport: Crm::OutboundHttp.new)
        @run = run
        @identity = identity
        @transport = transport
        @config = run.replication_config
      end

      def call
        return Result.success(run, code: :existing) if run.status_completed?

        Current.set(profile: identity.profile, api_token: identity.api_token) do
          run.update!(status: "Running", started_at: Time.current)
          response = transport.call(method: config.request_body.present? ? :post : :get,
            url: config.endpoint_url, headers: auth_headers.merge("Content-Type" => "application/json"),
            body: (config.request_body if config.request_body.present?))
          return fail_run(response.errors) if response.failure? || !response.value.success?

          payload = response.value.json
          rows = extract_rows(payload)
          return fail_run(["The replication source returned invalid JSON."]) unless rows

          counts = {processed: 0, created: 0, updated: 0, skipped: 0, errors: []}
          rows.first(MAX_RECORDS).each { |row| process(row, counts) }
          run.update!(status: "Completed", processed_count: counts[:processed], created_count: counts[:created],
            updated_count: counts[:updated], skipped_count: counts[:skipped], error_count: counts[:errors].length,
            error_details: counts[:errors].first(100), completed_at: Time.current)
          config.update!(last_run_at: Time.current)
          Result.success(run)
        end
      rescue StandardError => error
        Rails.logger.warn("Replication run failed (#{error.class.name})")
        fail_run(["Replication could not be completed."])
      end

      private

      attr_reader :run, :identity, :transport, :config

      def process(row, counts)
        counts[:processed] += 1
        unless row.is_a?(Hash)
          counts[:errors] << "Row #{counts[:processed]} is not an object."
          return
        end
        if config.delete_flag_field.present? && ActiveModel::Type::Boolean.new.cast(row[config.delete_flag_field])
          counts[:skipped] += 1
          return
        end

        attributes = map(row).slice(*writable_fields)
        key = config.key_field
        source_key = config.source_key_field.presence || config.field_mapping.to_h.invert[key] || key
        key_value = attributes[key] || row[source_key]
        if key_value.blank?
          counts[:errors] << "Row #{counts[:processed]} has no #{source_key}."
          return
        end
        attributes[key] = key_value
        adapter = Data::LocalActiveRecordAdapter.new(object_type: config.object_type, identity:)
        existing = Pundit.policy_scope!(identity, model).find_by(key => key_value)
        result = existing ? adapter.update(existing.id, attributes) : adapter.create(attributes)
        if result.success?
          counts[existing ? :updated : :created] += 1
        else
          counts[:errors] << "Row #{counts[:processed]}: #{result.errors.to_sentence.presence || result.code}"
        end
      rescue StandardError => error
        Rails.logger.warn("Replication row rejected (#{error.class.name})")
        counts[:errors] << "Row #{counts[:processed]} could not be imported."
      end

      def extract_rows(payload)
        return payload if payload.is_a?(Array)
        return unless payload.is_a?(Hash)

        value = payload["records"] || payload["data"] || payload["items"]
        value if value.is_a?(Array)
      end

      def map(row)
        mapping = config.field_mapping.to_h.stringify_keys
        row.stringify_keys.transform_keys { |key| mapping[key] || key }
      end

      def auth_headers
        values = JSON.parse(config.auth_config.presence || "{}")
        return {} if values.blank?
        return {"Authorization" => "Bearer #{values["token"]}"} if values["token"].present?

        {(values["header_name"].presence || "X-API-Key") => values["api_key"]}.compact
      rescue JSON::ParserError
        {}
      end

      def model = @model ||= ModelRegistry.model_for(config.object_type)
      def writable_fields = @writable_fields ||= ModelRegistry.writable_fields(config.object_type).pluck("name")

      def fail_run(errors)
        run.update!(status: "Failed", error_count: Array(errors).length,
          error_details: Array(errors).map { |error| error.to_s.slice(0, 500) }, completed_at: Time.current)
        Result.failure(:replication_failed, errors: run.error_details, value: run, status: :bad_gateway)
      end
    end
  end
end
