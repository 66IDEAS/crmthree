# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class AIProviderConfig < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "ai_provider_configs"
  enum :provider, {openai: "OpenAI", google: "Google", anthropic: "Anthropic", moonshot: "Moonshot"}, prefix: true, validate: true
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
end
