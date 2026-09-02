# frozen_string_literal: true

module Crm
  module Gamification
    class EventHandler
      EVENT_TYPES = {
        "account.create" => "create_account",
        "contact.create" => "create_contact",
        "activity.create" => "log_activity",
        "comment.create" => "post_comment"
      }.freeze

      class << self
        def call(event)
          new(event).call
        rescue StandardError => error
          Rails.logger.error("Gamification handler failed for #{event.name}: #{error.class}: #{error.message}")
        end
      end

      def initialize(event)
        @event = event
      end

      def call
        type = event_type
        return unless type

        actor = UserProfile.find_by(id: event.actor_id, active: true)
        return unless actor

        ApplicationRecord.transaction(requires_new: true) do
          DomainEventReceipt.create!(event_id: event.id, event_name: event.name, actor:, processed_at: Time.current)
          Current.set(profile: actor) { process(actor, type) }
        end
      rescue ActiveRecord::RecordNotUnique
        nil
      end

      private

      attr_reader :event

      def event_type
        return "close_deal_won" if event.name == "opportunity.stage_changed" && event.payload["result"] == "Won"
        if event.name == "lead.update" && event.payload.fetch("changed_fields", []).include?("status")
          return "qualify_lead" if Lead.find_by(id: event.record_id)&.status_qualified?
        end
        if event.name == "ticket.status_changed"
          status = TicketStatus.find_by(id: event.payload["to_status_id"])
          return "resolve_ticket" if status&.is_resolved?
        end

        EVENT_TYPES[event.name]
      end

      def process(profile, type)
        challenge_reward = progress_challenges(profile, type)
        configured_points = XPEvent.find_by(event_type: type, active: true)&.xp_value.to_i
        award_points(profile, configured_points + challenge_reward, reason: type)
        streak = update_streak(profile, type)
        update_personal_best(profile, type, streak:)
        evaluate_badges(profile)
        celebrate(profile, "deal_won", "Deal won — excellent work!", event.id) if type == "close_deal_won"
      end

      def award_points(profile, points, reason:)
        return if points.zero?

        profile.with_lock do
          old_xp = profile.xp_total
          old_level = profile.level
          old_level_name = profile.level_name
          profile.xp_total += points
          definition = LevelDefinition.where("xp_threshold <= ?", profile.xp_total).order(xp_threshold: :desc, level: :desc).first
          if definition
            profile.level = definition.level
            profile.level_name = definition.name
          end
          profile.save!
          changes = {"xp_total" => [old_xp, profile.xp_total]}
          if profile.level != old_level
            changes["level"] = [old_level, profile.level]
            changes["level_name"] = [old_level_name, profile.level_name]
          end
          AuditWriter.record!(record: profile, action: :update, changes:)
          if profile.level != old_level
            notify(profile, type: "LevelUp", title: "Level up: #{profile.level_name}",
              message: "You reached level #{profile.level} with #{profile.xp_total} XP.")
            celebrate(profile, "level_up", "Level up! You are now #{profile.level_name}.", "#{event.id}:level")
          end
        end
      end

      def progress_challenges(profile, type)
        reward = 0
        Challenge.where(user_id: profile.id, status: "Active", target_metric: type).find_each do |challenge|
          before = challenge.attributes.slice("current_value", "status", "completed_at")
          challenge.current_value = [challenge.current_value + 1, challenge.target_value].min
          if challenge.current_value >= challenge.target_value
            challenge.status = "Completed"
            challenge.completed_at = Time.current
            reward += challenge.reward_xp
          end
          challenge.save!
          AuditWriter.record!(record: challenge, action: :update, changes: changes_from(before, challenge))
          next unless challenge.status_completed?

          award_badge(profile, challenge.reward_badge, source: "challenge:#{challenge.id}") if challenge.reward_badge
          notify(profile, type: "System", title: "Challenge completed", message: challenge.title)
          celebrate(profile, "challenge", "Challenge completed: #{challenge.title}", "#{event.id}:challenge:#{challenge.id}")
        end
        reward
      end

      def update_streak(profile, type)
        return unless type == "log_activity"

        streak = Streak.find_or_initialize_by(user_id: profile.id, activity_type: type)
        today = Date.current
        return streak if streak.last_activity_date == today

        previous_longest = streak.longest_count
        streak.current_count = streak.last_activity_date == today - 1 ? streak.current_count + 1 : 1
        streak.longest_count = [streak.longest_count, streak.current_count].max
        streak.last_activity_date = today
        streak.save!

        current_max = Streak.where(user_id: profile.id).maximum(:current_count).to_i
        longest_max = Streak.where(user_id: profile.id).maximum(:longest_count).to_i
        changes = {}
        changes["current_streak_days"] = [profile.current_streak_days, current_max] if profile.current_streak_days != current_max
        changes["longest_streak_days"] = [profile.longest_streak_days, longest_max] if profile.longest_streak_days != longest_max
        if changes.any?
          profile.update!(current_streak_days: current_max, longest_streak_days: longest_max)
          AuditWriter.record!(record: profile, action: :update, changes:)
        end
        if streak.longest_count > previous_longest && streak.longest_count > 1
          celebrate(profile, "streak", "#{streak.longest_count}-day activity streak!", "#{event.id}:streak")
        end
        streak
      end

      def update_personal_best(profile, type, streak:)
        case type
        when "close_deal_won"
          opportunity = Opportunity.find_by(id: event.record_id)
          record_personal_best(profile, "largest_deal", opportunity&.amount, higher_is_better: true)
        when "resolve_ticket"
          ticket = Ticket.find_by(id: event.record_id)
          duration = (ticket.resolved_at - ticket.created_at) / 1.hour if ticket&.resolved_at
          record_personal_best(profile, "fastest_ticket_resolution_hours", duration, higher_is_better: false)
        when "log_activity"
          record_personal_best(profile, "activity_streak", streak&.longest_count, higher_is_better: true)
        end
      end

      def record_personal_best(profile, metric, candidate, higher_is_better:)
        return if candidate.blank?

        best = PersonalBest.find_or_initialize_by(user_id: profile.id, metric:)
        improved = best.new_record? || (higher_is_better ? candidate.to_d > best.value.to_d : candidate.to_d < best.value.to_d)
        return unless improved

        best.previous_value = best.value if best.persisted?
        best.previous_achieved_at = best.achieved_at if best.persisted?
        best.value = candidate
        best.achieved_at = Time.current
        best.save!
        label = metric.humanize
        notify(profile, type: "PersonalBest", title: "New personal best", message: "#{label}: #{candidate.to_d.round(2)}")
        celebrate(profile, "personal_best", "New personal best: #{label}", "#{event.id}:best:#{metric}")
      end

      def evaluate_badges(profile)
        Badge.where(active: true).find_each do |badge|
          next if UserBadge.exists?(user_id: profile.id, badge_id: badge.id)
          next unless badge_earned?(profile, badge.criteria.to_h)

          award_badge(profile, badge, source: "event:#{event.id}")
        end
      end

      def badge_earned?(profile, criteria)
        metric = criteria["metric"].to_s
        target = criteria["threshold"].to_d
        value = metric_value(profile, metric)
        case criteria.fetch("comparison", ">=")
        when ">" then value > target
        when "==" then value == target
        when "<=" then value <= target
        when "<" then value < target
        else value >= target
        end
      end

      def metric_value(profile, metric)
        case metric
        when "contacts_created" then Contact.where(created_by: profile.id).count
        when "deals_won" then Opportunity.where(owner_id: profile.id, result: "Won").count
        when "tickets_within_sla"
          Ticket.where(owner_id: profile.id).where.not(resolved_at: nil, sla_resolution_deadline: nil)
            .where("resolved_at <= sla_resolution_deadline").count
        when "complete_records"
          [Account, Contact, Lead, Opportunity, Activity, Ticket].sum { |model| model.where(created_by: profile.id).count }
        when "challenges_completed" then Challenge.where(user_id: profile.id, status: "Completed").count
        else 0
        end.to_d
      end

      def award_badge(profile, badge, source:)
        return unless badge

        UserBadge.create!(user: profile, badge:, earned_at: Time.current)
        notify(profile, type: "BadgeEarned", title: "Badge earned: #{badge.name}", message: badge.description)
        celebrate(profile, "badge", "Badge earned: #{badge.name}", "#{source}:badge:#{badge.id}")
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => error
        raise unless UserBadge.exists?(user_id: profile.id, badge_id: badge.id)

        Rails.logger.debug { "Badge already awarded: #{error.message}" }
      end

      def notify(profile, type:, title:, message:)
        return unless NotificationPreferences.enabled?(profile, type)

        Notification.create!(user: profile, type:, title:, message:, read: false,
          link_type: "UserProfile", link_id: profile.id, send_email: false, email_sent: false)
      end

      def celebrate(profile, kind, message, key)
        CelebrationEvent.create!(user: profile, kind:, message:, dedupe_key: key)
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        nil
      end

      def changes_from(before, record)
        before.to_h { |field, value| [field, [value, record.public_send(field)]] }
          .select { |_field, values| values.first != values.last }
      end
    end
  end
end
