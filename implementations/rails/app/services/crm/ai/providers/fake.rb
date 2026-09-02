# frozen_string_literal: true

module Crm
  module AI
    module Providers
      class Fake
        attr_reader :calls

        def initialize(responses: [])
          @responses = Array(responses)
          @calls = []
        end

        def chat(messages:, system: nil, structured: false)
          calls << {messages:, system:, structured:}
          response = @responses.shift || (structured ? "{}" : "A concise CRM answer.")
          response.is_a?(Crm::Result) ? response : Result.success({content: response, model: "fake", tokens_used: 0})
        end
      end
    end
  end
end
