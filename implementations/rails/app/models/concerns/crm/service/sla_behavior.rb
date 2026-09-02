# frozen_string_literal: true

module Crm
  module Service
    module SLABehavior
      extend ActiveSupport::Concern

      PRIORITIES = %w[Low Medium High Critical].freeze

      included do
        validates :name, uniqueness: {case_sensitive: false}
        validates :response_time_hours, numericality: {greater_than: 0}
        validates :resolution_time_hours, numericality: {greater_than: 0}
        validate :crm_response_precedes_resolution
        validate :crm_valid_priorities
      end

      def applies_to?(priority)
        configured = Array(applies_to_priorities).compact_blank
        configured.empty? || configured.any? { |candidate| candidate.casecmp?(priority.to_s) }
      end

      private

      def crm_response_precedes_resolution
        return if response_time_hours.blank? || resolution_time_hours.blank?
        return if response_time_hours <= resolution_time_hours

        errors.add(:response_time_hours, "must be less than or equal to the resolution target")
      end

      def crm_valid_priorities
        values = Array(applies_to_priorities).compact_blank
        return if values.all? { |priority| priority.in?(PRIORITIES) }

        errors.add(:applies_to_priorities, "contains an unknown ticket priority")
      end
    end
  end
end
