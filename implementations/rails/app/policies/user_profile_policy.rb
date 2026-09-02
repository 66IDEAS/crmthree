# frozen_string_literal: true

class UserProfilePolicy < ApplicationPolicy
  def show?
    admin? || (send(:active?) && (record.id == user.id || record.id.in?(managed_profile_ids)))
  end

  def update? = show?
  def create? = admin?
  def destroy? = admin?
  def settings? = admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      policy = ApplicationPolicy.new(context, scope)
      return scope.none unless user&.active?
      return scope.all if policy.admin?

      ids = [user.id]
      ids.concat(policy.managed_profile_ids) if policy.manager?
      scope.where(id: ids.uniq)
    end
  end
end
