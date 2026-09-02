# frozen_string_literal: true

module Crm
  AuthorizationContext = ::Data.define(:profile, :api_token) do
    def self.for_profile(profile)
      new(profile: profile, api_token: nil)
    end

    def api?
      api_token.present?
    end
  end
end
