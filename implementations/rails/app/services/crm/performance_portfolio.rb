# frozen_string_literal: true

module Crm
  class PerformancePortfolio
    ReachedLevel = ::Data.define(:level, :name, :xp_threshold, :reached_at)
    Snapshot = ::Data.define(:profile, :current_level, :next_level, :progress_percent, :earned_badges,
      :unearned_badges, :active_challenge, :challenge_history, :streaks, :personal_bests,
      :reached_levels, :streak_outcomes)

    def self.for(profile)
      current = LevelDefinition.find_by(level: profile.level) || LevelDefinition.order(:level).first
      next_level = LevelDefinition.where("xp_threshold > ?", profile.xp_total).order(:xp_threshold, :level).first
      floor = current&.xp_threshold.to_i
      ceiling = next_level&.xp_threshold.to_i
      progress = next_level ? (((profile.xp_total - floor).to_f / [ceiling - floor, 1].max) * 100).clamp(0, 100).round : 100
      earned = UserBadge.where(user_id: profile.id).includes(:badge).order(earned_at: :desc, id: :desc).to_a
      earned_ids = earned.map(&:badge_id)
      challenges = Challenge.where(user_id: profile.id).includes(:reward_badge).order(year: :desc, month: :desc, id: :desc).to_a
      streaks = Streak.where(user_id: profile.id).order(current_count: :desc, longest_count: :desc).to_a
      Snapshot.new(profile:, current_level: current, next_level:, progress_percent: progress,
        earned_badges: earned, unearned_badges: Badge.where(active: true).where.not(id: earned_ids).order(:category, :name).to_a,
        active_challenge: challenges.find(&:status_active?), challenge_history: challenges,
        streaks:,
        personal_bests: PersonalBest.where(user_id: profile.id).order(achieved_at: :desc).to_a,
        reached_levels: reached_levels(profile), streak_outcomes: streak_outcomes(profile, streaks))
    end

    def self.reached_levels(profile)
      audits = AuditLog.where(object_type: "UserProfile", object_id: profile.id, field_name: "level")
        .order(timestamp: :asc, id: :asc).to_a
      LevelDefinition.where("level <= ?", profile.level).order(:level, :id).map do |definition|
        audit = audits.find { |entry| entry.new_value.to_i == definition.level }
        reached_at = audit&.timestamp || (profile.created_at if definition.level == 1)
        ReachedLevel.new(level: definition.level, name: definition.name, xp_threshold: definition.xp_threshold, reached_at:)
      end
    end

    def self.streak_outcomes(profile, streaks)
      streaks.index_with do |streak|
        next "Longest recorded run: #{streak.longest_count} days." unless streak.current_count.positive? && streak.last_activity_date

        from = streak.last_activity_date - (streak.current_count - 1).days
        range = from.beginning_of_day..streak.last_activity_date.end_of_day
        activities = Activity.where(owner_id: profile.id, created_at: range).count
        wins = Opportunity.where(owner_id: profile.id, result: "Won", actual_close_date: from..streak.last_activity_date).count
        resolutions = Ticket.where(owner_id: profile.id, resolved_at: range).count
        "During this run: #{activities} activities, #{wins} won deals, and #{resolutions} resolved tickets."
      end
    end
  end
end
