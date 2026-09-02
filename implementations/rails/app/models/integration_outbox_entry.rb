# frozen_string_literal: true

class IntegrationOutboxEntry < ApplicationRecord
  belongs_to :data_source_config

  before_validation { self.id ||= SecureRandom.uuid }
  enum :status, {pending: "Pending", processing: "Processing", completed: "Completed", failed: "Failed"}, prefix: true, validate: true
  validates :object_type, :record_id, :operation, :dedupe_key, presence: true
  validates :operation, inclusion: {in: %w[create update delete]}
end
