# frozen_string_literal: true

require "test_helper"

class SecurityInfrastructureTest < ActiveSupport::TestCase
  setup do
    seed_crm!
    @admin = create_profile(email: "security-admin@example.com", role: Role.find_by!(name: "Admin"))
  end

  test "email access rules normalize exact emails and domains" do
    Current.set(profile: @admin) do
      EmailAccessRule.create!(rule_type: "Email", value: " Person@Example.com ")
      EmailAccessRule.create!(rule_type: "Domain", value: "@allowed.example")
    end

    assert Crm::EmailAccess.allowed?("person@example.com")
    assert Crm::EmailAccess.allowed?("anyone@allowed.example")
    refute Crm::EmailAccess.allowed?("person@denied.example")
  end

  test "email access rules reject values that do not match their type" do
    invalid_email = Current.set(profile: @admin) { EmailAccessRule.new(rule_type: "Email", value: "not-an-email") }
    invalid_domain = Current.set(profile: @admin) { EmailAccessRule.new(rule_type: "Domain", value: "bad@domain") }

    refute invalid_email.valid?
    refute invalid_domain.valid?
  end

  test "API tokens are random digest-only scoped and revocable" do
    token, raw = Current.set(profile: @admin) do
      APIToken.issue!(profile: @admin, name: "test", scopes: ["read"])
    end

    refute_equal raw, token.token_digest
    assert_equal token, APIToken.authenticate(raw)
    token.update!(revoked_at: Time.current)
    assert_nil APIToken.authenticate(raw)
  end

  test "safe outbound URLs reject non-HTTPS loopback and private networks" do
    refute Crm::SafeOutboundUrl.allowed?("http://example.com")
    refute Crm::SafeOutboundUrl.allowed?("https://127.0.0.1/service")
    refute Crm::SafeOutboundUrl.allowed?("https://localhost/service")
    refute Crm::SafeOutboundUrl.allowed?("https://192.168.1.12/service")
  end

  test "sensitive parameters are filtered" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    filtered = filter.filter(password: "secret", api_key: "key", auth_config: {token: "value"})

    assert_equal "[FILTERED]", filtered.fetch(:password)
    assert_equal "[FILTERED]", filtered.fetch(:api_key)
    assert_equal "[FILTERED]", filtered.fetch(:auth_config)
  end
end
