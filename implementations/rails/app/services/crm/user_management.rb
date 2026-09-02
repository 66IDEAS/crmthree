# frozen_string_literal: true

module Crm
  class UserManagement
    PERSONAL_TABLES = %w[
      dashboard_configs notifications user_badges personal_bests streaks challenges
      api_tokens record_locks import_runs celebration_events
      ai_conversations intake_drafts external_message_receipts replication_runs
    ].freeze

    class << self
      def invite(attributes:, actor:, add_to_whitelist: false)
        email = Email.normalize(attributes.fetch(:email))
        if UserProfile.exists?(email:)
          return Result.failure(:duplicate_email, errors: ["A user with this email already exists"], status: :unprocessable_entity)
        end

        Current.set(profile: actor) do
          Transaction.run do
            role = Role.where(active: true).find(attributes.fetch(:role_id))
            auth_user = create_local_identity(email:, password: attributes[:password])
            profile = UserProfile.create!(
              email:, first_name: attributes.fetch(:first_name), last_name: attributes.fetch(:last_name),
              role:, auth_uid: auth_user&.id, active: true, xp_total: 0, level: 1, level_name: "Rookie",
              current_streak_days: 0, longest_streak_days: 0, theme_preference: "System",
              notification_preferences: {}, language_preference: "en"
            )
            add_whitelist!(email:, actor:) if add_to_whitelist && !EmailAccess.allowed?(email)
            AuditWriter.record!(record: profile, action: :create)
            Result.success(profile, code: auth_user ? :local_user_created : :invited)
          end
        end
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def change_role(profile:, role_id:, actor:)
        return self_change_failure if profile.id == actor.id

        role = Role.where(active: true).find(role_id)
        update_profile(profile:, actor:, attributes: {role:}, code: :role_changed)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def set_active(profile:, active:, actor:)
        return self_change_failure if profile.id == actor.id

        update_profile(profile:, actor:, attributes: {active:}, code: active ? :reactivated : :deactivated)
      end

      def destroy(profile:, actor:)
        return self_change_failure if profile.id == actor.id
        return Result.failure(:system_user, errors: ["The system profile cannot be deleted"]) if profile.id == Seeds::SYSTEM_PROFILE_ID

        Current.set(profile: actor) do
          ApplicationRecord.transaction do
            AuditWriter.record!(record: profile, action: :delete)
            rehome_references!(profile)
            profile.destroy!
          end
        end
        Result.success(profile, code: :deleted)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      private

      def create_local_identity(email:, password:)
        return if password.blank?

        AuthUser.create!(email:, password:, password_confirmation: password)
      end

      def add_whitelist!(email:, actor:)
        Current.set(profile: actor) { EmailAccessRule.create!(rule_type: "Email", value: email, active: true) }
      end

      def update_profile(profile:, actor:, attributes:, code:)
        Current.set(profile: actor) do
          profile.assign_attributes(attributes)
          changes = profile.changes
          profile.save!
          AuditWriter.record!(record: profile, action: :update, changes:)
        end
        Result.success(profile, code:)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      def self_change_failure
        Result.failure(:self_protection, errors: ["You cannot change your own access"], status: :unprocessable_entity)
      end

      def rehome_references!(profile)
        connection = ApplicationRecord.connection
        connection.tables.each do |table|
          next unless connection.foreign_keys(table).any? { |key| key.to_table == "user_profiles" }

          connection.foreign_keys(table).select { |key| key.to_table == "user_profiles" }.each do |foreign_key|
            rehome_reference!(connection:, table:, column: foreign_key.column, profile:)
          end
        end
      end

      def rehome_reference!(connection:, table:, column:, profile:)
        quoted_table = connection.quote_table_name(table)
        quoted_column = connection.quote_column_name(column)
        profile_id = connection.quote(profile.id)
        if table == "sessions" && column == "user_profile_id"
          connection.execute("UPDATE #{quoted_table} SET #{quoted_column} = NULL WHERE #{quoted_column} = #{profile_id}")
        elsif table.in?(PERSONAL_TABLES) && !column.in?(%w[created_by updated_by])
          connection.execute("DELETE FROM #{quoted_table} WHERE #{quoted_column} = #{profile_id}")
        else
          system_id = connection.quote(Seeds::SYSTEM_PROFILE_ID)
          connection.execute("UPDATE #{quoted_table} SET #{quoted_column} = #{system_id} WHERE #{quoted_column} = #{profile_id}")
        end
      end
    end
  end
end
