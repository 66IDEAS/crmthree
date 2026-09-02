# frozen_string_literal: true

class HomePolicy
  def initialize(user, _record)
    @user = user.is_a?(Crm::AuthorizationContext) ? user.profile : user
  end

  def show?
    @user&.active?
  end
end
