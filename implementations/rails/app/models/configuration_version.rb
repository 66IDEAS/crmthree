# frozen_string_literal: true

class ConfigurationVersion < ApplicationRecord
  belongs_to :configuration_proposal
  belongs_to :runtime_configuration
  belongs_to :applier, class_name: "UserProfile", foreign_key: :applied_by

  before_validation { self.id ||= SecureRandom.uuid }
end
