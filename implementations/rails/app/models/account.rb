# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class Account < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "accounts"
  enum :company_size, {value_1_10: "1-10", value_11_50: "11-50", value_51_200: "51-200", value_201_500: "201-500", value_501_1000: "501-1000", value_1001_5000: "1001-5000", value_5000: "5000+"}, prefix: true, validate: {allow_nil: true}
  enum :status, {active: "Active", inactive: "Inactive"}, prefix: true, validate: true
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :parent_account, class_name: "Account", foreign_key: "parent_account_id", optional: true
  belongs_to :owner, class_name: "UserProfile", foreign_key: "owner_id"
  has_many :contacts, class_name: "Contact", foreign_key: "account_id", dependent: :nullify
  has_many :contact_accounts, class_name: "ContactAccount", foreign_key: "account_id", dependent: :destroy
  has_many :additional_contacts, through: :contact_accounts, source: :contact
  has_many :child_accounts, class_name: "Account", foreign_key: "parent_account_id", dependent: :nullify
  has_many :leads, class_name: "Lead", foreign_key: "account_id", dependent: :nullify
  has_many :opportunities, class_name: "Opportunity", foreign_key: "account_id", dependent: :restrict_with_error
  has_many :quotations, class_name: "Quotation", foreign_key: "account_id", dependent: :restrict_with_error
  has_many :sales_orders, class_name: "SalesOrder", foreign_key: "account_id", dependent: :restrict_with_error
  has_many :invoices, class_name: "Invoice", foreign_key: "account_id", dependent: :restrict_with_error
  has_many :tickets, class_name: "Ticket", foreign_key: "account_id", dependent: :restrict_with_error
  has_many :assets, class_name: "Asset", foreign_key: "account_id", dependent: :restrict_with_error
  has_many :activities, class_name: "Activity", foreign_key: "account_id", dependent: :nullify
  has_many :service_contracts, class_name: "ServiceContract", foreign_key: "account_id", dependent: :restrict_with_error
  has_many :documents, -> { where(parent_type: "Account") }, class_name: "Document", foreign_key: "parent_id", dependent: :restrict_with_error
end
