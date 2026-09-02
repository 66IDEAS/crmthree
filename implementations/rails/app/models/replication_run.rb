# frozen_string_literal: true

class ReplicationRun < ApplicationRecord
  belongs_to :replication_config
  belongs_to :user_profile

  before_validation { self.id ||= SecureRandom.uuid }
  enum :status, {queued: "Queued", running: "Running", completed: "Completed", failed: "Failed"}, prefix: true, validate: true
  validates :idempotency_key, presence: true
end
