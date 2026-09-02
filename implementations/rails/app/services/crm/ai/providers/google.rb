# frozen_string_literal: true

module Crm
  module AI
    module Providers
      class Google < Base
        private

        def build_request(messages, structured:)
          system = messages.find { |message| message[:role] == "system" }&.dig(:content)
          base = config.endpoint_url.presence || "https://generativelanguage.googleapis.com/v1beta"
          endpoint = "#{base.delete_suffix("/")}/models/#{CGI.escape(config.model)}:generateContent"
          body = {
            contents: messages.reject { |message| message[:role] == "system" }.map do |message|
              {role: message[:role] == "assistant" ? "model" : "user", parts: [{text: message[:content]}]}
            end,
            generationConfig: {temperature: 0.2}.merge(structured ? {responseMimeType: "application/json"} : {})
          }
          body[:systemInstruction] = {parts: [{text: system}]} if system.present?
          {method: :post, url: endpoint, headers: {"x-goog-api-key" => config.api_key,
            "Content-Type" => "application/json"}, body:}
        end

        def extract_content(payload) = payload.dig("candidates", 0, "content", "parts", 0, "text")
        def extract_model(payload) = payload["modelVersion"].presence || config.model
        def extract_tokens(payload) = payload.dig("usageMetadata", "totalTokenCount").to_i
      end
    end
  end
end
