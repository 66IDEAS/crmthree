# frozen_string_literal: true

module Crm
  class TimelineFeed
    Entry = ::Data.define(:kind, :id, :occurred_at, :actor, :title, :status, :object_type, :record_id, :context, :xp)
    Page = ::Data.define(:entries, :page, :per_page, :total_count, :from, :to, :event_type)
    PER_PAGE = 25

    def self.for_user(profile:, filters: {})
      new(profile_ids: [profile.id], filters:).call
    end

    def self.for_team(profile_ids:, filters: {})
      new(profile_ids:, filters:).call
    end

    def initialize(profile_ids:, filters: {})
      @profile_ids = Array(profile_ids).compact.uniq
      @filters = filters.to_h.stringify_keys
    end

    def call
      from = parse_date(filters["from"], 30.days.ago.to_date)
      to = parse_date(filters["to"], Date.current)
      from, to = to, from if from > to
      event_type = filters["event_type"].in?(%w[activities events]) ? filters["event_type"] : "all"
      member_id = filters["member_id"].presence
      ids = member_id.in?(profile_ids) ? [member_id] : profile_ids
      entries = []
      entries.concat(activity_entries(ids, from:, to:)) unless event_type == "events"
      entries.concat(audit_entries(ids, from:, to:)) unless event_type == "activities"
      entries.sort_by! { |entry| [entry.occurred_at, entry.kind, entry.id] }
      entries.reverse!
      page = [filters["page"].to_i, 1].max
      offset = (page - 1) * PER_PAGE
      Page.new(entries: entries.slice(offset, PER_PAGE) || [], page:, per_page: PER_PAGE,
        total_count: entries.length, from:, to:, event_type:)
    end

    private

    attr_reader :profile_ids, :filters

    def activity_entries(ids, from:, to:)
      points = XPEvent.find_by(event_type: "log_activity", active: true)&.xp_value.to_i
      Activity.where(owner_id: ids).where(created_at: day_range(from, to)).includes(:owner, :account, :contact, :lead, :opportunity, :ticket).map do |activity|
        context = [activity.account, activity.contact, activity.lead, activity.opportunity, activity.ticket].compact.first
        Entry.new(kind: "activity", id: activity.id, occurred_at: activity.completed_at || activity.start_date || activity.created_at,
          actor: activity.owner, title: activity.subject, status: activity.status_before_type_cast,
          object_type: "Activity", record_id: activity.id,
          context: context && [context.class.name, context.id, RecordPresentation.display_name(context)], xp: points)
      end
    end

    def audit_entries(ids, from:, to:)
      AuditLog.where(user_id: ids, timestamp: day_range(from, to)).includes(:user).map do |audit|
        Entry.new(kind: "event", id: audit.id, occurred_at: audit.timestamp, actor: audit.user,
          title: audit.summary.presence || "#{audit.action_before_type_cast} #{audit.object_type}", status: audit.action_before_type_cast,
          object_type: audit.object_type, record_id: audit.object_id,
          context: [audit.object_type, audit.object_id, audit.object_name], xp: nil)
      end
    end

    def day_range(from, to)
      from.beginning_of_day..to.end_of_day
    end

    def parse_date(value, fallback)
      Date.iso8601(value.to_s)
    rescue Date::Error
      fallback
    end
  end
end
