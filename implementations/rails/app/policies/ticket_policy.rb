# frozen_string_literal: true

class TicketPolicy < ApplicationPolicy
  def convert_to_knowledge? = update? && record.status&.is_resolved? && record.resolution.present?

  def visible?
    return false unless allowed?(:read)
    return true if admin? || !record.respond_to?(:id)

    visible_ids = [user.id]
    visible_ids.concat(managed_profile_ids) if manager?
    record.owner_id.in?(visible_ids) || record.assigned_to.in?(visible_ids)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      policy = TicketPolicy.new(context, scope)
      return scope.none unless policy.allowed?(:read)
      return scope.all if policy.admin?

      visible_ids = [user.id]
      visible_ids.concat(policy.managed_profile_ids) if policy.manager?
      scope.where(owner_id: visible_ids).or(scope.where(assigned_to: visible_ids))
    end
  end
end
