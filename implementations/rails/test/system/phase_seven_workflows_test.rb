# frozen_string_literal: true

require "application_system_test_case"

class PhaseSevenWorkflowsSystemTest < ApplicationSystemTestCase
  setup do
    Rails.cache.clear
    seed_crm!
    @auth = AuthUser.create!(email: "phase7-system-admin@example.com", password: "correct-horse-battery")
    @admin = create_profile(email: @auth.email, auth_uid: @auth.id, role: Role.find_by!(name: "Admin"))
    @account = create_account(owner: @admin, name: "Phase Seven Visible Account")
  end

  test "admin activates an encrypted provider and intelligence surfaces appear on demand" do
    sign_in_as(@auth)
    assert_no_text "Generate priorities"

    visit settings_path
    find("#ai-providers > summary").click
    within "#ai-providers" do
      find("summary", text: "Add provider").click
      find("select[name='ai_provider_config[provider]']").select("openai")
      fill_in "Model", with: "local-contract-model"
      find("input[name='ai_provider_config[api_key]']").fill_in(with: "never-render-this-key")
      fill_in "Custom endpoint (optional)", with: "https://example.test/v1"
      check "Activate this provider"
      click_button "Save provider"
    end
    assert_text "AI provider saved"
    refute page.html.include?("never-render-this-key")

    visit root_path
    assert_text "AI Priority Summary"
    assert_button "Generate priorities"
    visit record_path(object_type: "Account", id: @account.id)
    assert_text "AI Briefing"
    assert_button "Generate briefing"

    visit intake_drafts_path
    assert_text "Review-first intake"
    assert_button "Extract for review"
    visit duplicate_links_path
    assert_button "Analyze authorised records"
    visit trends_path
    assert_text "CRM trends"
    assert_text "Projection = latest month"
  end
end
