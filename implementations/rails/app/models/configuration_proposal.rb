# frozen_string_literal: true

class ConfigurationProposal < ApplicationRecord
  include Crm::ActorStamped

  belongs_to :creator, class_name: "UserProfile", foreign_key: :created_by
  belongs_to :updater, class_name: "UserProfile", foreign_key: :updated_by
  belongs_to :approver, class_name: "UserProfile", foreign_key: :approved_by, optional: true
  has_many :configuration_versions, dependent: :restrict_with_error

  before_validation { self.id ||= SecureRandom.uuid }
  enum :kind, {configuration: "Configuration", feature: "Feature"}, prefix: true, validate: true
  enum :status, {draft: "Draft", approved: "Approved", rejected: "Rejected", rolled_back: "RolledBack"},
    prefix: true, validate: true
  validates :prompt, :preview, presence: true

  def self.policy_class = SettingsPolicy
end
