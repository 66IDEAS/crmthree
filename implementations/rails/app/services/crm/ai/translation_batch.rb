# frozen_string_literal: true

module Crm
  module AI
    class TranslationBatch
      BATCH_SIZE = 50

      def initialize(translation:, gateway: Gateway.new)
        @translation = translation
        @gateway = gateway
      end

      def call
        existing = translation.labels.to_h
        missing = LabelCatalog.all.reject { |key, _| existing[key].present? }
        return Result.success({translated: 0, remaining: 0}, code: :complete) if missing.empty?

        translated = 0
        missing.each_slice(BATCH_SIZE) do |batch|
          source = batch.to_h
          result = gateway.structured(messages: [{role: "user", content: JSON.generate(source)}],
            required_keys: %w[translations], system:
              "Translate each value into #{translation.language_name} (#{translation.language_code}). " \
              "Keep every key unchanged. Return JSON {\"translations\":{\"exact.key\":\"translation\"}} only.")
          return Result.failure(result.code, errors: result.errors, value: {translated:, remaining: missing.length - translated}, status: result.status) if result.failure?

          output = result.value["translations"]
          return malformed(translated, missing.length) unless output.is_a?(Hash)
          accepted = output.to_h.slice(*source.keys).select { |key, value| source.key?(key) && value.is_a?(String) && value.present? }
          return malformed(translated, missing.length) if accepted.keys.sort != source.keys.sort

          existing.merge!(accepted)
          translation.update!(labels: existing)
          translated += accepted.length
        end
        Result.success({translated:, remaining: 0})
      end

      private

      attr_reader :translation, :gateway

      def malformed(translated, total)
        Result.failure(:malformed_ai_response, errors: ["Translation stopped because a batch did not contain every requested key."],
          value: {translated:, remaining: total - translated}, status: :bad_gateway)
      end
    end
  end
end
