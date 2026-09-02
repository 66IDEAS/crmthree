# frozen_string_literal: true

module Crm
  module RoleBehavior
    extend ActiveSupport::Concern

    included do
      before_validation :crm_normalize_role_configuration
      validate :crm_valid_permissions
      validate :crm_valid_ribbon_items
      validate :crm_protect_system_identity, on: :update
      before_destroy :crm_prevent_system_role_deletion
      before_destroy :crm_prevent_used_role_deletion
    end

    private

    def crm_normalize_role_configuration
      self.permissions = permissions.to_h
      self.ribbon_items = Array(ribbon_items).compact_blank.uniq
      self.visible_cards = visible_cards.to_h
      self.layout_config = layout_config.to_h
    end

    def crm_valid_permissions
      valid = permissions.is_a?(Hash) && permissions.all? do |object_type, actions|
        (object_type == "*" || Crm::ModelRegistry.object_names.include?(object_type)) &&
          actions.is_a?(Hash) && actions.all? { |action, value| action.in?(ApplicationPolicy::ACTIONS) && value.in?([true, false]) }
      end
      errors.add(:permissions, "contains an unknown object, action, or value") unless valid
    end

    def crm_valid_ribbon_items
      allowed = ["*", "reports"] + Crm::Navigation::ENTRIES.flat_map { |entry| [entry.key, entry.group] }
      errors.add(:ribbon_items, "contains an unknown navigation item") unless ribbon_items.all? { |item| item.in?(allowed) }
    end

    def crm_protect_system_identity
      return unless is_system_role?

      errors.add(:name, "cannot be changed for a system role") if will_save_change_to_name?
      errors.add(:is_system_role, "cannot be changed for a system role") if will_save_change_to_is_system_role?
      errors.add(:active, "cannot be disabled for a system role") if will_save_change_to_active? && !active?
    end

    def crm_prevent_system_role_deletion
      throw(:abort) if is_system_role? && errors.add(:base, "System roles cannot be deleted")
    end

    def crm_prevent_used_role_deletion
      throw(:abort) if UserProfile.exists?(role_id: id) && errors.add(:base, "Roles assigned to users cannot be deleted")
    end
  end
end
