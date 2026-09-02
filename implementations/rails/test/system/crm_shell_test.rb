# frozen_string_literal: true

require "application_system_test_case"

class CrmShellTest < ApplicationSystemTestCase
  setup do
    page.current_window.resize_to(1440, 900)
    Rails.cache.clear
    seed_crm!
    @auth = AuthUser.create!(email: "system-admin@example.com", password: "correct-horse-battery")
    @admin = create_profile(email: @auth.email, auth_uid: @auth.id, role: Role.find_by!(name: "Admin"))
    @account = create_account(owner: @admin, name: "System Test Account")
    Current.set(profile: @admin) do
      Contact.create!(first_name: "Grace", last_name: "Hopper", account: @account, owner: @admin, status: "Active")
    end
  end

  test "keyboard-accessible shell, theme, CRUD, inline edit, and linked cards" do
    sign_in_as(@auth)

    home_icon = find(".ribbon-link[title='Home'] svg path", visible: :all)["d"]
    lead_icon = find(".ribbon-link[title='Leads'] svg path", visible: :all)["d"]
    assert_equal UiHelper::ICON_PATHS.fetch("home"), home_icon
    assert_equal UiHelper::ICON_PATHS.fetch("user-plus"), lead_icon
    refute_equal home_icon, lead_icon

    toggle = find("[aria-label='Toggle navigation']")
    assert_equal "false", toggle["aria-expanded"]
    toggle.click
    assert_equal "true", toggle["aria-expanded"]

    visit profile_path
    select "Dark", from: "Theme"
    assert_equal "dark", page.evaluate_script("document.documentElement.dataset.theme")
    click_button "Save preferences"
    assert_text "Profile preferences saved"

    visit new_record_path(object_type: "Account")
    assert_selector "label[for='record_name1']"
    fill_in "Primary name", with: "Created with keyboard"
    click_button "Create Account"
    assert_text "Created with keyboard"
    assert_selector ".detail-panel"

    visit records_path(object_type: "Account")
    assert_selector "table.data-table"
    find("summary", text: "Active", match: :first).click
    within("details[open] .inline-editor__form", match: :first) do
      select "Inactive"
      click_button "Save"
    end
    assert_text "Account updated"

    visit record_path(object_type: "Account", id: @account.id)
    assert_text "Contacts"
    assert_text "Grace Hopper"
    assert_selector ".linked-card"
    save_screenshot(Rails.root.join("tmp/screenshots/phase2-desktop.png")) if ENV["PHASE2_SCREENSHOTS"]
  end

  test "mobile layout uses an overlay ribbon and essential table columns" do
    page.current_window.resize_to(390, 844)
    sign_in_as(@auth)
    visit records_path(object_type: "Account")

    toggle = find("[aria-label='Toggle navigation']")
    toggle.click
    assert_equal "true", toggle["aria-expanded"]
    assert_selector ".ribbon-scrim", visible: true
    find(".ribbon-scrim").click
    assert_equal "false", toggle["aria-expanded"]

    visible_headers = page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll(".data-table:first-of-type th"))
        .filter((element) => getComputedStyle(element).display !== "none").length
    JS
    assert_operator visible_headers, :<=, 3
    assert_selector ".ask-input--mobile", visible: true
    assert_no_selector ".gamification", visible: true
    save_screenshot(Rails.root.join("tmp/screenshots/phase2-mobile.png")) if ENV["PHASE2_SCREENSHOTS"]
  end
end
