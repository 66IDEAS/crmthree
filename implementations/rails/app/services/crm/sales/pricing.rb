# frozen_string_literal: true

module Crm
  module Sales
    class Pricing
      PARENT_MODELS = {
        "Opportunity" => Opportunity,
        "Quotation" => Quotation,
        "SalesOrder" => SalesOrder,
        "Invoice" => Invoice
      }.freeze
      PARENT_TYPES = PARENT_MODELS.keys.freeze

      class << self
        def net_value(quantity:, unit_price:, discount_percent: 0)
          quantity = BigDecimal(quantity.to_s)
          price = BigDecimal(unit_price.to_s)
          discount = BigDecimal((discount_percent || 0).to_s)
          (quantity * price * (1 - (discount / 100))).round(2)
        end

        def next_item_number(parent_type:, parent_id:)
          return "000010" if parent_type.blank? || parent_id.blank?

          maximum = LineItem.where(parent_type:, parent_id:).pluck(:item_number)
            .filter_map { |value| value.to_s.match?(/\A\d+\z/) ? value.to_i : nil }.max.to_i
          format("%06d", maximum + 10)
        end

        def unit_price(product:, account: nil, quantity: 1, on: Date.current)
          entries = PricebookEntry.where(product:, active: true)
            .where("valid_from IS NULL OR valid_from <= ?", on)
            .where("valid_to IS NULL OR valid_to >= ?", on)
            .where("quantity_from IS NULL OR quantity_from <= ?", quantity)
            .where("quantity_to IS NULL OR quantity_to >= ?", quantity)
            .where(account_id: [account&.id, nil])
            .order(Arel.sql("CASE WHEN account_id IS NULL THEN 1 ELSE 0 END"), quantity_from: :desc)
          entry = entries.first
          return BigDecimal((product.base_price || 0).to_s) unless entry
          return BigDecimal(entry.price.to_s) if entry.price.present?

          net_value(quantity: 1, unit_price: product.base_price || 0, discount_percent: entry.discount_percent)
        end

        def recalculate_parent_total!(parent)
          return unless parent && total_attribute(parent)

          total = LineItem.where(parent_type: parent.class.name, parent_id: parent.id, alternative_to: [nil, ""])
            .sum(:total_price).round(2)
          if parent.is_a?(Invoice) && parent.paid_amount.present? && parent.paid_amount > total
            parent.errors.add(:base, "Line-item total cannot be lower than the amount already paid")
            raise ActiveRecord::RecordInvalid, parent
          end
          attribute = total_attribute(parent)
          previous = parent.public_send(attribute)
          return if BigDecimal((previous || 0).to_s) == total

          updates = {attribute => total, updated_at: Time.current}
          updates[:updated_by] = Current.profile.id if Current.profile && parent.respond_to?(:updated_by)
          parent.update_columns(updates)
          Crm::AuditWriter.record!(record: parent, action: :update, changes: {attribute.to_s => [previous, total]}) if Current.profile&.active?
        end

        private

        def total_attribute(parent)
          return :amount if parent.is_a?(Opportunity)
          :total_amount if parent.respond_to?(:total_amount)
        end
      end
    end
  end
end
