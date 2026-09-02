# frozen_string_literal: true

module Crm
  module Service
    module ServiceContractBehavior
      extend ActiveSupport::Concern

      included do
        validate :crm_end_after_start
      end

      def active_on?(date)
        status_active? && start_date.present? && end_date.present? && date.between?(start_date, end_date)
      end

      private

      def crm_end_after_start
        return if start_date.blank? || end_date.blank? || end_date >= start_date

        errors.add(:end_date, "must be on or after the start date")
      end
    end
  end
end
