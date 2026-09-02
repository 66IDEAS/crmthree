# frozen_string_literal: true

class DuplicateLink < ApplicationRecord
  include Crm::ActorStamped

  belongs_to :creator, class_name: "UserProfile", foreign_key: :created_by
  belongs_to :updater, class_name: "UserProfile", foreign_key: :updated_by
  belongs_to :merger, class_name: "UserProfile", foreign_key: :merged_by, optional: true

  before_validation { self.id ||= SecureRandom.uuid }
  enum :status, {potential: "Potential", merged: "Merged", false_positive: "FalsePositive", reverted: "Reverted"},
    prefix: true, validate: true
  validates :object_type, inclusion: {in: %w[Account Contact]}
  validates :confidence, numericality: {in: 0..100}

  def primary_record = Crm::ModelRegistry.model_for(object_type).find(primary_record_id)
  def duplicate_record = Crm::ModelRegistry.model_for(object_type).find(duplicate_record_id)
  def self.policy_class = DuplicateLinkPolicy
end
