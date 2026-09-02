# frozen_string_literal: true

class LeaderboardPolicy
  def initialize(identity, _record)
    @profile = identity.is_a?(Crm::AuthorizationContext) ? identity.profile : identity
  end

  def show? = @profile&.active? && @profile.role&.active?
end
