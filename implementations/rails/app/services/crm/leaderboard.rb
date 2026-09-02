# frozen_string_literal: true

module Crm
  class Leaderboard
    Entry = ::Data.define(:rank, :profile, :value, :trend, :current_user)
    Board = ::Data.define(:dimension, :period, :entries, :current_entry)
    DIMENSIONS = {
      "xp" => "XP Earned", "deals" => "Deals Closed", "activities" => "Activities Logged", "tickets" => "Tickets Resolved"
    }.freeze
    PERIODS = %w[week month quarter].freeze

    def initialize(viewer:, dimension: "xp", period: "month")
      @viewer = viewer
      @dimension = DIMENSIONS.key?(dimension.to_s) ? dimension.to_s : "xp"
      @period = period.to_s.in?(PERIODS) ? period.to_s : "month"
    end

    def call
      profiles = visible_profiles.to_a
      current_range = period_range(Date.current)
      previous_range = previous_period_range(current_range)
      current_values = metric_values(profiles, current_range)
      previous_values = metric_values(profiles, previous_range)
      previous_ranks = ranked_ids(profiles, previous_values).each_with_index.to_h { |id, index| [id, index + 1] }
      entries = ranked_ids(profiles, current_values).each_with_index.map do |id, index|
        profile = profiles.find { |candidate| candidate.id == id }
        rank = index + 1
        old_rank = previous_ranks[id] || rank
        Entry.new(rank:, profile:, value: current_values.fetch(id, 0), trend: old_rank <=> rank, current_user: id == viewer.id)
      end
      Board.new(dimension:, period:, entries:, current_entry: entries.find(&:current_user))
    end

    def top_all_time(limit: 3)
      visible_profiles.order(xp_total: :desc, last_name: :asc, first_name: :asc, id: :asc).limit(limit).to_a
    end

    private

    attr_reader :viewer, :dimension, :period

    def visible_profiles
      base = UserProfile.where(active: true).where.not(id: Seeds::SYSTEM_PROFILE_ID)
      return base if viewer.role.name == "Admin"

      team_ids = Team.where(manager_id: viewer.id, active: true).pluck(:id)
      team_ids << viewer.team_id if viewer.team_id
      ids = base.where(team_id: team_ids.compact.uniq).pluck(:id) | [viewer.id]
      base.where(id: ids)
    end

    def period_range(date)
      case period
      when "week" then date.beginning_of_week..date.end_of_week
      when "quarter" then date.beginning_of_quarter..date.end_of_quarter
      else date.beginning_of_month..date.end_of_month
      end
    end

    def previous_period_range(range)
      days = (range.end - range.begin).to_i + 1
      (range.begin - days.days)..(range.end - days.days)
    end

    def metric_values(profiles, range)
      ids = profiles.map(&:id)
      values = ids.index_with { 0 }
      case dimension
      when "xp"
        AuditLog.where(object_type: "UserProfile", object_id: ids, field_name: "xp_total", timestamp: time_range(range)).find_each do |log|
          values[log.object_id] += log.new_value.to_i - log.old_value.to_i
        end
      when "deals"
        Opportunity.where(owner_id: ids, result: "Won", actual_close_date: range).group(:owner_id).count.each { |id, value| values[id] = value }
      when "activities"
        Activity.where(owner_id: ids, created_at: time_range(range)).group(:owner_id).count.each { |id, value| values[id] = value }
      when "tickets"
        Ticket.where(owner_id: ids, resolved_at: time_range(range)).group(:owner_id).count.each { |id, value| values[id] = value }
      end
      values
    end

    def ranked_ids(profiles, values)
      profiles.sort_by { |profile| [-values.fetch(profile.id, 0).to_d, profile.last_name.downcase, profile.first_name.downcase, profile.id] }.map(&:id)
    end

    def time_range(range)
      range.begin.beginning_of_day..range.end.end_of_day
    end
  end
end
