# frozen_string_literal: true

module Crm
  module Service
    module TicketStatusBehavior
      extend ActiveSupport::Concern

      included do
        validates :name, uniqueness: {case_sensitive: false}
        validates :sort_order, numericality: {only_integer: true, greater_than_or_equal_to: 0}, uniqueness: true
        validate :crm_closed_status_is_resolved
        before_destroy :crm_prevent_destroy_when_in_use
      end

      private

      def crm_closed_status_is_resolved
        errors.add(:is_closed, "requires a resolved status") if is_closed? && !is_resolved?
      end

      def crm_prevent_destroy_when_in_use
        return unless Ticket.exists?(status_id: id)

        errors.add(:base, "Ticket status is in use and cannot be deleted")
        throw :abort
      end
    end
  end
end
