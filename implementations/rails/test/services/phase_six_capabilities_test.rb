# frozen_string_literal: true

require "test_helper"

class PhaseSixCapabilitiesTest < ActiveSupport::TestCase
  setup do
    seed_crm!
    @admin = create_profile(email: "phase6-admin@example.com", role: Role.find_by!(name: "Admin"))
    @user = create_profile(email: "phase6-user@example.com")
    @account = create_account(owner: @user, name: "Phase Six Customer")
    @opportunity = Current.set(profile: @user) do
      Opportunity.create!(name: "Phase Six Deal", account: @account, stage: PipelineStage.find_by!(name: "Qualification"),
        amount: 25_000, currency: "CHF", result: "Open", owner: @user)
    end
  end

  test "domain event processing awards XP and updates a streak exactly once" do
    event = domain_event(id: "10000000-0000-4000-8000-000000000001", name: "activity.create", record_id: SecureRandom.uuid)

    2.times { Crm::Gamification::EventHandler.call(event) }

    assert_equal 15, @user.reload.xp_total
    assert_equal 1, @user.current_streak_days
    assert_equal 1, Streak.find_by!(user: @user, activity_type: "log_activity").current_count
    assert_equal 1, DomainEventReceipt.where(event_id: event.id).count
    assert_match(/During this run/, Crm::PerformancePortfolio.for(@user).streak_outcomes.values.first)
  end

  test "qualifying a lead through the data adapter awards the configured event points" do
    lead = Current.set(profile: @user) do
      Lead.create!(first_name: "Grace", last_name: "Hopper", company: "Compiler Systems",
        status: "Contacted", source: "Referral", owner: @user)
    end

    result = Crm::Data::LocalActiveRecordAdapter.new(object_type: "Lead", identity: identity(@user))
      .update(lead.id, status: "Qualified")

    assert result.success?
    assert_equal 25, @user.reload.xp_total
    assert_equal "Qualified", lead.reload.status_before_type_cast
  end

  test "configured points produce a level up badge personal best notifications and celebrations" do
    @user.update_columns(xp_total: 490, level: 1, level_name: "Rookie")
    contact = Current.set(profile: @user) do
      Contact.create!(first_name: "Ada", last_name: "Lovelace", account: @account, owner: @user)
    end
    Crm::Gamification::EventHandler.call(domain_event(id: "10000000-0000-4000-8000-000000000002",
      name: "contact.create", record_id: contact.id))

    assert_equal 500, @user.reload.xp_total
    assert_equal 2, @user.level
    assert_equal "Closer", @user.level_name
    assert UserBadge.joins(:badge).exists?(user: @user, badges: {name: "First Contact"})
    assert Notification.exists?(user: @user, type: "LevelUp")
    assert Notification.exists?(user: @user, type: "BadgeEarned")
    assert CelebrationEvent.exists?(user: @user, kind: "level_up")
    assert CelebrationEvent.exists?(user: @user, kind: "badge")
  end

  test "local monthly challenge assignment is deterministic unique and completes from events" do
    first = Crm::Gamification::ChallengeAssignments.local_for(profile: @user)
    replay = Crm::Gamification::ChallengeAssignments.local_for(profile: @user)
    challenge = first.value
    challenge.update!(target_value: 1)

    Crm::Gamification::EventHandler.call(domain_event(id: "10000000-0000-4000-8000-000000000003",
      name: "activity.create", record_id: SecureRandom.uuid))

    assert first.success?
    assert_equal :existing, replay.code
    assert_equal first.value.id, replay.value.id
    assert challenge.reload.status_completed?
    assert_equal 1, challenge.current_value
    assert_equal 90, @user.reload.xp_total # 15 configured + 75 challenge reward
    assert Notification.exists?(user: @user, type: "ChallengeAssigned")
    assert CelebrationEvent.exists?(user: @user, kind: "challenge")
  end

  test "won deals create personal records and one-time celebration" do
    @opportunity.update_columns(result: "Won", actual_close_date: Date.current)
    event = domain_event(id: "10000000-0000-4000-8000-000000000004", name: "opportunity.stage_changed",
      record_id: @opportunity.id, payload: {"result" => "Won"})

    2.times { Crm::Gamification::EventHandler.call(event) }

    best = PersonalBest.find_by!(user: @user, metric: "largest_deal")
    assert_equal 25_000, best.value
    assert UserBadge.joins(:badge).exists?(user: @user, badges: {name: "Deal Closer"})
    assert_equal 1, CelebrationEvent.where(user: @user, kind: "deal_won").count
  end

  test "workspace actions respect locks update stages close manually and derive ticket timestamps" do
    room = Current.set(profile: @user) do
      DealRoom.create!(name: "Important Deal", opportunity: @opportunity, status: "Active", owner: @user)
    end
    actions = Crm::Workspace::Actions.new(identity: identity(@user))

    assert actions.update_deal_stage(room, stage_id: PipelineStage.find_by!(name: "Proposal").id).success?
    assert_equal "Proposal", @opportunity.reload.stage.name
    assert actions.close_deal_room(room).success?
    assert room.reload.status_closed?
    assert_equal "Open", @opportunity.reload.result_before_type_cast

    ticket = Current.set(profile: @user) do
      Ticket.create!(subject: "Workspace ticket", status: TicketStatus.find_by!(name: "New"), priority: "Medium",
        account: @account, owner: @user)
    end
    assert actions.update_ticket_status(ticket, status_id: TicketStatus.find_by!(name: "In Progress").id).success?
    assert ticket.reload.first_response_at
    assert actions.update_ticket_status(ticket, status_id: TicketStatus.find_by!(name: "Resolved").id,
      resolution: "Verified through the Case Room").success?
    assert ticket.reload.resolved_at
  end

  test "timeline feed merges activities and CRM events with filters and stable pagination" do
    activity = Current.set(profile: @user) do
      Activity.create!(type: "Call", subject: "Customer review", status: "Completed", account: @account,
        owner: @user, is_auto_logged: false)
    end
    Current.set(profile: @user) { Crm::AuditWriter.record!(record: @account, action: :update, changes: {"status" => ["Prospect", "Active"]}) }

    all = Crm::TimelineFeed.for_user(profile: @user)
    activities = Crm::TimelineFeed.for_user(profile: @user, filters: {event_type: "activities"})
    events = Crm::TimelineFeed.for_user(profile: @user, filters: {event_type: "events"})

    assert_includes all.entries.map(&:id), activity.id
    assert activities.entries.all? { |entry| entry.kind == "activity" }
    assert events.entries.all? { |entry| entry.kind == "event" }
    assert all.entries.each_cons(2).all? { |left, right| left.occurred_at >= right.occurred_at }
  end

  test "leaderboards expose only visible teams and portfolios aggregate performance history" do
    peer = create_profile(email: "phase6-peer@example.com")
    outsider = create_profile(email: "phase6-outsider@example.com")
    team = create_team(manager: @user, members: [@user, peer])
    @user.update_columns(xp_total: 200)
    peer.update_columns(xp_total: 300)
    outsider.update_columns(xp_total: 9_999)

    top = Crm::Leaderboard.new(viewer: @user).top_all_time
    portfolio = Crm::PerformancePortfolio.for(@user)

    assert_equal [peer.id, @user.id], top.map(&:id)
    assert_equal team.id, @user.reload.team_id
    assert_equal @user, portfolio.profile
    assert_equal "Rookie", portfolio.current_level.name
    assert_operator portfolio.progress_percent, :>, 0
    assert_equal [1], portfolio.reached_levels.map(&:level)
  end

  private

  def domain_event(id:, name:, record_id:, payload: {})
    Crm::DomainEvents::Event.new(id:, name:, record_type: name.split(".").first.camelize,
      record_id:, actor_id: @user.id, payload:)
  end
end
