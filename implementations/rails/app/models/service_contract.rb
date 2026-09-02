# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class ServiceContract < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "service_contracts"
  enum :status, {draft: "Draft", active: "Active", expired: "Expired", terminated: "Terminated"}, prefix: true, validate: true
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :account, class_name: "Account", foreign_key: "account_id"
  belongs_to :sla, class_name: "SLA", foreign_key: "sla_id", optional: true
  belongs_to :owner, class_name: "UserProfile", foreign_key: "owner_id"
  has_many :tickets, class_name: "Ticket", foreign_key: "service_contract_id", dependent: :nullify
end
