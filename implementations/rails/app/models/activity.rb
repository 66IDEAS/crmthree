# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class Activity < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "activities"
  self.inheritance_column = nil
  enum :type, {call: "Call", email: "Email", meeting: "Meeting", task: "Task"}, prefix: true, validate: true
  enum :status, {planned: "Planned", in_progress: "In Progress", completed: "Completed", cancelled: "Cancelled"}, prefix: true, validate: true
  enum :priority, {low: "Low", medium: "Medium", high: "High"}, prefix: true, validate: {allow_nil: true}
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :account, class_name: "Account", foreign_key: "account_id", optional: true
  belongs_to :contact, class_name: "Contact", foreign_key: "contact_id", optional: true
  belongs_to :lead, class_name: "Lead", foreign_key: "lead_id", optional: true
  belongs_to :opportunity, class_name: "Opportunity", foreign_key: "opportunity_id", optional: true
  belongs_to :ticket, class_name: "Ticket", foreign_key: "ticket_id", optional: true
  belongs_to :owner, class_name: "UserProfile", foreign_key: "owner_id"
end
