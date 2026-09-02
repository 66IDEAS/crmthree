# frozen_string_literal: true

class ImportRun < ApplicationRecord
  MAX_BYTES = 5.megabytes

  belongs_to :user_profile

  before_validation { self.id ||= SecureRandom.uuid }

  enum :status, {preview: "Preview", queued: "Queued", running: "Running", completed: "Completed", failed: "Failed"},
    prefix: true, validate: true

  validates :object_type, inclusion: {in: ->(_record) { Crm::ModelRegistry.navigable_object_names }}
  validates :filename, :idempotency_key, presence: true
  validates :source_csv, length: {maximum: MAX_BYTES}
  validates :idempotency_key, uniqueness: {scope: :user_profile_id}
  validate :json_containers_present

  def progress_percent
    return 0 if total_rows.zero?

    ((processed_rows.to_f / total_rows) * 100).round
  end

  private

  def json_containers_present
    %i[headers preview_rows mapping error_details].each do |attribute|
      errors.add(attribute, "must be an array or object") if public_send(attribute).nil?
    end
  end
end
