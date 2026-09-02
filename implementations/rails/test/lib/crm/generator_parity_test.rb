# frozen_string_literal: true

require "test_helper"
require Rails.root.join("lib/crm/blueprint")
require Rails.root.join("lib/crm/blueprint/generator")

class Crm::GeneratorParityTest < ActiveSupport::TestCase
  BLUEPRINT_PATH = Rails.root.join("../../specs/data-model.json").expand_path

  setup do
    @blueprint = Crm::Blueprint.new(BLUEPRINT_PATH).validate!
    @manifest = Crm::ModelRegistry.manifest
    @connection = ActiveRecord::Base.connection
  end

  test "all generated files match the authoritative blueprint" do
    assert Crm::Blueprint::Generator.new(blueprint: @blueprint).check!
    assert_equal @blueprint.object_names.sort, Crm::ModelRegistry.object_names.sort
    assert_equal Digest::SHA256.file(BLUEPRINT_PATH).hexdigest, @manifest.fetch("source_sha256")
  end

  test "every object and field exists exactly once in SQLite" do
    @blueprint.object_names.each do |object_name|
      definition = @manifest.fetch("objects").fetch(object_name)
      table = definition.fetch("table_name")
      expected_fields = @blueprint.fields_for(object_name)
      actual_columns = @connection.columns(table).index_by(&:name)

      assert_equal expected_fields.pluck("name").sort, actual_columns.keys.sort, object_name
      assert_equal expected_fields.length, actual_columns.length, object_name
      expected_fields.each do |field|
        column = actual_columns.fetch(field.fetch("name"))
        assert_equal !field.fetch("required"), column.null, "#{object_name}.#{field.fetch('name')} nullability"
        if field.fetch("type") == "string"
          assert_equal field.fetch("length"), column.limit, "#{object_name}.#{field.fetch('name')} length"
        end
      end
    end
  end

  test "every reference has a foreign key and supporting index" do
    @blueprint.object_names.each do |object_name|
      table = @blueprint.table_name(object_name)
      foreign_keys = @connection.foreign_keys(table).index_by(&:column)
      indexes = @connection.indexes(table)

      @blueprint.fields_for(object_name).select { |field| field["type"] == "reference" }.each do |field|
        foreign_key = foreign_keys.fetch(field.fetch("name"))
        assert_equal @blueprint.table_name(field.fetch("target")), foreign_key.to_table
        assert indexes.any? { |index| index.columns == [field.fetch("name")] }, "missing index for #{object_name}.#{field.fetch('name')}"
      end
    end
  end

  test "unique fields enums and SAP annotations remain represented" do
    @blueprint.object_names.each do |object_name|
      source_fields = @blueprint.specific_fields_for(object_name)
      generated = @manifest.fetch("objects").fetch(object_name)
      assert_equal source_fields, generated.fetch("specific_fields")

      indexes = @connection.indexes(generated.fetch("table_name"))
      source_fields.select { |field| field["unique"] }.each do |field|
        assert indexes.any? { |index| index.unique && index.columns == [field.fetch("name")] }
      end

      enum_fields = source_fields.select { |field| field["type"] == "enum" }
      enum_fields.each do |field|
        if field.fetch("name") == "parent_type" && source_fields.any? { |candidate| candidate.fetch("name") == "parent_id" }
          model = object_name.constantize
          refute model.defined_enums.key?("parent_type"), "polymorphic types must remain class names"
          validator = model.validators_on(:parent_type).find { |candidate| candidate.is_a?(ActiveModel::Validations::InclusionValidator) }
          assert_equal field.fetch("values"), validator.options.fetch(:in)
        else
          assert_equal field.fetch("values").sort, object_name.constantize.defined_enums.fetch(field.fetch("name")).values.sort
        end
      end
    end
  end

  test "generated models expose declared references and relationships" do
    @blueprint.object_names.each do |object_name|
      model = object_name.constantize
      assert_equal @blueprint.table_name(object_name), model.table_name

      @blueprint.relationships_for(object_name).each do |relationship|
        assert model.reflect_on_association(relationship.fetch("name")), "missing #{object_name}.#{relationship.fetch('name')}"
      end

      @blueprint.fields_for(object_name).select { |field| field["type"] == "reference" }.each do |field|
        association_name = {
          "created_by" => "creator", "updated_by" => "updater", "assigned_to" => "assignee",
          "linked_by" => "linker", "uploaded_by" => "uploader"
        }.fetch(field.fetch("name"), field.fetch("name").delete_suffix("_id"))
        reflection = model.reflect_on_association(association_name)
        assert reflection, "missing #{object_name}.#{association_name}"
        assert_equal field.fetch("target"), reflection.class_name
      end
    end
  end

  test "registry refuses objects outside its allowlist" do
    assert_raises(Crm::ModelRegistry::UnknownObject) { Crm::ModelRegistry.fetch("Kernel") }
    assert_raises(Crm::ModelRegistry::UnknownObject) { Crm::ModelRegistry.model_for("ApplicationRecord") }
  end
end
