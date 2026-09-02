# frozen_string_literal: true

class IntakeDraft < ApplicationRecord
  include Crm::ActorStamped

  belongs_to :user_profile
  belongs_to :creator, class_name: "UserProfile", foreign_key: :created_by
  belongs_to :updater, class_name: "UserProfile", foreign_key: :updated_by

  before_validation { self.id ||= SecureRandom.uuid }
  enum :status, {draft: "Draft", applied: "Applied", rejected: "Rejected"}, prefix: true, validate: true
  validates :kind, presence: true

  def self.policy_class = IntakeDraftPolicy
end
