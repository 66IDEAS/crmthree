# frozen_string_literal: true

module Crm
  class Idempotency
    def self.run(operation:, key:, actor:)
      raise ArgumentError, "An idempotency key is required" if key.blank?

      digest = Digest::SHA256.hexdigest(key)
      existing = IdempotencyRecord.find_by(user_profile: actor, operation: operation, key_digest: digest)
      return replay(existing) if existing

      record = IdempotencyRecord.create!(user_profile: actor, operation: operation, key_digest: digest)
      result = yield
      record.update!(state: result.success? ? "Completed" : "Failed", response: serializable(result.value), error_code: result.code)
      result
    rescue ActiveRecord::RecordNotUnique
      replay(IdempotencyRecord.find_by!(user_profile: actor, operation: operation, key_digest: digest))
    rescue StandardError => error
      result = ErrorMapper.call(error)
      record&.update!(state: "Failed", error_code: result.code)
      result
    end

    def self.replay(record)
      return Result.failure(:operation_in_progress, status: :conflict) if record.state_started?
      return Result.failure((record.error_code || "failed").to_sym, value: record.response) if record.state_failed?

      Result.success(record.response, code: :idempotent_replay)
    end
    private_class_method :replay

    def self.serializable(value)
      case value
      when ActiveRecord::Base then {"type" => value.class.name, "id" => value.id}
      when Hash, Array, String, Numeric, TrueClass, FalseClass, NilClass then value
      else {"value" => value.to_s}
      end
    end
    private_class_method :serializable
  end
end
