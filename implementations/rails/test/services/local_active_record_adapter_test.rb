# frozen_string_literal: true

require "test_helper"

class LocalActiveRecordAdapterTest < ActiveSupport::TestCase
  setup do
    seed_crm!
    @owner = create_profile(email: "adapter-owner@example.com")
    @other = create_profile(email: "adapter-other@example.com")
    @adapter = Crm::Data::LocalActiveRecordAdapter.new(object_type: "Account", identity: identity(@owner))
  end

  test "scopes reads and returns not found for an unrelated record" do
    owned = create_account(owner: @owner)
    unrelated = create_account(owner: @other)

    assert_equal [owned.id], @adapter.list.value.pluck(:id)
    assert_equal :not_found, @adapter.find(unrelated.id).code
  end

  test "allows only manifest fields and stamps the current actor" do
    result = @adapter.create(name1: "Adapter account", owner_id: @owner.id,
      created_by: @other.id, updated_by: @other.id, account_number: "MALICIOUS")

    assert result.success?, result.errors.inspect
    assert_equal @owner.id, result.value.created_by
    assert_equal @owner.id, result.value.updated_by
    refute_equal "MALICIOUS", result.value.account_number
    assert_equal 1, AuditLog.where(object_type: "Account", object_id: result.value.id, action: "Create").count
  end

  test "audits changed fields and redacts encrypted values" do
    admin = create_profile(email: "adapter-admin@example.com", role: Role.find_by!(name: "Admin"))
    adapter = Crm::Data::LocalActiveRecordAdapter.new(object_type: "AIProviderConfig", identity: identity(admin))
    created = adapter.create(provider: "OpenAI", model: "local-test", api_key: "first-secret", is_active: true)

    assert created.success?, created.errors.inspect
    updated = adapter.update(created.value.id, api_key: "second-secret")
    log = AuditLog.find_by!(object_type: "AIProviderConfig", object_id: created.value.id, field_name: "api_key")

    assert updated.success?
    assert_equal "[FILTERED]", log.old_value
    assert_equal "[FILTERED]", log.new_value
    refute_includes created.value.serializable_hash.keys, "api_key"
    refute_includes AIProviderConfig.connection.select_value("SELECT api_key FROM ai_provider_configs WHERE id = '#{created.value.id}'"),
      "second-secret"
  end

  test "encrypts structured external credentials and never serializes them" do
    admin = create_profile(email: "source-admin@example.com", role: Role.find_by!(name: "Admin"))
    adapter = Crm::Data::LocalActiveRecordAdapter.new(object_type: "DataSourceConfig", identity: identity(admin))
    created = adapter.create(object_type: "Account", source_type: "Local", auth_type: "APIKey",
      auth_config: {"api_key" => "data-source-secret"}, field_mapping: {}, active: true)

    assert created.success?, created.errors.inspect
    raw = DataSourceConfig.connection.select_value("SELECT auth_config FROM data_source_configs WHERE id = '#{created.value.id}'")
    refute_includes raw, "data-source-secret"
    refute_includes created.value.serializable_hash.keys, "auth_config"
    assert_equal({"api_key" => "data-source-secret"}, created.value.auth_config)
  end

  test "audits reassignment status and deletion in their record transactions" do
    admin = create_profile(email: "audit-admin@example.com", role: Role.find_by!(name: "Admin"))
    record = create_account(owner: @owner, name: "Lifecycle account")
    adapter = Crm::Data::LocalActiveRecordAdapter.new(object_type: "Account", identity: identity(admin))

    updated = adapter.update(record.id, owner_id: @other.id, status: "Inactive")

    assert updated.success?
    assert_equal %w[owner_id status], AuditLog.where(object_type: "Account", object_id: record.id, action: "Update")
      .order(:field_name).pluck(:field_name)

    deleted = adapter.delete(record.id)
    assert deleted.success?
    assert_not Account.exists?(record.id)
    assert AuditLog.exists?(object_type: "Account", object_id: record.id, action: "Delete")
  end

  test "audits opportunity stage transitions" do
    admin = create_profile(email: "stage-admin@example.com", role: Role.find_by!(name: "Admin"))
    account = create_account(owner: @owner, name: "Stage account")
    stages = PipelineStage.order(:sort_order).first(2)
    adapter = Crm::Data::LocalActiveRecordAdapter.new(object_type: "Opportunity", identity: identity(admin))
    created = adapter.create(name: "Stage audit", account_id: account.id, stage_id: stages.first.id,
      currency: "USD", result: "Open", owner_id: @owner.id)

    assert created.success?, created.errors.inspect
    assert adapter.update(created.value.id, stage_id: stages.last.id).success?
    log = AuditLog.find_by!(object_type: "Opportunity", object_id: created.value.id, field_name: "stage_id")
    assert_equal stages.first.id, log.old_value
    assert_equal stages.last.id, log.new_value
  end

  test "publishes a typed event only after persistence" do
    events = []
    Crm::DomainEvents.subscribe { |event| events << event }

    result = @adapter.create(name1: "Event account", owner_id: @owner.id)

    assert result.success?
    assert_equal "account.create", events.last.name
    assert_equal result.value.id, events.last.record_id
  end

  test "transaction helper rolls back a failed compound operation" do
    before = Account.count
    result = Crm::Transaction.run do
      create_account(owner: @owner, name: "Must roll back")
      Crm::Result.failure(:second_step_failed)
    end

    assert_equal :second_step_failed, result.code
    assert_equal before, Account.count
  end

  test "idempotency returns a replay without repeating work" do
    calls = 0
    first = Crm::Idempotency.run(operation: "test.convert", key: "request-1", actor: @owner) do
      calls += 1
      Crm::Result.success({"record_id" => "123"})
    end
    replay = Crm::Idempotency.run(operation: "test.convert", key: "request-1", actor: @owner) do
      calls += 1
      Crm::Result.success
    end

    assert first.success?
    assert replay.success?
    assert_equal :idempotent_replay, replay.code
    assert_equal 1, calls
  end

  test "search export dashboard AI and import interfaces retain the same scope" do
    owned = create_account(owner: @owner, name: "Visible needle")
    create_account(owner: @other, name: "Hidden needle")

    assert_equal [owned.id], @adapter.search("needle").value.pluck(:id)
    assert_equal [owned.id], @adapter.export_scope.value.pluck(:id)
    assert_equal [owned.id], @adapter.dashboard_scope.value.pluck(:id)
    assert_equal [owned.id], @adapter.ai_context_scope.value.pluck(:id)

    before = Account.count
    result = @adapter.import([
      {name1: "Would otherwise save", owner_id: @owner.id},
      {owner_id: @owner.id}
    ], idempotency_key: "failing-import")
    assert result.failure?
    assert_equal before, Account.count
    assert IdempotencyRecord.find_by!(operation: "Account.import").state_failed?
  end
end
