# frozen_string_literal: true

module Crm
  module Integrations
    class FakeEmailProvider
      attr_reader :name

      def initialize(name: "Fake", messages: [])
        @name = name
        @messages = messages
      end

      def each_message(&) = @messages.each(&)
    end
  end
end
