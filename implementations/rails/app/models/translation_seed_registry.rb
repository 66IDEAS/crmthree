# frozen_string_literal: true

class TranslationSeedRegistry < ApplicationRecord
  self.table_name = "translation_seed_registry"
  self.primary_key = "language_code"

  validates :language_code, :source_sha256, :seeded_at, presence: true
  validates :original_labels, exclusion: {in: [nil]}
end
