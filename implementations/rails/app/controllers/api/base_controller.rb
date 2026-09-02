# frozen_string_literal: true

class API::BaseController < ActionController::API
  include Pundit::Authorization

  before_action :authenticate_api_identity!
  after_action :verify_pundit_usage

  rescue_from Pundit::NotAuthorizedError do
    render json: {error: "not_found"}, status: :not_found
  end

  private

  def authenticate_api_identity!
    raw = request.authorization.to_s[/\ABearer ([A-Za-z0-9_-]+)\z/, 1]
    token = APIToken.authenticate(raw)
    profile = token&.user_profile
    return head :unauthorized unless profile&.active? && profile.role&.active?

    Current.api_token = token
    Current.profile = profile
  end

  def pundit_user
    Crm::AuthorizationContext.new(profile: Current.profile, api_token: Current.api_token)
  end

  def verify_pundit_usage
    pundit_policy_scoped? ? verify_policy_scoped : verify_authorized
  end
end
