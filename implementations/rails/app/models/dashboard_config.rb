# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class DashboardConfig < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "dashboard_configs"
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :user, class_name: "UserProfile", foreign_key: "user_id"
end
