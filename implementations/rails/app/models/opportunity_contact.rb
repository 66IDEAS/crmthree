# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class OpportunityContact < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "opportunity_contacts"
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :opportunity, class_name: "Opportunity", foreign_key: "opportunity_id"
  belongs_to :contact, class_name: "Contact", foreign_key: "contact_id"
end
