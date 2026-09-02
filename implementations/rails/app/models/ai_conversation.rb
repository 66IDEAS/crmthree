# frozen_string_literal: true

class AIConversation < ApplicationRecord
  belongs_to :user_profile

  before_validation { self.id ||= SecureRandom.uuid }
  validates :title, :last_used_at, presence: true
  validate { errors.add(:messages, "must be an array") unless messages.is_a?(Array) }

  def self.policy_class = AIConversationPolicy
end
