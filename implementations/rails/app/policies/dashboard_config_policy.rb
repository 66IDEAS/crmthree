# frozen_string_literal: true

class DashboardConfigPolicy < ApplicationPolicy
  def create? = active?
  def update? = active? && (record.is_a?(Class) || record.user_id == user.id)
  def show? = active? && record.user_id == user.id

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user&.active?

      scope.where(user_id: user.id)
    end

    private

    attr_reader :user
  end
end
