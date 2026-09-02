# frozen_string_literal: true

class NotificationPreferencesController < ApplicationController
  def update
    authorize current_profile, :update?
    allowed = Crm::NotificationPreferences::TYPES.keys + %w[desktop email]
    values = params.fetch(:preferences, {}).permit(*allowed).to_h
      .transform_values { |value| ActiveModel::Type::Boolean.new.cast(value) }
    current = current_profile.notification_preferences.to_h.stringify_keys
    Current.set(profile: current_profile) { current_profile.update!(notification_preferences: current.merge(values)) }
    redirect_to settings_path(anchor: "notification-preferences"), notice: "Notification preferences saved."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to settings_path(anchor: "notification-preferences"), alert: error.record.errors.full_messages.to_sentence
  end
end
