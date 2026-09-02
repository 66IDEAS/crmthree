# frozen_string_literal: true

module Crm
  class RoleManagement
    class << self
      def create(attributes:, actor:)
        role = Role.new(default_attributes.merge(attributes))
        persist(role:, actor:, action: :create)
      end

      def update(role:, attributes:, actor:)
        attributes = attributes.except(:name, :description, :is_system_role, :active) if role.is_system_role?
        role.assign_attributes(attributes)
        persist(role:, actor:, action: :update)
      end

      def destroy(role:, actor:)
        Current.set(profile: actor) do
          ApplicationRecord.transaction do
            AuditWriter.record!(record: role, action: :delete)
            role.destroy!
          end
        end
        Result.success(role, code: :deleted)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      private

      def default_attributes
        {
          is_system_role: false, permissions: {}, ribbon_items: [], visible_cards: {},
          layout_config: {}, active: true
        }
      end

      def persist(role:, actor:, action:)
        Current.set(profile: actor) do
          ApplicationRecord.transaction do
            changes = role.changes
            role.save!
            AuditWriter.record!(record: role, action:, changes:)
          end
        end
        Result.success(role, code: action)
      rescue StandardError => error
        ErrorMapper.call(error)
      end
    end
  end
end
