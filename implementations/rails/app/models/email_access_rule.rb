# frozen_string_literal: true

class EmailAccessRule < ApplicationRecord
  include Crm::ActorStamped

  belongs_to :creator, class_name: "UserProfile", foreign_key: :created_by
  belongs_to :updater, class_name: "UserProfile", foreign_key: :updated_by

  enum :rule_type, {email: "Email", domain: "Domain"}, prefix: true, validate: true

  before_validation { self.id ||= SecureRandom.uuid }
  before_validation :normalize_value

  validates :value, presence: true, length: {maximum: 241}, uniqueness: {scope: :rule_type}
  validate :value_matches_rule_type

  def self.policy_class = SettingsPolicy

  private

  def normalize_value
    self.value = value.to_s.strip.downcase.delete_prefix("@")
  end

  def value_matches_rule_type
    if rule_type_email? && !value.match?(URI::MailTo::EMAIL_REGEXP)
      errors.add(:value, "must be a valid email address")
    elsif rule_type_domain? && !value.match?(/\A[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?\z/)
      errors.add(:value, "must be a valid domain")
    end
  end
end
