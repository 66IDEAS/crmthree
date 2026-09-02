# frozen_string_literal: true

require "digest"
require "json"
require "pathname"
require "set"

module Crm
  class Blueprint
    class ValidationError < StandardError; end

    FIELD_TYPES = %w[
      boolean currency date datetime decimal enum integer json reference string text uuid
    ].freeze
    RELATIONSHIP_TYPES = %w[one-to-many many-to-many].freeze
    FIELD_NAME_PATTERN = /\A[a-z][a-z0-9_]*\z/
    OBJECT_NAME_PATTERN = /\A[A-Z][A-Za-z0-9]*\z/
    CONDITION_PATTERN = /\A([a-z][a-z0-9_]*) = '([A-Za-z0-9]+)'\z/

    CURATED_LIST_COLUMNS = {
      "AIProviderConfig" => %w[provider model endpoint_url is_active],
      "Account" => %w[account_number name1 city industry_description company_size annual_revenue currency status],
      "Activity" => %w[activity_number subject type status priority due_date account_id owner_id],
      "Asset" => %w[asset_number name product_id account_id serial_number warranty_end_date status owner_id],
      "AuditLog" => %w[timestamp object_type object_name action field_name user_id],
      "Badge" => %w[name description category is_custom active],
      "Challenge" => %w[title user_id target_metric current_value target_value status reward_xp],
      "Comment" => %w[content author_id created_at],
      "Contact" => %w[contact_number first_name last_name account_id position email phone status],
      "ContactAccount" => %w[contact_id account_id role is_primary],
      "DashboardConfig" => %w[name user_id is_default],
      "DataSourceConfig" => %w[object_type source_type endpoint_url auth_type active],
      "DealRoom" => %w[deal_room_number name opportunity_id status owner_id],
      "Document" => %w[name parent_type file_type file_size uploaded_by created_at],
      "Invoice" => %w[invoice_number account_id status invoice_date due_date total_amount paid_amount currency],
      "KnowledgeArticle" => %w[article_number title category status author_id views_count helpful_count published_at],
      "Lead" => %w[lead_number first_name last_name company status score source owner_id],
      "LevelDefinition" => %w[level name xp_threshold],
      "LineItem" => %w[item_number product_id quantity unit_price discount_percent total_price],
      "Notification" => %w[title user_id type read email_sent created_at],
      "Opportunity" => %w[opportunity_number name account_id stage_id amount probability expected_close_date result],
      "OpportunityContact" => %w[opportunity_id contact_id role],
      "PersonalBest" => %w[user_id metric value achieved_at previous_value],
      "PipelineStage" => %w[name sort_order default_probability is_closed is_won active],
      "PricebookEntry" => %w[product_id account_id price currency discount_percent valid_from valid_to active],
      "Product" => %w[product_number name product_group product_type base_price currency status],
      "Quotation" => %w[quotation_number account_id contact_id opportunity_id status valid_to total_amount currency],
      "Role" => %w[name description is_system_role active],
      "SLA" => %w[name response_time_hours resolution_time_hours business_hours_only active],
      "SalesOrder" => %w[order_number account_id contact_id opportunity_id status order_date total_amount currency],
      "ServiceContract" => %w[contract_number name account_id start_date end_date status sla_id owner_id],
      "Streak" => %w[user_id activity_type current_count longest_count last_activity_date],
      "Team" => %w[name manager_id active description],
      "Ticket" => %w[ticket_number subject status_id priority category account_id assigned_to sla_resolution_deadline],
      "TicketKnowledgeArticle" => %w[ticket_id article_id linked_at linked_by],
      "TicketStatus" => %w[name sort_order is_closed is_resolved active],
      "UserBadge" => %w[user_id badge_id earned_at],
      "UserProfile" => %w[first_name last_name email role_id team_id active level_name xp_total],
      "XPEvent" => %w[event_type description xp_value active]
    }.freeze

    attr_reader :path, :data

    def initialize(path)
      @path = Pathname(path).expand_path
      @data = JSON.parse(@path.read)
    rescue JSON::ParserError => error
      raise ValidationError, "#{@path}: invalid JSON: #{error.message}"
    end

    def validate!
      errors = []
      validate_root(errors)
      validate_common_fields(errors)
      validate_objects(errors)
      validate_relationships(errors)

      raise ValidationError, errors.join("\n") if errors.any?

      self
    end

    def manifest
      validate!

      {
        "version" => data.fetch("version"),
        "source" => relative_source,
        "source_sha256" => Digest::SHA256.file(path).hexdigest,
        "field_types" => deep_sort(data.fetch("field_types")),
        "common_fields" => data.fetch("common_fields").map { |field| deep_sort(field) },
        "objects" => data.fetch("objects").keys.sort.to_h do |object_name|
          definition = data.fetch("objects").fetch(object_name)
          specific_fields = definition.fetch("fields")
          all_fields = data.fetch("common_fields") + specific_fields
          auto_number = specific_fields.find { |field| field["auto_generated"] }

          [object_name, deep_sort(definition.merge(
            "model_class" => object_name,
            "table_name" => table_name(object_name),
            "fields" => all_fields,
            "specific_fields" => specific_fields,
            "display_name_fields" => display_name_fields(object_name, specific_fields, auto_number),
            "auto_number_field" => auto_number&.fetch("name", nil),
            "searchable_fields" => specific_fields.filter_map do |field|
              field.fetch("name") if %w[string text].include?(field.fetch("type"))
            end,
            "default_list_columns" => list_columns(object_name, specific_fields, auto_number),
            "reference_option_fields" => reference_option_fields(object_name, specific_fields, auto_number),
            "enum_definitions" => specific_fields.filter_map do |field|
              [field.fetch("name"), field.fetch("values")] if field.fetch("type") == "enum"
            end.to_h,
            "junction" => junction_object?(object_name)
          ))]
        end
      }
    end

    def object_names
      data.fetch("objects").keys
    end

    def fields_for(object_name)
      data.fetch("common_fields") + data.fetch("objects").fetch(object_name).fetch("fields")
    end

    def specific_fields_for(object_name)
      data.fetch("objects").fetch(object_name).fetch("fields")
    end

    def relationships_for(object_name)
      data.fetch("objects").fetch(object_name).fetch("relationships", [])
    end

    def table_name(object_name)
      object_name.underscore.pluralize
    end

    def junction_object?(object_name)
      through_objects.include?(object_name) || object_name == "UserBadge"
    end

    private

    def validate_root(errors)
      errors << "version must be a non-empty string" unless data["version"].is_a?(String) && data["version"].present?
      errors << "field_types must be an object" unless data["field_types"].is_a?(Hash)
      errors << "common_fields must be an array" unless data["common_fields"].is_a?(Array)
      errors << "objects must be a non-empty object" unless data["objects"].is_a?(Hash) && data["objects"].any?

      declared_types = data.fetch("field_types", {}).keys.sort
      errors << "field_types must declare exactly: #{FIELD_TYPES.join(', ')}" unless declared_types == FIELD_TYPES.sort
    end

    def validate_common_fields(errors)
      fields = data.fetch("common_fields", [])
      validate_field_collection("common_fields", fields, errors)

      expected = %w[id created_at updated_at created_by updated_by]
      actual = fields.filter_map { |field| field["name"] }
      errors << "common_fields must be exactly #{expected.join(', ')}" unless actual == expected
    end

    def validate_objects(errors)
      data.fetch("objects", {}).each do |object_name, definition|
        errors << "invalid object name #{object_name.inspect}" unless object_name.match?(OBJECT_NAME_PATTERN)
        unless definition.is_a?(Hash) && definition["fields"].is_a?(Array)
          errors << "#{object_name} must contain a fields array"
          next
        end

        fields = definition.fetch("fields")
        validate_field_collection(object_name, fields, errors)

        duplicate_common = fields.filter_map { |field| field["name"] } &
          data.fetch("common_fields", []).filter_map { |field| field["name"] }
        errors << "#{object_name} repeats common fields: #{duplicate_common.join(', ')}" if duplicate_common.any?
      end
    end

    def validate_field_collection(owner, fields, errors)
      names = fields.filter_map { |field| field.is_a?(Hash) ? field["name"] : nil }
      duplicates = names.tally.select { |_name, count| count > 1 }.keys
      errors << "#{owner} has duplicate fields: #{duplicates.join(', ')}" if duplicates.any?

      fields.each_with_index do |field, index|
        unless field.is_a?(Hash)
          errors << "#{owner} field #{index + 1} must be an object"
          next
        end

        name = field["name"]
        type = field["type"]
        location = "#{owner}.#{name || index + 1}"

        errors << "#{location} has an invalid field name" unless name.is_a?(String) && name.match?(FIELD_NAME_PATTERN)
        errors << "#{location} has unknown type #{type.inspect}" unless FIELD_TYPES.include?(type)
        errors << "#{location} required must be boolean" unless [true, false].include?(field["required"])

        validate_string_field(field, location, errors) if type == "string"
        validate_decimal_field(field, location, errors) if %w[decimal currency].include?(type)
        validate_enum_field(field, location, errors) if type == "enum"
        validate_reference_field(field, location, errors) if type == "reference"
        validate_default(field, location, errors)
      end
    end

    def validate_string_field(field, location, errors)
      length = field["length"]
      errors << "#{location} length must be a positive integer" unless length.is_a?(Integer) && length.positive?
    end

    def validate_decimal_field(field, location, errors)
      precision = field.fetch("precision", 15)
      scale = field.fetch("scale", 2)
      unless precision.is_a?(Integer) && precision.positive? && scale.is_a?(Integer) && scale >= 0 && scale <= precision
        errors << "#{location} has invalid precision/scale"
      end
    end

    def validate_enum_field(field, location, errors)
      values = field["values"]
      unless values.is_a?(Array) && values.any? && values.all? { |value| value.is_a?(String) && value.present? }
        errors << "#{location} enum values must be a non-empty string array"
        return
      end

      errors << "#{location} enum values must be unique" unless values.uniq.length == values.length
      errors << "#{location} default is outside its enum" if field.key?("default") && !values.include?(field["default"])
    end

    def validate_reference_field(field, location, errors)
      target = field["target"]
      errors << "#{location} reference target is missing" unless target.is_a?(String) && target.present?
      errors << "#{location} references unknown object #{target.inspect}" unless data.fetch("objects", {}).key?(target)
    end

    def validate_default(field, location, errors)
      return unless field.key?("default")

      default = field["default"]
      valid = case field["type"]
      when "boolean" then [true, false].include?(default)
      when "integer" then default.is_a?(Integer)
      when "decimal", "currency" then default.is_a?(Numeric)
      when "json" then default.is_a?(Hash) || default.is_a?(Array)
      else true
      end
      errors << "#{location} default has the wrong type" unless valid
    end

    def validate_relationships(errors)
      data.fetch("objects", {}).each do |source, definition|
        relationships = definition.fetch("relationships", [])
        unless relationships.is_a?(Array)
          errors << "#{source}.relationships must be an array"
          next
        end

        names = relationships.filter_map { |relationship| relationship["name"] if relationship.is_a?(Hash) }
        duplicates = names.tally.select { |_name, count| count > 1 }.keys
        errors << "#{source} has duplicate relationships: #{duplicates.join(', ')}" if duplicates.any?

        relationships.each do |relationship|
          validate_relationship(source, relationship, errors)
        end
      end
    end

    def validate_relationship(source, relationship, errors)
      unless relationship.is_a?(Hash)
        errors << "#{source} has a relationship that is not an object"
        return
      end

      name = relationship["name"]
      type = relationship["type"]
      target = relationship["target"]
      location = "#{source}.#{name}"
      errors << "#{location} has an invalid name" unless name.is_a?(String) && name.match?(FIELD_NAME_PATTERN)
      errors << "#{location} has unknown relationship type #{type.inspect}" unless RELATIONSHIP_TYPES.include?(type)
      errors << "#{location} targets unknown object #{target.inspect}" unless data.fetch("objects", {}).key?(target)
      return unless data.fetch("objects", {}).key?(target)

      if type == "one-to-many"
        validate_one_to_many(location, source, target, relationship, errors)
      elsif type == "many-to-many"
        validate_many_to_many(location, source, target, relationship, errors)
      end
    end

    def validate_one_to_many(location, source, target, relationship, errors)
      foreign_key = relationship["foreign_key"]
      target_field = specific_fields_for(target).find { |field| field["name"] == foreign_key }
      errors << "#{location} foreign_key #{foreign_key.inspect} does not exist on #{target}" unless target_field

      condition = relationship["condition"]
      return unless condition

      match = CONDITION_PATTERN.match(condition)
      unless match
        errors << "#{location} has unsupported condition #{condition.inspect}"
        return
      end

      condition_field = specific_fields_for(target).find { |field| field["name"] == match[1] }
      errors << "#{location} condition field #{match[1]} does not exist on #{target}" unless condition_field
      if condition_field && (condition_field["type"] != "enum" || !condition_field.fetch("values", []).include?(match[2]))
        errors << "#{location} condition value #{match[2]} is inconsistent with #{target}.#{match[1]}"
      end
      errors << "#{location} condition must identify #{source}" unless match[2] == source
    end

    def validate_many_to_many(location, source, target, relationship, errors)
      through = relationship["through"]
      unless data.fetch("objects", {}).key?(through)
        errors << "#{location} uses unknown junction #{through.inspect}"
        return
      end

      reference_targets = specific_fields_for(through).filter_map do |field|
        field["target"] if field["type"] == "reference"
      end
      errors << "#{location} junction #{through} does not reference #{source}" unless reference_targets.include?(source)
      errors << "#{location} junction #{through} does not reference #{target}" unless reference_targets.include?(target)
    end

    def display_name_fields(object_name, fields, auto_number)
      names = fields.map { |field| field.fetch("name") }
      return %w[first_name last_name] if %w[Contact Lead].include?(object_name)
      return ["name"] if names.include?("name")
      return ["name1"] if names.include?("name1")
      return ["title"] if names.include?("title")
      return ["subject"] if names.include?("subject")
      return [auto_number.fetch("name")] if auto_number

      field = fields.find { |candidate| %w[string enum].include?(candidate.fetch("type")) }
      field ? [field.fetch("name")] : ["id"]
    end

    def list_columns(object_name, fields, auto_number)
      curated = CURATED_LIST_COLUMNS[object_name]
      return curated if curated

      display = display_name_fields(object_name, fields, auto_number)
      candidates = fields.filter_map do |field|
        field.fetch("name") unless %w[json text].include?(field.fetch("type"))
      end
      [auto_number&.fetch("name"), *display, *candidates].compact.uniq.first(5)
    end

    def reference_option_fields(object_name, fields, auto_number)
      [auto_number&.fetch("name"), *display_name_fields(object_name, fields, auto_number)].compact.uniq
    end

    def through_objects
      @through_objects ||= data.fetch("objects").values.flat_map do |definition|
        definition.fetch("relationships", []).filter_map { |relationship| relationship["through"] }
      end.to_set
    end

    def relative_source
      path.relative_path_from(path.dirname.dirname).to_s
    rescue ArgumentError
      path.to_s
    end

    def deep_sort(value)
      case value
      when Hash
        value.keys.sort.to_h { |key| [key, deep_sort(value.fetch(key))] }
      when Array
        value.map { |item| deep_sort(item) }
      else
        value
      end
    end
  end
end
