# frozen_string_literal: true

class HardenIdentityConstraints < ActiveRecord::Migration[8.1]
  UUID_COLUMNS = {
    sessions: %i[id auth_user_id user_profile_id],
    email_access_rules: %i[id created_by updated_by],
    api_tokens: %i[id user_profile_id created_by updated_by],
    idempotency_records: %i[id user_profile_id]
  }.freeze

  def change
    UUID_COLUMNS.each do |table, columns|
      columns.each do |column|
        nullable = connection.columns(table).find { |candidate| candidate.name == column.to_s }.null
        expression = nullable ? "(length(#{column}) = 36) OR #{column} IS NULL" : "length(#{column}) = 36"
        add_check_constraint table, expression, name: "chk_#{table}_#{column}_uuid"
      end
    end

    add_check_constraint :email_access_rules, "rule_type IN ('Email', 'Domain')",
      name: "chk_email_access_rules_type"
    add_check_constraint :email_access_rules, "value = lower(trim(value))",
      name: "chk_email_access_rules_value_normalized"
    add_check_constraint :api_tokens, "json_valid(scopes)", name: "chk_api_tokens_scopes_json"
    add_check_constraint :idempotency_records, "(json_valid(response)) OR response IS NULL",
      name: "chk_idempotency_records_response_json"
  end
end
