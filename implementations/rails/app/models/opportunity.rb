# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class Opportunity < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "opportunities"
  enum :result, {open: "Open", won: "Won", lost: "Lost"}, prefix: true, validate: true
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :account, class_name: "Account", foreign_key: "account_id"
  belongs_to :lead, class_name: "Lead", foreign_key: "lead_id", optional: true
  belongs_to :stage, class_name: "PipelineStage", foreign_key: "stage_id"
  belongs_to :owner, class_name: "UserProfile", foreign_key: "owner_id"
  has_many :line_items, -> { where(parent_type: "Opportunity") }, class_name: "LineItem", foreign_key: "parent_id", dependent: :restrict_with_error
  has_many :opportunity_contacts, class_name: "OpportunityContact", foreign_key: "opportunity_id", dependent: :destroy
  has_many :contacts, through: :opportunity_contacts, source: :contact
  has_many :quotations, class_name: "Quotation", foreign_key: "opportunity_id", dependent: :nullify
  has_many :sales_orders, class_name: "SalesOrder", foreign_key: "opportunity_id", dependent: :nullify
  has_many :activities, class_name: "Activity", foreign_key: "opportunity_id", dependent: :nullify
  has_many :documents, -> { where(parent_type: "Opportunity") }, class_name: "Document", foreign_key: "parent_id", dependent: :restrict_with_error
end
