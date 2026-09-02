# frozen_string_literal: true

require "securerandom"

class Translation < ApplicationRecord
  before_validation { self.id ||= SecureRandom.uuid }

  validates :language_code, presence: true, uniqueness: true, length: {maximum: 10}
  validates :language_name, presence: true
  validates :labels, exclusion: {in: [nil]}

  def self.policy_class = TranslationPolicy
end
