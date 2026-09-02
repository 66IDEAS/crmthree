# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class PricebookEntry < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "pricebook_entries"
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :product, class_name: "Product", foreign_key: "product_id"
  belongs_to :account, class_name: "Account", foreign_key: "account_id", optional: true
end
