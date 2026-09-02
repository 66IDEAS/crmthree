# frozen_string_literal: true

class IntakeDraftPolicy < ApplicationPolicy
  def show? = active_owner_or_admin?
  def update? = active_owner_or_admin?
  def create? = send(:active?)
  def destroy? = active_owner_or_admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      policy = ApplicationPolicy.new(context, scope)
      return scope.none unless user&.active?
      return scope.all if policy.admin?

      scope.where(user_profile_id: user.id)
    end
  end

  private

  def active_owner_or_admin? = admin? || (send(:active?) && record.user_profile_id == user.id)
end
