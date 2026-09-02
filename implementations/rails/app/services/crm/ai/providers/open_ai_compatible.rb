# frozen_string_literal: true

module Crm
  module AI
    module Providers
      class OpenAICompatible < Base
        DEFAULT_ENDPOINTS = {
          "OpenAI" => "https://api.openai.com/v1/chat/completions",
          "Moonshot" => "https://api.moonshot.ai/v1/chat/completions"
        }.freeze

        private

        def build_request(messages, structured:)
          endpoint = config.endpoint_url.presence || DEFAULT_ENDPOINTS.fetch(config.provider_before_type_cast)
          endpoint = "#{endpoint.delete_suffix("/")}/chat/completions" unless endpoint.end_with?("/chat/completions")
          body = {model: config.model, messages:, temperature: 0.2}
          body[:response_format] = {type: "json_object"} if structured
          {method: :post, url: endpoint, headers: {"Authorization" => "Bearer #{config.api_key}",
            "Content-Type" => "application/json"}, body:}
        end

        def extract_content(payload) = payload.dig("choices", 0, "message", "content")
        def extract_model(payload) = payload["model"].presence || config.model
        def extract_tokens(payload) = payload.dig("usage", "total_tokens").to_i
      end
    end
  end
end
