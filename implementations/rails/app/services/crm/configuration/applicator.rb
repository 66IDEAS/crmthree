# frozen_string_literal: true

module Crm
  module Configuration
    class Applicator
      def initialize(proposal:, actor:)
        @proposal = proposal
        @actor = actor
      end

      def apply
        return Result.failure(:invalid_state, errors: ["Only draft proposals can be approved."]) unless proposal.status_draft?

        Current.set(profile: actor) do
          ApplicationRecord.transaction do
            key = proposal.proposed_changes.fetch("key")
            runtime = RuntimeConfiguration.find_or_initialize_by(key:)
            previous = runtime.persisted? ? runtime.payload.deep_dup : {}
            runtime.payload = proposal.proposed_changes
            runtime.version = runtime.persisted? ? runtime.version + 1 : 1
            runtime.save!
            ConfigurationVersion.create!(configuration_proposal: proposal, runtime_configuration: runtime,
              previous_payload: previous, applied_payload: runtime.payload, version: runtime.version, applier: actor)
            proposal.update!(status: "Approved", approved_by: actor.id, applied_at: Time.current)
          end
        end
        Result.success(proposal)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def rollback
        version = proposal.configuration_versions.order(version: :desc).first
        return Result.failure(:invalid_state, errors: ["This proposal has no applied version."]) unless version && proposal.status_approved?

        Current.set(profile: actor) do
          ApplicationRecord.transaction do
            runtime = version.runtime_configuration
            runtime.update!(payload: version.previous_payload, version: runtime.version + 1)
            version.update!(reverted_at: Time.current)
            proposal.update!(status: "RolledBack", rolled_back_at: Time.current)
          end
        end
        Result.success(proposal)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      private

      attr_reader :proposal, :actor
    end
  end
end
