# frozen_string_literal: true

module Crm
  module Sales
    class DocumentConverter
      TARGETS = {
        "Opportunity" => %w[Quotation SalesOrder],
        "Quotation" => %w[SalesOrder],
        "SalesOrder" => %w[Invoice]
      }.freeze

      def initialize(source_type:, source_id:, target_type:, idempotency_key:, identity:)
        @source_type = source_type.to_s
        @source_id = source_id
        @target_type = target_type.to_s
        @idempotency_key = idempotency_key
        @identity = identity
        @writer = RecordWriter.new(identity:)
      end

      def call
        return Result.failure(:invalid_conversion, errors: ["This document conversion is not supported"]) unless target_type.in?(TARGETS.fetch(source_type, []))

        Idempotency.run(operation: "#{source_type}.#{source_id}.to.#{target_type}", key: idempotency_key, actor: identity.profile) do
          Current.set(profile: identity.profile, api_token: identity.api_token) do
            Transaction.run { convert }
          end
        end
      end

      private

      attr_reader :source_type, :source_id, :target_type, :idempotency_key, :identity, :writer

      def convert
        source_model = Pricing::PARENT_MODELS.fetch(source_type)
        source = Pundit.policy_scope!(identity, source_model).find(source_id)
        writer.authorize!(source, :show?)

        source.with_lock do
          target = writer.create!(Pricing::PARENT_MODELS.fetch(target_type), target_attributes(source))
          source.line_items.order(:item_number, :id).each do |line_item|
            writer.create!(LineItem, copied_line_attributes(line_item, target))
          end
          Pricing.recalculate_parent_total!(target)
          Result.success({"target_type" => target_type, "target_id" => target.id}, code: :converted)
        end
      end

      def target_attributes(source)
        common = {account: source.account, owner: source.owner, currency: source.currency.presence || "USD"}
        case [source_type, target_type]
        when ["Opportunity", "Quotation"]
          common.merge(opportunity: source, status: "Draft", valid_from: Date.current, valid_to: 30.days.from_now.to_date)
        when ["Opportunity", "SalesOrder"]
          common.merge(opportunity: source, status: "Draft", order_date: Date.current)
        when ["Quotation", "SalesOrder"]
          common.merge(contact: source.contact, opportunity: source.opportunity, quotation: source, status: "Draft", order_date: Date.current)
        when ["SalesOrder", "Invoice"]
          common.merge(contact: source.contact, sales_order: source, status: "Draft", invoice_date: Date.current,
            due_date: 30.days.from_now.to_date, paid_amount: 0)
        else
          raise ArgumentError, "Unsupported conversion"
        end
      end

      def copied_line_attributes(line_item, target)
        {
          parent: target,
          item_number: line_item.item_number,
          product: line_item.product,
          quantity: line_item.quantity,
          unit_price: line_item.unit_price,
          discount_percent: line_item.discount_percent,
          unit_of_measure: line_item.unit_of_measure,
          comment: line_item.comment,
          alternative_to: line_item.alternative_to
        }
      end
    end
  end
end
