# frozen_string_literal: true

module Crm
  module AI
    module Providers
      class Base
        DEFAULT_MAX_TOKENS = 1_200

        def initialize(config:, transport: Crm::OutboundHttp.new)
          @config = config
          @transport = transport
        end

        def chat(messages:, system: nil, structured: false)
          request = build_request(normalize_messages(messages, system), structured:)
          response = transport.call(**request)
          return response if response.failure?
          return provider_failure(response.value.status) unless response.value.success?

          payload = response.value.json
          content = payload && extract_content(payload)
          return Result.failure(:malformed_provider_response, errors: ["The AI provider returned an invalid response."], status: :bad_gateway) if content.blank?

          Result.success({content:, model: extract_model(payload), tokens_used: extract_tokens(payload)})
        rescue StandardError => error
          Rails.logger.warn("AI provider response rejected (#{error.class.name})")
          Result.failure(:ai_provider_error, errors: ["The AI provider response could not be processed."], status: :bad_gateway)
        end

        private

        attr_reader :config, :transport

        def normalize_messages(messages, system)
          normalized = Array(messages).filter_map do |message|
            role = message[:role] || message["role"]
            content = message[:content] || message["content"]
            next unless role.to_s.in?(%w[user assistant]) && content.present?

            {role: role.to_s, content: content.to_s.slice(0, 20_000)}
          end
          system.present? ? [{role: "system", content: system.to_s.slice(0, 30_000)}] + normalized : normalized
        end

        def provider_failure(status)
          Rails.logger.warn("AI provider returned HTTP #{status}")
          Result.failure(:ai_provider_error, errors: ["The AI provider could not complete the request."], status: :bad_gateway)
        end
      end
    end
  end
end
