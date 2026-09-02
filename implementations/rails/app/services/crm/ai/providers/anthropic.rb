# frozen_string_literal: true

module Crm
  module AI
    module Providers
      class Anthropic < Base
        private

        def build_request(messages, structured:)
          system = messages.find { |message| message[:role] == "system" }&.dig(:content)
          conversation = messages.reject { |message| message[:role] == "system" }
          system = [system, ("Return only valid JSON." if structured)].compact.join("\n")
          {method: :post, url: config.endpoint_url.presence || "https://api.anthropic.com/v1/messages",
            headers: {"x-api-key" => config.api_key, "anthropic-version" => "2023-06-01",
              "Content-Type" => "application/json"},
            body: {model: config.model, max_tokens: DEFAULT_MAX_TOKENS, system:, messages: conversation}}
        end

        def extract_content(payload) = Array(payload["content"]).find { |part| part["type"] == "text" }&.dig("text")
        def extract_model(payload) = payload["model"].presence || config.model
        def extract_tokens(payload) = payload.dig("usage", "input_tokens").to_i + payload.dig("usage", "output_tokens").to_i
      end
    end
  end
end
