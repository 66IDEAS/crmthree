# frozen_string_literal: true

require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    @auth_user = Crm::FirstAdminBootstrap.call!(email: "admin@example.com", first_name: "Ada", last_name: "Admin",
      password: "correct-horse-battery")
  end

  test "uses the official theme-aware CRMTHREE logo on sign in" do
    get new_session_path

    assert_response :success
    assert_select "img[alt='CRMTHREE by 66IDEAS'][src*='crmthree-by-light']", count: 1
    assert_select "img[alt='CRMTHREE by 66IDEAS'][src*='crmthree-by-dark']", count: 1
  end

  test "signs in through an encrypted database-backed session and signs out" do
    post session_path, params: {email: " ADMIN@example.com ", password: "correct-horse-battery"}

    assert_redirected_to root_path
    assert_equal 1, @auth_user.sessions.usable.count
    refute_includes response.headers["Set-Cookie"], @auth_user.email
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Ada Admin"
    assert_select ".top-bar img[alt='CRMTHREE'][src*='crmthree-light']", count: 1
    assert_select ".top-bar img[alt='CRMTHREE'][src*='crmthree-dark']", count: 1
    assert_select ".brand-wordmark", count: 0

    delete session_path
    assert_redirected_to new_session_path
    assert @auth_user.sessions.first.reload.revoked_at.present?
  end

  test "uses a generic response for invalid credentials" do
    post session_path, params: {email: "missing@example.com", password: "not-the-password"}

    assert_redirected_to new_session_path
    assert_equal "Email or password is incorrect", flash[:alert]
  end

  test "rate limits repeated login attempts" do
    5.times { post session_path, params: {email: "missing@example.com", password: "bad"} }
    post session_path, params: {email: "missing@example.com", password: "bad"}

    assert_response :too_many_requests
  end

  test "shows the signed-in email in the pending access state" do
    pending = AuthUser.create!(email: "pending@example.com", password: "correct-horse-battery")
    post session_path, params: {email: pending.email, password: "correct-horse-battery"}
    follow_redirect!

    assert_response :success
    assert_includes response.body, "pending@example.com"
    assert_includes response.body, "Sign out"
  end

  test "has no registration route" do
    post "/users", params: {}

    assert_response :not_found
  end
end
