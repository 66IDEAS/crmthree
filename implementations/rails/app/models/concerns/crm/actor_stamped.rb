# frozen_string_literal: true

module Crm
  module ActorStamped
    extend ActiveSupport::Concern

    included do
      before_validation :stamp_crm_actor
    end

    private

    def stamp_crm_actor
      return unless Current.profile

      self.created_by ||= Current.profile.id if new_record? && respond_to?(:created_by=)
      self.updated_by = Current.profile.id if respond_to?(:updated_by=)
    end
  end
end
