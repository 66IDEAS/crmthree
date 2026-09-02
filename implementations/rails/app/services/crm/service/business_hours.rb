# frozen_string_literal: true

module Crm
  module Service
    class BusinessHours
      OPENS_AT = 9
      CLOSES_AT = 17

      class << self
        def deadline(from:, hours:, business_hours_only:)
          seconds = (BigDecimal(hours.to_s) * 3600).to_i
          return from + seconds.seconds unless business_hours_only

          cursor = next_open(from.in_time_zone)
          remaining = seconds
          while remaining.positive?
            closing = cursor.change(hour: CLOSES_AT, min: 0, sec: 0)
            available = (closing - cursor).to_i
            return cursor + remaining.seconds if remaining <= available

            remaining -= available
            cursor = next_open(closing + 1.second)
          end
          cursor
        end

        private

        def next_open(time)
          cursor = time
          cursor = cursor.next_day.beginning_of_day while weekend?(cursor)
          opening = cursor.change(hour: OPENS_AT, min: 0, sec: 0)
          closing = cursor.change(hour: CLOSES_AT, min: 0, sec: 0)
          return opening if cursor < opening
          return cursor if cursor < closing

          next_open(cursor.next_day.beginning_of_day)
        end

        def weekend?(time)
          time.saturday? || time.sunday?
        end
      end
    end
  end
end
