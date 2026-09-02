# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class Quotation < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "quotations"
  enum :status, {draft: "Draft", sent: "Sent", accepted: "Accepted", rejected: "Rejected", expired: "Expired"}, prefix: true, validate: true
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :account, class_name: "Account", foreign_key: "account_id"
  belongs_to :contact, class_name: "Contact", foreign_key: "contact_id", optional: true
  belongs_to :opportunity, class_name: "Opportunity", foreign_key: "opportunity_id", optional: true
  belongs_to :owner, class_name: "UserProfile", foreign_key: "owner_id"
  has_many :line_items, -> { where(parent_type: "Quotation") }, class_name: "LineItem", foreign_key: "parent_id", dependent: :restrict_with_error
  has_many :sales_orders, class_name: "SalesOrder", foreign_key: "quotation_id", dependent: :nullify
  has_many :documents, -> { where(parent_type: "Quotation") }, class_name: "Document", foreign_key: "parent_id", dependent: :restrict_with_error
end
