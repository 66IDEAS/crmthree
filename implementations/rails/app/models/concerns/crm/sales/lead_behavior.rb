# frozen_string_literal: true

module Crm
  module Sales
    module LeadBehavior
      extend ActiveSupport::Concern

      TRANSITIONS = {
        "New" => %w[Contacted],
        "Contacted" => %w[Qualified Unqualified],
        "Qualified" => %w[Converted],
        "Unqualified" => %w[Contacted],
        "Converted" => []
      }.freeze

      included do
        attr_accessor :conversion_in_progress

        validates :score, numericality: {only_integer: true, in: 0..100}, allow_nil: true
        validate :crm_valid_status_transition, on: :update
        validate :crm_conversion_fields_present
        after_update_commit :crm_publish_assignment, if: :saved_change_to_owner_id?
      end

      def converted?
        status_converted?
      end

      private

      def crm_publish_assignment
        from, to = saved_change_to_owner_id
        Crm::DomainEvents.publish_after_commit(Crm::DomainEvents::Event.new(
          id: SecureRandom.uuid,
          name: "lead.assigned", record_type: self.class.name, record_id: id,
          actor_id: Current.profile&.id || updated_by, payload: {"from_user_id" => from, "to_user_id" => to}
        ))
      end

      def crm_valid_status_transition
        return unless will_save_change_to_status?
        return if conversion_in_progress

        from, to = status_change_to_be_saved.map { |value| self.class.statuses.fetch(value.to_s, value.to_s) }
        return if to.in?(TRANSITIONS.fetch(from, []))

        errors.add(:status, "cannot change from #{from} to #{to}")
      end

      def crm_conversion_fields_present
        return unless status_converted?
        return if converted_at.present? && converted_account_id.present? && converted_contact_id.present?

        errors.add(:status, "requires a converted account, contact, and timestamp")
      end
    end
  end
end
