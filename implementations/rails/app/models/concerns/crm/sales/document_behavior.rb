# frozen_string_literal: true

module Crm
  module Sales
    module DocumentBehavior
      extend ActiveSupport::Concern

      included do
        validate :crm_valid_document_dates
        validate :crm_valid_invoice_payment if name == "Invoice"
      end

      private

      def crm_valid_document_dates
        if is_a?(Quotation) && valid_from.present? && valid_to.present? && valid_to < valid_from
          errors.add(:valid_to, "must be on or after the valid-from date")
        elsif is_a?(Invoice) && invoice_date.present? && due_date.present? && due_date < invoice_date
          errors.add(:due_date, "must be on or after the invoice date")
        end
      end

      def crm_valid_invoice_payment
        return if paid_amount.blank?

        errors.add(:paid_amount, "must be greater than or equal to 0") if paid_amount.negative?
        if total_amount.present? && paid_amount > total_amount
          errors.add(:paid_amount, "cannot exceed the invoice total")
        end
      end
    end
  end
end
