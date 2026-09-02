# frozen_string_literal: true

module Crm
  class TranslationService
    class << self
      def translate(key, fallback:, profile: Current.profile)
        return fallback if profile.blank? || profile.language_preference.blank? || profile.language_preference == "en"

        labels = labels_for(profile)
        labels[key.to_s].presence || fallback
      end

      def options
        [["English", "en"]] + Translation.order(:language_name).pluck(:language_name, :language_code)
      end

      def translated_count(translation)
        translation.labels.to_h.values.count(&:present?)
      end

      private

      def labels_for(profile)
        return Translation.find_by(language_code: profile.language_preference)&.labels.to_h unless profile == Current.profile

        Current.translation_labels ||= Translation.find_by(language_code: profile.language_preference)&.labels.to_h
      end
    end
  end
end
