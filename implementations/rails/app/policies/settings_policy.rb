# frozen_string_literal: true

class SettingsPolicy < ApplicationPolicy
  def index? = active?
  def show? = active?
  def create? = admin?
  def update? = admin?
  def destroy? = admin?
  def settings? = admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      ApplicationPolicy.new(context, scope).admin? ? scope.all : scope.none
    end
  end
end
