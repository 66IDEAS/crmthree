# frozen_string_literal: true

class ReplicationConfig < ApplicationRecord
  include Crm::ActorStamped

  belongs_to :creator, class_name: "UserProfile", foreign_key: :created_by
  belongs_to :updater, class_name: "UserProfile", foreign_key: :updated_by
  has_many :replication_runs, dependent: :restrict_with_error

  before_validation { self.id ||= SecureRandom.uuid }
  encrypts :auth_config
  validates :object_type, inclusion: {in: -> { Crm::ModelRegistry.navigable_object_names }}
  validates :endpoint_url, :key_field, presence: true
  validate :endpoint_has_https_shape
  validate :key_field_exists

  def self.policy_class = SettingsPolicy

  private

  def endpoint_has_https_shape
    uri = URI.parse(endpoint_url.to_s)
    errors.add(:endpoint_url, "must be a public HTTPS URL") unless uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil?
  rescue URI::InvalidURIError
    errors.add(:endpoint_url, "must be a public HTTPS URL")
  end

  def key_field_exists
    return if object_type.blank?

    fields = Crm::ModelRegistry.fetch(object_type).fetch("fields").pluck("name")
    errors.add(:key_field, "must be a field on #{object_type}") unless key_field.in?(fields)
  rescue Crm::ModelRegistry::UnknownObject
    errors.add(:object_type, "is not supported")
  end
end
