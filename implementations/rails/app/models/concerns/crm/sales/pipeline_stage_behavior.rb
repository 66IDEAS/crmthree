# frozen_string_literal: true

module Crm
  module Sales
    module PipelineStageBehavior
      extend ActiveSupport::Concern

      included do
        validates :sort_order, numericality: {only_integer: true, greater_than_or_equal_to: 0}
        validates :default_probability, numericality: {only_integer: true, in: 0..100}, allow_nil: true
        validate :crm_won_stage_is_closed
        before_destroy :crm_prevent_destroy_when_in_use
      end

      private

      def crm_won_stage_is_closed
        errors.add(:is_won, "requires a closed stage") if is_won? && !is_closed?
      end

      def crm_prevent_destroy_when_in_use
        return unless Opportunity.exists?(stage_id: id)

        errors.add(:base, "Pipeline stage is in use and cannot be deleted")
        throw :abort
      end
    end
  end
end
