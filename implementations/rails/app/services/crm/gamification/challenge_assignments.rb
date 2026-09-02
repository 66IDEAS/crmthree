# frozen_string_literal: true

module Crm
  module Gamification
    class ChallengeAssignments
      Assignment = ::Data.define(:title, :description, :target_metric, :target_value, :reward_xp)

      class << self
        def monthly_for(profile:, period: Date.current, actor: profile, gateway: Crm::AI::Gateway.new)
          existing = Challenge.find_by(user_id: profile.id, month: period.month, year: period.year)
          return Result.success(existing, code: :existing) if existing
          return local_for(profile:, period:, actor:) unless gateway.available?

          metrics = {
            role: profile.role&.name,
            activities_last_30_days: Activity.where(owner_id: profile.id, created_at: 30.days.ago..).count,
            accounts_created_last_30_days: Account.where(created_by: profile.id, created_at: 30.days.ago..).count,
            deals_won_last_90_days: Opportunity.where(owner_id: profile.id, result: "Won", actual_close_date: 90.days.ago.to_date..).count,
            tickets_resolved_last_30_days: Ticket.where(assigned_to: profile.id, resolved_at: 30.days.ago..).count
          }
          response = gateway.structured(messages: [{role: "user", content: JSON.generate(metrics)}],
            required_keys: %w[title description target_metric target_value reward_xp], system:
              "Assign one realistic monthly CRM mission from authorised behaviour data. Return JSON only. " \
              "target_metric must be one of create_account, log_activity, close_deal_won, resolve_ticket; " \
              "target_value must be 1..30 and reward_xp 25..250. Cite the relevant baseline in description.")
          return response if response.failure?
          data = response.value
          metric = data["target_metric"].to_s
          target = data["target_value"].to_i
          reward = data["reward_xp"].to_i
          unless metric.in?(%w[create_account log_activity close_deal_won resolve_ticket]) && target.between?(1, 30) && reward.between?(25, 250)
            return Result.failure(:malformed_ai_response, errors: ["The proposed challenge was outside the safe mission limits."])
          end
          create_assignment(profile:, period:, actor:, assignment: Assignment.new(
            title: data["title"].to_s.slice(0, 255), description: data["description"].to_s.slice(0, 2_000),
            target_metric: metric, target_value: target, reward_xp: reward
          ))
        rescue StandardError => error
          ErrorMapper.call(error)
        end

        def local_for(profile:, period: Date.current, actor: profile)
          existing = Challenge.find_by(user_id: profile.id, month: period.month, year: period.year)
          return Result.success(existing, code: :existing) if existing

          assignment = deterministic_assignment(profile)
          create_assignment(profile:, period:, actor:, assignment:)
        rescue StandardError => error
          ErrorMapper.call(error)
        end

        private

        def create_assignment(profile:, period:, actor:, assignment:)
          Current.set(profile: actor) do
            challenge = Challenge.create!(user: profile, title: assignment.title, description: assignment.description,
              month: period.month, year: period.year, target_metric: assignment.target_metric,
              target_value: assignment.target_value, current_value: 0, status: "Active",
              reward_badge: Badge.find_by(category: "Challenge", active: true), reward_xp: assignment.reward_xp)
            Notification.create!(user: profile, type: "ChallengeAssigned", title: "Monthly challenge assigned",
              message: challenge.title, read: false, link_type: "UserProfile", link_id: profile.id,
              send_email: false, email_sent: false)
            Result.success(challenge, code: :created)
          end
        end

        def deterministic_assignment(profile)
          service_role = Array(profile.role&.ribbon_items).include?("service") && !Array(profile.role&.ribbon_items).include?("crm")
          return Assignment.new(title: "Resolve five customer tickets", description: "Resolve five tickets this month.",
            target_metric: "resolve_ticket", target_value: 5, reward_xp: 100) if service_role

          Assignment.new(title: "Log five customer activities", description: "Log five calls, emails, meetings, or tasks this month.",
            target_metric: "log_activity", target_value: 5, reward_xp: 75)
        end
      end
    end
  end
end
