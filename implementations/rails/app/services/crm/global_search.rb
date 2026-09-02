# frozen_string_literal: true

module Crm
  class GlobalSearch
    Group = ::Data.define(:object_type, :label, :icon, :records)

    def initialize(identity:)
      @identity = identity
    end

    def call(query)
      term = query.to_s.strip
      return [] if term.length < 2

      ModelRegistry.searchable_object_names.filter_map do |object_type|
        adapter = DataSourceRouter.for(object_type:, identity:)
        next unless adapter.success?

        result = adapter.value.search(term, limit: 5)
        next unless result.success? && result.value.any?

        navigation = Navigation::ENTRIES.find { |entry| entry.object_type == object_type }
        Group.new(
          object_type:,
          label: navigation&.label || object_type.underscore.humanize.pluralize,
          icon: navigation&.icon || "document",
          records: result.value.to_a
        )
      end
    end

    private

    attr_reader :identity
  end
end
