# frozen_string_literal: true

module Crm
  class RecordPresentation
    POSITIVE = %w[Active Completed Won Paid Low Resolved Published Accepted].freeze
    NEGATIVE = %w[Inactive Lost Rejected Overdue High Critical Failed Cancelled].freeze
    PROGRESS = ["In Progress", "In Review", "Sent", "Medium", "Waiting", "Partially Paid"].freeze
    INITIAL = %w[New Draft Open Planned Prospecting].freeze

    def self.display_name(record)
      if record.is_a?(UserProfile)
        return [record.first_name, record.last_name].compact_blank.join(" ").presence || record.email
      end
      if record.class.name.in?(%w[Quotation SalesOrder Invoice])
        number = display_number(record)
        return "#{number} (#{record.account.name1})" if number.present? && record.account
      end

      definition = ModelRegistry.fetch(record.class.name)
      values = definition.fetch("display_name_fields").filter_map do |field|
        value = record.public_send(field)
        value if value.present?
      end
      values.join(" ").presence || display_number(record) || record.id
    end

    def self.display_number(record)
      field = ModelRegistry.fetch(record.class.name)["auto_number_field"]
      NumberCounter.display(record.public_send(field)) if field && record.public_send(field).present?
    end

    def self.chip_tone(value)
      string = value.to_s
      return "positive" if POSITIVE.include?(string)
      return "negative" if NEGATIVE.include?(string)
      return "progress" if PROGRESS.include?(string)
      return "initial" if INITIAL.include?(string)

      "neutral"
    end
  end
end
