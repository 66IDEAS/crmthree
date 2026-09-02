# frozen_string_literal: true

require "digest"
require "json"

module Crm
  class Seeds
    SYSTEM_PROFILE_ID = "00000000-0000-4000-8000-000000000001"
    ADMIN_ROLE_ID = "00000000-0000-4000-8000-000000000002"
    SYSTEM_EMAIL = "system@localhost.invalid"

    ROLE_DEFAULTS = {
      "Admin" => {
        description: "Full local CRM administration",
        permissions: {"*" => {"create" => true, "read" => true, "read_all" => true, "update" => true, "delete" => true}},
        ribbon_items: ["*"]
      },
      "Manager" => {
        description: "Team management and team-wide CRM access",
        permissions: {"*" => {"create" => true, "read" => true, "read_all" => true, "update" => true, "delete" => false}},
        ribbon_items: ["crm", "service", "reports"]
      },
      "User" => {
        description: "Standard owner-scoped CRM access",
        permissions: {"*" => {"create" => true, "read" => true, "read_all" => false, "update" => true, "delete" => false}},
        ribbon_items: ["crm", "service"]
      }
    }.freeze

    PIPELINE_STAGES = [
      ["Prospecting", 10, 10, false, false],
      ["Qualification", 20, 25, false, false],
      ["Proposal", 30, 50, false, false],
      ["Negotiation", 40, 75, false, false],
      ["Closed Won", 50, 100, true, true],
      ["Closed Lost", 60, 0, true, false]
    ].freeze

    TICKET_STATUSES = [
      ["New", 10, false, false],
      ["In Progress", 20, false, false],
      ["Waiting", 30, false, false],
      ["Resolved", 40, false, true],
      ["Closed", 50, true, true]
    ].freeze

    LEVELS = [
      [1, "Rookie", 0],
      [2, "Closer", 500],
      [3, "Dealmaker", 1_500],
      [4, "Legend", 5_000]
    ].freeze

    XP_EVENTS = [
      ["create_account", "Create an account", 10],
      ["create_contact", "Create a contact", 10],
      ["qualify_lead", "Qualify a lead", 25],
      ["log_activity", "Log an activity", 15],
      ["post_comment", "Contribute to a workspace discussion", 5],
      ["close_deal_won", "Close an opportunity as won", 100],
      ["resolve_ticket", "Resolve a service ticket", 40]
    ].freeze

    BADGES = [
      ["First Contact", "Create the first contact", "Sales", {"metric" => "contacts_created", "threshold" => 1, "comparison" => ">="}],
      ["Deal Closer", "Close the first opportunity as won", "Sales", {"metric" => "deals_won", "threshold" => 1, "comparison" => ">="}],
      ["SLA Guardian", "Resolve ten tickets within SLA", "Service", {"metric" => "tickets_within_sla", "threshold" => 10, "comparison" => ">="}],
      ["Data Steward", "Create one hundred complete CRM records", "Data Quality", {"metric" => "complete_records", "threshold" => 100, "comparison" => ">="}],
      ["Monthly Mission", "Complete a monthly challenge", "Challenge", {"metric" => "challenges_completed", "threshold" => 1, "comparison" => ">="}]
    ].freeze

    class << self
      def run!
        bootstrap_system_actor!
        seed_roles!
        seed_pipeline_stages!
        seed_ticket_statuses!
        seed_levels!
        seed_xp_events!
        seed_badges!
        seed_translations!
      end

      private

      def bootstrap_system_actor!
        ApplicationRecord.transaction do
          ApplicationRecord.connection.execute("PRAGMA defer_foreign_keys = ON")
          now = Time.current
          admin = Role.find_by(name: "Admin")
          unless admin
            Role.insert_all!([role_attributes(ADMIN_ROLE_ID, "Admin", ROLE_DEFAULTS.fetch("Admin"), now)])
            admin = Role.find(ADMIN_ROLE_ID)
          end

          next if UserProfile.exists?(id: SYSTEM_PROFILE_ID)

          UserProfile.insert_all!([{
            id: SYSTEM_PROFILE_ID,
            created_at: now,
            updated_at: now,
            created_by: SYSTEM_PROFILE_ID,
            updated_by: SYSTEM_PROFILE_ID,
            auth_uid: "local:system-seeder",
            email: SYSTEM_EMAIL,
            first_name: "System",
            last_name: "Seeder",
            role_id: admin.id,
            xp_total: 0,
            level: 1,
            level_name: "Rookie",
            current_streak_days: 0,
            longest_streak_days: 0,
            active: false,
            theme_preference: "System",
            notification_preferences: {},
            language_preference: "en"
          }])
        end
      end

      def seed_roles!
        ROLE_DEFAULTS.each do |name, defaults|
          next if Role.exists?(name: name)

          create_with_actor(Role, defaults.merge(
            name: name,
            is_system_role: true,
            visible_cards: {},
            layout_config: {},
            active: true
          ))
        end
      end

      def seed_pipeline_stages!
        PIPELINE_STAGES.each do |name, sort_order, probability, closed, won|
          next if PipelineStage.exists?(name: name)

          create_with_actor(PipelineStage,
            name: name,
            sort_order: sort_order,
            default_probability: probability,
            is_closed: closed,
            is_won: won,
            active: true)
        end
      end

      def seed_ticket_statuses!
        TICKET_STATUSES.each do |name, sort_order, closed, resolved|
          next if TicketStatus.exists?(name: name)

          create_with_actor(TicketStatus,
            name: name,
            sort_order: sort_order,
            is_closed: closed,
            is_resolved: resolved,
            active: true)
        end
      end

      def seed_levels!
        LEVELS.each do |level, name, threshold|
          next if LevelDefinition.exists?(level: level)

          create_with_actor(LevelDefinition, level: level, name: name, xp_threshold: threshold, unlocks: {})
        end
      end

      def seed_xp_events!
        XP_EVENTS.each do |event_type, description, value|
          next if XPEvent.exists?(event_type: event_type)

          create_with_actor(XPEvent, event_type: event_type, description: description, xp_value: value, active: true)
        end
      end

      def seed_badges!
        BADGES.each do |name, description, category, criteria|
          next if Badge.exists?(name: name)

          create_with_actor(Badge,
            name: name,
            description: description,
            category: category,
            criteria: criteria,
            is_custom: false,
            active: true)
        end
      end

      def seed_translations!
        Rails.root.join("config/crm/translations").glob("*.json").sort.each do |path|
          payload = JSON.parse(path.read)
          language_code = payload.fetch("code")
          digest = Digest::SHA256.file(path).hexdigest
          seed_translation_pack!(payload:, language_code:, digest:)
        end
      end

      def seed_translation_pack!(payload:, language_code:, digest:)
        registry = TranslationSeedRegistry.find_by(language_code:)
        translation = Translation.find_by(language_code:)
        return if registry && !translation

        if registry
          merge_translation_pack!(translation:, registry:, labels: payload.fetch("labels"), digest:)
          return
        end

        translation ||= Translation.create!(
          language_code:,
          language_name: payload.fetch("language_name"),
          labels: payload.fetch("labels")
        )
        TranslationSeedRegistry.create!(
          language_code:, source_sha256: digest, original_labels: payload.fetch("labels"), seeded_at: Time.current
        )
      end

      def merge_translation_pack!(translation:, registry:, labels:, digest:)
        return if registry.source_sha256 == digest && registry.original_labels.present?

        previous = registry.original_labels.to_h
        current = translation.labels.to_h
        labels.each do |key, value|
          current[key] = value if !current.key?(key) || current[key] == previous[key]
        end
        translation.update!(labels: current)
        registry.update!(source_sha256: digest, original_labels: labels, seeded_at: Time.current)
      end

      def create_with_actor(model, attributes)
        model.create!(attributes.merge(created_by: SYSTEM_PROFILE_ID, updated_by: SYSTEM_PROFILE_ID))
      end

      def role_attributes(id, name, defaults, now)
        {
          id: id,
          created_at: now,
          updated_at: now,
          created_by: SYSTEM_PROFILE_ID,
          updated_by: SYSTEM_PROFILE_ID,
          name: name,
          description: defaults.fetch(:description),
          is_system_role: true,
          permissions: defaults.fetch(:permissions),
          ribbon_items: defaults.fetch(:ribbon_items),
          visible_cards: {},
          layout_config: {},
          active: true
        }
      end
    end
  end
end
