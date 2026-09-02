# frozen_string_literal: true

class AddGamificationEventInfrastructure < ActiveRecord::Migration[8.1]
  def change
    remove_index :deal_rooms, :opportunity_id, name: "idx_deal_rooms_opportunity_id"
    add_index :deal_rooms, :opportunity_id, unique: true, name: "idx_deal_rooms_opportunity_id"

    create_table :domain_event_receipts, id: false do |table|
      table.string :id, limit: 36, primary_key: true
      table.string :event_id, limit: 36, null: false
      table.string :event_name, limit: 100, null: false
      table.string :actor_id, limit: 36, null: false
      table.datetime :processed_at, null: false
      table.timestamps
    end
    add_index :domain_event_receipts, :event_id, unique: true
    add_foreign_key :domain_event_receipts, :user_profiles, column: :actor_id

    create_table :celebration_events, id: false do |table|
      table.string :id, limit: 36, primary_key: true
      table.string :user_id, limit: 36, null: false
      table.string :kind, limit: 40, null: false
      table.string :message, limit: 255, null: false
      table.string :dedupe_key, limit: 180, null: false
      table.datetime :consumed_at
      table.timestamps
    end
    add_index :celebration_events, :dedupe_key, unique: true
    add_index :celebration_events, %i[user_id consumed_at]
    add_foreign_key :celebration_events, :user_profiles, column: :user_id
  end
end
