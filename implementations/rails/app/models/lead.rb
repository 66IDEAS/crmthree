# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class Lead < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "leads"
  enum :source, {web: "Web", referral: "Referral", trade_show: "Trade Show", cold_call: "Cold Call", email_campaign: "Email Campaign", social_media: "Social Media", partner: "Partner", other: "Other"}, prefix: true, validate: {allow_nil: true}
  enum :status, {new: "New", contacted: "Contacted", qualified: "Qualified", unqualified: "Unqualified", converted: "Converted"}, prefix: true, validate: true
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :account, class_name: "Account", foreign_key: "account_id", optional: true
  belongs_to :contact, class_name: "Contact", foreign_key: "contact_id", optional: true
  belongs_to :converted_account, class_name: "Account", foreign_key: "converted_account_id", optional: true
  belongs_to :converted_contact, class_name: "Contact", foreign_key: "converted_contact_id", optional: true
  belongs_to :converted_opportunity, class_name: "Opportunity", foreign_key: "converted_opportunity_id", optional: true
  belongs_to :owner, class_name: "UserProfile", foreign_key: "owner_id"
  has_many :activities, class_name: "Activity", foreign_key: "lead_id", dependent: :nullify
end
