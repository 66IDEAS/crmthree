# frozen_string_literal: true

require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = AuthUser.create!(email: "reset@example.com", password: "correct-horse-battery")
  end

  teardown do
    FileUtils.rm_f(Rails.root.join("tmp/local_password_resets/#{@user.id}.txt"))
  end

  test "creates private local instructions and resets the password once" do
    post password_resets_path, params: {email: @user.email}
    instructions = Rails.root.join("tmp/local_password_resets/#{@user.id}.txt")
    token = instructions.read[%r{/password/reset/([^\s]+)}, 1]

    assert_redirected_to new_session_path
    assert_path_exists instructions

    patch password_reset_path(token), params: {
      password: "new-correct-horse-battery",
      password_confirmation: "new-correct-horse-battery"
    }

    assert_redirected_to new_session_path
    assert @user.reload.authenticate("new-correct-horse-battery")
    assert_nil Crm::PasswordReset.authenticate(token)
    assert_not instructions.exist?
  end

  test "does not reveal whether an email exists" do
    post password_resets_path, params: {email: "missing@example.com"}

    assert_redirected_to new_session_path
    assert_equal "If that account exists, local reset instructions were created.", flash[:notice]
  end
end
