# frozen_string_literal: true

module Crm
  module DataSourceConfigBehavior
    extend ActiveSupport::Concern

    included do
      validate :crm_external_configuration
      after_commit { Crm::DataSourceRouter.clear_cache! }
    end

    private

    def crm_external_configuration
      return unless source_type_external?

      errors.add(:endpoint_url, "is required for an external source") if endpoint_url.blank?
      errors.add(:endpoint_url, "must be a public HTTPS URL") if endpoint_url.present? && !crm_public_https_shape?(endpoint_url)
      errors.add(:field_mapping, "must be an object") unless field_mapping.blank? || field_mapping.is_a?(Hash)
      errors.add(:auth_config, "must be an object") unless auth_config.blank? || auth_config.is_a?(Hash)
    end

    def crm_public_https_shape?(value)
      uri = URI.parse(value)
      uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil?
    rescue URI::InvalidURIError
      false
    end
  end
end
