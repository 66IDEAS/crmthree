# frozen_string_literal: true

module Crm
  Result = ::Data.define(:success, :value, :code, :errors, :status) do
    def self.success(value = nil, code: :ok, status: :ok)
      new(success: true, value: value, code: code, errors: [], status: status)
    end

    def self.failure(code, errors: [], status: :unprocessable_entity, value: nil)
      new(success: false, value: value, code: code, errors: Array(errors), status: status)
    end

    def success?
      success
    end

    def failure?
      !success
    end
  end
end
