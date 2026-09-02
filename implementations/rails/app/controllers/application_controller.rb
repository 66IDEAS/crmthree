class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  before_action :require_authentication
  before_action :load_shell_notifications
  before_action :load_shell_celebrations
  after_action :verify_pundit_usage

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rescue_from Pundit::NotAuthorizedError do
    render plain: "Not found", status: :not_found
  end

  private

  def load_shell_notifications
    return unless Current.profile

    @shell_notifications = Notification.where(user_id: Current.profile.id).order(created_at: :desc).limit(30).to_a
    @shell_unread_notifications = @shell_notifications.count { |notification| !notification.read? }
  end

  def load_shell_celebrations
    return unless Current.profile

    @shell_celebrations = CelebrationEvent.pending.where(user_id: Current.profile.id).order(created_at: :asc, id: :asc).limit(5).to_a
    CelebrationEvent.where(id: @shell_celebrations.map(&:id)).update_all(consumed_at: Time.current, updated_at: Time.current) if @shell_celebrations.any?
  end

  def pundit_user
    Crm::AuthorizationContext.new(profile: Current.profile, api_token: Current.api_token)
  end

  def verify_pundit_usage
    pundit_policy_scoped? ? verify_policy_scoped : verify_authorized
  end
end
