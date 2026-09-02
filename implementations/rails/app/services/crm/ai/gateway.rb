# frozen_string_literal: true

module Crm
  module AI
    class Gateway
      def initialize(provider: nil, transport: Crm::OutboundHttp.new)
        @provider = provider
        @transport = transport
      end

      def available? = provider.present?

      def chat(messages:, system: nil)
        return unavailable unless provider

        provider.chat(messages:, system:)
      end

      def structured(messages:, system:, required_keys: [])
        return unavailable unless provider

        response = provider.chat(messages:, system:, structured: true)
        return response if response.failure?

        parsed = parse_json(response.value.fetch(:content))
        return malformed unless parsed.is_a?(Hash) && required_keys.all? { |key| parsed.key?(key.to_s) }

        Result.success(parsed)
      end

      private

      def provider
        @provider ||= build_active_provider
      end

      def build_active_provider
        config = AIProviderConfig.find_by(is_active: true)
        return unless config

        case config.provider_before_type_cast
        when "OpenAI", "Moonshot" then Providers::OpenAICompatible.new(config:, transport: @transport)
        when "Anthropic" then Providers::Anthropic.new(config:, transport: @transport)
        when "Google" then Providers::Google.new(config:, transport: @transport)
        end
      end

      def parse_json(content)
        JSON.parse(content.to_s.sub(/\A```(?:json)?\s*/i, "").sub(/\s*```\z/, ""))
      rescue JSON::ParserError
        nil
      end

      def unavailable
        Result.failure(:ai_not_configured, errors: ["AI is not configured. Ask an administrator to activate a provider."], status: :service_unavailable)
      end

      def malformed
        Result.failure(:malformed_ai_response, errors: ["The AI response did not match the required format."], status: :bad_gateway)
      end
    end
  end
end
