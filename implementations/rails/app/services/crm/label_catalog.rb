# frozen_string_literal: true

module Crm
  class LabelCatalog
    class << self
      def all
        @all ||= begin
          keys = Rails.root.join("config/crm/translations").glob("*.json").flat_map do |path|
            JSON.parse(path.read).fetch("labels").keys
          end.uniq.sort
          keys.to_h { |key| [key, english_for(key)] }.freeze
        end
      end

      def english_for(key)
        canonical = canonical_english[key]
        return canonical if canonical

        return navigation_label(key.delete_prefix("nav.")) if key.start_with?("nav.")
        return field_label(key) if key.start_with?("field.")
        return key.delete_prefix("enum.") if key.start_with?("enum.")

        key.split(".").last.to_s.tr("_", " ").humanize
      end

      def reset!
        @all = nil
        @canonical_english = nil
      end

      private

      # The shared catalog's English defaults, generated from the reference implementation's
      # catalog exporter (shared architecture, section 13). The rule-based branches below stay
      # as fallback for keys the artifact does not know yet.
      def canonical_english
        @canonical_english ||= JSON.parse(Rails.root.join("config/crm/catalog.en.json").read).freeze
      end

      def navigation_label(key)
        entry = Navigation::ENTRIES.find { |candidate| candidate.key == key }
        entry&.label || key.humanize
      end

      def field_label(key)
        _prefix, object_key, field_name = key.split(".", 3)
        object_type = ModelRegistry.object_names.find { |name| name == object_key || name.underscore == object_key }
        field = object_type && ModelRegistry.field(object_type, field_name)
        field&.fetch("description", nil) || field_name.to_s.humanize
      end
    end
  end
end
