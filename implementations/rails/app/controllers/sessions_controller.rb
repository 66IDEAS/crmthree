# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :require_authentication
  skip_after_action :verify_pundit_usage
  rate_limit to: 5, within: 1.minute, only: :create

  DUMMY_PASSWORD_DIGEST = BCrypt::Password.create("timing-safe-placeholder", cost: BCrypt::Engine.cost).to_s.freeze

  def new
    redirect_to root_path if authenticated?
  end

  def create
    auth_user = AuthUser.find_by(email: Crm::Email.normalize(params[:email]))
    password_matches = auth_user ? auth_user.authenticate(params[:password]) : BCrypt::Password.new(DUMMY_PASSWORD_DIGEST).is_password?(params[:password])

    if !auth_user || !password_matches || auth_user.locked?
      record_failed_attempt(auth_user)
      return redirect_to new_session_path, alert: "Email or password is incorrect"
    end

    auth_user.update!(failed_attempts: 0, locked_until: nil)
    resolution = Crm::ProfileResolver.call(auth_user: auth_user)
    start_crm_session!(auth_user, resolution.success? ? resolution.value : nil)
    redirect_to resolution.success? ? root_path : access_pending_path
  end

  def destroy
    terminate_crm_session!
    redirect_to new_session_path, notice: "Signed out"
  end

  private

  def record_failed_attempt(auth_user)
    return unless auth_user

    attempts = auth_user.failed_attempts + 1
    auth_user.update!(failed_attempts: attempts, locked_until: (15.minutes.from_now if attempts >= 5))
  end
end
