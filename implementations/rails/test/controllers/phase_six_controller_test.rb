# frozen_string_literal: true

require "test_helper"

class PhaseSixControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    seed_crm!
    @admin_auth = create_auth("phase6-web-admin@example.com")
    @admin = create_profile(email: @admin_auth.email, auth_uid: @admin_auth.id, role: Role.find_by!(name: "Admin"))
    @owner_auth = create_auth("phase6-web-owner@example.com")
    @owner = create_profile(email: @owner_auth.email, auth_uid: @owner_auth.id)
    @other_auth = create_auth("phase6-web-other@example.com")
    @other = create_profile(email: @other_auth.email, auth_uid: @other_auth.id)
    @account = create_account(owner: @owner, name: "Workspace Customer AG")
    @opportunity = Current.set(profile: @owner) do
      Opportunity.create!(name: "Regional Service Expansion", account: @account,
        stage: PipelineStage.find_by!(name: "Qualification"), amount: 84_500, currency: "CHF",
        result: "Open", owner: @owner)
    end
    @ticket = Current.set(profile: @owner) do
      Ticket.create!(subject: "Identity synchronization is delayed", status: TicketStatus.find_by!(name: "New"),
        priority: "High", category: "Integration", account: @account, owner: @owner)
    end
    sign_in(@owner_auth)
  end

  test "opportunity creates one custom Deal Room with notes stage changes and manual closure" do
    get record_path(object_type: "Opportunity", id: @opportunity.id)
    assert_response :success
    assert_select "a", text: /Create Deal Room/

    assert_difference "DealRoom.count", 1 do
      post deal_rooms_path, params: {opportunity_id: @opportunity.id,
        deal_room: {name: "Expansion Command Center", description: "Coordinate commercial stakeholders."}}
    end
    room = DealRoom.find_by!(opportunity: @opportunity)
    assert_redirected_to deal_room_path(room)

    get deal_room_path(room)
    assert_response :success
    assert_select ".workspace-summary", text: /contextual opportunity briefing/i
    assert_select ".workspace-facts", text: /CHF 84,500/
    assert_select "[data-controller~='workspace-live'][data-workspace-live-type-value='DealRoom']"

    assert_difference "Comment.where(parent_type: 'DealRoom', parent_id: room.id).count", 1 do
      post workspace_comments_path(workspace_type: "DealRoom", workspace_id: room.id),
        params: {content: "Finance has confirmed the revised business case."}
    end
    assert_redirected_to deal_room_path(room, anchor: "comments")

    patch update_stage_deal_room_path(room), params: {stage_id: PipelineStage.find_by!(name: "Proposal").id}
    assert_redirected_to deal_room_path(room)
    assert_equal "Proposal", @opportunity.reload.stage.name

    patch close_deal_room_path(room)
    assert room.reload.status_closed?
    assert_equal "Open", @opportunity.reload.result_before_type_cast

    assert_no_difference "DealRoom.count" do
      post deal_rooms_path, params: {opportunity_id: @opportunity.id,
        deal_room: {name: "Duplicate", description: "Must not be created"}}
    end
    assert_response :conflict
  end

  test "Case Room updates lifecycle posts notes and links published knowledge" do
    article = Current.set(profile: @owner) do
      KnowledgeArticle.create!(title: "Restore identity queue processing", content: "Restart the connector safely.",
        category: "Integration", status: "Published", source: "Manual", author: @owner,
        views_count: 0, helpful_count: 0)
    end

    get case_room_path(@ticket)
    assert_response :success
    assert_select ".workspace-summary", text: /contextual support briefing/i
    assert_select ".workspace-facts", text: /Identity synchronization is delayed|Integration/
    assert_select "[data-controller~='workspace-live'][data-workspace-live-type-value='Ticket']"

    assert_difference "Comment.where(parent_type: 'Ticket', parent_id: @ticket.id).count", 1 do
      post workspace_comments_path(workspace_type: "Ticket", workspace_id: @ticket.id),
        params: {content: "Customer confirms the queue can be restarted tonight."}
    end

    patch update_status_case_room_path(@ticket), params: {status_id: TicketStatus.find_by!(name: "In Progress").id}
    assert @ticket.reload.first_response_at
    patch update_status_case_room_path(@ticket), params: {
      status_id: TicketStatus.find_by!(name: "Resolved").id,
      resolution: "Restarted and verified queue processing."
    }
    assert @ticket.reload.resolved_at
    assert_equal "Restarted and verified queue processing.", @ticket.resolution

    assert_difference "TicketKnowledgeArticle.count", 1 do
      post link_knowledge_case_room_path(@ticket), params: {article_id: article.id}
    end
    assert @ticket.knowledge_articles.exists?(article.id)
  end

  test "personal and manager timelines are filtered without exposing another team" do
    teammate = create_profile(email: "phase6-web-teammate@example.com")
    team = create_team(manager: @owner, members: [@owner, teammate])
    outsider_team = create_team(manager: @other, members: [@other])
    Current.set(profile: teammate) do
      Activity.create!(type: "Call", subject: "Visible coaching call", status: "Completed", owner: teammate,
        account: @account, is_auto_logged: false)
    end
    Current.set(profile: @other) do
      Activity.create!(type: "Call", subject: "Private other-team call", status: "Completed", owner: @other,
        is_auto_logged: false)
    end

    get my_timeline_path
    assert_response :success
    assert_select "h1", text: "My Timeline"

    get team_timeline_path(team_id: team.id)
    assert_response :success
    assert_includes response.body, "Visible coaching call"
    refute_includes response.body, "Private other-team call"

    get team_timeline_path(team_id: outsider_team.id)
    assert_response :success
    refute_includes response.body, "Private other-team call"

    sign_in(@other_auth)
    get team_timeline_path
    assert_response :success # @other manages outsider_team

    unassigned_auth = create_auth("phase6-web-unassigned@example.com")
    create_profile(email: unassigned_auth.email, auth_uid: unassigned_auth.id)
    sign_in(unassigned_auth)
    get team_timeline_path
    assert_response :not_found
  end

  test "leaderboard visibility profiles manager portfolio and celebration delivery are scoped" do
    teammate = create_profile(email: "phase6-board-teammate@example.com")
    outsider = create_profile(email: "phase6-board-outsider@example.com")
    create_team(manager: @owner, members: [@owner, teammate])
    @owner.update_columns(xp_total: 120)
    teammate.update_columns(xp_total: 280)
    outsider.update_columns(xp_total: 99_999)

    get leaderboard_path
    assert_response :success
    assert_includes response.body, teammate.email.split("@").first
    refute_includes response.body, outsider.email.split("@").first
    assert_select "tr.is-current-user"

    get member_profile_path(teammate)
    assert_response :success
    assert_select ".trophy-case"
    assert_select "a", text: /Export Portfolio/

    get performance_portfolio_path(teammate, format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match(/#{teammate.first_name}-#{teammate.last_name}-portfolio\.csv/i,
      response.headers.fetch("Content-Disposition"))

    event = CelebrationEvent.create!(user: @owner, kind: "badge", message: "A rare badge was earned.",
      dedupe_key: "controller-celebration")
    get root_path
    assert_response :success
    assert_includes response.body, "A rare badge was earned."
    assert event.reload.consumed_at
    get root_path
    refute_includes response.body, "A rare badge was earned."
  end

  test "gamification settings are administered with validation and remain inaccessible to users" do
    sign_in(@admin_auth)
    get settings_path(anchor: "gamification")
    assert_response :success
    assert_select "#gamification", text: /XP Events/
    assert_select "#gamification form.gamification-row-form"

    event = XPEvent.find_by!(event_type: "log_activity")
    patch gamification_setting_path(object_type: "XPEvent", id: event.id), params: {
      setting: {description: "Document a useful customer interaction", xp_value: 22, active: "1"}
    }
    assert_redirected_to settings_path(anchor: "gamification")
    assert_equal 22, event.reload.xp_value

    level = LevelDefinition.find_by!(level: 2)
    patch gamification_setting_path(object_type: "LevelDefinition", id: level.id), params: {
      setting: {name: level.name, xp_threshold: level.xp_threshold, unlocks: "not-json"}
    }
    assert_redirected_to settings_path(anchor: "gamification")
    assert_equal "Gamification JSON is invalid", flash[:alert].split(":").first

    sign_in(@owner_auth)
    patch gamification_setting_path(object_type: "XPEvent", id: event.id), params: {
      setting: {description: "Unauthorized", xp_value: 9_999, active: "1"}
    }
    assert_response :not_found
    assert_equal 22, event.reload.xp_value
  end

  test "workspace routes and comments do not leak records outside policy scope" do
    room = Current.set(profile: @owner) do
      DealRoom.create!(name: "Private workspace", opportunity: @opportunity, status: "Active", owner: @owner)
    end
    sign_in(@other_auth)

    get deal_room_path(room)
    assert_response :not_found
    get case_room_path(@ticket)
    assert_response :not_found
    assert_no_difference "Comment.count" do
      post workspace_comments_path(workspace_type: "DealRoom", workspace_id: room.id), params: {content: "Intrusion"}
    end
    assert_response :not_found
  end

  private

  def create_auth(email)
    AuthUser.create!(email:, password: "correct-horse-battery")
  end

  def sign_in(auth)
    delete session_path
    post session_path, params: {email: auth.email, password: "correct-horse-battery"}
  end
end
