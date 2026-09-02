# frozen_string_literal: true

class CreatePhaseSevenInfrastructure < ActiveRecord::Migration[8.1]
  def change
    create_ai_conversations
    create_replication_records
    create_integration_outbox
    create_intake_drafts
    create_duplicate_links
    create_configuration_proposals
    create_external_message_receipts
    strengthen_provider_configuration
  end

  private

  def uuid_table(name, &)
    create_table name, id: false do |table|
      table.string :id, limit: 36, primary_key: true
      yield table
      table.timestamps null: false
    end
    add_check_constraint name, "length(id) = 36", name: "chk_#{name}_id_uuid"
  end

  def actor_columns(table)
    table.string :created_by, limit: 36, null: false
    table.string :updated_by, limit: 36, null: false
  end

  def actor_foreign_keys(table)
    add_foreign_key table, :user_profiles, column: :created_by
    add_foreign_key table, :user_profiles, column: :updated_by
  end

  def create_ai_conversations
    uuid_table :ai_conversations do |table|
      table.string :user_profile_id, limit: 36, null: false
      table.string :title, limit: 160, null: false, default: "CRM Assistant"
      table.string :context_type, limit: 80
      table.string :context_id, limit: 36
      table.json :messages, null: false, default: []
      table.datetime :last_used_at, null: false
    end
    add_foreign_key :ai_conversations, :user_profiles
    add_index :ai_conversations, %i[user_profile_id last_used_at]
    add_check_constraint :ai_conversations, "json_valid(messages)", name: "chk_ai_conversations_messages_json"
  end

  def create_replication_records
    uuid_table :replication_configs do |table|
      table.string :object_type, limit: 80, null: false
      table.string :endpoint_url, limit: 500, null: false
      table.json :request_body, null: false, default: {}
      table.json :field_mapping, null: false, default: {}
      table.string :key_field, limit: 100, null: false
      table.boolean :active, null: false, default: true
      table.datetime :last_run_at
      actor_columns(table)
    end
    add_index :replication_configs, %i[object_type endpoint_url], unique: true
    add_check_constraint :replication_configs, "json_valid(request_body)", name: "chk_replication_configs_request_json"
    add_check_constraint :replication_configs, "json_valid(field_mapping)", name: "chk_replication_configs_mapping_json"
    actor_foreign_keys :replication_configs

    uuid_table :replication_runs do |table|
      table.string :replication_config_id, limit: 36, null: false
      table.string :user_profile_id, limit: 36, null: false
      table.string :status, limit: 20, null: false, default: "Queued"
      table.string :idempotency_key, limit: 120, null: false
      table.integer :processed_count, null: false, default: 0
      table.integer :created_count, null: false, default: 0
      table.integer :updated_count, null: false, default: 0
      table.integer :skipped_count, null: false, default: 0
      table.integer :error_count, null: false, default: 0
      table.json :error_details, null: false, default: []
      table.datetime :started_at
      table.datetime :completed_at
    end
    add_foreign_key :replication_runs, :replication_configs
    add_foreign_key :replication_runs, :user_profiles
    add_index :replication_runs, %i[replication_config_id idempotency_key], unique: true,
      name: "idx_replication_runs_idempotency"
    add_check_constraint :replication_runs,
      "status IN ('Queued','Running','Completed','Failed')", name: "chk_replication_runs_status"
    add_check_constraint :replication_runs, "json_valid(error_details)", name: "chk_replication_runs_errors_json"
  end

  def create_integration_outbox
    uuid_table :integration_outbox_entries do |table|
      table.string :data_source_config_id, limit: 36, null: false
      table.string :object_type, limit: 80, null: false
      table.string :record_id, limit: 100, null: false
      table.string :operation, limit: 20, null: false
      table.json :payload, null: false, default: {}
      table.string :dedupe_key, limit: 160, null: false
      table.string :status, limit: 20, null: false, default: "Pending"
      table.integer :attempts, null: false, default: 0
      table.text :last_error
      table.datetime :processed_at
    end
    add_foreign_key :integration_outbox_entries, :data_source_configs
    add_index :integration_outbox_entries, :dedupe_key, unique: true
    add_index :integration_outbox_entries, %i[status created_at]
    add_check_constraint :integration_outbox_entries, "json_valid(payload)", name: "chk_integration_outbox_payload_json"
    add_check_constraint :integration_outbox_entries,
      "status IN ('Pending','Processing','Completed','Failed')", name: "chk_integration_outbox_status"
  end

  def create_intake_drafts
    uuid_table :intake_drafts do |table|
      table.string :user_profile_id, limit: 36, null: false
      table.string :kind, limit: 40, null: false
      table.string :source, limit: 500
      table.string :object_type, limit: 80
      table.json :extracted_data, null: false, default: {}
      table.json :metadata, null: false, default: {}
      table.text :preview
      table.string :status, limit: 20, null: false, default: "Draft"
      table.string :applied_record_type, limit: 80
      table.string :applied_record_id, limit: 36
      table.datetime :applied_at
      actor_columns(table)
    end
    add_foreign_key :intake_drafts, :user_profiles
    actor_foreign_keys :intake_drafts
    add_index :intake_drafts, %i[user_profile_id status created_at]
    add_check_constraint :intake_drafts, "json_valid(extracted_data)", name: "chk_intake_drafts_data_json"
    add_check_constraint :intake_drafts, "json_valid(metadata)", name: "chk_intake_drafts_metadata_json"
    add_check_constraint :intake_drafts,
      "status IN ('Draft','Applied','Rejected')", name: "chk_intake_drafts_status"
  end

  def create_duplicate_links
    uuid_table :duplicate_links do |table|
      table.string :object_type, limit: 80, null: false
      table.string :primary_record_id, limit: 36, null: false
      table.string :duplicate_record_id, limit: 36, null: false
      table.decimal :confidence, precision: 5, scale: 2, null: false
      table.json :reasons, null: false, default: []
      table.json :primary_snapshot, null: false, default: {}
      table.string :status, limit: 20, null: false, default: "Potential"
      table.string :merged_by, limit: 36
      table.datetime :merged_at
      actor_columns(table)
    end
    add_index :duplicate_links, %i[object_type primary_record_id duplicate_record_id], unique: true,
      name: "idx_duplicate_links_pair"
    add_index :duplicate_links, %i[object_type primary_record_id status], name: "idx_duplicate_links_primary"
    add_foreign_key :duplicate_links, :user_profiles, column: :merged_by
    actor_foreign_keys :duplicate_links
    add_check_constraint :duplicate_links, "primary_record_id <> duplicate_record_id", name: "chk_duplicate_links_distinct"
    add_check_constraint :duplicate_links, "confidence BETWEEN 0 AND 100", name: "chk_duplicate_links_confidence"
    add_check_constraint :duplicate_links, "json_valid(reasons)", name: "chk_duplicate_links_reasons_json"
    add_check_constraint :duplicate_links, "json_valid(primary_snapshot)", name: "chk_duplicate_links_snapshot_json"
    add_check_constraint :duplicate_links,
      "status IN ('Potential','Merged','FalsePositive','Reverted')", name: "chk_duplicate_links_status"
  end

  def create_configuration_proposals
    uuid_table :configuration_proposals do |table|
      table.string :kind, limit: 30, null: false
      table.text :prompt, null: false
      table.json :proposed_changes, null: false, default: {}
      table.text :preview, null: false
      table.string :status, limit: 20, null: false, default: "Draft"
      table.integer :version, null: false, default: 1
      table.string :approved_by, limit: 36
      table.datetime :applied_at
      table.datetime :rolled_back_at
      actor_columns(table)
    end
    add_foreign_key :configuration_proposals, :user_profiles, column: :approved_by
    actor_foreign_keys :configuration_proposals
    add_index :configuration_proposals, %i[status created_at]
    add_check_constraint :configuration_proposals, "json_valid(proposed_changes)", name: "chk_configuration_proposals_json"
    add_check_constraint :configuration_proposals,
      "kind IN ('Configuration','Feature')", name: "chk_configuration_proposals_kind"
    add_check_constraint :configuration_proposals,
      "status IN ('Draft','Approved','Rejected','RolledBack')", name: "chk_configuration_proposals_status"

    uuid_table :runtime_configurations do |table|
      table.string :key, limit: 160, null: false
      table.json :payload, null: false, default: {}
      table.integer :version, null: false, default: 1
      actor_columns(table)
    end
    add_index :runtime_configurations, :key, unique: true
    add_check_constraint :runtime_configurations, "json_valid(payload)", name: "chk_runtime_configurations_json"
    actor_foreign_keys :runtime_configurations

    uuid_table :configuration_versions do |table|
      table.string :configuration_proposal_id, limit: 36, null: false
      table.string :runtime_configuration_id, limit: 36, null: false
      table.json :previous_payload, null: false, default: {}
      table.json :applied_payload, null: false, default: {}
      table.integer :version, null: false
      table.string :applied_by, limit: 36, null: false
      table.datetime :reverted_at
    end
    add_foreign_key :configuration_versions, :configuration_proposals
    add_foreign_key :configuration_versions, :runtime_configurations
    add_foreign_key :configuration_versions, :user_profiles, column: :applied_by
    add_index :configuration_versions, %i[runtime_configuration_id version], unique: true,
      name: "idx_configuration_versions_runtime_version"
    add_check_constraint :configuration_versions, "json_valid(previous_payload)", name: "chk_configuration_versions_previous_json"
    add_check_constraint :configuration_versions, "json_valid(applied_payload)", name: "chk_configuration_versions_applied_json"
  end

  def create_external_message_receipts
    uuid_table :external_message_receipts do |table|
      table.string :provider, limit: 40, null: false
      table.string :external_id, limit: 255, null: false
      table.string :payload_digest, limit: 64, null: false
      table.string :activity_id, limit: 36
      table.string :user_profile_id, limit: 36, null: false
      table.datetime :processed_at, null: false
    end
    add_foreign_key :external_message_receipts, :activities
    add_foreign_key :external_message_receipts, :user_profiles
    add_index :external_message_receipts, %i[provider external_id], unique: true
  end

  def strengthen_provider_configuration
    add_index :ai_provider_configs, :is_active, unique: true, where: "is_active = 1",
      name: "idx_ai_provider_configs_single_active"
    add_index :data_source_configs, :object_type, unique: true,
      name: "idx_data_source_configs_object_unique" unless index_exists?(:data_source_configs, :object_type, unique: true)
  end
end
