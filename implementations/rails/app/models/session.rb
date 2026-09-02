# frozen_string_literal: true

class Session < ApplicationRecord
  belongs_to :auth_user
  belongs_to :user_profile, optional: true

  before_validation { self.id ||= SecureRandom.uuid }

  scope :usable, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end

  def self.authenticate(token)
    return if token.blank?

    digest = digest(token)
    candidate = usable.find_by(token_digest: digest)
    candidate if candidate && ActiveSupport::SecurityUtils.secure_compare(candidate.token_digest, digest)
  end
end
