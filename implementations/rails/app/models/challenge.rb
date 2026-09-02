# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class Challenge < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "challenges"
  enum :status, {active: "Active", completed: "Completed", failed: "Failed", cancelled: "Cancelled"}, prefix: true, validate: true
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :user, class_name: "UserProfile", foreign_key: "user_id"
  belongs_to :reward_badge, class_name: "Badge", foreign_key: "reward_badge_id", optional: true
end
