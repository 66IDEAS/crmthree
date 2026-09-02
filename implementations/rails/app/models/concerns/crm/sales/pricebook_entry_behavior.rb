# frozen_string_literal: true

module Crm
  module Sales
    module PricebookEntryBehavior
      extend ActiveSupport::Concern

      included do
        validates :price, numericality: {greater_than_or_equal_to: 0}, allow_nil: true
        validates :discount_percent, numericality: {in: 0..100}, allow_nil: true
        validates :quantity_from, numericality: {greater_than: 0}, allow_nil: true
        validates :quantity_to, numericality: {greater_than: 0}, allow_nil: true
        validate :crm_price_or_discount
        validate :crm_valid_pricebook_ranges
      end

      private

      def crm_price_or_discount
        errors.add(:base, "requires a fixed price or discount") if price.blank? && discount_percent.blank?
        errors.add(:currency, "is required when a fixed price is set") if price.present? && currency.blank?
      end

      def crm_valid_pricebook_ranges
        if quantity_from.present? && quantity_to.present? && quantity_to < quantity_from
          errors.add(:quantity_to, "must be greater than or equal to the minimum quantity")
        end
        if valid_from.present? && valid_to.present? && valid_to < valid_from
          errors.add(:valid_to, "must be on or after the valid-from date")
        end
      end
    end
  end
end
