# frozen_string_literal: true

class IdempotencyRecord < ApplicationRecord
  belongs_to :user_profile

  enum :state, {started: "Started", completed: "Completed", failed: "Failed"}, prefix: true, validate: true
  before_validation { self.id ||= SecureRandom.uuid }

  validates :operation, :key_digest, presence: true
end
