# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class DataSourceConfig < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "data_source_configs"
  enum :source_type, {local: "Local", external: "External"}, prefix: true, validate: true
  enum :auth_type, {none: "None", basicauth: "BasicAuth", oauth2: "OAuth2", apikey: "APIKey"}, prefix: true, validate: {allow_nil: true}
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
end
