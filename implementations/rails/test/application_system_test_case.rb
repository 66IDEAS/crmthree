# frozen_string_literal: true

require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1440, 900]

  def sign_in_as(auth_user)
    visit new_session_path
    fill_in "Email", with: auth_user.email
    fill_in "Password", with: "correct-horse-battery"
    click_button "Sign in"
    assert_text "Welcome back"
  end
end
