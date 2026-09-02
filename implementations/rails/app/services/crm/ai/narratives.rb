# frozen_string_literal: true

module Crm
  module AI
    class Narratives
      def initialize(identity:, gateway: Gateway.new)
        @identity = identity
        @gateway = gateway
      end

      def coaching(opportunity_id:)
        opportunity = Pundit.policy_scope!(identity, Opportunity).find(opportunity_id)
        history = Pundit.policy_scope!(identity, Opportunity).where.not(result: "Open")
        same_stage = history.where(stage_id: opportunity.stage_id)
        evidence = {
          current: ContextBuilder.new(identity:).record(object_type: "Opportunity", id: opportunity.id).value,
          comparable_closed: same_stage.count,
          comparable_won: same_stage.where(result: "Won").count,
          overall_won: history.where(result: "Won").count,
          overall_lost: history.where(result: "Lost").count,
          recent_activity_count: Pundit.policy_scope!(identity, Activity).where(opportunity_id:, created_at: 30.days.ago..).count
        }
        gateway.chat(messages: [{role: "user", content: JSON.generate(evidence)}], system:
          "Coach this opportunity using only the supplied company-history evidence. State the exact evidence behind each " \
          "stage-specific recommendation. If comparable history is sparse, say so. Give at most three next actions.")
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def performance(profile:)
        raise Pundit::NotAuthorizedError unless profile.id == identity.profile.id || Pundit.policy!(identity, profile).show?
        evidence = {
          deals_won: Pundit.policy_scope!(identity, Opportunity).where(owner_id: profile.id, result: "Won").count,
          won_value: Pundit.policy_scope!(identity, Opportunity).where(owner_id: profile.id, result: "Won").sum(:amount),
          activities_30_days: Pundit.policy_scope!(identity, Activity).where(owner_id: profile.id, created_at: 30.days.ago..).count,
          tickets_resolved: Pundit.policy_scope!(identity, Ticket).where(assigned_to: profile.id).where.not(resolved_at: nil).count,
          xp: profile.xp_total, streak: profile.current_streak_days
        }
        gateway.chat(messages: [{role: "user", content: JSON.generate(evidence)}], system:
          "Write a short, concrete performance narrative using only these authorised values. Name strengths, one improvement " \
          "area, and one realistic next action. Do not compare against data that is absent.")
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      private

      attr_reader :identity, :gateway
    end
  end
end
