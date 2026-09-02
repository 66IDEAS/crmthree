# frozen_string_literal: true

module Crm
  module AIProviderConfigBehavior
    extend ActiveSupport::Concern

    included do
      validate :crm_endpoint_is_safe
      before_save :crm_deactivate_other_providers, if: :will_save_change_to_is_active?
    end

    private

    def crm_endpoint_is_safe
      return if endpoint_url.blank? || crm_public_https_shape?(endpoint_url)

      errors.add(:endpoint_url, "must be a public HTTPS URL")
    end

    def crm_public_https_shape?(value)
      uri = URI.parse(value)
      uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil?
    rescue URI::InvalidURIError
      false
    end

    def crm_deactivate_other_providers
      return unless is_active?

      self.class.where.not(id: id).where(is_active: true).update_all(is_active: false, updated_at: Time.current)
    end
  end
end
