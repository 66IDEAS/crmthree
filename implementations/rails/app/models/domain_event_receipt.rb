# frozen_string_literal: true

class DomainEventReceipt < ApplicationRecord
  before_validation { self.id ||= SecureRandom.uuid }

  belongs_to :actor, class_name: "UserProfile"

  validates :event_id, :event_name, :processed_at, presence: true
  validates :event_id, uniqueness: true
end
