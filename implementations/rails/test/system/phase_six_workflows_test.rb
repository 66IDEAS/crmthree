# frozen_string_literal: true

require "application_system_test_case"

class PhaseSixWorkflowsSystemTest < ApplicationSystemTestCase
  setup do
    page.current_window.resize_to(1440, 900)
    Rails.cache.clear
    seed_crm!
    @owner_auth = AuthUser.create!(email: "phase6-system-owner@example.com", password: "correct-horse-battery")
    @owner = create_profile(email: @owner_auth.email, auth_uid: @owner_auth.id)
    @admin_auth = AuthUser.create!(email: "phase6-system-admin@example.com", password: "correct-horse-battery")
    @admin = create_profile(email: @admin_auth.email, auth_uid: @admin_auth.id, role: Role.find_by!(name: "Admin"))
    @account = create_account(owner: @owner, name: "Helvetic Mobility Group")
    @opportunity = Current.set(profile: @owner) do
      Opportunity.create!(name: "Fleet service modernization", account: @account,
        stage: PipelineStage.find_by!(name: "Qualification"), amount: 135_000, currency: "CHF",
        expected_close_date: 45.days.from_now.to_date, probability: 30, result: "Open", owner: @owner)
    end
    @ticket = Current.set(profile: @owner) do
      Ticket.create!(subject: "Fleet telemetry stops after midnight", status: TicketStatus.find_by!(name: "New"),
        priority: "High", category: "Telemetry", account: @account, owner: @owner)
    end
  end

  test "Deal Room collaboration is focused lock-safe live and manually closed" do
    sign_in_as(@owner_auth)
    visit record_path(object_type: "Opportunity", id: @opportunity.id)
    click_link "Create Deal Room"

    fill_in "Name", with: "Fleet Modernization Command Center"
    fill_in "Description", with: "Coordinate commercial, legal, and delivery stakeholders."
    click_button "Create Deal Room"

    assert_text "Deal Room created"
    assert_text "Fleet Modernization Command Center"
    assert_text "CHF 135,000"
    assert_text "Deal Stage Progress"
    assert_no_text(/AI deal summary/i)
    room = DealRoom.find_by!(opportunity: @opportunity)

    within("#comments") do
      find("textarea").set("Commercial proposal is ready for the customer workshop.")
      click_button "Post"
      assert_text "Commercial proposal is ready for the customer workshop."
    end
    assert_equal 1, room.comments.count

    within(".workspace-actions") do
      find("select").select("Proposal")
      click_button "Update Stage"
    end
    assert_text "Deal stage updated"
    assert_equal "Proposal", @opportunity.reload.stage.name

    Capybara.using_session(:admin_workspace) do
      page.current_window.resize_to(1440, 900)
      sign_in_as(@admin_auth)
      visit deal_room_path(room)
      within("#comments") do
        find("textarea").set("Legal review completed; no blocking clauses remain.")
        click_button "Post"
      end
      assert_text "Legal review completed; no blocking clauses remain."
    end

    Capybara.using_session(:default) do
      assert_text "Legal review completed; no blocking clauses remain.", wait: 8
      accept_confirm { click_button "Close Deal Room" }
      assert_text "Deal Room closed"
      assert_no_button "Update Stage"
    end
    assert room.reload.status_closed?
    assert_equal "Open", @opportunity.reload.result_before_type_cast
  end

  test "Case Room timelines leaderboard profile and mobile workspace complete the experience" do
    Current.set(profile: @owner) do
      Activity.create!(type: "Call", subject: "Fleet operations checkpoint", status: "Completed",
        account: @account, opportunity: @opportunity, owner: @owner, is_auto_logged: false)
    end
    Crm::Gamification::ChallengeAssignments.local_for(profile: @owner)
    sign_in_as(@owner_auth)

    visit case_room_path(@ticket)
    assert_text "Fleet telemetry stops after midnight"
    assert_text "Ticket Info"
    assert_no_text(/AI case summary/i)
    within(".workspace-actions") do
      find("select[name='status_id']").select("In Progress")
      click_button "Update Status"
    end
    assert_text "Ticket status updated"
    assert @ticket.reload.first_response_at
    within("#comments") do
      find("textarea").set("Monitoring confirms the fault window.")
      click_button "Post"
      assert_text "Monitoring confirms the fault window."
    end

    Capybara.using_session(:admin_case_workspace) do
      page.current_window.resize_to(1440, 900)
      sign_in_as(@admin_auth)
      visit case_room_path(@ticket)
      within("#comments") do
        find("textarea").set("Engineering has deployed additional queue telemetry.")
        click_button "Post"
      end
      assert_text "Engineering has deployed additional queue telemetry."
    end
    Capybara.using_session(:default) do
      assert_text "Engineering has deployed additional queue telemetry.", wait: 8
    end

    visit my_timeline_path
    assert_text "My Timeline"
    assert_text "Fleet operations checkpoint"

    visit leaderboard_path
    assert_text "Leaderboard"
    assert_selector "tr.is-current-user"
    click_link Crm::RecordPresentation.display_name(@owner)
    assert_text "Trophy Case"
    assert_text(/Active monthly mission/i)
    assert_link "Export Portfolio"

    visit case_room_path(@ticket)
    page.current_window.resize_to(390, 844)
    assert_selector ".workspace-columns"
    main_box = find(".workspace-main").rect
    side_box = find(".workspace-sidebar").rect
    assert_operator side_box.y, :>, main_box.y
    assert_no_selector ".gamification", visible: true
    viewport_width = page.evaluate_script("window.innerWidth")
    assert_operator find(".workspace").rect.width, :<=, viewport_width
  end
end
