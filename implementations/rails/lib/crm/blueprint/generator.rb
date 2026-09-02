# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "stringio"

module Crm
  class Blueprint
    class Generator
      GENERATED_NOTICE = "Generated from specs/data-model.json by crm:blueprint:generate. Do not edit by hand."
      DOMAIN_MIGRATION = "20260901090000_create_crm_domain.rb"
      INFRASTRUCTURE_MIGRATION = "20260901090100_create_crm_infrastructure.rb"

      COMPOSITE_UNIQUES = {
        "ContactAccount" => %w[contact_id account_id],
        "OpportunityContact" => %w[opportunity_id contact_id],
        "TicketKnowledgeArticle" => %w[ticket_id article_id],
        "UserBadge" => %w[user_id badge_id],
        "DashboardConfig" => %w[user_id name],
        "Challenge" => %w[user_id month year],
        "Streak" => %w[user_id activity_type],
        "PersonalBest" => %w[user_id metric],
        "LineItem" => %w[parent_type parent_id item_number]
      }.freeze

      attr_reader :blueprint, :rails_root

      def initialize(blueprint:, rails_root: Rails.root)
        @blueprint = blueprint.validate!
        @rails_root = Pathname(rails_root)
      end

      def generate!
        outputs.each do |path, content|
          path.dirname.mkpath
          path.write(content)
        end
        remove_stale_generated_models!
        outputs.keys
      end

      def check!
        differences = outputs.filter_map do |path, expected|
          path.to_s unless path.exist? && path.read == expected
        end
        return true if differences.empty?

        raise ValidationError, "Generated blueprint files are stale:\n#{differences.join("\n")}\nRun bin/rails crm:blueprint:generate"
      end

      def outputs
        @outputs ||= begin
          files = {
            rails_root.join("config/crm/model_manifest.json") => JSON.pretty_generate(blueprint.manifest) + "\n",
            rails_root.join("db/migrate", DOMAIN_MIGRATION) => domain_migration,
            rails_root.join("db/migrate", INFRASTRUCTURE_MIGRATION) => infrastructure_migration
          }
          blueprint.path.dirname.join("translations").glob("*.json").sort.each do |source|
            files[rails_root.join("config/crm/translations", source.basename)] = source.read
          end
          blueprint.object_names.each do |object_name|
            files[rails_root.join("app/models/#{object_name.underscore}.rb")] = model_source(object_name)
          end
          files
        end
      end

      private

      def domain_migration
        output = StringIO.new
        line(output, "# frozen_string_literal: true")
        line(output)
        line(output, "# #{GENERATED_NOTICE}")
        line(output, "class CreateCrmDomain < ActiveRecord::Migration[8.1]")
        line(output, "  def change")
        blueprint.object_names.each { |object_name| emit_table(output, object_name) }
        blueprint.object_names.each { |object_name| emit_constraints_and_indexes(output, object_name) }
        blueprint.object_names.each { |object_name| emit_foreign_keys(output, object_name) }
        line(output, "  end")
        line(output, "end")
        output.string
      end

      def infrastructure_migration
        <<~RUBY
          # frozen_string_literal: true

          # #{GENERATED_NOTICE}
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
        RUBY
      end

      def emit_table(output, object_name)
        table = blueprint.table_name(object_name)
        line(output)
        line(output, "    create_table :#{table}, id: false do |t|")
        blueprint.fields_for(object_name).each do |field|
          line(output, "      #{column_definition(field)}")
        end
        line(output, "    end")
      end

      def column_definition(field)
        name = field.fetch("name")
        type = field.fetch("type")
        options = []
        options << "limit: 36" if %w[uuid reference].include?(type)
        options << "limit: #{field.fetch('length')}" if type == "string"
        options << "limit: #{field.fetch('values').map(&:length).max}" if type == "enum"
        options << "precision: #{field.fetch('precision', 15)}" if %w[decimal currency].include?(type)
        options << "scale: #{field.fetch('scale', 2)}" if %w[decimal currency].include?(type)
        options << "null: false" if field["required"]
        options << "primary_key: true" if field["primary_key"]
        options << "default: #{ruby_literal(field['default'])}" if field.key?("default")
        suffix = options.any? ? ", #{options.join(', ')}" : ""
        "t.#{migration_type(type)} :#{name}#{suffix}"
      end

      def migration_type(type)
        case type
        when "uuid", "reference", "string", "enum" then "string"
        when "currency" then "decimal"
        else type
        end
      end

      def emit_constraints_and_indexes(output, object_name)
        table = blueprint.table_name(object_name)
        fields = blueprint.fields_for(object_name)
        line(output)

        fields.each do |field|
          name = field.fetch("name")
          case field.fetch("type")
          when "string"
            add_check(output, table, name, "length(#{name}) <= #{field.fetch('length')}", "#{table}_#{name}_length")
          when "uuid", "reference"
            add_check(output, table, name, "length(#{name}) = 36", "#{table}_#{name}_uuid", nullable: !field["required"])
          when "enum"
            values = field.fetch("values").map { |value| sql_string(value) }.join(", ")
            add_check(output, table, name, "#{name} IN (#{values})", "#{table}_#{name}_enum", nullable: !field["required"])
          when "json"
            add_check(output, table, name, "json_valid(#{name})", "#{table}_#{name}_json", nullable: !field["required"])
          end

          if field["unique"] && !field["primary_key"]
            add_index(output, table, [name], unique: true)
          elsif field["type"] == "reference"
            add_index(output, table, [name])
          end
        end

        composite = COMPOSITE_UNIQUES[object_name]
        add_index(output, table, composite, unique: true) if composite

        field_names = fields.map { |field| field.fetch("name") }
        add_index(output, table, %w[parent_type parent_id]) if field_names.include?("parent_type") && field_names.include?("parent_id")
        add_index(output, table, %w[object_type object_id]) if field_names.include?("object_type") && field_names.include?("object_id")
      end

      def emit_foreign_keys(output, object_name)
        table = blueprint.table_name(object_name)
        reference_fields = blueprint.fields_for(object_name).select { |field| field["type"] == "reference" }
        return if reference_fields.empty?

        line(output)
        reference_fields.each do |field|
          target_table = blueprint.table_name(field.fetch("target"))
          options = [
            "column: :#{field.fetch('name')}",
            "primary_key: :id",
            "name: #{constraint_name("fk", table, field.fetch('name')).inspect}",
            "deferrable: :deferred"
          ]
          owned_columns = COMPOSITE_UNIQUES.fetch(object_name, [])
          options << "on_delete: :cascade" if blueprint.junction_object?(object_name) && owned_columns.include?(field.fetch("name"))
          line(output, "    add_foreign_key :#{table}, :#{target_table}, #{options.join(', ')}")
        end
      end

      def add_check(output, table, field_name, expression, raw_name, nullable: false)
        expression = "(#{expression}) OR #{field_name} IS NULL" if nullable
        line(output, "    add_check_constraint :#{table}, #{expression.inspect}, name: #{constraint_name('chk', raw_name).inspect}")
      end

      def add_index(output, table, columns, unique: false)
        columns = Array(columns)
        name = constraint_name("idx", table, *columns)
        unique_option = unique ? ", unique: true" : ""
        line(output, "    add_index :#{table}, #{columns.map(&:to_sym).inspect}, name: #{name.inspect}#{unique_option}")
      end

      def constraint_name(*parts)
        candidate = parts.join("_")
        return candidate if candidate.length <= 62

        "#{candidate.first(51)}_#{Digest::SHA256.hexdigest(candidate).first(10)}"
      end

      def model_source(object_name)
        output = StringIO.new
        definition = blueprint.data.fetch("objects").fetch(object_name)
        line(output, "# frozen_string_literal: true")
        line(output)
        line(output, "# #{GENERATED_NOTICE}")
        line(output, "class #{object_name} < ApplicationRecord")
        line(output, "  include Crm::BlueprintModel")
        line(output, "  self.table_name = #{blueprint.table_name(object_name).inspect}")
        line(output, "  self.inheritance_column = nil") if definition.fetch("fields").any? { |field| field.fetch("name") == "type" }
        emit_enums(output, definition.fetch("fields"))
        emit_belongs_to(output, object_name)
        emit_polymorphic_parent(output, object_name)
        emit_relationships(output, object_name)
        line(output, "end")
        output.string
      end

      def emit_enums(output, fields)
        fields.select { |field| field["type"] == "enum" }.each do |field|
          next if field.fetch("name") == "parent_type" && fields.any? { |candidate| candidate.fetch("name") == "parent_id" }

          mapping = enum_mapping(field.fetch("values"))
          validation = field["required"] ? "true" : "{allow_nil: true}"
          line(output, "  enum :#{field.fetch('name')}, #{mapping.inspect}, prefix: true, validate: #{validation}")
        end
      end

      def enum_mapping(values)
        used = Set.new
        values.to_h do |value|
          base = value.parameterize(separator: "_").underscore
          base = "value_#{base}" unless base.match?(/\A[a-z]/)
          key = base
          suffix = 2
          while used.include?(key)
            key = "#{base}_#{suffix}"
            suffix += 1
          end
          used << key
          [key.to_sym, value]
        end
      end

      def emit_belongs_to(output, object_name)
        blueprint.fields_for(object_name).select { |field| field["type"] == "reference" }.each do |field|
          association = belongs_to_name(field.fetch("name"))
          options = ["class_name: #{field.fetch('target').inspect}", "foreign_key: #{field.fetch('name').inspect}"]
          options << "optional: true" unless field["required"]
          line(output, "  belongs_to :#{association}, #{options.join(', ')}")
        end
      end

      def emit_polymorphic_parent(output, object_name)
        names = blueprint.specific_fields_for(object_name).map { |field| field.fetch("name") }
        return unless names.include?("parent_type") && names.include?("parent_id")

        line(output, "  belongs_to :parent, polymorphic: true, foreign_key: :parent_id, foreign_type: :parent_type")
      end

      def emit_relationships(output, object_name)
        through_associations = Set.new
        blueprint.relationships_for(object_name).each do |relationship|
          if relationship.fetch("type") == "one-to-many"
            emit_one_to_many(output, relationship)
          else
            emit_many_to_many(output, object_name, relationship, through_associations)
          end
        end
      end

      def emit_one_to_many(output, relationship)
        target = relationship.fetch("target")
        foreign_key = relationship.fetch("foreign_key")
        target_field = blueprint.specific_fields_for(target).find { |field| field["name"] == foreign_key }
        dependent = target_field&.fetch("required", false) ? :restrict_with_error : :nullify
        options = ["class_name: #{target.inspect}", "foreign_key: #{foreign_key.inspect}", "dependent: :#{dependent}"]
        if (condition = relationship["condition"])
          match = Blueprint::CONDITION_PATTERN.match(condition)
          scope = "-> { where(#{match[1]}: #{match[2].inspect}) }, "
        end
        line(output, "  has_many :#{relationship.fetch('name')}, #{scope}#{options.join(', ')}")
      end

      def emit_many_to_many(output, object_name, relationship, through_associations)
        through = relationship.fetch("through")
        through_name = through.underscore.pluralize
        unless through_associations.include?(through_name)
          owner_field = blueprint.specific_fields_for(through).find do |field|
            field["type"] == "reference" && field["target"] == object_name
          end
          options = ["class_name: #{through.inspect}", "foreign_key: #{owner_field.fetch('name').inspect}", "dependent: :destroy"]
          line(output, "  has_many :#{through_name}, #{options.join(', ')}")
          through_associations << through_name
        end

        target = relationship.fetch("target")
        source_field = blueprint.specific_fields_for(through).find do |field|
          field["type"] == "reference" && field["target"] == target
        end
        source = belongs_to_name(source_field.fetch("name"))
        line(output, "  has_many :#{relationship.fetch('name')}, through: :#{through_name}, source: :#{source}")
      end

      def belongs_to_name(field_name)
        return "creator" if field_name == "created_by"
        return "updater" if field_name == "updated_by"
        return "assignee" if field_name == "assigned_to"
        return "linker" if field_name == "linked_by"
        return "uploader" if field_name == "uploaded_by"

        field_name.delete_suffix("_id")
      end

      def ruby_literal(value)
        value.inspect
      end

      def sql_string(value)
        "'#{value.gsub("'", "''")}'"
      end

      def line(output, content = "")
        output << content << "\n"
      end

      def remove_stale_generated_models!
        expected = outputs.keys.select { |path| path.dirname == rails_root.join("app/models") }.to_set
        rails_root.join("app/models").glob("*.rb").each do |path|
          next if expected.include?(path)
          next unless path.read.include?(GENERATED_NOTICE)

          path.delete
        end
      end
    end
  end
end
