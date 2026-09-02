# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  COOKIE_NAME = :crm_session_token
  SESSION_LIFETIME = 30.days

  included do
    before_action :resume_crm_session
    helper_method :current_profile, :authenticated?
  end

  private

  def resume_crm_session
    record = Session.authenticate(cookies.encrypted[COOKIE_NAME])
    return cookies.delete(COOKIE_NAME) unless record

    Current.session = record
    Current.auth_user = record.auth_user
    resolution = Crm::ProfileResolver.call(auth_user: record.auth_user)
    if resolution.success?
      record.update!(user_profile: resolution.value, last_seen_at: Time.current) if record.user_profile_id != resolution.value.id || record.last_seen_at < 5.minutes.ago
      Current.profile = resolution.value
    end
  end

  def require_authentication
    return if Current.profile

    redirect_to(Current.auth_user ? access_pending_path : new_session_path)
  end

  def require_identity
    redirect_to new_session_path unless Current.auth_user
  end

  def start_crm_session!(auth_user, profile)
    reset_session
    raw_token = SecureRandom.urlsafe_base64(48)
    record = Session.create!(
      auth_user: auth_user,
      user_profile: profile,
      token_digest: Session.digest(raw_token),
      ip_address: request.remote_ip,
      user_agent: request.user_agent.to_s.first(500),
      last_seen_at: Time.current,
      expires_at: SESSION_LIFETIME.from_now
    )
    cookies.encrypted[COOKIE_NAME] = {
      value: raw_token,
      httponly: true,
      same_site: :lax,
      secure: request.ssl?,
      expires: record.expires_at
    }
    Current.session = record
    Current.auth_user = auth_user
    Current.profile = profile
  end

  def terminate_crm_session!
    Current.session&.update!(revoked_at: Time.current)
    cookies.delete(COOKIE_NAME)
    reset_session
    Current.reset
  end

  def current_profile
    Current.profile
  end

  def authenticated?
    Current.profile.present?
  end
end
