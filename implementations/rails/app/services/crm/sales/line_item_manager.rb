# frozen_string_literal: true

module Crm
  module Sales
    class LineItemManager
      ATTRIBUTES = %w[product_id quantity unit_price discount_percent].freeze

      def initialize(parent_type:, parent_id:, identity:)
        @parent_type = parent_type.to_s
        @parent_id = parent_id
        @identity = identity
        @writer = RecordWriter.new(identity:)
      end

      def create(attributes, idempotency_key:)
        Idempotency.run(operation: "#{parent_type}.#{parent_id}.line_item.create", key: idempotency_key, actor: identity.profile) do
          Current.set(profile: identity.profile, api_token: identity.api_token) do
            Transaction.run do
              with_parent do |parent|
                product = authorized_product(attributes[:product_id] || attributes["product_id"])
                writer.authorize!(LineItem, :create?)
                line_item = writer.create!(LineItem, line_attributes(attributes, parent, product), authorize: false)
                Result.success({"line_item_id" => line_item.id}, code: :created)
              end
            end
          end
        end
      end

      def update(line_item_id, attributes)
        Current.set(profile: identity.profile, api_token: identity.api_token) do
          Transaction.run do
            with_parent do |parent|
              line_item = parent.line_items.find(line_item_id)
              product = authorized_product(attributes[:product_id] || attributes["product_id"])
              writer.authorize!(LineItem, :update?)
              writer.update!(line_item, line_attributes(attributes, parent, product).except(:parent), authorize: false)
              Result.success(line_item, code: :updated)
            end
          end
        end
      end

      def destroy(line_item_id)
        Current.set(profile: identity.profile, api_token: identity.api_token) do
          Transaction.run do
            with_parent do |parent|
              line_item = parent.line_items.find(line_item_id)
              writer.authorize!(LineItem, :update?)
              writer.destroy!(line_item, authorize: false)
              Result.success(line_item, code: :deleted)
            end
          end
        end
      end

      private

      attr_reader :parent_type, :parent_id, :identity, :writer

      def with_parent
        parent_model = Pricing::PARENT_MODELS[parent_type]
        raise ActiveRecord::RecordNotFound unless parent_model

        parent = Pundit.policy_scope!(identity, parent_model).find(parent_id)
        writer.authorize!(parent, :update?)
        parent.with_lock { yield(parent) }
      end

      def authorized_product(product_id)
        Pundit.policy_scope!(identity, Product).where(status: "Active").find(product_id)
      end

      def line_attributes(attributes, parent, product)
        values = attributes.to_h.stringify_keys.slice(*ATTRIBUTES)
        values.merge(parent:, product:)
      end
    end
  end
end
