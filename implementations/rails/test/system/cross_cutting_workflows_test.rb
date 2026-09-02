# frozen_string_literal: true

require "application_system_test_case"

class CrossCuttingWorkflowsSystemTest < ApplicationSystemTestCase
  setup do
    page.current_window.resize_to(1440, 900)
    Rails.cache.clear
    seed_crm!
    @auth = AuthUser.create!(email: "phase5-system-admin@example.com", password: "correct-horse-battery")
    @admin = create_profile(email: @auth.email, auth_uid: @auth.id, role: Role.find_by!(name: "Admin"))
    @account = create_account(owner: @admin, name: "Northstar Search Demonstration")
    Current.set(profile: @admin) do
      Notification.create!(user: @admin, type: "System", title: "Review Northstar",
        message: "The account is ready for review.", read: false, link_type: "Account", link_id: @account.id,
        send_email: false, email_sent: false)
    end
  end

  test "dashboard search notifications settings and CSV preview form one usable workflow" do
    sign_in_as(@auth)

    assert_selector ".kpi-card", minimum: 4
    assert_selector "canvas[data-dashboard-charts-target='chart']", visible: true, minimum: 3
    find("button[aria-label='Configure dashboard widgets']").click
    within "dialog[open]" do
      uncheck "Inactive Assets"
      click_button "Save dashboard"
    end
    assert_text "Dashboard widgets updated"

    find("#global-search").fill_in(with: "Northstar Search")
    assert_selector ".search-result", text: "Northstar Search Demonstration", wait: 5
    find("summary[aria-label='Notifications']").click
    within ".notification-panel" do
      assert_text "Review Northstar"
      assert_text "The account is ready for review."
    end

    visit settings_path
    assert_selector "details#notification-preferences"
    assert_selector "details#user-management"
    find("#language-management > summary").click
    within find("tr", text: "Deutsch (German)") do
      click_link "Manage"
    end
    assert_selector "progress[aria-label='Translation progress']"
    click_button "Fields"
    assert_selector "tr[data-category='fields']", visible: true
    assert_selector "tr[data-category='navigation']", visible: false
    find("input[aria-label='Filter translation labels']").fill_in(with: "account number")
    assert_selector "tr[data-filter-text*='account number']", visible: true

    visit settings_path
    find("#data-import > summary").click
    within "#data-import" do
      find("select[name='object_type']").select("Accounts")
      attach_file "file", Rails.root.join("test/fixtures/files/phase5_accounts.csv")
      assert page.evaluate_script("document.querySelector('#data-import form').checkValidity()")
      click_button "Preview import"
    end

    assert_text "Import Accounts"
    assert_text "Aurora Field Services"
    assert_text "First five rows"
    assert_button "Import 2 records"
    save_screenshot(Rails.root.join("tmp/screenshots/phase5-cross-cutting.png")) if ENV["PHASE5_SCREENSHOTS"]
  end

  test "dashboard and settings remain usable at phone width" do
    page.current_window.resize_to(390, 844)
    sign_in_as(@auth)

    assert_selector ".dashboard-grid"
    grid_columns = page.evaluate_script("getComputedStyle(document.querySelector('.dashboard-grid')).gridTemplateColumns.split(' ').length")
    assert_equal 1, grid_columns
    find("summary[aria-label='Notifications']").click
    assert_selector ".notification-panel", visible: true

    visit settings_path
    find("#notification-preferences > summary").click
    assert_selector ".preference-options--grid"
    save_screenshot(Rails.root.join("tmp/screenshots/phase5-mobile.png")) if ENV["PHASE5_SCREENSHOTS"]
  end

  test "two users with different roles see a live edit lock handoff" do
    owner_auth = AuthUser.create!(email: @owner&.email || "phase5-lock-owner@example.com", password: "correct-horse-battery")
    owner = create_profile(email: owner_auth.email, auth_uid: owner_auth.id)
    account = create_account(owner:, name: "Live lock handoff")

    Capybara.using_session("phase5-admin-lock") do
      sign_in_as(@auth)
      visit edit_record_path(object_type: "Account", id: account.id)
      assert_text "Edit Live lock handoff"
    end

    Capybara.using_session("phase5-owner-lock") do
      sign_in_as(owner_auth)
      visit record_path(object_type: "Account", id: account.id)
      assert_text "#{Crm::RecordPresentation.display_name(@admin)} is editing"
      assert_button "Edit", disabled: true
    end

    Capybara.using_session("phase5-admin-lock") do
      find("input[name='record[name1]']").fill_in(with: "Live lock released")
      click_button "Save changes"
      assert_text "Live lock released"
    end

    Capybara.using_session("phase5-owner-lock") do
      assert_link "Edit", wait: 5
      assert_no_text "is editing"
    end
  end
end
