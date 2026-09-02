# frozen_string_literal: true

class CreateIdentityAndServiceInfrastructure < ActiveRecord::Migration[8.1]
  def change
    create_table :auth_users, id: false do |t|
      t.string :id, limit: 36, primary_key: true
      t.string :email, limit: 241, null: false
      t.string :password_digest, null: false
      t.string :password_reset_digest
      t.datetime :password_reset_sent_at
      t.integer :failed_attempts, null: false, default: 0
      t.datetime :locked_until
      t.timestamps
    end
    add_index :auth_users, :email, unique: true
    add_check_constraint :auth_users, "length(id) = 36", name: "chk_auth_users_id_uuid"
    add_check_constraint :auth_users, "email = lower(trim(email))", name: "chk_auth_users_email_normalized"

    create_table :sessions, id: false do |t|
      t.string :id, limit: 36, primary_key: true
      t.string :auth_user_id, limit: 36, null: false
      t.string :user_profile_id, limit: 36
      t.string :token_digest, limit: 64, null: false
      t.string :ip_address, limit: 64
      t.string :user_agent, limit: 500
      t.datetime :last_seen_at, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :sessions, :token_digest, unique: true
    add_index :sessions, :auth_user_id
    add_index :sessions, :user_profile_id
    add_foreign_key :sessions, :auth_users
    add_foreign_key :sessions, :user_profiles

    create_table :email_access_rules, id: false do |t|
      t.string :id, limit: 36, primary_key: true
      t.string :rule_type, limit: 10, null: false
      t.string :value, limit: 241, null: false
      t.boolean :active, null: false, default: true
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.timestamps
    end
    add_index :email_access_rules, %i[rule_type value], unique: true
    add_foreign_key :email_access_rules, :user_profiles, column: :created_by, deferrable: :deferred
    add_foreign_key :email_access_rules, :user_profiles, column: :updated_by, deferrable: :deferred

    create_table :api_tokens, id: false do |t|
      t.string :id, limit: 36, primary_key: true
      t.string :user_profile_id, limit: 36, null: false
      t.string :name, limit: 100, null: false
      t.string :token_digest, limit: 64, null: false
      t.json :scopes, null: false, default: []
      t.datetime :last_used_at
      t.datetime :expires_at
      t.datetime :revoked_at
      t.string :created_by, limit: 36, null: false
      t.string :updated_by, limit: 36, null: false
      t.timestamps
    end
    add_index :api_tokens, :token_digest, unique: true
    add_index :api_tokens, :user_profile_id
    add_foreign_key :api_tokens, :user_profiles
    add_foreign_key :api_tokens, :user_profiles, column: :created_by, deferrable: :deferred
    add_foreign_key :api_tokens, :user_profiles, column: :updated_by, deferrable: :deferred

    create_table :idempotency_records, id: false do |t|
      t.string :id, limit: 36, primary_key: true
      t.string :operation, limit: 100, null: false
      t.string :key_digest, limit: 64, null: false
      t.string :user_profile_id, limit: 36, null: false
      t.string :state, limit: 10, null: false, default: "Started"
      t.json :response
      t.string :error_code, limit: 100
      t.timestamps
    end
    add_index :idempotency_records, %i[user_profile_id operation key_digest], unique: true,
      name: "idx_idempotency_actor_operation_key"
    add_foreign_key :idempotency_records, :user_profiles
    add_check_constraint :idempotency_records, "state IN ('Started', 'Completed', 'Failed')",
      name: "chk_idempotency_records_state"
  end
end
