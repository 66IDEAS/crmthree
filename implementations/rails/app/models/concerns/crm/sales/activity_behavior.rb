# frozen_string_literal: true

module Crm
  module Sales
    module ActivityBehavior
      extend ActiveSupport::Concern

      included do
        before_validation :crm_sync_completion_timestamp
        validate :crm_end_after_start
      end

      private

      def crm_sync_completion_timestamp
        self.completed_at ||= Time.current if status_completed?
        self.completed_at = nil unless status_completed?
      end

      def crm_end_after_start
        return if start_date.blank? || end_date.blank? || end_date >= start_date

        errors.add(:end_date, "must be after the start date")
      end
    end
  end
end
