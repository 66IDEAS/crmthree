# frozen_string_literal: true

class ActivityPolicy < ApplicationPolicy
  def destroy?
    return super unless record.respond_to?(:is_auto_logged?) && record.is_auto_logged?

    send(:active?) && record.owner_id == user.id && context.api? == false
  end
end
