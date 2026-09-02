# frozen_string_literal: true

class KnowledgeArticlePolicy < ApplicationPolicy
  def show?
    allowed?(:read) && (record.status_published? || editable_by_user?)
  end

  def update? = allowed?(:update) && editable_by_user?
  def destroy? = allowed?(:delete) && editable_by_user?

  class Scope < ApplicationPolicy::Scope
    def resolve
      policy = KnowledgeArticlePolicy.new(context, scope)
      return scope.none unless policy.allowed?(:read)
      return scope.all if policy.admin?

      visible_ids = [user.id]
      visible_ids.concat(policy.managed_profile_ids) if policy.manager?
      scope.where(status: "Published").or(scope.where(author_id: visible_ids))
    end
  end

  private

  def editable_by_user?
    admin? || record.author_id == user.id || (manager? && record.author_id.in?(managed_profile_ids))
  end
end
