# frozen_string_literal: true

class TimelinePolicy
  def initialize(identity, _record)
    @profile = identity.is_a?(Crm::AuthorizationContext) ? identity.profile : identity
  end

  def show?
    profile&.active? && profile.role&.active?
  end

  def team?
    show? && (profile.role.name == "Admin" || Team.where(manager_id: profile.id, active: true).exists?)
  end

  private

  attr_reader :profile
end
