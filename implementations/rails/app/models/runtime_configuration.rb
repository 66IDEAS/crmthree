# frozen_string_literal: true

class RuntimeConfiguration < ApplicationRecord
  include Crm::ActorStamped

  belongs_to :creator, class_name: "UserProfile", foreign_key: :created_by
  belongs_to :updater, class_name: "UserProfile", foreign_key: :updated_by
  has_many :configuration_versions, dependent: :restrict_with_error

  before_validation { self.id ||= SecureRandom.uuid }
  validates :key, presence: true, uniqueness: true

  def self.policy_class = SettingsPolicy
end
