# frozen_string_literal: true

module Crm
  module NotificationBehavior
    extend ActiveSupport::Concern

    included do
      after_create_commit :crm_broadcast_notification
    end

    private

    def crm_broadcast_notification
      NotificationChannel.broadcast_to(user, {
        "id" => id,
        "title" => title,
        "message" => message,
        "desktop" => Crm::NotificationPreferences.desktop?(user)
      })
    end
  end
end
