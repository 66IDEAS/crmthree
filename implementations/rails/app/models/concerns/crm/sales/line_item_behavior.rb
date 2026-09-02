# frozen_string_literal: true

module Crm
  module Sales
    module LineItemBehavior
      extend ActiveSupport::Concern

      included do
        validates :quantity, numericality: {greater_than: 0}
        validates :unit_price, numericality: {greater_than_or_equal_to: 0}
        validates :discount_percent, numericality: {in: 0..100}, allow_nil: true
        validate :crm_parent_exists
        before_validation :crm_apply_product_defaults
        before_validation :crm_calculate_total
        after_save :crm_recalculate_parent_total
        after_destroy :crm_recalculate_parent_total
      end

      private

      def crm_parent_exists
        errors.add(:parent, "must exist") unless parent_type.in?(Pricing::PARENT_TYPES) && parent.present?
      rescue NameError, ActiveRecord::RecordNotFound
        errors.add(:parent, "must exist")
      end

      def crm_apply_product_defaults
        return unless product

        self.quantity ||= 1
        self.discount_percent ||= 0
        self.unit_of_measure = product.unit_of_measure if unit_of_measure.blank?
        self.unit_price = Pricing.unit_price(product:, account: crm_parent_account, quantity:) if unit_price.blank?
      end

      def crm_calculate_total
        return if quantity.blank? || unit_price.blank?

        self.total_price = Pricing.net_value(quantity:, unit_price:, discount_percent:)
      end

      def crm_recalculate_parent_total
        parent_record = parent_type.constantize.find_by(id: parent_id) if parent_type.in?(Pricing::PARENT_TYPES)
        Pricing.recalculate_parent_total!(parent_record) if parent_record
      end

      def crm_parent_account
        parent&.account if parent&.respond_to?(:account)
      end
    end
  end
end
