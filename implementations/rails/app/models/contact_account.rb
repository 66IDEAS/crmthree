# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class ContactAccount < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "contact_accounts"
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :contact, class_name: "Contact", foreign_key: "contact_id"
  belongs_to :account, class_name: "Account", foreign_key: "account_id"
end
