# frozen_string_literal: true

module Crm
  class ProfileResolver
    def self.call(auth_user:, allow_empty_instance_bootstrap: false, bootstrap_attributes: {})
      new(auth_user, allow_empty_instance_bootstrap, bootstrap_attributes).call
    end

    def initialize(auth_user, allow_empty_instance_bootstrap, bootstrap_attributes)
      @auth_user = auth_user
      @allow_empty_instance_bootstrap = allow_empty_instance_bootstrap
      @bootstrap_attributes = bootstrap_attributes
    end

    def call
      return Result.failure(:email_not_allowed, status: :forbidden) unless EmailAccess.allowed?(auth_user.email)

      linked = UserProfile.find_by(auth_uid: auth_user.id)
      return active_result(linked) if linked

      claim_matching_profile || bootstrap_empty_instance || Result.failure(:pending_access, status: :forbidden)
    rescue ActiveRecord::RecordNotUnique
      Result.failure(:ambiguous_profile, status: :conflict)
    end

    private

    attr_reader :auth_user, :allow_empty_instance_bootstrap, :bootstrap_attributes

    def claim_matching_profile
      UserProfile.transaction do
        profile = UserProfile.lock.where(auth_uid: nil)
          .find_by("lower(trim(email)) = ?", auth_user.email)
        return unless profile
        return Result.failure(:inactive_profile, status: :forbidden) unless profile.active?

        profile.update!(auth_uid: auth_user.id, email: auth_user.email)
        Result.success(profile, code: :profile_claimed)
      end
    end

    def bootstrap_empty_instance
      return unless allow_empty_instance_bootstrap
      return unless UserProfile.where.not(id: Seeds::SYSTEM_PROFILE_ID).none?

      FirstAdminBootstrap.call!(email: auth_user.email, password: nil, auth_user: auth_user,
        **bootstrap_attributes)
      active_result(UserProfile.find_by!(auth_uid: auth_user.id))
    end

    def active_result(profile)
      return Result.failure(:inactive_profile, status: :forbidden) unless profile.active?

      Result.success(profile)
    end
  end
end
