# frozen_string_literal: true

class NotificationPolicy < ApplicationPolicy
  def index? = active?
  def show? = active? && record.user_id == user.id
  def update? = show?
  def destroy? = show?

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user&.active?

      scope.where(user_id: user.id)
    end

    private

    attr_reader :user
  end
end
