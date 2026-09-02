# frozen_string_literal: true

module Crm
  module Email
    module_function

    def normalize(value)
      value.to_s.strip.downcase.presence
    end
  end
end
