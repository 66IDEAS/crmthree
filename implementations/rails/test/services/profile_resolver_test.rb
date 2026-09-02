# frozen_string_literal: true

require "test_helper"

class ProfileResolverTest < ActiveSupport::TestCase
  setup { seed_crm! }

  test "resolves an already linked active profile" do
    user = AuthUser.create!(email: "linked@example.com", password: "correct-horse-battery")
    profile = create_profile(email: user.email, auth_uid: user.id)

    result = Crm::ProfileResolver.call(auth_user: user)

    assert result.success?
    assert_equal profile, result.value
  end

  test "atomically claims an unlinked active profile by normalized email" do
    user = AuthUser.create!(email: "claim@example.com", password: "correct-horse-battery")
    profile = create_profile(email: "claim@example.com")

    result = Crm::ProfileResolver.call(auth_user: user)

    assert_equal :profile_claimed, result.code
    assert_equal user.id, profile.reload.auth_uid
  end

  test "rejects inactive and non-whitelisted identities" do
    inactive_user = AuthUser.create!(email: "inactive@example.com", password: "correct-horse-battery")
    create_profile(email: inactive_user.email, active: false, auth_uid: inactive_user.id)
    assert_equal :inactive_profile, Crm::ProfileResolver.call(auth_user: inactive_user).code

    admin = UserProfile.find(Crm::Seeds::SYSTEM_PROFILE_ID)
    Current.set(profile: admin) { EmailAccessRule.create!(rule_type: "Domain", value: "allowed.example") }
    denied_user = AuthUser.create!(email: "person@denied.example", password: "correct-horse-battery")

    assert_equal :email_not_allowed, Crm::ProfileResolver.call(auth_user: denied_user).code
  end

  test "uses the explicit one-time empty-instance bootstrap branch" do
    user = AuthUser.create!(email: "first@example.com", password: "correct-horse-battery")

    result = Crm::ProfileResolver.call(auth_user: user, allow_empty_instance_bootstrap: true,
      bootstrap_attributes: {first_name: "First", last_name: "Admin"})

    assert result.success?
    assert_equal "Admin", result.value.role.name
    assert_equal user.id, result.value.auth_uid
  end

  test "returns pending access when no profile can be resolved" do
    create_profile(email: "existing@example.com")
    user = AuthUser.create!(email: "pending@example.com", password: "correct-horse-battery")

    assert_equal :pending_access, Crm::ProfileResolver.call(auth_user: user).code
  end
end
