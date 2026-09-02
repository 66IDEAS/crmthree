# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class Badge < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "badges"
  enum :category, {sales: "Sales", service: "Service", data_quality: "Data Quality", collaboration: "Collaboration", milestone: "Milestone", challenge: "Challenge", special: "Special"}, prefix: true, validate: true
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
end
