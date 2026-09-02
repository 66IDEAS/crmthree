# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_01_191000) do
  create_table "accounts", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "account_number", limit: 10, null: false
    t.decimal "annual_revenue", precision: 15, scale: 2
    t.string "city", limit: 40
    t.string "company_size", limit: 9
    t.string "country", limit: 3
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "currency", limit: 5
    t.text "description"
    t.string "email", limit: 241
    t.string "fax", limit: 30
    t.string "house_number", limit: 10
    t.string "industry", limit: 10
    t.string "industry_description", limit: 100
    t.string "name1", limit: 40, null: false
    t.string "name2", limit: 40
    t.string "owner_id", limit: 36, null: false
    t.string "parent_account_id", limit: 36
    t.string "phone", limit: 30
    t.string "postal_code", limit: 10
    t.string "region", limit: 3
    t.string "status", limit: 8, default: "Active", null: false
    t.string "street", limit: 60
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.string "website", limit: 132
    t.index ["account_number"], name: "idx_accounts_account_number", unique: true
    t.index ["created_by"], name: "idx_accounts_created_by"
    t.index ["owner_id"], name: "idx_accounts_owner_id"
    t.index ["parent_account_id"], name: "idx_accounts_parent_account_id"
    t.index ["updated_by"], name: "idx_accounts_updated_by"
    t.check_constraint "(company_size IN ('1-10', '11-50', '51-200', '201-500', '501-1000', '1001-5000', '5000+')) OR company_size IS NULL", name: "chk_accounts_company_size_enum"
    t.check_constraint "(length(parent_account_id) = 36) OR parent_account_id IS NULL", name: "chk_accounts_parent_account_id_uuid"
    t.check_constraint "length(account_number) <= 10", name: "chk_accounts_account_number_length"
    t.check_constraint "length(city) <= 40", name: "chk_accounts_city_length"
    t.check_constraint "length(country) <= 3", name: "chk_accounts_country_length"
    t.check_constraint "length(created_by) = 36", name: "chk_accounts_created_by_uuid"
    t.check_constraint "length(currency) <= 5", name: "chk_accounts_currency_length"
    t.check_constraint "length(email) <= 241", name: "chk_accounts_email_length"
    t.check_constraint "length(fax) <= 30", name: "chk_accounts_fax_length"
    t.check_constraint "length(house_number) <= 10", name: "chk_accounts_house_number_length"
    t.check_constraint "length(id) = 36", name: "chk_accounts_id_uuid"
    t.check_constraint "length(industry) <= 10", name: "chk_accounts_industry_length"
    t.check_constraint "length(industry_description) <= 100", name: "chk_accounts_industry_description_length"
    t.check_constraint "length(name1) <= 40", name: "chk_accounts_name1_length"
    t.check_constraint "length(name2) <= 40", name: "chk_accounts_name2_length"
    t.check_constraint "length(owner_id) = 36", name: "chk_accounts_owner_id_uuid"
    t.check_constraint "length(phone) <= 30", name: "chk_accounts_phone_length"
    t.check_constraint "length(postal_code) <= 10", name: "chk_accounts_postal_code_length"
    t.check_constraint "length(region) <= 3", name: "chk_accounts_region_length"
    t.check_constraint "length(street) <= 60", name: "chk_accounts_street_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_accounts_updated_by_uuid"
    t.check_constraint "length(website) <= 132", name: "chk_accounts_website_length"
    t.check_constraint "status IN ('Active', 'Inactive')", name: "chk_accounts_status_enum"
  end

  create_table "activities", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "account_id", limit: 36
    t.string "activity_number", limit: 10, null: false
    t.datetime "completed_at"
    t.string "contact_id", limit: 36
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.text "description"
    t.date "due_date"
    t.integer "duration_minutes"
    t.datetime "end_date"
    t.boolean "is_auto_logged", default: false, null: false
    t.string "lead_id", limit: 36
    t.string "opportunity_id", limit: 36
    t.string "owner_id", limit: 36, null: false
    t.string "priority", limit: 6, default: "Medium"
    t.datetime "start_date"
    t.string "status", limit: 11, default: "Planned", null: false
    t.string "subject", limit: 255, null: false
    t.string "ticket_id", limit: 36
    t.string "type", limit: 7, null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["account_id"], name: "idx_activities_account_id"
    t.index ["activity_number"], name: "idx_activities_activity_number", unique: true
    t.index ["contact_id"], name: "idx_activities_contact_id"
    t.index ["created_by"], name: "idx_activities_created_by"
    t.index ["lead_id"], name: "idx_activities_lead_id"
    t.index ["opportunity_id"], name: "idx_activities_opportunity_id"
    t.index ["owner_id"], name: "idx_activities_owner_id"
    t.index ["ticket_id"], name: "idx_activities_ticket_id"
    t.index ["updated_by"], name: "idx_activities_updated_by"
    t.check_constraint "(length(account_id) = 36) OR account_id IS NULL", name: "chk_activities_account_id_uuid"
    t.check_constraint "(length(contact_id) = 36) OR contact_id IS NULL", name: "chk_activities_contact_id_uuid"
    t.check_constraint "(length(lead_id) = 36) OR lead_id IS NULL", name: "chk_activities_lead_id_uuid"
    t.check_constraint "(length(opportunity_id) = 36) OR opportunity_id IS NULL", name: "chk_activities_opportunity_id_uuid"
    t.check_constraint "(length(ticket_id) = 36) OR ticket_id IS NULL", name: "chk_activities_ticket_id_uuid"
    t.check_constraint "(priority IN ('Low', 'Medium', 'High')) OR priority IS NULL", name: "chk_activities_priority_enum"
    t.check_constraint "length(activity_number) <= 10", name: "chk_activities_activity_number_length"
    t.check_constraint "length(created_by) = 36", name: "chk_activities_created_by_uuid"
    t.check_constraint "length(id) = 36", name: "chk_activities_id_uuid"
    t.check_constraint "length(owner_id) = 36", name: "chk_activities_owner_id_uuid"
    t.check_constraint "length(subject) <= 255", name: "chk_activities_subject_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_activities_updated_by_uuid"
    t.check_constraint "status IN ('Planned', 'In Progress', 'Completed', 'Cancelled')", name: "chk_activities_status_enum"
    t.check_constraint "type IN ('Call', 'Email', 'Meeting', 'Task')", name: "chk_activities_type_enum"
  end

  create_table "ai_conversations", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "context_id", limit: 36
    t.string "context_type", limit: 80
    t.datetime "created_at", null: false
    t.datetime "last_used_at", null: false
    t.json "messages", default: [], null: false
    t.string "title", limit: 160, default: "CRM Assistant", null: false
    t.datetime "updated_at", null: false
    t.string "user_profile_id", limit: 36, null: false
    t.index ["user_profile_id", "last_used_at"], name: "index_ai_conversations_on_user_profile_id_and_last_used_at"
    t.check_constraint "json_valid(messages)", name: "chk_ai_conversations_messages_json"
    t.check_constraint "length(id) = 36", name: "chk_ai_conversations_id_uuid"
  end

  create_table "ai_provider_configs", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "api_key", limit: 500, null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "endpoint_url", limit: 500
    t.boolean "is_active", default: false, null: false
    t.string "model", limit: 100, null: false
    t.string "provider", limit: 9, null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["created_by"], name: "idx_ai_provider_configs_created_by"
    t.index ["is_active"], name: "idx_ai_provider_configs_single_active", unique: true, where: "is_active = 1"
    t.index ["updated_by"], name: "idx_ai_provider_configs_updated_by"
    t.check_constraint "length(api_key) <= 500", name: "chk_ai_provider_configs_api_key_length"
    t.check_constraint "length(created_by) = 36", name: "chk_ai_provider_configs_created_by_uuid"
    t.check_constraint "length(endpoint_url) <= 500", name: "chk_ai_provider_configs_endpoint_url_length"
    t.check_constraint "length(id) = 36", name: "chk_ai_provider_configs_id_uuid"
    t.check_constraint "length(model) <= 100", name: "chk_ai_provider_configs_model_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_ai_provider_configs_updated_by_uuid"
    t.check_constraint "provider IN ('OpenAI', 'Google', 'Anthropic', 'Moonshot')", name: "chk_ai_provider_configs_provider_enum"
  end

  create_table "api_tokens", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.datetime "expires_at"
    t.datetime "last_used_at"
    t.string "name", limit: 100, null: false
    t.datetime "revoked_at"
    t.json "scopes", default: [], null: false
    t.string "token_digest", limit: 64, null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.string "user_profile_id", limit: 36, null: false
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
    t.index ["user_profile_id"], name: "index_api_tokens_on_user_profile_id"
    t.check_constraint "json_valid(scopes)", name: "chk_api_tokens_scopes_json"
    t.check_constraint "length(created_by) = 36", name: "chk_api_tokens_created_by_uuid"
    t.check_constraint "length(id) = 36", name: "chk_api_tokens_id_uuid"
    t.check_constraint "length(updated_by) = 36", name: "chk_api_tokens_updated_by_uuid"
    t.check_constraint "length(user_profile_id) = 36", name: "chk_api_tokens_user_profile_id_uuid"
  end

  create_table "assets", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "account_id", limit: 36, null: false
    t.string "asset_number", limit: 18, null: false
    t.string "contact_id", limit: 36
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "functional_location", limit: 30
    t.date "install_date"
    t.string "manufacturer", limit: 30
    t.string "model_number", limit: 20
    t.string "name", limit: 40, null: false
    t.string "owner_id", limit: 36, null: false
    t.string "product_id", limit: 36, null: false
    t.string "serial_number", limit: 18
    t.string "status", limit: 9, default: "Active", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.date "warranty_end_date"
    t.index ["account_id"], name: "idx_assets_account_id"
    t.index ["asset_number"], name: "idx_assets_asset_number", unique: true
    t.index ["contact_id"], name: "idx_assets_contact_id"
    t.index ["created_by"], name: "idx_assets_created_by"
    t.index ["owner_id"], name: "idx_assets_owner_id"
    t.index ["product_id"], name: "idx_assets_product_id"
    t.index ["updated_by"], name: "idx_assets_updated_by"
    t.check_constraint "(length(contact_id) = 36) OR contact_id IS NULL", name: "chk_assets_contact_id_uuid"
    t.check_constraint "length(account_id) = 36", name: "chk_assets_account_id_uuid"
    t.check_constraint "length(asset_number) <= 18", name: "chk_assets_asset_number_length"
    t.check_constraint "length(created_by) = 36", name: "chk_assets_created_by_uuid"
    t.check_constraint "length(functional_location) <= 30", name: "chk_assets_functional_location_length"
    t.check_constraint "length(id) = 36", name: "chk_assets_id_uuid"
    t.check_constraint "length(manufacturer) <= 30", name: "chk_assets_manufacturer_length"
    t.check_constraint "length(model_number) <= 20", name: "chk_assets_model_number_length"
    t.check_constraint "length(name) <= 40", name: "chk_assets_name_length"
    t.check_constraint "length(owner_id) = 36", name: "chk_assets_owner_id_uuid"
    t.check_constraint "length(product_id) = 36", name: "chk_assets_product_id_uuid"
    t.check_constraint "length(serial_number) <= 18", name: "chk_assets_serial_number_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_assets_updated_by_uuid"
    t.check_constraint "status IN ('Active', 'Inactive', 'Retired', 'In Repair')", name: "chk_assets_status_enum"
    t.check_constraint "warranty_end_date IS NULL OR install_date IS NULL OR warranty_end_date >= install_date", name: "chk_assets_warranty_after_install"
  end

  create_table "audit_logs", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "action", limit: 6, null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "field_name", limit: 100
    t.text "new_value"
    t.string "object_id", limit: 36, null: false
    t.string "object_name", limit: 255
    t.string "object_type", limit: 50, null: false
    t.text "old_value"
    t.string "summary", limit: 500
    t.datetime "timestamp", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.string "user_id", limit: 36, null: false
    t.index ["created_by"], name: "idx_audit_logs_created_by"
    t.index ["object_type", "object_id"], name: "idx_audit_logs_object_type_object_id"
    t.index ["updated_by"], name: "idx_audit_logs_updated_by"
    t.index ["user_id"], name: "idx_audit_logs_user_id"
    t.check_constraint "action IN ('Create', 'Update', 'Delete')", name: "chk_audit_logs_action_enum"
    t.check_constraint "length(created_by) = 36", name: "chk_audit_logs_created_by_uuid"
    t.check_constraint "length(field_name) <= 100", name: "chk_audit_logs_field_name_length"
    t.check_constraint "length(id) = 36", name: "chk_audit_logs_id_uuid"
    t.check_constraint "length(object_id) = 36", name: "chk_audit_logs_object_id_uuid"
    t.check_constraint "length(object_name) <= 255", name: "chk_audit_logs_object_name_length"
    t.check_constraint "length(object_type) <= 50", name: "chk_audit_logs_object_type_length"
    t.check_constraint "length(summary) <= 500", name: "chk_audit_logs_summary_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_audit_logs_updated_by_uuid"
    t.check_constraint "length(user_id) = 36", name: "chk_audit_logs_user_id_uuid"
  end

  create_table "auth_users", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", limit: 241, null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_until"
    t.string "password_digest", null: false
    t.string "password_reset_digest"
    t.datetime "password_reset_sent_at"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_auth_users_on_email", unique: true
    t.check_constraint "email = lower(trim(email))", name: "chk_auth_users_email_normalized"
    t.check_constraint "length(id) = 36", name: "chk_auth_users_id_uuid"
  end

  create_table "badges", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "category", limit: 13, null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.json "criteria", null: false
    t.string "description", limit: 255, null: false
    t.string "icon_url", limit: 500
    t.boolean "is_custom", default: false, null: false
    t.string "name", limit: 100, null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["created_by"], name: "idx_badges_created_by"
    t.index ["name"], name: "idx_badges_name", unique: true
    t.index ["updated_by"], name: "idx_badges_updated_by"
    t.check_constraint "category IN ('Sales', 'Service', 'Data Quality', 'Collaboration', 'Milestone', 'Challenge', 'Special')", name: "chk_badges_category_enum"
    t.check_constraint "json_valid(criteria)", name: "chk_badges_criteria_json"
    t.check_constraint "length(created_by) = 36", name: "chk_badges_created_by_uuid"
    t.check_constraint "length(description) <= 255", name: "chk_badges_description_length"
    t.check_constraint "length(icon_url) <= 500", name: "chk_badges_icon_url_length"
    t.check_constraint "length(id) = 36", name: "chk_badges_id_uuid"
    t.check_constraint "length(name) <= 100", name: "chk_badges_name_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_badges_updated_by_uuid"
  end

  create_table "celebration_events", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "consumed_at"
    t.datetime "created_at", null: false
    t.string "dedupe_key", limit: 180, null: false
    t.string "kind", limit: 40, null: false
    t.string "message", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.string "user_id", limit: 36, null: false
    t.index ["dedupe_key"], name: "index_celebration_events_on_dedupe_key", unique: true
    t.index ["user_id", "consumed_at"], name: "index_celebration_events_on_user_id_and_consumed_at"
  end

  create_table "challenges", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.decimal "current_value", precision: 10, scale: 2, default: "0.0", null: false
    t.text "description", null: false
    t.integer "month", null: false
    t.string "reward_badge_id", limit: 36
    t.integer "reward_xp", default: 0, null: false
    t.string "status", limit: 9, default: "Active", null: false
    t.string "target_metric", limit: 100, null: false
    t.decimal "target_value", precision: 10, scale: 2, null: false
    t.string "title", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.string "user_id", limit: 36, null: false
    t.integer "year", null: false
    t.index ["created_by"], name: "idx_challenges_created_by"
    t.index ["reward_badge_id"], name: "idx_challenges_reward_badge_id"
    t.index ["updated_by"], name: "idx_challenges_updated_by"
    t.index ["user_id", "month", "year"], name: "idx_challenges_user_id_month_year", unique: true
    t.index ["user_id"], name: "idx_challenges_user_id"
    t.check_constraint "(length(reward_badge_id) = 36) OR reward_badge_id IS NULL", name: "chk_challenges_reward_badge_id_uuid"
    t.check_constraint "length(created_by) = 36", name: "chk_challenges_created_by_uuid"
    t.check_constraint "length(id) = 36", name: "chk_challenges_id_uuid"
    t.check_constraint "length(target_metric) <= 100", name: "chk_challenges_target_metric_length"
    t.check_constraint "length(title) <= 255", name: "chk_challenges_title_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_challenges_updated_by_uuid"
    t.check_constraint "length(user_id) = 36", name: "chk_challenges_user_id_uuid"
    t.check_constraint "status IN ('Active', 'Completed', 'Failed', 'Cancelled')", name: "chk_challenges_status_enum"
  end

  create_table "comments", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "author_id", limit: 36, null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "parent_id", limit: 36, null: false
    t.string "parent_type", limit: 16, null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["author_id"], name: "idx_comments_author_id"
    t.index ["created_by"], name: "idx_comments_created_by"
    t.index ["parent_type", "parent_id"], name: "idx_comments_parent_type_parent_id"
    t.index ["updated_by"], name: "idx_comments_updated_by"
    t.check_constraint "length(author_id) = 36", name: "chk_comments_author_id_uuid"
    t.check_constraint "length(created_by) = 36", name: "chk_comments_created_by_uuid"
    t.check_constraint "length(id) = 36", name: "chk_comments_id_uuid"
    t.check_constraint "length(parent_id) = 36", name: "chk_comments_parent_id_uuid"
    t.check_constraint "length(updated_by) = 36", name: "chk_comments_updated_by_uuid"
    t.check_constraint "parent_type IN ('Account', 'Contact', 'Lead', 'Opportunity', 'Quotation', 'SalesOrder', 'Invoice', 'Ticket', 'KnowledgeArticle', 'Activity', 'DealRoom')", name: "chk_comments_parent_type_enum"
  end

  create_table "configuration_proposals", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "applied_at"
    t.string "approved_by", limit: 36
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "kind", limit: 30, null: false
    t.text "preview", null: false
    t.text "prompt", null: false
    t.json "proposed_changes", default: {}, null: false
    t.datetime "rolled_back_at"
    t.string "status", limit: 20, default: "Draft", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.integer "version", default: 1, null: false
    t.index ["status", "created_at"], name: "index_configuration_proposals_on_status_and_created_at"
    t.check_constraint "json_valid(proposed_changes)", name: "chk_configuration_proposals_json"
    t.check_constraint "kind IN ('Configuration','Feature')", name: "chk_configuration_proposals_kind"
    t.check_constraint "length(id) = 36", name: "chk_configuration_proposals_id_uuid"
    t.check_constraint "status IN ('Draft','Approved','Rejected','RolledBack')", name: "chk_configuration_proposals_status"
  end

  create_table "configuration_versions", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "applied_by", limit: 36, null: false
    t.json "applied_payload", default: {}, null: false
    t.string "configuration_proposal_id", limit: 36, null: false
    t.datetime "created_at", null: false
    t.json "previous_payload", default: {}, null: false
    t.datetime "reverted_at"
    t.string "runtime_configuration_id", limit: 36, null: false
    t.datetime "updated_at", null: false
    t.integer "version", null: false
    t.index ["runtime_configuration_id", "version"], name: "idx_configuration_versions_runtime_version", unique: true
    t.check_constraint "json_valid(applied_payload)", name: "chk_configuration_versions_applied_json"
    t.check_constraint "json_valid(previous_payload)", name: "chk_configuration_versions_previous_json"
    t.check_constraint "length(id) = 36", name: "chk_configuration_versions_id_uuid"
  end

  create_table "contact_accounts", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "account_id", limit: 36, null: false
    t.string "contact_id", limit: 36, null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.boolean "is_primary", default: false, null: false
    t.string "role", limit: 50
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["account_id"], name: "idx_contact_accounts_account_id"
    t.index ["contact_id", "account_id"], name: "idx_contact_accounts_contact_id_account_id", unique: true
    t.index ["contact_id"], name: "idx_contact_accounts_contact_id"
    t.index ["created_by"], name: "idx_contact_accounts_created_by"
    t.index ["updated_by"], name: "idx_contact_accounts_updated_by"
    t.check_constraint "length(account_id) = 36", name: "chk_contact_accounts_account_id_uuid"
    t.check_constraint "length(contact_id) = 36", name: "chk_contact_accounts_contact_id_uuid"
    t.check_constraint "length(created_by) = 36", name: "chk_contact_accounts_created_by_uuid"
    t.check_constraint "length(id) = 36", name: "chk_contact_accounts_id_uuid"
    t.check_constraint "length(role) <= 50", name: "chk_contact_accounts_role_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_contact_accounts_updated_by_uuid"
  end

  create_table "contacts", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "account_id", limit: 36
    t.string "city", limit: 40
    t.string "contact_number", limit: 10, null: false
    t.string "country", limit: 3
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "department", limit: 40
    t.text "description"
    t.string "email", limit: 241
    t.string "first_name", limit: 40, null: false
    t.string "house_number", limit: 10
    t.string "last_name", limit: 40, null: false
    t.string "mobile", limit: 30
    t.string "owner_id", limit: 36, null: false
    t.string "phone", limit: 30
    t.string "position", limit: 40
    t.string "postal_code", limit: 10
    t.string "status", limit: 8, default: "Active", null: false
    t.string "street", limit: 60
    t.string "title", limit: 30
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["account_id"], name: "idx_contacts_account_id"
    t.index ["contact_number"], name: "idx_contacts_contact_number", unique: true
    t.index ["created_by"], name: "idx_contacts_created_by"
    t.index ["owner_id"], name: "idx_contacts_owner_id"
    t.index ["updated_by"], name: "idx_contacts_updated_by"
    t.check_constraint "(length(account_id) = 36) OR account_id IS NULL", name: "chk_contacts_account_id_uuid"
    t.check_constraint "length(city) <= 40", name: "chk_contacts_city_length"
    t.check_constraint "length(contact_number) <= 10", name: "chk_contacts_contact_number_length"
    t.check_constraint "length(country) <= 3", name: "chk_contacts_country_length"
    t.check_constraint "length(created_by) = 36", name: "chk_contacts_created_by_uuid"
    t.check_constraint "length(department) <= 40", name: "chk_contacts_department_length"
    t.check_constraint "length(email) <= 241", name: "chk_contacts_email_length"
    t.check_constraint "length(first_name) <= 40", name: "chk_contacts_first_name_length"
    t.check_constraint "length(house_number) <= 10", name: "chk_contacts_house_number_length"
    t.check_constraint "length(id) = 36", name: "chk_contacts_id_uuid"
    t.check_constraint "length(last_name) <= 40", name: "chk_contacts_last_name_length"
    t.check_constraint "length(mobile) <= 30", name: "chk_contacts_mobile_length"
    t.check_constraint "length(owner_id) = 36", name: "chk_contacts_owner_id_uuid"
    t.check_constraint "length(phone) <= 30", name: "chk_contacts_phone_length"
    t.check_constraint "length(position) <= 40", name: "chk_contacts_position_length"
    t.check_constraint "length(postal_code) <= 10", name: "chk_contacts_postal_code_length"
    t.check_constraint "length(street) <= 60", name: "chk_contacts_street_length"
    t.check_constraint "length(title) <= 30", name: "chk_contacts_title_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_contacts_updated_by_uuid"
    t.check_constraint "status IN ('Active', 'Inactive')", name: "chk_contacts_status_enum"
  end

  create_table "dashboard_configs", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.boolean "is_default", default: true, null: false
    t.string "name", limit: 100, default: "My Dashboard", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.string "user_id", limit: 36, null: false
    t.json "widgets", null: false
    t.index ["created_by"], name: "idx_dashboard_configs_created_by"
    t.index ["updated_by"], name: "idx_dashboard_configs_updated_by"
    t.index ["user_id", "is_default"], name: "idx_dashboard_configs_one_default", unique: true, where: "is_default = 1"
    t.index ["user_id", "name"], name: "idx_dashboard_configs_user_id_name", unique: true
    t.index ["user_id"], name: "idx_dashboard_configs_user_id"
    t.check_constraint "json_valid(widgets)", name: "chk_dashboard_configs_widgets_json"
    t.check_constraint "length(created_by) = 36", name: "chk_dashboard_configs_created_by_uuid"
    t.check_constraint "length(id) = 36", name: "chk_dashboard_configs_id_uuid"
    t.check_constraint "length(name) <= 100", name: "chk_dashboard_configs_name_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_dashboard_configs_updated_by_uuid"
    t.check_constraint "length(user_id) = 36", name: "chk_dashboard_configs_user_id_uuid"
  end

  create_table "data_source_configs", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.json "auth_config"
    t.string "auth_type", limit: 9
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "endpoint_url", limit: 500
    t.json "field_mapping"
    t.string "object_type", limit: 50, null: false
    t.string "source_type", limit: 8, default: "Local", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["created_by"], name: "idx_data_source_configs_created_by"
    t.index ["object_type"], name: "idx_data_source_configs_object_type", unique: true
    t.index ["updated_by"], name: "idx_data_source_configs_updated_by"
    t.check_constraint "(auth_type IN ('None', 'BasicAuth', 'OAuth2', 'APIKey')) OR auth_type IS NULL", name: "chk_data_source_configs_auth_type_enum"
    t.check_constraint "(json_valid(auth_config)) OR auth_config IS NULL", name: "chk_data_source_configs_auth_config_json"
    t.check_constraint "(json_valid(field_mapping)) OR field_mapping IS NULL", name: "chk_data_source_configs_field_mapping_json"
    t.check_constraint "length(created_by) = 36", name: "chk_data_source_configs_created_by_uuid"
    t.check_constraint "length(endpoint_url) <= 500", name: "chk_data_source_configs_endpoint_url_length"
    t.check_constraint "length(id) = 36", name: "chk_data_source_configs_id_uuid"
    t.check_constraint "length(object_type) <= 50", name: "chk_data_source_configs_object_type_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_data_source_configs_updated_by_uuid"
    t.check_constraint "source_type IN ('Local', 'External')", name: "chk_data_source_configs_source_type_enum"
  end

  create_table "deal_rooms", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "deal_room_number", limit: 10, null: false
    t.text "description"
    t.string "name", limit: 120, null: false
    t.string "opportunity_id", limit: 36, null: false
    t.string "owner_id", limit: 36, null: false
    t.string "status", limit: 6, default: "Active", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["created_by"], name: "idx_deal_rooms_created_by"
    t.index ["deal_room_number"], name: "idx_deal_rooms_deal_room_number", unique: true
    t.index ["opportunity_id"], name: "idx_deal_rooms_opportunity_id", unique: true
    t.index ["owner_id"], name: "idx_deal_rooms_owner_id"
    t.index ["updated_by"], name: "idx_deal_rooms_updated_by"
    t.check_constraint "length(created_by) = 36", name: "chk_deal_rooms_created_by_uuid"
    t.check_constraint "length(deal_room_number) <= 10", name: "chk_deal_rooms_deal_room_number_length"
    t.check_constraint "length(id) = 36", name: "chk_deal_rooms_id_uuid"
    t.check_constraint "length(name) <= 120", name: "chk_deal_rooms_name_length"
    t.check_constraint "length(opportunity_id) = 36", name: "chk_deal_rooms_opportunity_id_uuid"
    t.check_constraint "length(owner_id) = 36", name: "chk_deal_rooms_owner_id_uuid"
    t.check_constraint "length(updated_by) = 36", name: "chk_deal_rooms_updated_by_uuid"
    t.check_constraint "status IN ('Active', 'Closed')", name: "chk_deal_rooms_status_enum"
  end

  create_table "documents", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "file_path", limit: 500, null: false
    t.integer "file_size"
    t.string "file_type", limit: 50
    t.string "name", limit: 255, null: false
    t.string "parent_id", limit: 36, null: false
    t.string "parent_type", limit: 16, null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.string "uploaded_by", limit: 36, null: false
    t.index ["created_by"], name: "idx_documents_created_by"
    t.index ["parent_type", "parent_id"], name: "idx_documents_parent_type_parent_id"
    t.index ["updated_by"], name: "idx_documents_updated_by"
    t.index ["uploaded_by"], name: "idx_documents_uploaded_by"
    t.check_constraint "length(created_by) = 36", name: "chk_documents_created_by_uuid"
    t.check_constraint "length(file_path) <= 500", name: "chk_documents_file_path_length"
    t.check_constraint "length(file_type) <= 50", name: "chk_documents_file_type_length"
    t.check_constraint "length(id) = 36", name: "chk_documents_id_uuid"
    t.check_constraint "length(name) <= 255", name: "chk_documents_name_length"
    t.check_constraint "length(parent_id) = 36", name: "chk_documents_parent_id_uuid"
    t.check_constraint "length(updated_by) = 36", name: "chk_documents_updated_by_uuid"
    t.check_constraint "length(uploaded_by) = 36", name: "chk_documents_uploaded_by_uuid"
    t.check_constraint "parent_type IN ('Account', 'Contact', 'Opportunity', 'Quotation', 'SalesOrder', 'Invoice', 'Ticket', 'KnowledgeArticle', 'DealRoom')", name: "chk_documents_parent_type_enum"
  end

  create_table "domain_event_receipts", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "actor_id", limit: 36, null: false
    t.datetime "created_at", null: false
    t.string "event_id", limit: 36, null: false
    t.string "event_name", limit: 100, null: false
    t.datetime "processed_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_domain_event_receipts_on_event_id", unique: true
  end

  create_table "duplicate_links", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.decimal "confidence", precision: 5, scale: 2, null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "duplicate_record_id", limit: 36, null: false
    t.datetime "merged_at"
    t.string "merged_by", limit: 36
    t.string "object_type", limit: 80, null: false
    t.string "primary_record_id", limit: 36, null: false
    t.json "primary_snapshot", default: {}, null: false
    t.json "reasons", default: [], null: false
    t.string "status", limit: 20, default: "Potential", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["object_type", "primary_record_id", "duplicate_record_id"], name: "idx_duplicate_links_pair", unique: true
    t.index ["object_type", "primary_record_id", "status"], name: "idx_duplicate_links_primary"
    t.check_constraint "confidence BETWEEN 0 AND 100", name: "chk_duplicate_links_confidence"
    t.check_constraint "json_valid(primary_snapshot)", name: "chk_duplicate_links_snapshot_json"
    t.check_constraint "json_valid(reasons)", name: "chk_duplicate_links_reasons_json"
    t.check_constraint "length(id) = 36", name: "chk_duplicate_links_id_uuid"
    t.check_constraint "primary_record_id <> duplicate_record_id", name: "chk_duplicate_links_distinct"
    t.check_constraint "status IN ('Potential','Merged','FalsePositive','Reverted')", name: "chk_duplicate_links_status"
  end

  create_table "email_access_rules", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "rule_type", limit: 10, null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.string "value", limit: 241, null: false
    t.index ["rule_type", "value"], name: "index_email_access_rules_on_rule_type_and_value", unique: true
    t.check_constraint "length(created_by) = 36", name: "chk_email_access_rules_created_by_uuid"
    t.check_constraint "length(id) = 36", name: "chk_email_access_rules_id_uuid"
    t.check_constraint "length(updated_by) = 36", name: "chk_email_access_rules_updated_by_uuid"
    t.check_constraint "rule_type IN ('Email', 'Domain')", name: "chk_email_access_rules_type"
    t.check_constraint "value = lower(trim(value))", name: "chk_email_access_rules_value_normalized"
  end

  create_table "external_message_receipts", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "activity_id", limit: 36
    t.datetime "created_at", null: false
    t.string "external_id", limit: 255, null: false
    t.string "payload_digest", limit: 64, null: false
    t.datetime "processed_at", null: false
    t.string "provider", limit: 40, null: false
    t.datetime "updated_at", null: false
    t.string "user_profile_id", limit: 36, null: false
    t.index ["provider", "external_id"], name: "index_external_message_receipts_on_provider_and_external_id", unique: true
    t.check_constraint "length(id) = 36", name: "chk_external_message_receipts_id_uuid"
  end

  create_table "idempotency_records", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "error_code", limit: 100
    t.string "key_digest", limit: 64, null: false
    t.string "operation", limit: 100, null: false
    t.json "response"
    t.string "state", limit: 10, default: "Started", null: false
    t.datetime "updated_at", null: false
    t.string "user_profile_id", limit: 36, null: false
    t.index ["user_profile_id", "operation", "key_digest"], name: "idx_idempotency_actor_operation_key", unique: true
    t.check_constraint "(json_valid(response)) OR response IS NULL", name: "chk_idempotency_records_response_json"
    t.check_constraint "length(id) = 36", name: "chk_idempotency_records_id_uuid"
    t.check_constraint "length(user_profile_id) = 36", name: "chk_idempotency_records_user_profile_id_uuid"
    t.check_constraint "state IN ('Started', 'Completed', 'Failed')", name: "chk_idempotency_records_state"
  end

  create_table "import_runs", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "created_count", default: 0, null: false
    t.json "error_details", default: [], null: false
    t.string "filename", limit: 255, null: false
    t.json "headers", default: [], null: false
    t.string "idempotency_key", limit: 100, null: false
    t.json "mapping", default: {}, null: false
    t.string "object_type", limit: 80, null: false
    t.json "preview_rows", default: [], null: false
    t.integer "processed_rows", default: 0, null: false
    t.integer "skipped_count", default: 0, null: false
    t.text "source_csv", null: false
    t.datetime "started_at"
    t.string "status", limit: 12, default: "Preview", null: false
    t.integer "total_rows", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "user_profile_id", limit: 36, null: false
    t.index ["user_profile_id", "created_at"], name: "index_import_runs_on_user_profile_id_and_created_at"
    t.index ["user_profile_id", "idempotency_key"], name: "index_import_runs_on_user_profile_id_and_idempotency_key", unique: true
    t.check_constraint "length(id) = 36", name: "chk_import_runs_id_uuid"
    t.check_constraint "status IN ('Preview', 'Queued', 'Running', 'Completed', 'Failed')", name: "chk_import_runs_status"
    t.check_constraint "total_rows >= 0 AND processed_rows >= 0 AND created_count >= 0 AND skipped_count >= 0", name: "chk_import_runs_nonnegative_counts"
  end

  create_table "intake_drafts", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "applied_at"
    t.string "applied_record_id", limit: 36
    t.string "applied_record_type", limit: 80
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.json "extracted_data", default: {}, null: false
    t.string "kind", limit: 40, null: false
    t.json "metadata", default: {}, null: false
    t.string "object_type", limit: 80
    t.text "preview"
    t.string "source", limit: 500
    t.string "status", limit: 20, default: "Draft", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.string "user_profile_id", limit: 36, null: false
    t.index ["user_profile_id", "status", "created_at"], name: "idx_on_user_profile_id_status_created_at_546e36a2e6"
    t.check_constraint "json_valid(extracted_data)", name: "chk_intake_drafts_data_json"
    t.check_constraint "json_valid(metadata)", name: "chk_intake_drafts_metadata_json"
    t.check_constraint "length(id) = 36", name: "chk_intake_drafts_id_uuid"
    t.check_constraint "status IN ('Draft','Applied','Rejected')", name: "chk_intake_drafts_status"
  end

  create_table "integration_outbox_entries", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "data_source_config_id", limit: 36, null: false
    t.string "dedupe_key", limit: 160, null: false
    t.text "last_error"
    t.string "object_type", limit: 80, null: false
    t.string "operation", limit: 20, null: false
    t.json "payload", default: {}, null: false
    t.datetime "processed_at"
    t.string "record_id", limit: 100, null: false
    t.string "status", limit: 20, default: "Pending", null: false
    t.datetime "updated_at", null: false
    t.index ["dedupe_key"], name: "index_integration_outbox_entries_on_dedupe_key", unique: true
    t.index ["status", "created_at"], name: "index_integration_outbox_entries_on_status_and_created_at"
    t.check_constraint "json_valid(payload)", name: "chk_integration_outbox_payload_json"
    t.check_constraint "length(id) = 36", name: "chk_integration_outbox_entries_id_uuid"
    t.check_constraint "status IN ('Pending','Processing','Completed','Failed')", name: "chk_integration_outbox_status"
  end

  create_table "invoices", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "account_id", limit: 36, null: false
    t.string "contact_id", limit: 36
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "currency", limit: 5, default: "USD", null: false
    t.date "due_date", null: false
    t.date "invoice_date", null: false
    t.string "invoice_number", limit: 10, null: false
    t.text "notes"
    t.string "owner_id", limit: 36, null: false
    t.decimal "paid_amount", precision: 15, scale: 2, default: "0.0"
    t.string "sales_order_id", limit: 36
    t.string "status", limit: 14, default: "Draft", null: false
    t.decimal "total_amount", precision: 15, scale: 2
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["account_id"], name: "idx_invoices_account_id"
    t.index ["contact_id"], name: "idx_invoices_contact_id"
    t.index ["created_by"], name: "idx_invoices_created_by"
    t.index ["invoice_number"], name: "idx_invoices_invoice_number", unique: true
    t.index ["owner_id"], name: "idx_invoices_owner_id"
    t.index ["sales_order_id"], name: "idx_invoices_sales_order_id"
    t.index ["updated_by"], name: "idx_invoices_updated_by"
    t.check_constraint "(length(contact_id) = 36) OR contact_id IS NULL", name: "chk_invoices_contact_id_uuid"
    t.check_constraint "(length(sales_order_id) = 36) OR sales_order_id IS NULL", name: "chk_invoices_sales_order_id_uuid"
    t.check_constraint "length(account_id) = 36", name: "chk_invoices_account_id_uuid"
    t.check_constraint "length(created_by) = 36", name: "chk_invoices_created_by_uuid"
    t.check_constraint "length(currency) <= 5", name: "chk_invoices_currency_length"
    t.check_constraint "length(id) = 36", name: "chk_invoices_id_uuid"
    t.check_constraint "length(invoice_number) <= 10", name: "chk_invoices_invoice_number_length"
    t.check_constraint "length(owner_id) = 36", name: "chk_invoices_owner_id_uuid"
    t.check_constraint "length(updated_by) = 36", name: "chk_invoices_updated_by_uuid"
    t.check_constraint "paid_amount IS NULL OR paid_amount >= 0", name: "chk_invoices_paid_nonnegative"
    t.check_constraint "paid_amount IS NULL OR total_amount IS NULL OR paid_amount <= total_amount", name: "chk_invoices_paid_not_above_total"
    t.check_constraint "status IN ('Draft', 'Sent', 'Paid', 'Partially Paid', 'Overdue', 'Cancelled')", name: "chk_invoices_status_enum"
  end

  create_table "knowledge_articles", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "article_number", limit: 10, null: false
    t.string "author_id", limit: 36, null: false
    t.string "category", limit: 100
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.integer "helpful_count", default: 0, null: false
    t.datetime "published_at"
    t.string "source", limit: 15, default: "Manual", null: false
    t.string "status", limit: 9, default: "Draft", null: false
    t.string "title", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.integer "views_count", default: 0, null: false
    t.index ["article_number"], name: "idx_knowledge_articles_article_number", unique: true
    t.index ["author_id"], name: "idx_knowledge_articles_author_id"
    t.index ["created_by"], name: "idx_knowledge_articles_created_by"
    t.index ["updated_by"], name: "idx_knowledge_articles_updated_by"
    t.check_constraint "helpful_count >= 0", name: "chk_knowledge_articles_helpful_nonnegative"
    t.check_constraint "length(article_number) <= 10", name: "chk_knowledge_articles_article_number_length"
    t.check_constraint "length(author_id) = 36", name: "chk_knowledge_articles_author_id_uuid"
    t.check_constraint "length(category) <= 100", name: "chk_knowledge_articles_category_length"
    t.check_constraint "length(created_by) = 36", name: "chk_knowledge_articles_created_by_uuid"
    t.check_constraint "length(id) = 36", name: "chk_knowledge_articles_id_uuid"
    t.check_constraint "length(title) <= 255", name: "chk_knowledge_articles_title_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_knowledge_articles_updated_by_uuid"
    t.check_constraint "source IN ('Manual', 'AI Generated', 'Case Conversion')", name: "chk_knowledge_articles_source_enum"
    t.check_constraint "status IN ('Draft', 'In Review', 'Published', 'Archived')", name: "chk_knowledge_articles_status_enum"
    t.check_constraint "views_count >= 0", name: "chk_knowledge_articles_views_nonnegative"
  end

  create_table "leads", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "account_id", limit: 36
    t.string "company", limit: 40
    t.string "contact_id", limit: 36
    t.string "converted_account_id", limit: 36
    t.datetime "converted_at"
    t.string "converted_contact_id", limit: 36
    t.string "converted_opportunity_id", limit: 36
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.text "description"
    t.string "email", limit: 241
    t.string "first_name", limit: 40, null: false
    t.string "last_name", limit: 40, null: false
    t.string "lead_number", limit: 10, null: false
    t.string "mobile", limit: 30
    t.string "owner_id", limit: 36, null: false
    t.string "phone", limit: 30
    t.string "position", limit: 40
    t.integer "score", default: 0
    t.string "source", limit: 14
    t.string "status", limit: 11, default: "New", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.string "website", limit: 132
    t.index ["account_id"], name: "idx_leads_account_id"
    t.index ["contact_id"], name: "idx_leads_contact_id"
    t.index ["converted_account_id"], name: "idx_leads_converted_account_id"
    t.index ["converted_contact_id"], name: "idx_leads_converted_contact_id"
    t.index ["converted_opportunity_id"], name: "idx_leads_converted_opportunity_id"
    t.index ["created_by"], name: "idx_leads_created_by"
    t.index ["lead_number"], name: "idx_leads_lead_number", unique: true
    t.index ["owner_id"], name: "idx_leads_owner_id"
    t.index ["updated_by"], name: "idx_leads_updated_by"
    t.check_constraint "(length(account_id) = 36) OR account_id IS NULL", name: "chk_leads_account_id_uuid"
    t.check_constraint "(length(contact_id) = 36) OR contact_id IS NULL", name: "chk_leads_contact_id_uuid"
    t.check_constraint "(length(converted_account_id) = 36) OR converted_account_id IS NULL", name: "chk_leads_converted_account_id_uuid"
    t.check_constraint "(length(converted_contact_id) = 36) OR converted_contact_id IS NULL", name: "chk_leads_converted_contact_id_uuid"
    t.check_constraint "(length(converted_opportunity_id) = 36) OR converted_opportunity_id IS NULL", name: "chk_leads_converted_opportunity_id_uuid"
    t.check_constraint "(source IN ('Web', 'Referral', 'Trade Show', 'Cold Call', 'Email Campaign', 'Social Media', 'Partner', 'Other')) OR source IS NULL", name: "chk_leads_source_enum"
    t.check_constraint "length(company) <= 40", name: "chk_leads_company_length"
    t.check_constraint "length(created_by) = 36", name: "chk_leads_created_by_uuid"
    t.check_constraint "length(email) <= 241", name: "chk_leads_email_length"
    t.check_constraint "length(first_name) <= 40", name: "chk_leads_first_name_length"
    t.check_constraint "length(id) = 36", name: "chk_leads_id_uuid"
    t.check_constraint "length(last_name) <= 40", name: "chk_leads_last_name_length"
    t.check_constraint "length(lead_number) <= 10", name: "chk_leads_lead_number_length"
    t.check_constraint "length(mobile) <= 30", name: "chk_leads_mobile_length"
    t.check_constraint "length(owner_id) = 36", name: "chk_leads_owner_id_uuid"
    t.check_constraint "length(phone) <= 30", name: "chk_leads_phone_length"
    t.check_constraint "length(position) <= 40", name: "chk_leads_position_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_leads_updated_by_uuid"
    t.check_constraint "length(website) <= 132", name: "chk_leads_website_length"
    t.check_constraint "score IS NULL OR score BETWEEN 0 AND 100", name: "chk_leads_score_range"
    t.check_constraint "status IN ('New', 'Contacted', 'Qualified', 'Unqualified', 'Converted')", name: "chk_leads_status_enum"
  end

  create_table "level_definitions", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "icon_url", limit: 500
    t.integer "level", null: false
    t.string "name", limit: 50, null: false
    t.json "unlocks"
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.integer "xp_threshold", null: false
    t.index ["created_by"], name: "idx_level_definitions_created_by"
    t.index ["level"], name: "idx_level_definitions_level", unique: true
    t.index ["updated_by"], name: "idx_level_definitions_updated_by"
    t.check_constraint "(json_valid(unlocks)) OR unlocks IS NULL", name: "chk_level_definitions_unlocks_json"
    t.check_constraint "length(created_by) = 36", name: "chk_level_definitions_created_by_uuid"
    t.check_constraint "length(icon_url) <= 500", name: "chk_level_definitions_icon_url_length"
    t.check_constraint "length(id) = 36", name: "chk_level_definitions_id_uuid"
    t.check_constraint "length(name) <= 50", name: "chk_level_definitions_name_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_level_definitions_updated_by_uuid"
  end

  create_table "line_items", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "alternative_to", limit: 6
    t.string "comment", limit: 40
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.decimal "discount_percent", precision: 5, scale: 2, default: "0.0"
    t.string "item_number", limit: 6, null: false
    t.string "parent_id", limit: 36, null: false
    t.string "parent_type", limit: 11, null: false
    t.string "product_id", limit: 36, null: false
    t.decimal "quantity", precision: 13, scale: 3, default: "1.0", null: false
    t.decimal "total_price", precision: 15, scale: 2
    t.string "unit_of_measure", limit: 3
    t.decimal "unit_price", precision: 11, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["created_by"], name: "idx_line_items_created_by"
    t.index ["parent_type", "parent_id", "item_number"], name: "idx_line_items_parent_type_parent_id_item_number", unique: true
    t.index ["parent_type", "parent_id"], name: "idx_line_items_parent_type_parent_id"
    t.index ["product_id"], name: "idx_line_items_product_id"
    t.index ["updated_by"], name: "idx_line_items_updated_by"
    t.check_constraint "discount_percent IS NULL OR discount_percent BETWEEN 0 AND 100", name: "chk_line_items_discount_range"
    t.check_constraint "length(alternative_to) <= 6", name: "chk_line_items_alternative_to_length"
    t.check_constraint "length(comment) <= 40", name: "chk_line_items_comment_length"
    t.check_constraint "length(created_by) = 36", name: "chk_line_items_created_by_uuid"
    t.check_constraint "length(id) = 36", name: "chk_line_items_id_uuid"
    t.check_constraint "length(item_number) <= 6", name: "chk_line_items_item_number_length"
    t.check_constraint "length(parent_id) = 36", name: "chk_line_items_parent_id_uuid"
    t.check_constraint "length(product_id) = 36", name: "chk_line_items_product_id_uuid"
    t.check_constraint "length(unit_of_measure) <= 3", name: "chk_line_items_unit_of_measure_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_line_items_updated_by_uuid"
    t.check_constraint "parent_type IN ('Opportunity', 'Quotation', 'SalesOrder', 'Invoice')", name: "chk_line_items_parent_type_enum"
    t.check_constraint "quantity > 0", name: "chk_line_items_quantity_positive"
    t.check_constraint "total_price IS NULL OR total_price >= 0", name: "chk_line_items_total_nonnegative"
    t.check_constraint "unit_price >= 0", name: "chk_line_items_unit_price_nonnegative"
  end

  create_table "list_sort_settings", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "direction", limit: 4, default: "Asc", null: false
    t.string "object_type", limit: 80, null: false
    t.string "sort_by", limit: 10, default: "Number", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["object_type"], name: "index_list_sort_settings_on_object_type", unique: true
    t.check_constraint "direction IN ('Asc', 'Desc')", name: "chk_list_sort_settings_direction"
    t.check_constraint "length(id) = 36", name: "chk_list_sort_settings_id_uuid"
    t.check_constraint "sort_by IN ('Number', 'Name')", name: "chk_list_sort_settings_sort_by"
  end

  create_table "notifications", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.boolean "email_sent", default: false, null: false
    t.string "link_id", limit: 36
    t.string "link_type", limit: 50
    t.string "message", limit: 500
    t.boolean "read", default: false, null: false
    t.boolean "send_email", default: false, null: false
    t.string "title", limit: 255, null: false
    t.string "type", limit: 18, null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.string "user_id", limit: 36, null: false
    t.index ["created_by"], name: "idx_notifications_created_by"
    t.index ["updated_by"], name: "idx_notifications_updated_by"
    t.index ["user_id"], name: "idx_notifications_user_id"
    t.check_constraint "(length(link_id) = 36) OR link_id IS NULL", name: "chk_notifications_link_id_uuid"
    t.check_constraint "length(created_by) = 36", name: "chk_notifications_created_by_uuid"
    t.check_constraint "length(id) = 36", name: "chk_notifications_id_uuid"
    t.check_constraint "length(link_type) <= 50", name: "chk_notifications_link_type_length"
    t.check_constraint "length(message) <= 500", name: "chk_notifications_message_length"
    t.check_constraint "length(title) <= 255", name: "chk_notifications_title_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_notifications_updated_by_uuid"
    t.check_constraint "length(user_id) = 36", name: "chk_notifications_user_id_uuid"
    t.check_constraint "type IN ('TicketAssigned', 'SLABreach', 'DealStageChange', 'MentionedInComment', 'LeadAssigned', 'ChallengeAssigned', 'BadgeEarned', 'LevelUp', 'PersonalBest', 'System')", name: "chk_notifications_type_enum"
  end

  create_table "number_counters", primary_key: "object_type", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "next_value", default: 1, null: false
    t.datetime "updated_at", null: false
    t.check_constraint "next_value > 0", name: "number_counters_positive"
  end

  create_table "opportunities", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "account_id", limit: 36, null: false
    t.date "actual_close_date"
    t.decimal "amount", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "currency", limit: 5, default: "USD", null: false
    t.text "description"
    t.date "expected_close_date"
    t.string "lead_id", limit: 36
    t.string "loss_reason", limit: 255
    t.string "name", limit: 120, null: false
    t.string "opportunity_number", limit: 10, null: false
    t.string "owner_id", limit: 36, null: false
    t.integer "probability"
    t.string "result", limit: 4, default: "Open", null: false
    t.string "stage_id", limit: 36, null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["account_id"], name: "idx_opportunities_account_id"
    t.index ["created_by"], name: "idx_opportunities_created_by"
    t.index ["lead_id"], name: "idx_opportunities_lead_id"
    t.index ["opportunity_number"], name: "idx_opportunities_opportunity_number", unique: true
    t.index ["owner_id"], name: "idx_opportunities_owner_id"
    t.index ["stage_id"], name: "idx_opportunities_stage_id"
    t.index ["updated_by"], name: "idx_opportunities_updated_by"
    t.check_constraint "(length(lead_id) = 36) OR lead_id IS NULL", name: "chk_opportunities_lead_id_uuid"
    t.check_constraint "length(account_id) = 36", name: "chk_opportunities_account_id_uuid"
    t.check_constraint "length(created_by) = 36", name: "chk_opportunities_created_by_uuid"
    t.check_constraint "length(currency) <= 5", name: "chk_opportunities_currency_length"
    t.check_constraint "length(id) = 36", name: "chk_opportunities_id_uuid"
    t.check_constraint "length(loss_reason) <= 255", name: "chk_opportunities_loss_reason_length"
    t.check_constraint "length(name) <= 120", name: "chk_opportunities_name_length"
    t.check_constraint "length(opportunity_number) <= 10", name: "chk_opportunities_opportunity_number_length"
    t.check_constraint "length(owner_id) = 36", name: "chk_opportunities_owner_id_uuid"
    t.check_constraint "length(stage_id) = 36", name: "chk_opportunities_stage_id_uuid"
    t.check_constraint "length(updated_by) = 36", name: "chk_opportunities_updated_by_uuid"
    t.check_constraint "probability IS NULL OR probability BETWEEN 0 AND 100", name: "chk_opportunities_probability_range"
    t.check_constraint "result IN ('Open', 'Won', 'Lost')", name: "chk_opportunities_result_enum"
  end

  create_table "opportunity_contacts", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "contact_id", limit: 36, null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "opportunity_id", limit: 36, null: false
    t.string "role", limit: 50
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["contact_id"], name: "idx_opportunity_contacts_contact_id"
    t.index ["created_by"], name: "idx_opportunity_contacts_created_by"
    t.index ["opportunity_id", "contact_id"], name: "idx_opportunity_contacts_opportunity_id_contact_id", unique: true
    t.index ["opportunity_id"], name: "idx_opportunity_contacts_opportunity_id"
    t.index ["updated_by"], name: "idx_opportunity_contacts_updated_by"
    t.check_constraint "length(contact_id) = 36", name: "chk_opportunity_contacts_contact_id_uuid"
    t.check_constraint "length(created_by) = 36", name: "chk_opportunity_contacts_created_by_uuid"
    t.check_constraint "length(id) = 36", name: "chk_opportunity_contacts_id_uuid"
    t.check_constraint "length(opportunity_id) = 36", name: "chk_opportunity_contacts_opportunity_id_uuid"
    t.check_constraint "length(role) <= 50", name: "chk_opportunity_contacts_role_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_opportunity_contacts_updated_by_uuid"
  end

  create_table "personal_bests", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "achieved_at", null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "metric", limit: 100, null: false
    t.datetime "previous_achieved_at"
    t.decimal "previous_value", precision: 15, scale: 2
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.string "user_id", limit: 36, null: false
    t.decimal "value", precision: 15, scale: 2, null: false
    t.index ["created_by"], name: "idx_personal_bests_created_by"
    t.index ["updated_by"], name: "idx_personal_bests_updated_by"
    t.index ["user_id", "metric"], name: "idx_personal_bests_user_id_metric", unique: true
    t.index ["user_id"], name: "idx_personal_bests_user_id"
    t.check_constraint "length(created_by) = 36", name: "chk_personal_bests_created_by_uuid"
    t.check_constraint "length(id) = 36", name: "chk_personal_bests_id_uuid"
    t.check_constraint "length(metric) <= 100", name: "chk_personal_bests_metric_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_personal_bests_updated_by_uuid"
    t.check_constraint "length(user_id) = 36", name: "chk_personal_bests_user_id_uuid"
  end

  create_table "pipeline_stages", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.integer "default_probability"
    t.string "description", limit: 255
    t.boolean "is_closed", default: false, null: false
    t.boolean "is_won", default: false, null: false
    t.string "name", limit: 50, null: false
    t.integer "sort_order", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["created_by"], name: "idx_pipeline_stages_created_by"
    t.index ["updated_by"], name: "idx_pipeline_stages_updated_by"
    t.check_constraint "(default_probability IS NULL OR default_probability BETWEEN 0 AND 100) AND NOT (is_won = 1 AND is_closed = 0)", name: "chk_pipeline_stages_probability_and_result"
    t.check_constraint "length(created_by) = 36", name: "chk_pipeline_stages_created_by_uuid"
    t.check_constraint "length(description) <= 255", name: "chk_pipeline_stages_description_length"
    t.check_constraint "length(id) = 36", name: "chk_pipeline_stages_id_uuid"
    t.check_constraint "length(name) <= 50", name: "chk_pipeline_stages_name_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_pipeline_stages_updated_by_uuid"
  end

  create_table "pricebook_entries", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "account_id", limit: 36
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "currency", limit: 5
    t.decimal "discount_percent", precision: 5, scale: 2
    t.decimal "price", precision: 15, scale: 2
    t.string "product_id", limit: 36, null: false
    t.decimal "quantity_from", precision: 13, scale: 3
    t.decimal "quantity_to", precision: 13, scale: 3
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.date "valid_from"
    t.date "valid_to"
    t.index ["account_id"], name: "idx_pricebook_entries_account_id"
    t.index ["created_by"], name: "idx_pricebook_entries_created_by"
    t.index ["product_id"], name: "idx_pricebook_entries_product_id"
    t.index ["updated_by"], name: "idx_pricebook_entries_updated_by"
    t.check_constraint "(length(account_id) = 36) OR account_id IS NULL", name: "chk_pricebook_entries_account_id_uuid"
    t.check_constraint "length(created_by) = 36", name: "chk_pricebook_entries_created_by_uuid"
    t.check_constraint "length(currency) <= 5", name: "chk_pricebook_entries_currency_length"
    t.check_constraint "length(id) = 36", name: "chk_pricebook_entries_id_uuid"
    t.check_constraint "length(product_id) = 36", name: "chk_pricebook_entries_product_id_uuid"
    t.check_constraint "length(updated_by) = 36", name: "chk_pricebook_entries_updated_by_uuid"
  end

  create_table "products", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.decimal "base_price", precision: 13, scale: 2
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "currency", limit: 5
    t.text "description"
    t.string "name", limit: 40, null: false
    t.string "product_group", limit: 9
    t.string "product_group_description", limit: 100
    t.string "product_number", limit: 40, null: false
    t.string "product_type", limit: 12, default: "Physical", null: false
    t.string "status", limit: 12, default: "Active", null: false
    t.string "unit_of_measure", limit: 3, default: "EA", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["created_by"], name: "idx_products_created_by"
    t.index ["product_number"], name: "idx_products_product_number", unique: true
    t.index ["updated_by"], name: "idx_products_updated_by"
    t.check_constraint "length(created_by) = 36", name: "chk_products_created_by_uuid"
    t.check_constraint "length(currency) <= 5", name: "chk_products_currency_length"
    t.check_constraint "length(id) = 36", name: "chk_products_id_uuid"
    t.check_constraint "length(name) <= 40", name: "chk_products_name_length"
    t.check_constraint "length(product_group) <= 9", name: "chk_products_product_group_length"
    t.check_constraint "length(product_group_description) <= 100", name: "chk_products_product_group_description_length"
    t.check_constraint "length(product_number) <= 40", name: "chk_products_product_number_length"
    t.check_constraint "length(unit_of_measure) <= 3", name: "chk_products_unit_of_measure_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_products_updated_by_uuid"
    t.check_constraint "product_type IN ('Physical', 'Service', 'Subscription', 'License')", name: "chk_products_product_type_enum"
    t.check_constraint "status IN ('Active', 'Inactive', 'Discontinued')", name: "chk_products_status_enum"
  end

  create_table "quotations", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "account_id", limit: 36, null: false
    t.string "contact_id", limit: 36
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "currency", limit: 5, default: "USD", null: false
    t.text "notes"
    t.string "opportunity_id", limit: 36
    t.string "owner_id", limit: 36, null: false
    t.string "quotation_number", limit: 10, null: false
    t.string "status", limit: 8, default: "Draft", null: false
    t.decimal "total_amount", precision: 15, scale: 2
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.date "valid_from"
    t.date "valid_to"
    t.index ["account_id"], name: "idx_quotations_account_id"
    t.index ["contact_id"], name: "idx_quotations_contact_id"
    t.index ["created_by"], name: "idx_quotations_created_by"
    t.index ["opportunity_id"], name: "idx_quotations_opportunity_id"
    t.index ["owner_id"], name: "idx_quotations_owner_id"
    t.index ["quotation_number"], name: "idx_quotations_quotation_number", unique: true
    t.index ["updated_by"], name: "idx_quotations_updated_by"
    t.check_constraint "(length(contact_id) = 36) OR contact_id IS NULL", name: "chk_quotations_contact_id_uuid"
    t.check_constraint "(length(opportunity_id) = 36) OR opportunity_id IS NULL", name: "chk_quotations_opportunity_id_uuid"
    t.check_constraint "length(account_id) = 36", name: "chk_quotations_account_id_uuid"
    t.check_constraint "length(created_by) = 36", name: "chk_quotations_created_by_uuid"
    t.check_constraint "length(currency) <= 5", name: "chk_quotations_currency_length"
    t.check_constraint "length(id) = 36", name: "chk_quotations_id_uuid"
    t.check_constraint "length(owner_id) = 36", name: "chk_quotations_owner_id_uuid"
    t.check_constraint "length(quotation_number) <= 10", name: "chk_quotations_quotation_number_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_quotations_updated_by_uuid"
    t.check_constraint "status IN ('Draft', 'Sent', 'Accepted', 'Rejected', 'Expired')", name: "chk_quotations_status_enum"
  end

  create_table "record_locks", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "holder_id", limit: 36, null: false
    t.string "object_type", limit: 80, null: false
    t.string "record_id", limit: 36, null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_record_locks_on_expires_at"
    t.index ["object_type", "record_id"], name: "index_record_locks_on_object_type_and_record_id", unique: true
    t.check_constraint "length(id) = 36", name: "chk_record_locks_id_uuid"
  end

  create_table "replication_configs", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "auth_config"
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "delete_flag_field", limit: 100
    t.string "endpoint_url", limit: 500, null: false
    t.json "field_mapping", default: {}, null: false
    t.string "key_field", limit: 100, null: false
    t.datetime "last_run_at"
    t.string "object_type", limit: 80, null: false
    t.json "request_body", default: {}, null: false
    t.string "source_key_field", limit: 100
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["object_type", "endpoint_url"], name: "index_replication_configs_on_object_type_and_endpoint_url", unique: true
    t.check_constraint "json_valid(field_mapping)", name: "chk_replication_configs_mapping_json"
    t.check_constraint "json_valid(request_body)", name: "chk_replication_configs_request_json"
    t.check_constraint "length(id) = 36", name: "chk_replication_configs_id_uuid"
  end

  create_table "replication_runs", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "created_count", default: 0, null: false
    t.integer "error_count", default: 0, null: false
    t.json "error_details", default: [], null: false
    t.string "idempotency_key", limit: 120, null: false
    t.integer "processed_count", default: 0, null: false
    t.string "replication_config_id", limit: 36, null: false
    t.integer "skipped_count", default: 0, null: false
    t.datetime "started_at"
    t.string "status", limit: 20, default: "Queued", null: false
    t.datetime "updated_at", null: false
    t.integer "updated_count", default: 0, null: false
    t.string "user_profile_id", limit: 36, null: false
    t.index ["replication_config_id", "idempotency_key"], name: "idx_replication_runs_idempotency", unique: true
    t.check_constraint "json_valid(error_details)", name: "chk_replication_runs_errors_json"
    t.check_constraint "length(id) = 36", name: "chk_replication_runs_id_uuid"
    t.check_constraint "status IN ('Queued','Running','Completed','Failed')", name: "chk_replication_runs_status"
  end

  create_table "roles", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "description", limit: 255
    t.boolean "is_system_role", default: false, null: false
    t.json "layout_config"
    t.string "name", limit: 50, null: false
    t.json "permissions", null: false
    t.json "ribbon_items", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.json "visible_cards"
    t.index ["created_by"], name: "idx_roles_created_by"
    t.index ["name"], name: "idx_roles_name", unique: true
    t.index ["updated_by"], name: "idx_roles_updated_by"
    t.check_constraint "(json_valid(layout_config)) OR layout_config IS NULL", name: "chk_roles_layout_config_json"
    t.check_constraint "(json_valid(visible_cards)) OR visible_cards IS NULL", name: "chk_roles_visible_cards_json"
    t.check_constraint "json_valid(permissions)", name: "chk_roles_permissions_json"
    t.check_constraint "json_valid(ribbon_items)", name: "chk_roles_ribbon_items_json"
    t.check_constraint "length(created_by) = 36", name: "chk_roles_created_by_uuid"
    t.check_constraint "length(description) <= 255", name: "chk_roles_description_length"
    t.check_constraint "length(id) = 36", name: "chk_roles_id_uuid"
    t.check_constraint "length(name) <= 50", name: "chk_roles_name_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_roles_updated_by_uuid"
  end

  create_table "runtime_configurations", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "key", limit: 160, null: false
    t.json "payload", default: {}, null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.integer "version", default: 1, null: false
    t.index ["key"], name: "index_runtime_configurations_on_key", unique: true
    t.check_constraint "json_valid(payload)", name: "chk_runtime_configurations_json"
    t.check_constraint "length(id) = 36", name: "chk_runtime_configurations_id_uuid"
  end

  create_table "sales_orders", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "account_id", limit: 36, null: false
    t.string "contact_id", limit: 36
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "currency", limit: 5, default: "USD", null: false
    t.text "notes"
    t.string "opportunity_id", limit: 36
    t.date "order_date", null: false
    t.string "order_number", limit: 10, null: false
    t.string "owner_id", limit: 36, null: false
    t.string "quotation_id", limit: 36
    t.string "status", limit: 11, default: "Draft", null: false
    t.decimal "total_amount", precision: 15, scale: 2
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["account_id"], name: "idx_sales_orders_account_id"
    t.index ["contact_id"], name: "idx_sales_orders_contact_id"
    t.index ["created_by"], name: "idx_sales_orders_created_by"
    t.index ["opportunity_id"], name: "idx_sales_orders_opportunity_id"
    t.index ["order_number"], name: "idx_sales_orders_order_number", unique: true
    t.index ["owner_id"], name: "idx_sales_orders_owner_id"
    t.index ["quotation_id"], name: "idx_sales_orders_quotation_id"
    t.index ["updated_by"], name: "idx_sales_orders_updated_by"
    t.check_constraint "(length(contact_id) = 36) OR contact_id IS NULL", name: "chk_sales_orders_contact_id_uuid"
    t.check_constraint "(length(opportunity_id) = 36) OR opportunity_id IS NULL", name: "chk_sales_orders_opportunity_id_uuid"
    t.check_constraint "(length(quotation_id) = 36) OR quotation_id IS NULL", name: "chk_sales_orders_quotation_id_uuid"
    t.check_constraint "length(account_id) = 36", name: "chk_sales_orders_account_id_uuid"
    t.check_constraint "length(created_by) = 36", name: "chk_sales_orders_created_by_uuid"
    t.check_constraint "length(currency) <= 5", name: "chk_sales_orders_currency_length"
    t.check_constraint "length(id) = 36", name: "chk_sales_orders_id_uuid"
    t.check_constraint "length(order_number) <= 10", name: "chk_sales_orders_order_number_length"
    t.check_constraint "length(owner_id) = 36", name: "chk_sales_orders_owner_id_uuid"
    t.check_constraint "length(updated_by) = 36", name: "chk_sales_orders_updated_by_uuid"
    t.check_constraint "status IN ('Draft', 'Confirmed', 'In Progress', 'Shipped', 'Completed', 'Cancelled')", name: "chk_sales_orders_status_enum"
  end

  create_table "service_contracts", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "account_id", limit: 36, null: false
    t.string "contract_number", limit: 10, null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.date "end_date", null: false
    t.text "entitlements"
    t.string "name", limit: 120, null: false
    t.string "owner_id", limit: 36, null: false
    t.string "sla_id", limit: 36
    t.date "start_date", null: false
    t.string "status", limit: 10, default: "Draft", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["account_id"], name: "idx_service_contracts_account_id"
    t.index ["contract_number"], name: "idx_service_contracts_contract_number", unique: true
    t.index ["created_by"], name: "idx_service_contracts_created_by"
    t.index ["owner_id"], name: "idx_service_contracts_owner_id"
    t.index ["sla_id"], name: "idx_service_contracts_sla_id"
    t.index ["updated_by"], name: "idx_service_contracts_updated_by"
    t.check_constraint "(length(sla_id) = 36) OR sla_id IS NULL", name: "chk_service_contracts_sla_id_uuid"
    t.check_constraint "end_date >= start_date", name: "chk_service_contracts_date_order"
    t.check_constraint "length(account_id) = 36", name: "chk_service_contracts_account_id_uuid"
    t.check_constraint "length(contract_number) <= 10", name: "chk_service_contracts_contract_number_length"
    t.check_constraint "length(created_by) = 36", name: "chk_service_contracts_created_by_uuid"
    t.check_constraint "length(id) = 36", name: "chk_service_contracts_id_uuid"
    t.check_constraint "length(name) <= 120", name: "chk_service_contracts_name_length"
    t.check_constraint "length(owner_id) = 36", name: "chk_service_contracts_owner_id_uuid"
    t.check_constraint "length(updated_by) = 36", name: "chk_service_contracts_updated_by_uuid"
    t.check_constraint "status IN ('Draft', 'Active', 'Expired', 'Terminated')", name: "chk_service_contracts_status_enum"
  end

  create_table "sessions", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "auth_user_id", limit: 36, null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "ip_address", limit: 64
    t.datetime "last_seen_at", null: false
    t.datetime "revoked_at"
    t.string "token_digest", limit: 64, null: false
    t.datetime "updated_at", null: false
    t.string "user_agent", limit: 500
    t.string "user_profile_id", limit: 36
    t.index ["auth_user_id"], name: "index_sessions_on_auth_user_id"
    t.index ["token_digest"], name: "index_sessions_on_token_digest", unique: true
    t.index ["user_profile_id"], name: "index_sessions_on_user_profile_id"
    t.check_constraint "(length(user_profile_id) = 36) OR user_profile_id IS NULL", name: "chk_sessions_user_profile_id_uuid"
    t.check_constraint "length(auth_user_id) = 36", name: "chk_sessions_auth_user_id_uuid"
    t.check_constraint "length(id) = 36", name: "chk_sessions_id_uuid"
  end

  create_table "slas", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.json "applies_to_priorities"
    t.boolean "business_hours_only", default: true, null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.text "description"
    t.string "name", limit: 100, null: false
    t.decimal "resolution_time_hours", precision: 5, scale: 1, null: false
    t.decimal "response_time_hours", precision: 5, scale: 1, null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["created_by"], name: "idx_slas_created_by"
    t.index ["name"], name: "index_slas_on_name", unique: true
    t.index ["updated_by"], name: "idx_slas_updated_by"
    t.check_constraint "(json_valid(applies_to_priorities)) OR applies_to_priorities IS NULL", name: "chk_slas_applies_to_priorities_json"
    t.check_constraint "length(created_by) = 36", name: "chk_slas_created_by_uuid"
    t.check_constraint "length(id) = 36", name: "chk_slas_id_uuid"
    t.check_constraint "length(name) <= 100", name: "chk_slas_name_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_slas_updated_by_uuid"
    t.check_constraint "resolution_time_hours > 0", name: "chk_slas_resolution_positive"
    t.check_constraint "response_time_hours <= resolution_time_hours", name: "chk_slas_response_before_resolution"
    t.check_constraint "response_time_hours > 0", name: "chk_slas_response_positive"
  end

  create_table "streaks", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "activity_type", limit: 50, null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.integer "current_count", default: 0, null: false
    t.date "last_activity_date"
    t.integer "longest_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.string "user_id", limit: 36, null: false
    t.index ["created_by"], name: "idx_streaks_created_by"
    t.index ["updated_by"], name: "idx_streaks_updated_by"
    t.index ["user_id", "activity_type"], name: "idx_streaks_user_id_activity_type", unique: true
    t.index ["user_id"], name: "idx_streaks_user_id"
    t.check_constraint "length(activity_type) <= 50", name: "chk_streaks_activity_type_length"
    t.check_constraint "length(created_by) = 36", name: "chk_streaks_created_by_uuid"
    t.check_constraint "length(id) = 36", name: "chk_streaks_id_uuid"
    t.check_constraint "length(updated_by) = 36", name: "chk_streaks_updated_by_uuid"
    t.check_constraint "length(user_id) = 36", name: "chk_streaks_user_id_uuid"
  end

  create_table "teams", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "description", limit: 255
    t.string "manager_id", limit: 36, null: false
    t.string "name", limit: 100, null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["created_by"], name: "idx_teams_created_by"
    t.index ["manager_id"], name: "idx_teams_manager_id"
    t.index ["updated_by"], name: "idx_teams_updated_by"
    t.check_constraint "length(created_by) = 36", name: "chk_teams_created_by_uuid"
    t.check_constraint "length(description) <= 255", name: "chk_teams_description_length"
    t.check_constraint "length(id) = 36", name: "chk_teams_id_uuid"
    t.check_constraint "length(manager_id) = 36", name: "chk_teams_manager_id_uuid"
    t.check_constraint "length(name) <= 100", name: "chk_teams_name_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_teams_updated_by_uuid"
  end

  create_table "ticket_knowledge_articles", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "article_id", limit: 36, null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.datetime "linked_at", null: false
    t.string "linked_by", limit: 36, null: false
    t.string "ticket_id", limit: 36, null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["article_id"], name: "idx_ticket_knowledge_articles_article_id"
    t.index ["created_by"], name: "idx_ticket_knowledge_articles_created_by"
    t.index ["linked_by"], name: "idx_ticket_knowledge_articles_linked_by"
    t.index ["ticket_id", "article_id"], name: "idx_ticket_knowledge_articles_ticket_id_article_id", unique: true
    t.index ["ticket_id"], name: "idx_ticket_knowledge_articles_ticket_id"
    t.index ["updated_by"], name: "idx_ticket_knowledge_articles_updated_by"
    t.check_constraint "length(article_id) = 36", name: "chk_ticket_knowledge_articles_article_id_uuid"
    t.check_constraint "length(created_by) = 36", name: "chk_ticket_knowledge_articles_created_by_uuid"
    t.check_constraint "length(id) = 36", name: "chk_ticket_knowledge_articles_id_uuid"
    t.check_constraint "length(linked_by) = 36", name: "chk_ticket_knowledge_articles_linked_by_uuid"
    t.check_constraint "length(ticket_id) = 36", name: "chk_ticket_knowledge_articles_ticket_id_uuid"
    t.check_constraint "length(updated_by) = 36", name: "chk_ticket_knowledge_articles_updated_by_uuid"
  end

  create_table "ticket_statuses", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "description", limit: 255
    t.boolean "is_closed", default: false, null: false
    t.boolean "is_resolved", default: false, null: false
    t.string "name", limit: 50, null: false
    t.integer "sort_order", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["created_by"], name: "idx_ticket_statuses_created_by"
    t.index ["name"], name: "index_ticket_statuses_on_name", unique: true
    t.index ["sort_order"], name: "index_ticket_statuses_on_sort_order", unique: true
    t.index ["updated_by"], name: "idx_ticket_statuses_updated_by"
    t.check_constraint "NOT is_closed OR is_resolved", name: "chk_ticket_statuses_closed_is_resolved"
    t.check_constraint "length(created_by) = 36", name: "chk_ticket_statuses_created_by_uuid"
    t.check_constraint "length(description) <= 255", name: "chk_ticket_statuses_description_length"
    t.check_constraint "length(id) = 36", name: "chk_ticket_statuses_id_uuid"
    t.check_constraint "length(name) <= 50", name: "chk_ticket_statuses_name_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_ticket_statuses_updated_by_uuid"
    t.check_constraint "sort_order >= 0", name: "chk_ticket_statuses_sort_order_nonnegative"
  end

  create_table "tickets", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "account_id", limit: 36, null: false
    t.string "asset_id", limit: 36
    t.string "assigned_to", limit: 36
    t.string "category", limit: 50
    t.datetime "closed_at"
    t.string "contact_id", limit: 36
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.text "description"
    t.datetime "first_response_at"
    t.string "owner_id", limit: 36, null: false
    t.string "priority", limit: 8, default: "Medium", null: false
    t.text "resolution"
    t.datetime "resolved_at"
    t.string "service_contract_id", limit: 36
    t.string "sla_id", limit: 36
    t.datetime "sla_resolution_deadline"
    t.datetime "sla_response_deadline"
    t.string "status_id", limit: 36, null: false
    t.string "subject", limit: 40, null: false
    t.string "ticket_number", limit: 12, null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.index ["account_id"], name: "idx_tickets_account_id"
    t.index ["asset_id"], name: "idx_tickets_asset_id"
    t.index ["assigned_to"], name: "idx_tickets_assigned_to"
    t.index ["contact_id"], name: "idx_tickets_contact_id"
    t.index ["created_by"], name: "idx_tickets_created_by"
    t.index ["owner_id"], name: "idx_tickets_owner_id"
    t.index ["service_contract_id"], name: "idx_tickets_service_contract_id"
    t.index ["sla_id"], name: "idx_tickets_sla_id"
    t.index ["status_id"], name: "idx_tickets_status_id"
    t.index ["ticket_number"], name: "idx_tickets_ticket_number", unique: true
    t.index ["updated_by"], name: "idx_tickets_updated_by"
    t.check_constraint "(length(asset_id) = 36) OR asset_id IS NULL", name: "chk_tickets_asset_id_uuid"
    t.check_constraint "(length(assigned_to) = 36) OR assigned_to IS NULL", name: "chk_tickets_assigned_to_uuid"
    t.check_constraint "(length(contact_id) = 36) OR contact_id IS NULL", name: "chk_tickets_contact_id_uuid"
    t.check_constraint "(length(service_contract_id) = 36) OR service_contract_id IS NULL", name: "chk_tickets_service_contract_id_uuid"
    t.check_constraint "(length(sla_id) = 36) OR sla_id IS NULL", name: "chk_tickets_sla_id_uuid"
    t.check_constraint "closed_at IS NULL OR resolved_at IS NOT NULL", name: "chk_tickets_closed_requires_resolved"
    t.check_constraint "length(account_id) = 36", name: "chk_tickets_account_id_uuid"
    t.check_constraint "length(category) <= 50", name: "chk_tickets_category_length"
    t.check_constraint "length(created_by) = 36", name: "chk_tickets_created_by_uuid"
    t.check_constraint "length(id) = 36", name: "chk_tickets_id_uuid"
    t.check_constraint "length(owner_id) = 36", name: "chk_tickets_owner_id_uuid"
    t.check_constraint "length(status_id) = 36", name: "chk_tickets_status_id_uuid"
    t.check_constraint "length(subject) <= 40", name: "chk_tickets_subject_length"
    t.check_constraint "length(ticket_number) <= 12", name: "chk_tickets_ticket_number_length"
    t.check_constraint "length(updated_by) = 36", name: "chk_tickets_updated_by_uuid"
    t.check_constraint "priority IN ('Low', 'Medium', 'High', 'Critical')", name: "chk_tickets_priority_enum"
    t.check_constraint "sla_resolution_deadline IS NULL OR sla_response_deadline IS NULL OR sla_resolution_deadline >= sla_response_deadline", name: "chk_tickets_sla_deadline_order"
  end

  create_table "translation_seed_registry", primary_key: "language_code", id: :string, force: :cascade do |t|
    t.json "original_labels", default: {}, null: false
    t.datetime "seeded_at", null: false
    t.string "source_sha256", limit: 64, null: false
  end

  create_table "translations", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "labels", default: {}, null: false
    t.string "language_code", null: false
    t.string "language_name", null: false
    t.datetime "updated_at", null: false
    t.index ["language_code"], name: "index_translations_on_language_code", unique: true
    t.check_constraint "json_valid(labels)", name: "translations_valid_json"
  end

  create_table "user_badges", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "badge_id", limit: 36, null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.datetime "earned_at", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.string "user_id", limit: 36, null: false
    t.index ["badge_id"], name: "idx_user_badges_badge_id"
    t.index ["created_by"], name: "idx_user_badges_created_by"
    t.index ["updated_by"], name: "idx_user_badges_updated_by"
    t.index ["user_id", "badge_id"], name: "idx_user_badges_user_id_badge_id", unique: true
    t.index ["user_id"], name: "idx_user_badges_user_id"
    t.check_constraint "length(badge_id) = 36", name: "chk_user_badges_badge_id_uuid"
    t.check_constraint "length(created_by) = 36", name: "chk_user_badges_created_by_uuid"
    t.check_constraint "length(id) = 36", name: "chk_user_badges_id_uuid"
    t.check_constraint "length(updated_by) = 36", name: "chk_user_badges_updated_by_uuid"
    t.check_constraint "length(user_id) = 36", name: "chk_user_badges_user_id_uuid"
  end

  create_table "user_profiles", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "auth_uid", limit: 128
    t.string "avatar_url", limit: 2048
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.integer "current_streak_days", default: 0, null: false
    t.string "email", limit: 241, null: false
    t.string "first_name", limit: 40, null: false
    t.string "language_preference", limit: 5, default: "en"
    t.string "last_name", limit: 40, null: false
    t.integer "level", default: 1, null: false
    t.string "level_name", limit: 50, default: "Rookie", null: false
    t.integer "longest_streak_days", default: 0, null: false
    t.json "notification_preferences"
    t.string "role_id", limit: 36, null: false
    t.string "team_id", limit: 36
    t.string "theme_preference", limit: 6, default: "System", null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.integer "xp_total", default: 0, null: false
    t.index ["auth_uid"], name: "idx_user_profiles_auth_uid", unique: true
    t.index ["created_by"], name: "idx_user_profiles_created_by"
    t.index ["email"], name: "idx_user_profiles_email", unique: true
    t.index ["role_id"], name: "idx_user_profiles_role_id"
    t.index ["team_id"], name: "idx_user_profiles_team_id"
    t.index ["updated_by"], name: "idx_user_profiles_updated_by"
    t.check_constraint "(json_valid(notification_preferences)) OR notification_preferences IS NULL", name: "chk_user_profiles_notification_preferences_json"
    t.check_constraint "(length(team_id) = 36) OR team_id IS NULL", name: "chk_user_profiles_team_id_uuid"
    t.check_constraint "length(auth_uid) <= 128", name: "chk_user_profiles_auth_uid_length"
    t.check_constraint "length(avatar_url) <= 2048", name: "chk_user_profiles_avatar_url_length"
    t.check_constraint "length(created_by) = 36", name: "chk_user_profiles_created_by_uuid"
    t.check_constraint "length(email) <= 241", name: "chk_user_profiles_email_length"
    t.check_constraint "length(first_name) <= 40", name: "chk_user_profiles_first_name_length"
    t.check_constraint "length(id) = 36", name: "chk_user_profiles_id_uuid"
    t.check_constraint "length(language_preference) <= 5", name: "chk_user_profiles_language_preference_length"
    t.check_constraint "length(last_name) <= 40", name: "chk_user_profiles_last_name_length"
    t.check_constraint "length(level_name) <= 50", name: "chk_user_profiles_level_name_length"
    t.check_constraint "length(role_id) = 36", name: "chk_user_profiles_role_id_uuid"
    t.check_constraint "length(updated_by) = 36", name: "chk_user_profiles_updated_by_uuid"
    t.check_constraint "theme_preference IN ('Light', 'Dark', 'System')", name: "chk_user_profiles_theme_preference_enum"
  end

  create_table "xp_events", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "created_by", limit: 36, null: false
    t.string "description", limit: 255, null: false
    t.string "event_type", limit: 100, null: false
    t.datetime "updated_at", null: false
    t.string "updated_by", limit: 36, null: false
    t.integer "xp_value", null: false
    t.index ["created_by"], name: "idx_xp_events_created_by"
    t.index ["event_type"], name: "idx_xp_events_event_type", unique: true
    t.index ["updated_by"], name: "idx_xp_events_updated_by"
    t.check_constraint "length(created_by) = 36", name: "chk_xp_events_created_by_uuid"
    t.check_constraint "length(description) <= 255", name: "chk_xp_events_description_length"
    t.check_constraint "length(event_type) <= 100", name: "chk_xp_events_event_type_length"
    t.check_constraint "length(id) = 36", name: "chk_xp_events_id_uuid"
    t.check_constraint "length(updated_by) = 36", name: "chk_xp_events_updated_by_uuid"
  end

  add_foreign_key "accounts", "accounts", column: "parent_account_id", deferrable: :deferred
  add_foreign_key "accounts", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "accounts", "user_profiles", column: "owner_id", deferrable: :deferred
  add_foreign_key "accounts", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "activities", "accounts", deferrable: :deferred
  add_foreign_key "activities", "contacts", deferrable: :deferred
  add_foreign_key "activities", "leads", deferrable: :deferred
  add_foreign_key "activities", "opportunities", deferrable: :deferred
  add_foreign_key "activities", "tickets", deferrable: :deferred
  add_foreign_key "activities", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "activities", "user_profiles", column: "owner_id", deferrable: :deferred
  add_foreign_key "activities", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "ai_conversations", "user_profiles"
  add_foreign_key "ai_provider_configs", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "ai_provider_configs", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "api_tokens", "user_profiles"
  add_foreign_key "api_tokens", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "api_tokens", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "assets", "accounts", deferrable: :deferred
  add_foreign_key "assets", "contacts", deferrable: :deferred
  add_foreign_key "assets", "products", deferrable: :deferred
  add_foreign_key "assets", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "assets", "user_profiles", column: "owner_id", deferrable: :deferred
  add_foreign_key "assets", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "audit_logs", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "audit_logs", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "audit_logs", "user_profiles", column: "user_id", deferrable: :deferred
  add_foreign_key "badges", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "badges", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "celebration_events", "user_profiles", column: "user_id"
  add_foreign_key "challenges", "badges", column: "reward_badge_id", deferrable: :deferred
  add_foreign_key "challenges", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "challenges", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "challenges", "user_profiles", column: "user_id", deferrable: :deferred
  add_foreign_key "comments", "user_profiles", column: "author_id", deferrable: :deferred
  add_foreign_key "comments", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "comments", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "configuration_proposals", "user_profiles", column: "approved_by"
  add_foreign_key "configuration_proposals", "user_profiles", column: "created_by"
  add_foreign_key "configuration_proposals", "user_profiles", column: "updated_by"
  add_foreign_key "configuration_versions", "configuration_proposals"
  add_foreign_key "configuration_versions", "runtime_configurations"
  add_foreign_key "configuration_versions", "user_profiles", column: "applied_by"
  add_foreign_key "contact_accounts", "accounts", on_delete: :cascade, deferrable: :deferred
  add_foreign_key "contact_accounts", "contacts", on_delete: :cascade, deferrable: :deferred
  add_foreign_key "contact_accounts", "user_profiles", column: "created_by", on_delete: :cascade, deferrable: :deferred
  add_foreign_key "contact_accounts", "user_profiles", column: "updated_by", on_delete: :cascade, deferrable: :deferred
  add_foreign_key "contacts", "accounts", deferrable: :deferred
  add_foreign_key "contacts", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "contacts", "user_profiles", column: "owner_id", deferrable: :deferred
  add_foreign_key "contacts", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "dashboard_configs", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "dashboard_configs", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "dashboard_configs", "user_profiles", column: "user_id", deferrable: :deferred
  add_foreign_key "data_source_configs", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "data_source_configs", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "deal_rooms", "opportunities", deferrable: :deferred
  add_foreign_key "deal_rooms", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "deal_rooms", "user_profiles", column: "owner_id", deferrable: :deferred
  add_foreign_key "deal_rooms", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "documents", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "documents", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "documents", "user_profiles", column: "uploaded_by", deferrable: :deferred
  add_foreign_key "domain_event_receipts", "user_profiles", column: "actor_id"
  add_foreign_key "duplicate_links", "user_profiles", column: "created_by"
  add_foreign_key "duplicate_links", "user_profiles", column: "merged_by"
  add_foreign_key "duplicate_links", "user_profiles", column: "updated_by"
  add_foreign_key "email_access_rules", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "email_access_rules", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "external_message_receipts", "activities"
  add_foreign_key "external_message_receipts", "user_profiles"
  add_foreign_key "idempotency_records", "user_profiles"
  add_foreign_key "import_runs", "user_profiles"
  add_foreign_key "intake_drafts", "user_profiles"
  add_foreign_key "intake_drafts", "user_profiles", column: "created_by"
  add_foreign_key "intake_drafts", "user_profiles", column: "updated_by"
  add_foreign_key "integration_outbox_entries", "data_source_configs"
  add_foreign_key "invoices", "accounts", deferrable: :deferred
  add_foreign_key "invoices", "contacts", deferrable: :deferred
  add_foreign_key "invoices", "sales_orders", deferrable: :deferred
  add_foreign_key "invoices", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "invoices", "user_profiles", column: "owner_id", deferrable: :deferred
  add_foreign_key "invoices", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "knowledge_articles", "user_profiles", column: "author_id", deferrable: :deferred
  add_foreign_key "knowledge_articles", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "knowledge_articles", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "leads", "accounts", column: "converted_account_id", deferrable: :deferred
  add_foreign_key "leads", "accounts", deferrable: :deferred
  add_foreign_key "leads", "contacts", column: "converted_contact_id", deferrable: :deferred
  add_foreign_key "leads", "contacts", deferrable: :deferred
  add_foreign_key "leads", "opportunities", column: "converted_opportunity_id", deferrable: :deferred
  add_foreign_key "leads", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "leads", "user_profiles", column: "owner_id", deferrable: :deferred
  add_foreign_key "leads", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "level_definitions", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "level_definitions", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "line_items", "products", deferrable: :deferred
  add_foreign_key "line_items", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "line_items", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "list_sort_settings", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "list_sort_settings", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "notifications", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "notifications", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "notifications", "user_profiles", column: "user_id", deferrable: :deferred
  add_foreign_key "opportunities", "accounts", deferrable: :deferred
  add_foreign_key "opportunities", "leads", deferrable: :deferred
  add_foreign_key "opportunities", "pipeline_stages", column: "stage_id", deferrable: :deferred
  add_foreign_key "opportunities", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "opportunities", "user_profiles", column: "owner_id", deferrable: :deferred
  add_foreign_key "opportunities", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "opportunity_contacts", "contacts", on_delete: :cascade, deferrable: :deferred
  add_foreign_key "opportunity_contacts", "opportunities", on_delete: :cascade, deferrable: :deferred
  add_foreign_key "opportunity_contacts", "user_profiles", column: "created_by", on_delete: :cascade, deferrable: :deferred
  add_foreign_key "opportunity_contacts", "user_profiles", column: "updated_by", on_delete: :cascade, deferrable: :deferred
  add_foreign_key "personal_bests", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "personal_bests", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "personal_bests", "user_profiles", column: "user_id", deferrable: :deferred
  add_foreign_key "pipeline_stages", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "pipeline_stages", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "pricebook_entries", "accounts", deferrable: :deferred
  add_foreign_key "pricebook_entries", "products", deferrable: :deferred
  add_foreign_key "pricebook_entries", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "pricebook_entries", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "products", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "products", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "quotations", "accounts", deferrable: :deferred
  add_foreign_key "quotations", "contacts", deferrable: :deferred
  add_foreign_key "quotations", "opportunities", deferrable: :deferred
  add_foreign_key "quotations", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "quotations", "user_profiles", column: "owner_id", deferrable: :deferred
  add_foreign_key "quotations", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "record_locks", "user_profiles", column: "holder_id"
  add_foreign_key "replication_configs", "user_profiles", column: "created_by"
  add_foreign_key "replication_configs", "user_profiles", column: "updated_by"
  add_foreign_key "replication_runs", "replication_configs"
  add_foreign_key "replication_runs", "user_profiles"
  add_foreign_key "roles", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "roles", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "runtime_configurations", "user_profiles", column: "created_by"
  add_foreign_key "runtime_configurations", "user_profiles", column: "updated_by"
  add_foreign_key "sales_orders", "accounts", deferrable: :deferred
  add_foreign_key "sales_orders", "contacts", deferrable: :deferred
  add_foreign_key "sales_orders", "opportunities", deferrable: :deferred
  add_foreign_key "sales_orders", "quotations", deferrable: :deferred
  add_foreign_key "sales_orders", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "sales_orders", "user_profiles", column: "owner_id", deferrable: :deferred
  add_foreign_key "sales_orders", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "service_contracts", "accounts", deferrable: :deferred
  add_foreign_key "service_contracts", "slas", deferrable: :deferred
  add_foreign_key "service_contracts", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "service_contracts", "user_profiles", column: "owner_id", deferrable: :deferred
  add_foreign_key "service_contracts", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "sessions", "auth_users"
  add_foreign_key "sessions", "user_profiles"
  add_foreign_key "slas", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "slas", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "streaks", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "streaks", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "streaks", "user_profiles", column: "user_id", deferrable: :deferred
  add_foreign_key "teams", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "teams", "user_profiles", column: "manager_id", deferrable: :deferred
  add_foreign_key "teams", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "ticket_knowledge_articles", "knowledge_articles", column: "article_id", on_delete: :cascade, deferrable: :deferred
  add_foreign_key "ticket_knowledge_articles", "tickets", on_delete: :cascade, deferrable: :deferred
  add_foreign_key "ticket_knowledge_articles", "user_profiles", column: "created_by", on_delete: :cascade, deferrable: :deferred
  add_foreign_key "ticket_knowledge_articles", "user_profiles", column: "linked_by", on_delete: :cascade, deferrable: :deferred
  add_foreign_key "ticket_knowledge_articles", "user_profiles", column: "updated_by", on_delete: :cascade, deferrable: :deferred
  add_foreign_key "ticket_statuses", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "ticket_statuses", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "tickets", "accounts", deferrable: :deferred
  add_foreign_key "tickets", "assets", deferrable: :deferred
  add_foreign_key "tickets", "contacts", deferrable: :deferred
  add_foreign_key "tickets", "service_contracts", deferrable: :deferred
  add_foreign_key "tickets", "slas", deferrable: :deferred
  add_foreign_key "tickets", "ticket_statuses", column: "status_id", deferrable: :deferred
  add_foreign_key "tickets", "user_profiles", column: "assigned_to", deferrable: :deferred
  add_foreign_key "tickets", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "tickets", "user_profiles", column: "owner_id", deferrable: :deferred
  add_foreign_key "tickets", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "user_badges", "badges", on_delete: :cascade, deferrable: :deferred
  add_foreign_key "user_badges", "user_profiles", column: "created_by", on_delete: :cascade, deferrable: :deferred
  add_foreign_key "user_badges", "user_profiles", column: "updated_by", on_delete: :cascade, deferrable: :deferred
  add_foreign_key "user_badges", "user_profiles", column: "user_id", on_delete: :cascade, deferrable: :deferred
  add_foreign_key "user_profiles", "roles", deferrable: :deferred
  add_foreign_key "user_profiles", "teams", deferrable: :deferred
  add_foreign_key "user_profiles", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "user_profiles", "user_profiles", column: "updated_by", deferrable: :deferred
  add_foreign_key "xp_events", "user_profiles", column: "created_by", deferrable: :deferred
  add_foreign_key "xp_events", "user_profiles", column: "updated_by", deferrable: :deferred
end
