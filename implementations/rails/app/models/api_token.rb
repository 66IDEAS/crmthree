# frozen_string_literal: true

class APIToken < ApplicationRecord
  include Crm::ActorStamped

  belongs_to :user_profile
  belongs_to :creator, class_name: "UserProfile", foreign_key: :created_by
  belongs_to :updater, class_name: "UserProfile", foreign_key: :updated_by

  before_validation { self.id ||= SecureRandom.uuid }
  validates :name, :token_digest, presence: true
  validates :token_digest, uniqueness: true
  validate :scopes_are_strings

  def self.policy_class = SettingsPolicy

  scope :usable, -> { where(revoked_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def self.issue!(profile:, name:, scopes:, expires_at: nil)
    raw = SecureRandom.urlsafe_base64(48)
    token = create!(user_profile: profile, name: name, scopes: scopes, expires_at: expires_at,
      token_digest: digest(raw))
    [token, raw]
  end

  def self.authenticate(raw)
    return if raw.blank?

    raw_digest = digest(raw)
    candidate = usable.find_by(token_digest: raw_digest)
    return unless candidate && ActiveSupport::SecurityUtils.secure_compare(candidate.token_digest, raw_digest)

    candidate.touch(:last_used_at)
    candidate
  end

  def self.digest(raw)
    Digest::SHA256.hexdigest(raw)
  end

  private

  def scopes_are_strings
    errors.add(:scopes, "must be an array of strings") unless scopes.is_a?(Array) && scopes.all?(String)
  end
end
