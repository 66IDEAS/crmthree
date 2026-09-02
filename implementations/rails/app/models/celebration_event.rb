# frozen_string_literal: true

class CelebrationEvent < ApplicationRecord
  before_validation { self.id ||= SecureRandom.uuid }

  belongs_to :user, class_name: "UserProfile"

  validates :kind, :message, :dedupe_key, presence: true
  validates :dedupe_key, uniqueness: true

  scope :pending, -> { where(consumed_at: nil) }
end
