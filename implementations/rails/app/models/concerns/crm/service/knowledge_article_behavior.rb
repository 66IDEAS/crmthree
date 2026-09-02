# frozen_string_literal: true

module Crm
  module Service
    module KnowledgeArticleBehavior
      extend ActiveSupport::Concern

      included do
        validates :views_count, numericality: {only_integer: true, greater_than_or_equal_to: 0}
        validates :helpful_count, numericality: {only_integer: true, greater_than_or_equal_to: 0}
        before_validation :crm_sync_published_at
      end

      private

      def crm_sync_published_at
        self.published_at ||= Time.current if status_published?
        self.published_at = nil if (status_draft? || status_in_review?) && will_save_change_to_status?
      end
    end
  end
end
