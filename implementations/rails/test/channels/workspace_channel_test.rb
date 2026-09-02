# frozen_string_literal: true

require "test_helper"

class WorkspaceChannelTest < ActionCable::Channel::TestCase
  tests WorkspaceChannel

  setup do
    seed_crm!
    @owner = create_profile(email: "workspace-channel-owner@example.com")
    @other = create_profile(email: "workspace-channel-other@example.com")
    @account = create_account(owner: @owner, name: "Realtime Workspace Customer")
    @opportunity = Current.set(profile: @owner) do
      Opportunity.create!(name: "Realtime opportunity", account: @account,
        stage: PipelineStage.find_by!(name: "Qualification"), currency: "CHF", result: "Open", owner: @owner)
    end
    @room = Current.set(profile: @owner) do
      DealRoom.create!(name: "Realtime Deal Room", opportunity: @opportunity, status: "Active", owner: @owner)
    end
    @ticket = Current.set(profile: @owner) do
      Ticket.create!(subject: "Realtime service case", status: TicketStatus.find_by!(name: "New"),
        priority: "Medium", account: @account, owner: @owner)
    end
  end

  test "streams only Deal Rooms visible to the subscriber" do
    stub_connection current_profile: @owner
    subscribe workspace_type: "DealRoom", workspace_id: @room.id

    assert subscription.confirmed?
    assert_has_stream WorkspaceChannel.broadcasting_for("DealRoom:#{@room.id}")

    unsubscribe
    stub_connection current_profile: @other
    subscribe workspace_type: "DealRoom", workspace_id: @room.id
    assert subscription.rejected?
    assert_no_streams
  end

  test "streams visible tickets and rejects unsupported types" do
    stub_connection current_profile: @owner
    subscribe workspace_type: "Ticket", workspace_id: @ticket.id
    assert subscription.confirmed?
    assert_has_stream WorkspaceChannel.broadcasting_for("Ticket:#{@ticket.id}")

    unsubscribe
    subscribe workspace_type: "Account", workspace_id: @account.id
    assert subscription.rejected?
    assert_no_streams
  end

  test "workspace changes broadcast refresh invalidations with the acting profile" do
    stream = WorkspaceChannel.broadcasting_for("DealRoom:#{@room.id}")

    assert_broadcast_on(stream, {"action" => "refresh", "actor_id" => @owner.id}) do
      result = Crm::Workspace::Comments.create(parent: @room, content: "Shared in real time", identity: identity(@owner))
      assert result.success?
    end
  end
end
