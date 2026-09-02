# frozen_string_literal: true

class GamificationSettingPolicy < ApplicationPolicy
  def index? = admin?
  def show? = admin?
  def create? = admin?
  def update? = admin?
  def destroy? = admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      ApplicationPolicy.new(context, scope).admin? ? scope.all : scope.none
    end
  end
end
