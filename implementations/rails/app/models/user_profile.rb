# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class UserProfile < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "user_profiles"
  enum :theme_preference, {light: "Light", dark: "Dark", system: "System"}, prefix: true, validate: true
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :role, class_name: "Role", foreign_key: "role_id"
  belongs_to :team, class_name: "Team", foreign_key: "team_id", optional: true
end
