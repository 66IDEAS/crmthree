# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class Ticket < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "tickets"
  enum :priority, {low: "Low", medium: "Medium", high: "High", critical: "Critical"}, prefix: true, validate: true
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :status, class_name: "TicketStatus", foreign_key: "status_id"
  belongs_to :account, class_name: "Account", foreign_key: "account_id"
  belongs_to :contact, class_name: "Contact", foreign_key: "contact_id", optional: true
  belongs_to :asset, class_name: "Asset", foreign_key: "asset_id", optional: true
  belongs_to :service_contract, class_name: "ServiceContract", foreign_key: "service_contract_id", optional: true
  belongs_to :sla, class_name: "SLA", foreign_key: "sla_id", optional: true
  belongs_to :assignee, class_name: "UserProfile", foreign_key: "assigned_to", optional: true
  belongs_to :owner, class_name: "UserProfile", foreign_key: "owner_id"
  has_many :ticket_knowledge_articles, class_name: "TicketKnowledgeArticle", foreign_key: "ticket_id", dependent: :destroy
  has_many :knowledge_articles, through: :ticket_knowledge_articles, source: :article
  has_many :activities, class_name: "Activity", foreign_key: "ticket_id", dependent: :nullify
  has_many :documents, -> { where(parent_type: "Ticket") }, class_name: "Document", foreign_key: "parent_id", dependent: :restrict_with_error
end
