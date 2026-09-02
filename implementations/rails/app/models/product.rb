# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class Product < ApplicationRecord
  include Crm::BlueprintModel
  self.table_name = "products"
  enum :product_type, {physical: "Physical", service: "Service", subscription: "Subscription", license: "License"}, prefix: true, validate: true
  enum :status, {active: "Active", inactive: "Inactive", discontinued: "Discontinued"}, prefix: true, validate: true
  belongs_to :creator, class_name: "UserProfile", foreign_key: "created_by"
  belongs_to :updater, class_name: "UserProfile", foreign_key: "updated_by"
end
