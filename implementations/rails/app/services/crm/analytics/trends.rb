# frozen_string_literal: true

module Crm
  module Analytics
    class Trends
      Metric = ::Data.define(:key, :label, :values, :direction, :projection, :explanation)

      def initialize(identity:, months: 6)
        @identity = identity
        @months = [[months.to_i, 3].max, 24].min
      end

      def call
        periods = (@months - 1).downto(0).map { |offset| Date.current.beginning_of_month - offset.months }
        opportunities = Pundit.policy_scope!(identity, Opportunity)
        activities = Pundit.policy_scope!(identity, Activity)
        tickets = Pundit.policy_scope!(identity, Ticket)
        metrics = [
          metric("pipeline", "Pipeline created", periods) { |range| opportunities.where(created_at: range).sum(:amount).to_f },
          metric("closed", "Deals won", periods) { |range| opportunities.where(actual_close_date: range, result: "Won").count.to_f },
          metric("activity", "Activities completed", periods) { |range| activities.where(completed_at: range).count.to_f },
          metric("response", "Average first response hours", periods) do |range|
            rows = tickets.where(created_at: range).where.not(first_response_at: nil).pluck(:created_at, :first_response_at)
            rows.any? ? rows.sum { |created, response| (response - created) / 1.hour } / rows.length : 0.0
          end
        ]
        Result.success({periods: periods.map { |date| date.strftime("%b %Y") }, metrics:})
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      private

      attr_reader :identity

      def metric(key, label, periods)
        values = periods.map { |date| yield(date.beginning_of_month..date.end_of_month.end_of_day).round(2) }
        delta = values.last.to_f - values[-2].to_f
        direction = delta > 0 ? "Up" : (delta < 0 ? "Down" : "Flat")
        changes = values.each_cons(2).map { |a, b| b - a }
        projection = [values.last.to_f + (changes.sum / [changes.length, 1].max), 0].max.round(2)
        Metric.new(key:, label:, values:, direction:, projection:,
          explanation: "Projection = latest month plus the average month-to-month change across #{values.length} authorised periods.")
      end
    end
  end
end
