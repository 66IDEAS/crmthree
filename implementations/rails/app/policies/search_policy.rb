# frozen_string_literal: true

class SearchPolicy < ApplicationPolicy
  def show? = user&.active? && user.role&.active?
end
