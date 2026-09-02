# frozen_string_literal: true

module Crm
  module Sales
    module OpportunityBehavior
      extend ActiveSupport::Concern

      included do
        validates :probability, numericality: {only_integer: true, in: 0..100}, allow_nil: true
        validate :crm_stage_must_be_active, if: -> { new_record? || will_save_change_to_stage_id? }
        validate :crm_result_matches_stage
        before_validation :crm_apply_pipeline_stage, if: -> { stage.present? && (new_record? || will_save_change_to_stage_id?) }
        after_update_commit :crm_publish_stage_change, if: :saved_change_to_stage_id?
      end

      private

      def crm_stage_must_be_active
        errors.add(:stage, "must be active") unless stage&.active?
      end

      def crm_apply_pipeline_stage
        self.probability = stage.default_probability if probability.blank? || will_save_change_to_stage_id?
        if stage.is_closed?
          self.result = stage.is_won? ? "Won" : "Lost"
          self.actual_close_date ||= Date.current
        else
          self.result = "Open"
          self.actual_close_date = nil
          self.loss_reason = nil
        end
      end

      def crm_publish_stage_change
        from, to = saved_change_to_stage_id
        Crm::DomainEvents.publish_after_commit(Crm::DomainEvents::Event.new(
          id: SecureRandom.uuid,
          name: "opportunity.stage_changed",
          record_type: self.class.name,
          record_id: id,
          actor_id: Current.profile&.id || updated_by,
          payload: {"from_stage_id" => from, "to_stage_id" => to, "result" => result}
        ))
      end

      def crm_result_matches_stage
        return unless stage

        expected = if stage.is_closed?
          stage.is_won? ? "won" : "lost"
        else
          "open"
        end
        errors.add(:result, "must match the selected pipeline stage") unless result == expected
      end
    end
  end
end
