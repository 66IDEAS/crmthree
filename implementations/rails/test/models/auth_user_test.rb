# frozen_string_literal: true

require "test_helper"

class AuthUserTest < ActiveSupport::TestCase
  test "normalizes email and hashes a sufficiently long password" do
    user = AuthUser.create!(email: "  Admin@Example.COM ", password: "correct-horse-battery")

    assert_equal "admin@example.com", user.email
    assert user.authenticate("correct-horse-battery")
    refute_equal "correct-horse-battery", user.password_digest
  end

  test "rejects short passwords" do
    user = AuthUser.new(email: "user@example.com", password: "too-short")

    refute user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 12 characters)"
  end

  test "session token authentication rejects expired and revoked records" do
    user = AuthUser.create!(email: "sessions@example.com", password: "correct-horse-battery")
    raw = SecureRandom.urlsafe_base64(48)
    record = Session.create!(auth_user: user, token_digest: Session.digest(raw), last_seen_at: Time.current,
      expires_at: 1.hour.from_now)

    assert_equal record, Session.authenticate(raw)
    record.update!(revoked_at: Time.current)
    assert_nil Session.authenticate(raw)
  end
end
