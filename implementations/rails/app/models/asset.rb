# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class Asset < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "assets"
  enum :status, {active: "Active", inactive: "Inactive", retired: "Retired", in_repair: "In Repair"}, prefix: true, validate: true
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :product, class_name: "Product", foreign_key: "product_id"
  belongs_to :account, class_name: "Account", foreign_key: "account_id"
  belongs_to :contact, class_name: "Contact", foreign_key: "contact_id", optional: true
  belongs_to :owner, class_name: "UserProfile", foreign_key: "owner_id"
  has_many :tickets, class_name: "Ticket", foreign_key: "asset_id", dependent: :nullify
end
