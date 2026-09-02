# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class Team < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "teams"
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :manager, class_name: "UserProfile", foreign_key: "manager_id"
  has_many :members, class_name: "UserProfile", foreign_key: "team_id", dependent: :nullify
end
