# frozen_string_literal: true

require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    seed_crm!
    @auth = AuthUser.create!(email: "settings-admin@example.com", password: "correct-horse-battery")
    @admin = create_profile(email: @auth.email, auth_uid: @auth.id, role: Role.find_by!(name: "Admin"))
    post session_path, params: {email: @auth.email, password: "correct-horse-battery"}
  end

  test "admin configures list sorting and profile theme" do
    get settings_path
    assert_response :success
    assert_select "h1", "Settings"
    assert_select ".settings-section h2", text: "Pipeline stages"
    assert_select "a", text: /Add stage/
    assert_includes response.body, "Closed Won"
    assert_includes response.body, "Default list sorting"

    assert_difference "PipelineStage.count", 1 do
      post records_path(object_type: "PipelineStage"), params: {
        return_to: settings_path,
        record: {name: "Commercial Review", sort_order: 45, default_probability: 85,
          is_closed: "0", is_won: "0", active: "1"}
      }
    end
    assert_redirected_to settings_path
    assert PipelineStage.find_by!(name: "Commercial Review").active?

    patch list_sort_setting_path(object_type: "Account"), params: {
      list_sort_setting: {sort_by: "Name", direction: "Desc"}
    }
    assert_redirected_to settings_path
    setting = ListSortSetting.find_by!(object_type: "Account")
    assert_equal "Name", setting.sort_by
    assert_equal "Desc", setting.direction
    assert_equal @admin.id, setting.created_by
    assert AuditLog.where(object_type: "ListSortSetting", object_id: setting.id).exists?

    patch profile_path, params: {user_profile: {theme_preference: "Dark", language_preference: "de"}}
    assert_redirected_to profile_path
    assert @admin.reload.theme_preference_dark?
    assert_equal "de", @admin.language_preference
  end
end
