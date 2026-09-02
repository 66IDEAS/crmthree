# frozen_string_literal: true

module Crm
  class Transaction
    class Failed < StandardError
      attr_reader :result

      def initialize(result)
        @result = result
        super(result.code.to_s)
      end
    end

    def self.run
      ApplicationRecord.transaction do
        result = yield
        raise Failed, result if result.failure?

        result
      end
    rescue Failed => error
      error.result
    rescue StandardError => error
      ErrorMapper.call(error)
    end
  end
end
