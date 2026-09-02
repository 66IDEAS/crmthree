# frozen_string_literal: true

module Crm
  module Integrations
    class MailboxProvider
      def initialize(client:)
        @client = client
      end

      def each_message(&block)
        client.each_message(&block)
      end

      private

      attr_reader :client
    end
  end
end
