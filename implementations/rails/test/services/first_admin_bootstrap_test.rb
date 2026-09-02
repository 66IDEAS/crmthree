# frozen_string_literal: true

require "test_helper"

class FirstAdminBootstrapTest < ActiveSupport::TestCase
  test "creates a self-referencing administrator atomically and is idempotent" do
    user = Crm::FirstAdminBootstrap.call!(email: " Admin@Example.com ", first_name: "Ada", last_name: "Admin",
      password: "correct-horse-battery")
    rerun = Crm::FirstAdminBootstrap.call!(email: "admin@example.com", first_name: "Ada", last_name: "Admin",
      password: "correct-horse-battery")
    profile = UserProfile.find_by!(auth_uid: user.id)

    assert_equal user, rerun
    assert_equal "Admin", profile.role.name
    assert_equal profile.id, profile.created_by
    assert_equal profile.id, profile.updated_by
    assert profile.active?
  end

  test "refuses partial identity state" do
    AuthUser.create!(email: "partial@example.com", password: "correct-horse-battery")

    assert_raises(Crm::FirstAdminBootstrap::UnsafeState) do
      Crm::FirstAdminBootstrap.call!(email: "partial@example.com", first_name: "Part", last_name: "Ial",
        password: "correct-horse-battery")
    end
    assert_nil UserProfile.find_by(email: "partial@example.com")
  end
end
