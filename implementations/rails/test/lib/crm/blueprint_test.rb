# frozen_string_literal: true

require "test_helper"
require "tempfile"
require Rails.root.join("lib/crm/blueprint")

class Crm::BlueprintTest < ActiveSupport::TestCase
  BLUEPRINT_PATH = Rails.root.join("../../specs/data-model.json").expand_path

  test "the shared blueprint is valid" do
    blueprint = Crm::Blueprint.new(BLUEPRINT_PATH).validate!

    assert_equal "1.0", blueprint.data.fetch("version")
    assert_equal 39, blueprint.object_names.length
  end

  test "unknown field types are rejected" do
    assert_invalid(/unknown type/) do |data|
      data.fetch("objects").fetch("Account").fetch("fields").first["type"] = "floating_point"
    end
  end

  test "missing reference targets are rejected" do
    assert_invalid(/references unknown object/) do |data|
      owner = data.fetch("objects").fetch("Account").fetch("fields").find { |field| field["name"] == "owner_id" }
      owner["target"] = "MissingUser"
    end
  end

  test "invalid and duplicate enums are rejected" do
    assert_invalid(/enum values must be unique/) do |data|
      status = data.fetch("objects").fetch("Account").fetch("fields").find { |field| field["name"] == "status" }
      status["values"] << "Active"
    end

    assert_invalid(/default is outside its enum/) do |data|
      status = data.fetch("objects").fetch("Account").fetch("fields").find { |field| field["name"] == "status" }
      status["default"] = "Archived"
    end
  end

  test "duplicate fields and invalid SAP lengths are rejected" do
    assert_invalid(/duplicate fields/) do |data|
      fields = data.fetch("objects").fetch("Account").fetch("fields")
      fields << fields.first.dup
    end

    assert_invalid(/length must be a positive integer/) do |data|
      data.fetch("objects").fetch("Account").fetch("fields").first["length"] = 0
    end
  end

  test "inconsistent relationships are rejected" do
    assert_invalid(/foreign_key .* does not exist/) do |data|
      relationship = data.fetch("objects").fetch("Account").fetch("relationships").first
      relationship["foreign_key"] = "missing_account_id"
    end

    assert_invalid(/does not reference Account/) do |data|
      junction = data.fetch("objects").fetch("ContactAccount").fetch("fields")
      junction.find { |field| field["name"] == "account_id" }["target"] = "Lead"
    end
  end

  test "manifest metadata is deterministic and UI-ready" do
    blueprint = Crm::Blueprint.new(BLUEPRINT_PATH)
    first = blueprint.manifest
    second = Crm::Blueprint.new(BLUEPRINT_PATH).manifest

    assert_equal first, second
    assert_equal %w[first_name last_name], first.dig("objects", "Contact", "display_name_fields")
    assert_equal "account_number", first.dig("objects", "Account", "auto_number_field")
    assert_equal %w[item_number product_id quantity unit_price discount_percent total_price],
      first.dig("objects", "LineItem", "default_list_columns")
    assert_includes first.dig("objects", "KnowledgeArticle", "searchable_fields"), "content"

    assert_equal Crm::Blueprint::CURATED_LIST_COLUMNS.keys.sort, blueprint.object_names.sort
    Crm::Blueprint::CURATED_LIST_COLUMNS.each do |object_name, columns|
      definition = first.dig("objects", object_name)
      assert_equal columns, definition.fetch("default_list_columns")
      assert_empty columns - definition.fetch("fields").map { |field| field.fetch("name") }
      assert_operator columns.length, :<=, 8
    end
  end

  private

  def assert_invalid(pattern)
    data = JSON.parse(BLUEPRINT_PATH.read)
    yield data

    Tempfile.create(["invalid-blueprint", ".json"]) do |file|
      file.write(JSON.generate(data))
      file.flush
      error = assert_raises(Crm::Blueprint::ValidationError) { Crm::Blueprint.new(file.path).validate! }
      assert_match pattern, error.message
    end
  end
end
