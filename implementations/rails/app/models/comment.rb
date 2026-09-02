# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class Comment < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "comments"
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
  belongs_to :author, class_name: "UserProfile", foreign_key: "author_id"
  belongs_to :parent, polymorphic: true, foreign_key: :parent_id, foreign_type: :parent_type
end
