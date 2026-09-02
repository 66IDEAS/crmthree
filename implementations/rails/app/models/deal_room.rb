# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class DealRoom < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "deal_rooms"
  enum :status, {active: "Active", closed: "Closed"}, prefix: true, validate: true
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :opportunity, class_name: "Opportunity", foreign_key: "opportunity_id"
  belongs_to :owner, class_name: "UserProfile", foreign_key: "owner_id"
  has_many :comments, -> { where(parent_type: "DealRoom") }, class_name: "Comment", foreign_key: "parent_id", dependent: :restrict_with_error
  has_many :documents, -> { where(parent_type: "DealRoom") }, class_name: "Document", foreign_key: "parent_id", dependent: :restrict_with_error
end
