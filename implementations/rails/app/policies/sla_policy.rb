# frozen_string_literal: true

class SLAPolicy < ApplicationPolicy
  def show? = allowed?(:read)
  def create? = admin?
  def update? = admin?
  def destroy? = admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      SLAPolicy.new(context, scope).allowed?(:read) ? scope.all : scope.none
    end
  end
end
