# frozen_string_literal: true

class DuplicateLinkPolicy < ApplicationPolicy
  def index? = send(:active?)
  def show? = records_visible?
  def create? = send(:active?)
  def update? = records_visible?
  def destroy? = records_visible?

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user&.active?
      return scope.all if ApplicationPolicy.new(context, scope).admin?

      visible = %w[Account Contact].to_h do |type|
        [type, Pundit.policy_scope!(context, Crm::ModelRegistry.model_for(type)).select(:id)]
      end
      scope.where(object_type: "Account", primary_record_id: visible["Account"])
        .or(scope.where(object_type: "Contact", primary_record_id: visible["Contact"]))
    end
  end

  private

  def records_visible?
    return false unless send(:active?)
    model = Crm::ModelRegistry.model_for(record.object_type)
    ids = [record.primary_record_id, record.duplicate_record_id]
    Pundit.policy_scope!(context, model).where(id: ids).count == ids.uniq.length
  end
end
