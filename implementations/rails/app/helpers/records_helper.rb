# frozen_string_literal: true

module RecordsHelper
  NOTIFICATION_CHANNELS = {"desktop" => "Desktop", "email" => "Email"}.freeze
  FIELD_LABEL_OVERRIDES = {
    "name1" => "Primary name",
    "name2" => "Secondary name",
    "LineItem.item_number" => "Item #",
    "LineItem.unit_price" => "Net price",
    "LineItem.discount_percent" => "Discount %",
    "LineItem.total_price" => "Net value"
  }.freeze
  ACTIVITY_ACTIONS = [
    ["Call", "Log Call", "phone"],
    ["Email", "Log Email", "mail"],
    ["Meeting", "Log Meeting", "calendar"],
    ["Task", "New Task", "check-square"]
  ].freeze
  ACTIVITY_PARENT_FIELDS = {
    "Account" => "account_id", "Contact" => "contact_id", "Lead" => "lead_id",
    "Opportunity" => "opportunity_id", "Ticket" => "ticket_id"
  }.freeze
  DOCUMENT_CONVERSIONS = {
    "Opportunity" => [["Quotation", "Create Quotation", "document"], ["SalesOrder", "Create Sales Order", "cart"]],
    "Quotation" => [["SalesOrder", "Create Sales Order", "cart"]],
    "SalesOrder" => [["Invoice", "Create Invoice", "receipt"]]
  }.freeze
  SALES_OBJECT_LABELS = {"SalesOrder" => "Sales Order", "LineItem" => "Line Item"}.freeze

  def object_label(object_type, count: 1)
    fallback = object_type.to_s.underscore.humanize.pluralize(count)
    return fallback if count == 1

    Crm::TranslationService.translate("object.#{object_type}", fallback:)
  end

  def field_label(object_type, field)
    name = field.fetch("name")
    fallback = FIELD_LABEL_OVERRIDES["#{object_type}.#{name}"] || FIELD_LABEL_OVERRIDES[name] ||
      name.delete_prefix("is_").delete_suffix("_id").humanize
    Crm::TranslationService.translate("field.#{object_type}.#{name}", fallback:)
  end

  def formatted_field_value(record, field, references: {})
    value = record.public_send(field.fetch("name"))
    return nil if value.blank? && value != false

    case field.fetch("type")
    when "enum"
      raw = record.read_attribute_before_type_cast(field.fetch("name")).to_s
      Crm::TranslationService.translate("enum.#{raw}", fallback: raw)
    when "reference"
      references.dig(field.fetch("name"), value) || value
    when "date", "datetime"
      I18n.l(value, format: :long)
    when "currency"
      number_to_currency(value, unit: currency_unit(record), strip_insignificant_zeros: true)
    when "decimal"
      number_with_precision(value, precision: field.fetch("scale", 2), strip_insignificant_zeros: true)
    when "boolean"
      value ? crm_t("ui.yes", "Yes") : crm_t("ui.no", "No")
    when "json"
      JSON.pretty_generate(value)
    else
      value.to_s
    end
  end

  def enum_tone(record, field)
    Crm::RecordPresentation.chip_tone(record.read_attribute_before_type_cast(field.fetch("name")))
  end

  def crm_field_input(form, field, options: [], compact: false)
    return notification_preferences_input(form) if notification_preferences_field?(form.object, field)
    return sla_priorities_input(form) if form.object.is_a?(SLA) && field.fetch("name") == "applies_to_priorities"

    name = field.fetch("name")
    required = field["required"]
    css = compact ? "inline-input" : nil

    case field.fetch("type")
    when "text"
      form.text_area(name, required: required, class: css)
    when "enum"
      mapping = form.object&.class&.defined_enums&.fetch(name, {}) || {}
      values = field.fetch("values")
      if form.object.is_a?(Lead) && name == "status"
        values = form.object.converted? ? ["Converted"] : values - ["Converted"]
      end
      choices = values.map do |value|
        [Crm::TranslationService.translate("enum.#{value}", fallback: value), mapping.key(value) || value]
      end
      form.select(name, choices, required ? {} : {include_blank: true}, required: required, class: css)
    when "reference"
      form.select(name, options.map { |id, label| [label, id] }, required ? {} : {include_blank: true}, required: required, class: css)
    when "boolean"
      form.check_box(name, class: "checkbox-input")
    when "date"
      form.date_field(name, required: required, class: css)
    when "datetime"
      form.datetime_local_field(name, required: required, class: css)
    when "integer"
      form.number_field(name, required: required, step: 1, class: css)
    when "decimal", "currency"
      form.number_field(name, required: required, step: "any", class: css)
    when "json"
      form.text_area(name, value: pretty_json(form.object.public_send(name)), required: required, class: css)
    else
      input_type = name.include?("email") ? :email_field : (name.include?("url") || name.include?("website") ? :url_field : :text_field)
      form.public_send(input_type, name, required: required, maxlength: field["length"], class: css)
    end
  end

  def notification_preferences_field?(record, field)
    record.is_a?(UserProfile) && field.fetch("name") == "notification_preferences"
  end

  def notification_preference_items(record)
    preferences = record.notification_preferences.to_h.stringify_keys
    preference_keys(preferences).map do |key|
      [NOTIFICATION_CHANNELS[key] || key.underscore.humanize, boolean_value(preferences[key])]
    end
  end

  def activity_actions_for(record)
    parent_field = ACTIVITY_PARENT_FIELDS[record.class.name]
    return [] unless parent_field

    ACTIVITY_ACTIONS.map do |type, label, icon|
      {
        type:,
        label:,
        icon:,
        path: new_record_path(object_type: "Activity", activity_type: type, parent_field:, parent_id: record.id,
          context_label: display_name(record), return_to: record_path(object_type: record.class.name, id: record.id))
      }
    end
  end

  def conversion_actions_for(record)
    return [{target: "LeadConversion", label: "Convert Lead", icon: "transform", disabled: record.converted?}] if record.is_a?(Lead)

    DOCUMENT_CONVERSIONS.fetch(record.class.name, []).map do |target, label, icon|
      {target:, label:, icon:, disabled: false}
    end
  end

  def conversion_dialog_id(record, target)
    "convert-#{record.class.name.underscore}-#{record.id}-to-#{target.to_s.underscore}"
  end

  def sales_object_label(value)
    SALES_OBJECT_LABELS[value.to_s] || value.to_s.underscore.humanize
  end

  def sla_state_label(state)
    {
      within: "Within target",
      met: "Met",
      breached: "Breached",
      not_applicable: "Not applicable"
    }.fetch(state.to_sym, state.to_s.humanize)
  end

  def sla_state_tone(state)
    return "positive" if state.to_sym == :met
    return "negative" if state.to_sym == :breached
    return "progress" if state.to_sym == :within

    "neutral"
  end

  private

  def sla_priorities_input(form)
    selected = Array(form.object.applies_to_priorities).compact_blank
    content_tag(:div, class: "preference-options") do
    safe_join(Crm::Service::SLABehavior::PRIORITIES.map do |priority|
        input_name = "#{form.object_name}[applies_to_priorities][]"
        input_id = "#{form.object_name}_applies_to_priorities_#{priority}".parameterize(separator: "_")
        label_tag(input_id, class: "preference-option") do
          check_box_tag(input_name, priority, priority.in?(selected), id: input_id) + content_tag(:span, priority)
        end
      end) + hidden_field_tag("#{form.object_name}[applies_to_priorities][]", "", id: nil)
    end
  end

  def notification_preferences_input(form)
    preferences = form.object.notification_preferences.to_h.stringify_keys
    content_tag(:div, class: "preference-options") do
      safe_join(preference_keys(preferences).map do |key|
        input_name = "#{form.object_name}[notification_preferences][#{key}]"
        input_id = "#{form.object_name}_notification_preferences_#{key}".parameterize(separator: "_")
        label_tag(input_id, class: "preference-option") do
          hidden_field_tag(input_name, "false", id: nil) +
            check_box_tag(input_name, "true", boolean_value(preferences[key]), id: input_id) +
            content_tag(:span, NOTIFICATION_CHANNELS[key] || key.underscore.humanize)
        end
      end)
    end
  end

  def preference_keys(preferences)
    NOTIFICATION_CHANNELS.keys | preferences.keys
  end

  def boolean_value(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def pretty_json(value)
    value.present? ? JSON.pretty_generate(value) : ""
  rescue JSON::GeneratorError
    value.to_s
  end

  def currency_unit(record)
    currency = record.currency if record.respond_to?(:currency)
    currency ||= record.product&.currency if record.respond_to?(:product)
    currency.present? ? "#{currency} " : "$"
  end
end
