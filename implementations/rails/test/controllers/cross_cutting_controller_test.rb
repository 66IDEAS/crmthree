# frozen_string_literal: true

require "test_helper"

class CrossCuttingControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    seed_crm!
    @auth = AuthUser.create!(email: "phase5-admin@example.com", password: "correct-horse-battery")
    @admin = create_profile(email: @auth.email, auth_uid: @auth.id, role: Role.find_by!(name: "Admin"))
    @owner = create_profile(email: "phase5-owner@example.com")
    @other = create_profile(email: "phase5-other@example.com")
    @account = create_account(owner: @owner, name: "Global Needle Account")
    sign_in(@auth)
  end

  test "home renders policy-scoped KPI cards and configurable charts" do
    get root_path

    assert_response :success
    assert_select ".ai-priority-card", text: /AI Priority Summary/
    assert_select ".kpi-card", minimum: 4
    assert_select "canvas[data-dashboard-charts-target='chart']", minimum: 3

    patch dashboard_config_path, params: {widgets: %w[open_tickets tickets_by_priority]}
    assert_redirected_to root_path
    assert_equal %w[open_tickets tickets_by_priority],
      Crm::DashboardPreferences.visible_keys(DashboardConfig.find_by!(user_id: @admin.id, is_default: true))
  end

  test "global search is grouped and never returns an unrelated result" do
    ordinary_auth = AuthUser.create!(email: @owner.email, password: "correct-horse-battery")
    Current.set(profile: @admin) { @owner.update!(auth_uid: ordinary_auth.id) }
    delete session_path
    sign_in(ordinary_auth)
    visible = create_account(owner: @owner, name: "Scoped Needle")
    create_account(owner: @other, name: "Scoped Needle Secret")

    get search_path, params: {q: "scoped needle"}

    assert_response :success
    assert_select ".search-group h2", text: /Accounts/
    assert_select "a[href='#{record_path(object_type: "Account", id: visible.id)}']"
    assert_not_includes response.body, "Scoped Needle Secret"
  end

  test "notification panel supports open mark-all and deletion only for the recipient" do
    notification = Current.set(profile: @admin) do
      Notification.create!(user: @admin, type: "System", title: "Review requested", message: "Open the account",
        read: false, link_type: "Account", link_id: @account.id, send_email: false, email_sent: false)
    end
    hidden = Current.set(profile: @other) do
      Notification.create!(user: @other, type: "System", title: "Private", read: false,
        send_email: false, email_sent: false)
    end

    get notifications_path
    assert_response :success
    assert_includes response.body, "Review requested"
    assert_not_includes response.body, "Private"

    post open_notification_path(notification)
    assert_redirected_to record_path(object_type: "Account", id: @account.id)
    assert notification.reload.read?

    delete notification_path(hidden)
    assert_response :not_found
    assert Notification.exists?(hidden.id)

    post mark_all_notifications_path
    assert_redirected_to root_path
  end

  test "ordinary users can manage notification preferences but cannot see administration sections" do
    ordinary_auth = AuthUser.create!(email: @owner.email, password: "correct-horse-battery")
    Current.set(profile: @admin) { @owner.update!(auth_uid: ordinary_auth.id) }
    delete session_path
    sign_in(ordinary_auth)

    get settings_path
    assert_response :success
    assert_select "#notification-preferences"
    assert_select "#user-management", count: 0
    assert_select "#access-control", count: 0

    patch notification_preferences_path, params: {preferences: {TicketAssigned: "false", desktop: "true"}}
    assert_redirected_to settings_path(anchor: "notification-preferences")
    assert_equal false, @owner.reload.notification_preferences["TicketAssigned"]
    assert_equal true, @owner.notification_preferences["desktop"]
  end

  test "admin manages whitelist roles users languages and list defaults from settings endpoints" do
    post email_access_rules_path, params: {email_access_rule: {rule_type: "Domain", value: " example.org "}}
    assert_redirected_to settings_path(anchor: "access-control")
    assert EmailAccessRule.exists?(rule_type: "domain", value: "example.org")

    post roles_path, params: {role: {name: "Support Only", description: "Support",
      ribbon_items: %w[case_rooms knowledge], permissions: {"Ticket" => {"read" => "true", "update" => "true"}}}}
    assert_redirected_to settings_path(anchor: "role-management")
    role = Role.find_by(name: "Support Only")
    assert role, flash[:alert]
    assert role.permissions.dig("Ticket", "read")

    post users_path, params: {user: {email: "new-local@other.net", first_name: "New", last_name: "Local",
      role_id: role.id, password: "secure-local-pass-123", add_to_whitelist: "true"}}
    assert_redirected_to settings_path(anchor: "user-management")
    profile = UserProfile.find_by!(email: "new-local@other.net")
    assert profile.auth_uid.present?
    assert EmailAccessRule.exists?(rule_type: "email", value: profile.email)

    post translations_path, params: {translation: {language_name: "Esperanto", language_code: "eo"}}
    translation = Translation.find_by!(language_code: "eo")
    assert_redirected_to edit_translation_path(translation)
    patch translation_path(translation), params: {labels: {"nav.accounts" => "Kontoj"}}
    assert_equal "Kontoj", translation.reload.labels["nav.accounts"]

    patch list_sort_setting_path(object_type: "Ticket"), params: {list_sort_setting: {sort_by: "Name", direction: "Desc"}}
    assert_equal "Desc", ListSortSetting.find_by!(object_type: "Ticket").direction
  end

  test "record editing is locked across users and released after save" do
    account = create_account(owner: @admin, name: "Locked Account")
    get edit_record_path(object_type: "Account", id: account.id)
    assert_response :success
    assert RecordLock.exists?(object_type: "Account", record_id: account.id, holder_id: @admin.id)

    other_admin_auth = AuthUser.create!(email: "lock-admin@example.com", password: "correct-horse-battery")
    other_admin = create_profile(email: other_admin_auth.email, auth_uid: other_admin_auth.id, role: Role.find_by!(name: "Admin"))
    delete session_path
    sign_in(other_admin_auth)
    get edit_record_path(object_type: "Account", id: account.id)
    assert_redirected_to record_path(object_type: "Account", id: account.id)
    assert_match @admin.first_name, flash[:alert]

    delete session_path
    sign_in(@auth)
    patch record_path(object_type: "Account", id: account.id), params: {record: {name1: "Saved and unlocked"}}
    assert_redirected_to record_path(object_type: "Account", id: account.id)
    assert_not RecordLock.exists?(object_type: "Account", record_id: account.id)
  end

  test "list export streams every authorised matching record with selected fields" do
    owned = create_account(owner: @admin, name: "Export Needle")
    create_account(owner: @other, name: "Export Needle Secret")

    get record_export_path(object_type: "Account", format: :csv), params: {q: "Export Needle", columns: %w[account_number name1]}

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.body, "Export Needle"
    assert_includes response.body, owned.account_number.to_i.to_s
    assert_includes response.body, "Export Needle Secret" # Administrators intentionally have read-all scope.
  end

  private

  def sign_in(auth_user)
    octets = Digest::SHA256.digest(auth_user.email).bytes.first(2)
    post session_path, params: {email: auth_user.email, password: "correct-horse-battery"},
      headers: {"REMOTE_ADDR" => "10.42.#{octets.first}.#{octets.last}"}
    assert_redirected_to root_path
  end
end
