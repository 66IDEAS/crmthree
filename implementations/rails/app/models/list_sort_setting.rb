# frozen_string_literal: true

class ListSortSetting < ApplicationRecord
  include Crm::ActorStamped

  before_validation { self.id ||= SecureRandom.uuid }

  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"

  validates :object_type, presence: true, uniqueness: true, inclusion: {in: ->(_record) { Crm::ModelRegistry.object_names }}
  validates :sort_by, inclusion: {in: %w[Number Name]}
  validates :direction, inclusion: {in: %w[Asc Desc]}
end
