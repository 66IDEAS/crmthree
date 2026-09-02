# frozen_string_literal: true

module Crm
  module Integrations
    class OutboxDispatcher
      def initialize(entry:, adapter:)
        @entry = entry
        @adapter = adapter
      end

      def call
        entry.update!(status: "Processing", attempts: entry.attempts + 1, last_error: nil)
        result = adapter.execute_outbox(entry)
        if result.success?
          entry.update!(status: "Completed", processed_at: Time.current)
        else
          entry.update!(status: "Failed", last_error: result.errors.to_sentence.slice(0, 1_000))
        end
        result
      rescue StandardError => error
        entry.update_columns(status: "Failed", attempts: entry.attempts + 1,
          last_error: "External write failed", updated_at: Time.current)
        Rails.logger.warn("Outbox dispatch failed (#{error.class.name})")
        Result.failure(:external_write_failed, errors: ["The external write is saved for recovery."], status: :bad_gateway)
      end

      private

      attr_reader :entry, :adapter
    end
  end
end
