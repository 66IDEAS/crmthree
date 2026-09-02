# frozen_string_literal: true

class NumberCounter < ApplicationRecord
  ALLOCATION_MUTEX = Mutex.new

  self.primary_key = "object_type"

  validates :object_type, presence: true, uniqueness: true
  validates :next_value, numericality: {only_integer: true, greater_than: 0}

  class << self
    def allocate!(object_type:, width:)
      raise ArgumentError, "object_type is required" if object_type.blank?
      raise ArgumentError, "width must be a positive integer" unless width.is_a?(Integer) && width.positive?

      value = ALLOCATION_MUTEX.synchronize do
        transaction(requires_new: true) do
          now = Time.current
          quoted_type = connection.quote(object_type)
          quoted_time = connection.quote(now)
          connection.select_value(<<~SQL.squish).to_i
            INSERT INTO number_counters (object_type, next_value, created_at, updated_at)
            VALUES (#{quoted_type}, 2, #{quoted_time}, #{quoted_time})
            ON CONFLICT(object_type) DO UPDATE SET
              next_value = number_counters.next_value + 1,
              updated_at = excluded.updated_at
            RETURNING next_value - 1
          SQL
        end
      end

      formatted = value.to_s.rjust(width, "0")
      raise RangeError, "#{object_type} auto-number exceeded its #{width}-character field" if formatted.length > width

      formatted
    end

    def display(value)
      string = value.to_s
      return string unless string.match?(/\A\d+\z/)

      string.to_i.to_s
    end
  end
end
