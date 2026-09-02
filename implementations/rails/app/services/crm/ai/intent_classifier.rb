# frozen_string_literal: true

module Crm
  module AI
    class IntentClassifier
      QUESTION_WORDS = %w[who what where when why how which can could should would is are do does].freeze
      SEARCH_WORDS = %w[find show list locate search which who where].freeze

      def self.call(value)
        text = value.to_s.strip
        words = text.downcase.scan(/[[:alnum:]]+/)
        return :keyword if text.blank?
        return :keyword unless text.end_with?("?") || QUESTION_WORDS.include?(words.first) || words.length >= 4

        SEARCH_WORDS.include?(words.first) || text.match?(/\b(records?|customers?|deals?|tickets?|invoices?)\b/i) ? :semantic : :conversation
      end
    end
  end
end
