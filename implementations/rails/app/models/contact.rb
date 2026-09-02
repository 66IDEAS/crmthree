# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class Contact < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "contacts"
  enum :status, {active: "Active", inactive: "Inactive"}, prefix: true, validate: true
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :account, class_name: "Account", foreign_key: "account_id", optional: true
  belongs_to :owner, class_name: "UserProfile", foreign_key: "owner_id"
  has_many :contact_accounts, class_name: "ContactAccount", foreign_key: "contact_id", dependent: :destroy
  has_many :accounts, through: :contact_accounts, source: :account
  has_many :leads, class_name: "Lead", foreign_key: "contact_id", dependent: :nullify
  has_many :opportunity_contacts, class_name: "OpportunityContact", foreign_key: "contact_id", dependent: :destroy
  has_many :opportunities, through: :opportunity_contacts, source: :opportunity
  has_many :quotations, class_name: "Quotation", foreign_key: "contact_id", dependent: :nullify
  has_many :tickets, class_name: "Ticket", foreign_key: "contact_id", dependent: :nullify
  has_many :activities, class_name: "Activity", foreign_key: "contact_id", dependent: :nullify
  has_many :assets, class_name: "Asset", foreign_key: "contact_id", dependent: :nullify
end
