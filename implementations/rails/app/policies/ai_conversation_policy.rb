# frozen_string_literal: true

class AIConversationPolicy < ApplicationPolicy
  def show? = active_owner?
  def update? = active_owner?
  def create? = send(:active?)
  def destroy? = active_owner?

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user&.active?

      scope.where(user_profile_id: user.id)
    end
  end

  private

  def active_owner? = send(:active?) && record.user_profile_id == user.id
end
