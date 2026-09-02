# frozen_string_literal: true

module CrmTestData
  def seed_crm!
    Crm::Seeds.run!
  end

  def create_role(name:, permissions: nil)
    seed_crm!
    Current.set(profile: UserProfile.find(Crm::Seeds::SYSTEM_PROFILE_ID)) do
      Role.create!(
        name: name,
        description: "Test role",
        is_system_role: false,
        permissions: permissions || {"*" => {"create" => true, "read" => true, "read_all" => false, "update" => true, "delete" => false}},
        ribbon_items: ["crm", "service"],
        visible_cards: {},
        layout_config: {},
        active: true
      )
    end
  end

  def create_profile(email:, role: nil, active: true, auth_uid: nil)
    seed_crm!
    role ||= Role.find_by!(name: "User")
    Current.set(profile: UserProfile.find(Crm::Seeds::SYSTEM_PROFILE_ID)) do
      UserProfile.create!(
        email: email,
        first_name: "Test",
        last_name: email.split("@").first,
        role: role,
        active: active,
        auth_uid: auth_uid,
        xp_total: 0,
        level: 1,
        level_name: "Rookie",
        current_streak_days: 0,
        longest_streak_days: 0,
        theme_preference: "System",
        notification_preferences: {},
        language_preference: "en"
      )
    end
  end

  def create_team(manager:, members: [])
    team = Current.set(profile: manager) do
      Team.create!(name: "Team #{SecureRandom.hex(3)}", manager: manager, active: true)
    end
    members.each { |member| Current.set(profile: manager) { member.update!(team: team) } }
    team
  end

  def create_account(owner:, name: nil)
    Current.set(profile: owner) do
      Account.create!(name1: name || "Account #{SecureRandom.hex(3)}", owner_id: owner.id, status: "Active")
    end
  end

  def identity(profile, token: nil)
    Crm::AuthorizationContext.new(profile: profile, api_token: token)
  end
end
