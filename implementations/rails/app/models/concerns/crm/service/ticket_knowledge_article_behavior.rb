# frozen_string_literal: true

module Crm
  module Service
    module TicketKnowledgeArticleBehavior
      extend ActiveSupport::Concern

      included do
        before_validation :crm_apply_link_defaults
        validates :article_id, uniqueness: {scope: :ticket_id}
      end

      private

      def crm_apply_link_defaults
        self.linked_at ||= Time.current
        self.linked_by ||= Current.profile&.id
      end
    end
  end
end
