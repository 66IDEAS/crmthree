# frozen_string_literal: true

# Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand.
class CreateCrmInfrastructure < ActiveRecord::Migration[8.1]
  def change
    create_table :number_counters, id: false do |t|
      t.string :object_type, null: false, primary_key: true
      t.integer :next_value, null: false, default: 1
      t.timestamps null: false
    end
    add_check_constraint :number_counters, "next_value > 0", name: "number_counters_positive"

    create_table :translations, id: :string, limit: 36 do |t|
      t.string :language_code, null: false
      t.string :language_name, null: false
      t.json :labels, null: false, default: {}
      t.timestamps null: false
    end
    add_index :translations, :language_code, unique: true
    add_check_constraint :translations, "json_valid(labels)", name: "translations_valid_json"

    create_table :translation_seed_registry, id: false do |t|
      t.string :language_code, null: false, primary_key: true
      t.string :source_sha256, null: false, limit: 64
      t.datetime :seeded_at, null: false
    end
  end
end
