# frozen_string_literal: true

require "test_helper"

class CrossCuttingCapabilitiesTest < ActiveSupport::TestCase
  UploadedCSV = Struct.new(:contents, :original_filename) do
    def read = contents
    def size = contents.bytesize
  end

  setup do
    seed_crm!
    @admin = create_profile(email: "cross-admin@example.com", role: Role.find_by!(name: "Admin"))
    @owner = create_profile(email: "cross-owner@example.com")
    @other = create_profile(email: "cross-other@example.com")
    @account = create_account(owner: @owner, name: "Visible Customer")
  end

  test "dashboard metrics use policy-scoped records and widget choices persist per user" do
    stage = PipelineStage.find_by!(name: "Qualification")
    Current.set(profile: @owner) do
      Opportunity.create!(name: "Visible deal", account: @account, stage:, amount: 12_500,
        currency: "USD", result: "Open", owner: @owner)
    end
    hidden_account = create_account(owner: @other, name: "Hidden Customer")
    Current.set(profile: @other) do
      Opportunity.create!(name: "Hidden deal", account: hidden_account, stage:, amount: 99_000,
        currency: "USD", result: "Open", owner: @other)
    end

    snapshot = Crm::DashboardSnapshot.new(identity: identity(@owner)).call
    config = Crm::DashboardPreferences.for(@owner)
    updated = Crm::DashboardPreferences.update(profile: @owner, selected: %w[open_opportunities activity_trend])

    assert_equal 12_500, snapshot.pipeline_value
    assert_equal 1, snapshot.open_opportunities
    assert_equal({"Qualification" => 1}, snapshot.opportunities_by_stage)
    assert config.persisted?
    assert updated.success?
    assert_equal %w[open_opportunities activity_trend], Crm::DashboardPreferences.visible_keys(config.reload)
  end

  test "global search groups allowlisted results without leaking unrelated records" do
    6.times { |index| create_account(owner: @owner, name: "Northstar #{index}") }
    create_account(owner: @other, name: "Northstar secret")

    groups = Crm::GlobalSearch.new(identity: identity(@owner)).call("northstar")
    account_group = groups.find { |group| group.object_type == "Account" }

    assert_equal 5, account_group.records.length
    assert account_group.records.all? { |record| record.owner_id == @owner.id }
    assert_empty Crm::GlobalSearch.new(identity: identity(@owner)).call("n")
  end

  test "record locks are atomic renewable expiring and holder-restricted" do
    first = Crm::RecordLocks.acquire(object_type: "Account", record_id: @account.id, holder: @owner)
    conflict = Crm::RecordLocks.acquire(object_type: "Account", record_id: @account.id, holder: @other)
    renewed = Crm::RecordLocks.renew(object_type: "Account", record_id: @account.id, holder: @owner)

    assert first.success?
    assert_equal :locked, conflict.code
    assert_match @owner.first_name, conflict.errors.to_sentence
    assert renewed.success?
    first.value.update_column(:expires_at, 1.minute.ago)
    takeover = Crm::RecordLocks.acquire(object_type: "Account", record_id: @account.id, holder: @other)
    assert takeover.success?
    assert_equal @other, takeover.value.holder
    assert Crm::RecordLocks.release(object_type: "Account", record_id: @account.id, holder: @other).success?
    assert_nil Crm::RecordLocks.current(object_type: "Account", record_id: @account.id)
  end

  test "role management protects system roles and persists custom action and ribbon permissions" do
    created = Crm::RoleManagement.create(attributes: {
      name: "Customer Success", description: "Service specialists", active: true,
      ribbon_items: %w[case_rooms knowledge],
      permissions: {"Ticket" => {"create" => true, "read" => true, "read_all" => false, "update" => true, "delete" => false}}
    }, actor: @admin)

    assert created.success?, created.errors.inspect
    assert_equal %w[case_rooms knowledge], created.value.ribbon_items
    assert created.value.permissions.dig("Ticket", "update")
    admin_role = Role.find_by!(name: "Admin")
    refute Crm::RoleManagement.update(role: admin_role, attributes: {active: false, name: "Root"}, actor: @admin).failure?
    assert_equal "Admin", admin_role.reload.name
    assert admin_role.active?
    assert_not admin_role.destroy
    assert_includes admin_role.errors.full_messages, "System roles cannot be deleted"
  end

  test "user management supports pending and local identities and retains owned CRM records on delete" do
    pending = Crm::UserManagement.invite(attributes: {
      email: "pending-colleague@example.com", first_name: "Pending", last_name: "Colleague",
      role_id: Role.find_by!(name: "User").id, password: ""
    }, actor: @admin)
    local = Crm::UserManagement.invite(attributes: {
      email: "local-colleague@example.com", first_name: "Local", last_name: "Colleague",
      role_id: Role.find_by!(name: "User").id, password: "local-password-123"
    }, actor: @admin)

    assert pending.success?
    assert_nil pending.value.auth_uid
    assert local.success?
    assert AuthUser.exists?(id: local.value.auth_uid)
    owned = create_account(owner: pending.value, name: "Retained account")
    deleted = Crm::UserManagement.destroy(profile: pending.value, actor: @admin)
    assert deleted.success?, deleted.errors.inspect
    assert Account.exists?(owned.id)
    assert_equal Crm::Seeds::SYSTEM_PROFILE_ID, owned.reload.owner_id
    assert_equal :self_protection, Crm::UserManagement.set_active(profile: @admin, active: false, actor: @admin).code
  end

  test "CSV export uses names safe values and unpadded numbers" do
    Current.set(profile: @owner) { @account.update!(name1: "=SUM(A1:A2)") }
    definition = Crm::ModelRegistry.fetch("Account")
    names = %w[account_number name1 owner_id]
    fields = definition.fetch("specific_fields").select { |field| field.fetch("name").in?(names) }
    export = Crm::CSVExport.new(object_type: "Account", records: Account.where(id: @account.id), fields:,
      identity: identity(@owner)).each_line.to_a.join

    assert_includes export, "Account number"
    assert_includes export, "'=SUM(A1:A2)"
    assert_includes export, Crm::RecordPresentation.display_name(@owner)
    refute_includes export, @owner.id
    refute_includes export, @account.account_number
    assert_includes export, @account.account_number.to_i.to_s

    @owner.update!(language_preference: "de")
    translated = Crm::CSVExport.new(object_type: "Account", records: Account.where(id: @account.id), fields:,
      identity: identity(@owner)).each_line.first
    assert_includes translated, Translation.find_by!(language_code: "de").labels.fetch("field.Account.account_number")
  end

  test "CSV imports preview auto-map process row errors and remain idempotent on rerun" do
    file = UploadedCSV.new("name1,Status\nImported Alpha,Active\n,Active\n", "accounts.csv")
    preview = Crm::CSVImport.preview(file:, object_type: "Account", actor: @owner)
    assert preview.success?, preview.errors.inspect
    run = preview.value
    assert_equal 2, run.total_rows
    assert run.mapping.key?("name1")
    assert_equal "column", run.mapping.dig("name1", "mode")

    queued = Crm::CSVImport.queue(run:, mapping: run.mapping)
    assert queued.success?, queued.errors.inspect
    ImportRecordsJob.perform_now(run.id)
    run.reload
    assert run.status_completed?
    assert_equal 1, run.created_count
    assert_equal 1, run.skipped_count
    assert_equal 2, run.processed_rows
    assert_equal "", run.source_csv
    before = Account.count
    ImportRecordsJob.perform_now(run.id)
    assert_equal before, Account.count
  end

  test "translation service switches labels and pack upgrades preserve administrator edits" do
    translation = Translation.find_by!(language_code: "de")
    labels = translation.labels.to_h
    labels["nav.accounts"] = "Meine Kunden"
    translation.update!(labels:)
    @owner.update!(language_preference: "de")

    assert_equal "Meine Kunden", Crm::TranslationService.translate("nav.accounts", fallback: "Accounts", profile: @owner)
    assert_equal "Fallback", Crm::TranslationService.translate("missing.label", fallback: "Fallback", profile: @owner)

    registry = TranslationSeedRegistry.find_by!(language_code: "de")
    original = registry.original_labels.to_h
    registry.update!(source_sha256: "old", original_labels: original)
    Crm::Seeds.send(:merge_translation_pack!, translation:, registry:,
      labels: original.merge("nav.accounts" => "Neue Kunden", "rails.new_label" => "Neu"), digest: "new")
    assert_equal "Meine Kunden", translation.reload.labels["nav.accounts"]
    assert_equal "Neu", translation.labels["rails.new_label"]
  end

  test "all bundled translation packs have catalog parity and useful generated English labels" do
    packs = Rails.root.join("config/crm/translations").glob("*.json").sort.map { |path| JSON.parse(path.read) }
    expected_keys = packs.first.fetch("labels").keys.sort

    assert_equal 8, packs.length
    assert packs.all? { |pack| pack.fetch("labels").keys.sort == expected_keys }
    assert packs.all? { |pack| pack.fetch("labels").values.all? { |value| value.is_a?(String) && value.present? } }
    assert_equal expected_keys, Crm::LabelCatalog.all.keys.sort
    assert_equal Crm::ModelRegistry.field("Account", "name1").fetch("description"),
      Crm::LabelCatalog.english_for("field.Account.name1")
    canonical = JSON.parse(Rails.root.join("config/crm/catalog.en.json").read)
    assert_equal expected_keys, canonical.keys.sort
    assert_equal canonical, Crm::LabelCatalog.all.to_h
    assert_equal "Settings", Crm::LabelCatalog.english_for("settings.title")
    assert_equal "Saving...", Crm::LabelCatalog.english_for("ui.saving")
    assert_equal "Sign in with Google", Crm::LabelCatalog.english_for("ui.sign_in_google")
    assert_equal 8, TranslationSeedRegistry.where(language_code: packs.pluck("code")).count
  end

  test "role layout configuration limits list fields details and relationship cards" do
    role = @owner.role
    role.update!(
      layout_config: {"Account" => {"list_columns" => %w[account_number name1], "detail_fields" => %w[name1 status]}},
      visible_cards: {"Account" => ["contacts"]}
    )
    definition = Crm::ModelRegistry.fetch("Account")
    fields = definition.fetch("specific_fields")
    parent = Crm::LinkedRecords::ParentCard.new(field: {"name" => "parent_account_id"}, object_type: "Account",
      record_id: "parent", label: "Parent")
    contact_card = Crm::LinkedRecords::ChildCard.new(relationship: {"name" => "contacts", "target" => "Contact"},
      records: [], total_count: 0, references: {}, junctions: {}, link_options: [])
    ticket_card = Crm::LinkedRecords::ChildCard.new(relationship: {"name" => "tickets", "target" => "Ticket"},
      records: [], total_count: 0, references: {}, junctions: {}, link_options: [])

    assert_equal %w[account_number name1], Crm::RoleLayout.list_columns(profile: @owner, object_type: "Account", fallback: %w[id])
    assert_equal %w[name1 status], Crm::RoleLayout.detail_fields(profile: @owner, object_type: "Account", fallback: fields).pluck("name")
    parents, children = Crm::RoleLayout.filter_cards(profile: @owner, object_type: "Account", parents: [parent],
      children: [contact_card, ticket_card])
    assert_empty parents
    assert_equal [contact_card], children
  end

  test "configured list sorting orders the whole scope and repair safely handles a complete collection" do
    create_account(owner: @owner, name: "Alphabetical")
    create_account(owner: @owner, name: "Zulu")
    updated = Crm::ListSort.update(object_type: "Account", sort_by: "Name", direction: "Desc", actor: @admin)
    setting = Crm::ListSort.for("Account")
    adapter = Crm::Data::LocalActiveRecordAdapter.new(object_type: "Account", identity: identity(@owner))
    listed = adapter.list(sort: setting.field, direction: setting.direction, limit: 100).value

    assert updated.success?
    assert_equal "name1", setting.field
    assert_equal "Desc", setting.direction
    assert_equal %w[Zulu Visible\ Customer Alphabetical], listed.pluck(:name1)
    repair = Crm::AutoNumberRepair.call(object_type: "Account", actor: @admin)
    assert repair.success?
    assert_equal 0, repair.value
  end
end
