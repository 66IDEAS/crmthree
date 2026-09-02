# frozen_string_literal: true

module Crm
  module Service
    module AssetBehavior
      extend ActiveSupport::Concern

      included do
        validate :crm_warranty_after_install
      end

      private

      def crm_warranty_after_install
        return if install_date.blank? || warranty_end_date.blank? || warranty_end_date >= install_date

        errors.add(:warranty_end_date, "must be on or after the install date")
      end
    end
  end
end
