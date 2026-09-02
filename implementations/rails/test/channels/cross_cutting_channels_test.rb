# frozen_string_literal: true

require "test_helper"

class NotificationChannelTest < ActionCable::Channel::TestCase
  tests NotificationChannel

  setup do
    seed_crm!
    @profile = create_profile(email: "notification-channel@example.com")
    stub_connection current_profile: @profile
  end

  test "subscribes only to the authenticated profile stream" do
    subscribe

    assert subscription.confirmed?
    assert_has_stream_for @profile
  end

  test "new notifications broadcast to their recipient" do
    assert_broadcasts(NotificationChannel.broadcasting_for(@profile), 1) do
      Current.set(profile: @profile) do
        Notification.create!(user: @profile, type: "System", title: "Account review",
          message: "Review Northstar", read: false, send_email: false, email_sent: false)
      end
    end
  end
end

class RecordChannelTest < ActionCable::Channel::TestCase
  tests RecordChannel

  setup do
    seed_crm!
    @owner = create_profile(email: "record-channel-owner@example.com")
    @other = create_profile(email: "record-channel-other@example.com")
    @account = create_account(owner: @owner, name: "Channel-visible account")
  end

  test "streams a record visible to the current profile" do
    stub_connection current_profile: @owner
    subscribe object_type: "Account", record_id: @account.id

    assert subscription.confirmed?
    assert_has_stream RecordChannel.broadcasting_for("Account:#{@account.id}")
  end

  test "rejects a record outside the current profile policy scope" do
    stub_connection current_profile: @other
    subscribe object_type: "Account", record_id: @account.id

    assert subscription.rejected?
    assert_no_streams
  end

  test "rejects unknown objects and records" do
    stub_connection current_profile: @owner
    subscribe object_type: "Unknown", record_id: @account.id

    assert subscription.rejected?
    assert_no_streams
  end
end
