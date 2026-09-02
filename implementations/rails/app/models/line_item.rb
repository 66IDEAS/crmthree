# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class LineItem < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "line_items"
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :product, class_name: "Product", foreign_key: "product_id"
  belongs_to :parent, polymorphic: true, foreign_key: :parent_id, foreign_type: :parent_type
end
