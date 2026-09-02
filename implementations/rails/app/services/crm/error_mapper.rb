# frozen_string_literal: true

module Crm
  class ErrorMapper
    def self.call(error)
      case error
      when ActiveRecord::RecordNotFound, Pundit::NotAuthorizedError
        Result.failure(:not_found, status: :not_found)
      when ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed
        Result.failure(:validation_failed, errors: error.record.errors.full_messages)
      when ActiveRecord::RecordNotUnique
        Result.failure(:conflict, errors: ["The operation conflicts with an existing record"], status: :conflict)
      else
        Rails.logger.error("Unhandled CRM error: #{error.class}: #{error.message}\n#{Array(error.backtrace).first(8).join("\n")}")
        Result.failure(:internal_error, errors: ["The operation could not be completed"], status: :internal_server_error)
      end
    end
  end
end
