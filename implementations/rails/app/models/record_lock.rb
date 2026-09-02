# frozen_string_literal: true

class RecordLock < ApplicationRecord
  TTL = 15.minutes

  belongs_to :holder, class_name: "UserProfile"

  before_validation { self.id ||= SecureRandom.uuid }

  validates :object_type, inclusion: {in: ->(_record) { Crm::ModelRegistry.object_names }}
  validates :record_id, :expires_at, presence: true
  validates :record_id, uniqueness: {scope: :object_type}

  scope :active, -> { where("expires_at > ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end
end
