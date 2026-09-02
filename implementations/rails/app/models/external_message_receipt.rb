# frozen_string_literal: true

class ExternalMessageReceipt < ApplicationRecord
  belongs_to :activity, optional: true
  belongs_to :user_profile

  before_validation { self.id ||= SecureRandom.uuid }
  validates :provider, :external_id, :payload_digest, :processed_at, presence: true
end
