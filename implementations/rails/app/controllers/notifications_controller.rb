# frozen_string_literal: true

class NotificationsController < ApplicationController
  def index
    authorize Notification, :index?
    @notifications = policy_scope(Notification).order(created_at: :desc).limit(30)
    render partial: "notifications/panel", locals: {notifications: @notifications}
  end

  def open
    notification = policy_scope(Notification).find(params[:id])
    authorize notification, :update?
    notification.update!(read: true)
    redirect_to notification_path_for(notification)
  end

  def destroy
    notification = policy_scope(Notification).find(params[:id])
    authorize notification
    notification.destroy!
    redirect_back fallback_location: root_path, notice: "Notification deleted."
  end

  def mark_all
    authorize Notification, :index?
    policy_scope(Notification).where(read: false).update_all(read: true, updated_at: Time.current)
    redirect_back fallback_location: root_path, notice: "Notifications marked as read."
  end

  private

  def notification_path_for(notification)
    return root_path unless notification.link_type.present? && notification.link_id.present?
    return member_profile_path(notification.link_id) if notification.link_type == "UserProfile"
    return root_path unless Crm::ModelRegistry.include?(notification.link_type)

    record_path(object_type: notification.link_type, id: notification.link_id)
  end
end
