# frozen_string_literal: true

require "base64"

module Crm
  module Data
    class ExternalHttpAdapter
      MAX_PAGE_SIZE = 100

      def initialize(object_type:, identity:, config:, transport: Crm::OutboundHttp.new)
        @object_type = object_type
        @identity = identity
        @config = config
        @transport = transport
        @model = ModelRegistry.model_for(object_type)
      end

      def list(limit: 25, offset: 0, sort: "id", direction: "asc", query: nil, filters: {})
        response = request(:get, query: {limit: bounded(limit), offset: [offset.to_i, 0].max,
          sort:, direction:, q: query}.merge(filters.to_h))
        return response if response.failure?

        Result.success(records_from(response.value))
      end

      def count(**options)
        response = request(:get, query: {limit: 1, offset: 0, q: options[:query]})
        return response if response.failure?
        payload = response.value
        Result.success((payload["total"] || payload.dig("meta", "total") || collection(payload).length).to_i)
      end

      def search(term, limit: 25) = list(limit:, query: term)
      def export_scope(query: nil, filters: {}) = list(limit: MAX_PAGE_SIZE, query:, filters:)
      def dashboard_scope = export_scope
      def ai_context_scope = export_scope

      def find(id)
        response = request(:get, id:)
        return response if response.failure?

        attributes = response.value["record"] || response.value["data"] || response.value
        Result.success(instantiate(attributes))
      end

      def create(attributes)
        record_id = SecureRandom.uuid
        dispatch_write(:create, record_id, attributes)
      end

      def update(id, attributes) = dispatch_write(:update, id, attributes)
      def delete(id) = dispatch_write(:delete, id, {})

      def authorize_capability(id, capability)
        found = find(id)
        return found if found.failure?

        raise Pundit::NotAuthorizedError unless Pundit.policy!(identity, found.value).public_send(capability)
        Result.success(found.value)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def execute_outbox(entry)
        method = {"create" => :post, "update" => :patch, "delete" => :delete}.fetch(entry.operation)
        response = request(method, id: (entry.record_id unless entry.operation == "create"), body: reverse_map(entry.payload))
        return response if response.failure?
        return Result.success(model.new(id: entry.record_id)) if entry.operation == "delete"

        attributes = response.value["record"] || response.value["data"] || response.value
        attributes = entry.payload.merge("id" => entry.record_id) unless attributes.is_a?(Hash)
        Result.success(instantiate(attributes))
      end

      private

      attr_reader :object_type, :identity, :config, :transport, :model

      def dispatch_write(operation, record_id, attributes)
        if operation == :create
          candidate = model.new(attributes.to_h.stringify_keys.slice(*writable_fields))
          candidate.id = record_id
        else
          existing = find(record_id)
          return existing if existing.failure?
          candidate = existing.value
        end
        query = operation == :create ? :create? : (operation == :update ? :update? : :destroy?)
        raise Pundit::NotAuthorizedError unless Pundit.policy!(identity, candidate).public_send(query)

        dedupe_key = "#{config.id}:#{operation}:#{record_id}:#{Digest::SHA256.hexdigest(JSON.generate(attributes.to_h))}"
        entry = IntegrationOutboxEntry.find_or_create_by!(dedupe_key:) do |outbox|
          outbox.assign_attributes(data_source_config: config, object_type:, record_id:,
            operation: operation.to_s, payload: candidate.attributes.slice(*writable_fields).compact)
        end
        if entry.status_completed?
          return Result.success(candidate) if operation == :delete
          return find(record_id)
        end
        Crm::Integrations::OutboxDispatcher.new(entry:, adapter: self).call
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def request(method, id: nil, body: nil, query: {})
        url = endpoint(id, query:)
        response = transport.call(method:, url:, headers: auth_headers.merge("Content-Type" => "application/json"), body:)
        return response if response.failure?
        return Result.failure(:external_not_found, status: :not_found) if response.value.status == 404
        unless response.value.success?
          return Result.failure(:external_source_error,
            errors: ["The external data source returned HTTP #{response.value.status}."], status: :bad_gateway)
        end

        payload = response.value.body.blank? ? {} : response.value.json
        return Result.failure(:malformed_external_response, errors: ["The external data source returned invalid JSON."], status: :bad_gateway) unless payload

        Result.success(payload)
      end

      def endpoint(id, query: {})
        uri = URI.parse(config.endpoint_url)
        uri.path = [uri.path.delete_suffix("/"), (ERB::Util.url_encode(id.to_s) if id)].compact.join("/")
        clean = query.compact_blank
        uri.query = URI.encode_www_form(clean) if clean.present?
        uri.to_s
      end

      def auth_headers
        values = config.auth_config.to_h.stringify_keys
        case config.auth_type_before_type_cast
        when "BasicAuth"
          {"Authorization" => "Basic #{Base64.strict_encode64("#{values["username"]}:#{values["password"]}")}"}
        when "OAuth2"
          {"Authorization" => "Bearer #{values["access_token"] || values["token"]}"}
        when "APIKey"
          {(values["header_name"].presence || "X-API-Key") => values["api_key"] || values["key"]}
        else {}
        end.compact
      end

      def collection(payload)
        value = payload.is_a?(Array) ? payload : (payload["records"] || payload["data"] || payload["items"] || [])
        value.is_a?(Array) ? value : []
      end

      def records_from(payload) = collection(payload).filter_map { |attributes| instantiate(attributes) if attributes.is_a?(Hash) }

      def instantiate(attributes)
        mapped = map_fields(attributes.to_h.stringify_keys).slice(*model.column_names)
        mapped["id"] ||= attributes["id"] || attributes[:id]
        model.instantiate(mapped)
      end

      def map_fields(attributes)
        mapping = config.field_mapping.to_h.stringify_keys
        attributes.to_h.transform_keys { |key| mapping[key.to_s] || key.to_s }
      end

      def reverse_map(attributes)
        reverse = config.field_mapping.to_h.stringify_keys.invert
        attributes.to_h.transform_keys { |key| reverse[key.to_s] || key.to_s }
      end

      def writable_fields = @writable_fields ||= ModelRegistry.writable_fields(object_type).pluck("name")
      def bounded(value) = [[value.to_i, 1].max, MAX_PAGE_SIZE].min
    end
  end
end
