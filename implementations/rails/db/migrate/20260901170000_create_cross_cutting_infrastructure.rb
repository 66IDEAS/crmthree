# frozen_string_literal: true

class CreateCrossCuttingInfrastructure < ActiveRecord::Migration[8.1]
  def change
    create_record_locks
    create_import_runs
    strengthen_configuration_records
  end

  private

  def create_record_locks
    create_table :record_locks, id: false do |t|
      t.string :id, limit: 36, primary_key: true
      t.string :object_type, limit: 80, null: false
      t.string :record_id, limit: 36, null: false
      t.string :holder_id, limit: 36, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :record_locks, %i[object_type record_id], unique: true
    add_index :record_locks, :expires_at
    add_foreign_key :record_locks, :user_profiles, column: :holder_id
    add_check_constraint :record_locks, "length(id) = 36", name: "chk_record_locks_id_uuid"
  end

  def create_import_runs
    create_table :import_runs, id: false do |t|
      t.string :id, limit: 36, primary_key: true
      t.string :user_profile_id, limit: 36, null: false
      t.string :object_type, limit: 80, null: false
      t.string :filename, limit: 255, null: false
      t.string :status, limit: 12, null: false, default: "Preview"
      t.text :source_csv, null: false
      t.json :headers, null: false, default: []
      t.json :preview_rows, null: false, default: []
      t.json :mapping, null: false, default: {}
      t.integer :total_rows, null: false, default: 0
      t.integer :processed_rows, null: false, default: 0
      t.integer :created_count, null: false, default: 0
      t.integer :skipped_count, null: false, default: 0
      t.json :errors, null: false, default: []
      t.string :idempotency_key, limit: 100, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
    end
    add_index :import_runs, %i[user_profile_id idempotency_key], unique: true
    add_index :import_runs, %i[user_profile_id created_at]
    add_foreign_key :import_runs, :user_profiles
    add_check_constraint :import_runs, "length(id) = 36", name: "chk_import_runs_id_uuid"
    add_check_constraint :import_runs,
      "status IN ('Preview', 'Queued', 'Running', 'Completed', 'Failed')",
      name: "chk_import_runs_status"
    add_check_constraint :import_runs,
      "total_rows >= 0 AND processed_rows >= 0 AND created_count >= 0 AND skipped_count >= 0",
      name: "chk_import_runs_nonnegative_counts"
  end

  def strengthen_configuration_records
    add_column :translation_seed_registry, :original_labels, :json, null: false, default: {}
    add_index :dashboard_configs, %i[user_id is_default], unique: true,
      where: "is_default = 1", name: "idx_dashboard_configs_one_default"
  end
end
