# frozen_string_literal: true

module Crm
  class FirstAdminBootstrap
    class UnsafeState < StandardError; end

    def self.call!(email:, first_name:, last_name:, password: nil, auth_user: nil)
      new(email:, first_name:, last_name:, password:, auth_user:).call!
    end

    def initialize(email:, first_name:, last_name:, password:, auth_user:)
      @email = Email.normalize(email)
      @first_name = first_name.to_s.strip
      @last_name = last_name.to_s.strip
      @password = password
      @provided_auth_user = auth_user
    end

    def call!
      Seeds.run!
      validate_inputs!

      ApplicationRecord.transaction do
        ApplicationRecord.connection.execute("PRAGMA defer_foreign_keys = ON")
        existing = idempotent_existing_state
        return existing if existing

        refuse_populated_or_partial_state!
        auth_user = provided_auth_user || AuthUser.create!(email: email, password: password)
        create_profile!(auth_user)
        auth_user
      end
    end

    private

    attr_reader :email, :first_name, :last_name, :password, :provided_auth_user

    def validate_inputs!
      raise UnsafeState, "A valid email is required" unless email&.match?(URI::MailTo::EMAIL_REGEXP)
      raise UnsafeState, "First and last name are required" if first_name.blank? || last_name.blank?
      raise UnsafeState, "Password must be at least 12 characters" if !provided_auth_user && password.to_s.length < 12
    end

    def idempotent_existing_state
      auth_user = provided_auth_user || AuthUser.find_by(email: email)
      profile = UserProfile.find_by("lower(trim(email)) = ?", email)
      return unless auth_user || profile
      return if provided_auth_user == auth_user && profile.nil?

      if auth_user && profile&.auth_uid == auth_user.id && profile.role&.name == "Admin" && profile.active?
        return auth_user
      end

      raise UnsafeState, "Refusing partially populated or mismatched administrator state"
    end

    def refuse_populated_or_partial_state!
      real_profiles = UserProfile.where.not(id: Seeds::SYSTEM_PROFILE_ID)
      other_auth_users = provided_auth_user ? AuthUser.where.not(id: provided_auth_user.id) : AuthUser.all
      return if real_profiles.none? && other_auth_users.none?

      raise UnsafeState, "Refusing bootstrap because this instance already contains identities or profiles"
    end

    def create_profile!(auth_user)
      now = Time.current
      profile_id = SecureRandom.uuid
      UserProfile.insert_all!([{
        id: profile_id,
        created_at: now,
        updated_at: now,
        created_by: profile_id,
        updated_by: profile_id,
        auth_uid: auth_user.id,
        email: email,
        first_name: first_name,
        last_name: last_name,
        role_id: Role.find_by!(name: "Admin").id,
        xp_total: 0,
        level: 1,
        level_name: "Rookie",
        current_streak_days: 0,
        longest_streak_days: 0,
        active: true,
        theme_preference: "System",
        notification_preferences: {},
        language_preference: "en"
      }])
    end
  end
end
