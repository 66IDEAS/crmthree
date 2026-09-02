# frozen_string_literal: true

module Crm
  class RoleLayout
    class << self
      def list_columns(profile:, object_type:, fallback:)
        configured_fields(profile:, object_type:, key: "list_columns", fallback:)
      end

      def detail_fields(profile:, object_type:, fallback:)
        names = configured_fields(profile:, object_type:, key: "detail_fields", fallback: fallback.map { |field| field.fetch("name") })
        fallback.select { |field| field.fetch("name").in?(names) }
      end

      def filter_cards(profile:, object_type:, parents:, children:)
        configured = profile.role.visible_cards.to_h[object_type]
        configured = configured.to_h["relationships"] if configured.is_a?(Hash)
        names = Array(configured).map(&:to_s)
        return [parents, children] if names.empty?

        [
          parents.select { |card| card.field.fetch("name").in?(names) || card.object_type.in?(names) },
          children.select { |card| card.relationship.fetch("name").in?(names) || card.relationship.fetch("target").in?(names) }
        ]
      end

      private

      def configured_fields(profile:, object_type:, key:, fallback:)
        configured = profile.role.layout_config.to_h.dig(object_type, key)
        names = Array(configured).map(&:to_s)
        return fallback if names.empty?

        allowed = ModelRegistry.fetch(object_type).fetch("fields").pluck("name")
        selected = names & allowed
        selected.presence || fallback
      end
    end
  end
end
