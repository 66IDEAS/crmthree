# frozen_string_literal: true

module Crm
  class NotificationPreferences
    TYPES = {
      "TicketAssigned" => "Ticket Assigned", "SLABreach" => "SLA Breach",
      "DealStageChange" => "Deal Stage Change", "MentionedInComment" => "Mentioned in Comment",
      "LeadAssigned" => "Lead Assigned", "ChallengeAssigned" => "Challenge Assigned",
      "BadgeEarned" => "Badge Earned", "LevelUp" => "Level Up",
      "PersonalBest" => "Personal Best", "System" => "System"
    }.freeze

    class << self
      def enabled?(profile, type)
        preferences = profile.notification_preferences.to_h.stringify_keys
        cast(preferences.fetch(type, preferences.fetch(type.underscore, true)))
      end

      def desktop?(profile)
        cast(profile.notification_preferences.to_h.stringify_keys.fetch("desktop", false))
      end

      def email?(profile)
        cast(profile.notification_preferences.to_h.stringify_keys.fetch("email", false))
      end

      private

      def cast(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end
    end
  end
end
