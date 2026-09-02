# frozen_string_literal: true

require "csv"

class PerformancePortfoliosController < ApplicationController
  def show
    profile = UserProfile.find(params[:id])
    authorize profile, :show?
    portfolio = Crm::PerformancePortfolio.for(profile)
    filename = "#{profile.first_name}-#{profile.last_name}-portfolio".parameterize + ".csv"
    send_data csv_for(portfolio), filename:,
      type: "text/csv; charset=utf-8", disposition: "attachment"
  end

  private

  def csv_for(portfolio)
    CSV.generate do |csv|
      csv << %w[Section Name Value Date]
      csv << ["Profile", "Level", portfolio.profile.level_name, nil]
      csv << ["Profile", "XP Total", portfolio.profile.xp_total, nil]
      portfolio.reached_levels.each do |level|
        csv << ["Level History", safe("Level #{level.level}: #{level.name}"), level.xp_threshold, level.reached_at&.to_date]
      end
      portfolio.earned_badges.each { |earned| csv << ["Badge", safe(earned.badge.name), safe(earned.badge.description), earned.earned_at.to_date] }
      portfolio.challenge_history.each { |challenge| csv << ["Challenge", safe(challenge.title), challenge.status_before_type_cast, challenge.completed_at&.to_date] }
      portfolio.streaks.each do |streak|
        csv << ["Streak", safe(streak.activity_type.humanize), safe(portfolio.streak_outcomes.fetch(streak)), streak.last_activity_date]
      end
      portfolio.personal_bests.each { |best| csv << ["Personal Best", safe(best.metric.humanize), best.value, best.achieved_at.to_date] }
    end
  end

  def safe(value)
    text = value.to_s
    text.match?(/\A[=+\-@]/) ? "'#{text}" : text
  end
end
