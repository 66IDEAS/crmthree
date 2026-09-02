# frozen_string_literal: true

class PasswordResetsController < ApplicationController
  skip_before_action :require_authentication
  skip_after_action :verify_pundit_usage
  rate_limit to: 5, within: 1.minute, only: :create

  def new; end

  def create
    auth_user = AuthUser.find_by(email: Crm::Email.normalize(params[:email]))
    Crm::PasswordReset.issue!(auth_user) if auth_user
    redirect_to new_session_path, notice: "If that account exists, local reset instructions were created."
  end

  def edit
    @token = params[:token]
    render :invalid, status: :unprocessable_entity unless Crm::PasswordReset.authenticate(@token)
  end

  def update
    auth_user = Crm::PasswordReset.authenticate(params[:token])
    return render :invalid, status: :unprocessable_entity unless auth_user

    if auth_user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      auth_user.sessions.update_all(revoked_at: Time.current)
      Crm::PasswordReset.consume!(auth_user)
      redirect_to new_session_path, notice: "Password updated. Please sign in."
    else
      @token = params[:token]
      @errors = auth_user.errors.full_messages
      render :edit, status: :unprocessable_entity
    end
  end
end
