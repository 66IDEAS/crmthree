# frozen_string_literal: true

module Crm
  module AI
    class ProposalBuilder
      ALLOWED_ACTIONS = %w[add_field update_field update_label update_layout add_workflow feature_spec].freeze

      def initialize(identity:, gateway: Gateway.new)
        @identity = identity
        @gateway = gateway
      end

      def call(kind:, prompt:)
        type = kind.to_s == "Feature" ? "Feature" : "Configuration"
        response = gateway.structured(messages: [{role: "user", content: prompt.to_s.slice(0, 5_000)}],
          required_keys: %w[key changes preview], system: system_for(type))
        return response if response.failure?

        result = validate(response.value, type:)
        return result if result.failure?

        proposal = Current.set(profile: identity.profile) do
          ConfigurationProposal.create!(kind: type, prompt:, proposed_changes: result.value.fetch("changes"),
            preview: result.value.fetch("preview"), status: "Draft")
        end
        Result.success(proposal)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      private

      attr_reader :identity, :gateway

      def system_for(type)
        base = "Return only constrained JSON {\"key\":\"...\",\"changes\":[{\"action\":\"...\",\"target\":\"...\",\"value\":{}}],\"preview\":\"...\"}. " \
          "Allowed actions: #{ALLOWED_ACTIONS.join(", ")}. Do not emit Ruby, shell, templates, SQL, file paths, or executable code."
        type == "Feature" ? "#{base} Describe specification, schema, UI, logic, and test scaffolding as inert JSON values." : base
      end

      def validate(payload, type:)
        changes = payload["changes"]
        key = payload["key"].to_s
        preview = payload["preview"].to_s
        valid = key.match?(/\A[a-z0-9:_-]{3,160}\z/) && changes.is_a?(Array) && changes.length.between?(1, 30) &&
          changes.all? { |change| change.is_a?(Hash) && ALLOWED_ACTIONS.include?(change["action"]) && change["target"].to_s.match?(/\A[A-Za-z0-9_.:-]{1,160}\z/) } &&
          JSON.generate(changes).bytesize <= 100.kilobytes && preview.present?
        return Result.failure(:unsafe_proposal, errors: ["The proposal did not pass the constrained manifest validation."]) unless valid

        Result.success({"key" => "#{type.downcase}:#{key}", "changes" => {"key" => "#{type.downcase}:#{key}", "items" => changes}, "preview" => preview.slice(0, 20_000)})
      end
    end
  end
end
