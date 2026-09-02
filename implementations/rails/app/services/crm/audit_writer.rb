# frozen_string_literal: true

module Crm
  class AuditWriter
    FILTER = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    IGNORED_FIELDS = %w[created_at updated_at created_by updated_by].freeze

    def self.record!(record:, action:, changes: {}, actor: Current.profile)
      raise ArgumentError, "An active audit actor is required" unless actor&.active?

      auditable_changes(action, changes).each do |field, values|
        old_value, new_value = values
        AuditLog.create!(
          object_type: record.class.name,
          object_id: record.id,
          action: action.to_s.capitalize,
          field_name: field,
          old_value: serialize(field, old_value),
          new_value: serialize(field, new_value),
          user_id: actor.id,
          timestamp: Time.current,
          object_name: display_name(record),
          summary: summary(record, action:, field:, new_value:),
          created_by: actor.id,
          updated_by: actor.id
        )
      end
    end

    def self.auditable_changes(action, changes)
      filtered = changes.except(*IGNORED_FIELDS)
      return {nil => [nil, nil]} if filtered.empty? || action.to_sym != :update

      filtered
    end
    private_class_method :auditable_changes

    def self.serialize(field, value)
      return if value.nil?
      return "[FILTERED]" if FILTER.filter({field.to_s => value}).fetch(field.to_s) == "[FILTERED]"

      value.is_a?(String) ? value : value.to_json
    end
    private_class_method :serialize

    def self.display_name(record)
      %w[name name1 subject title email].each do |attribute|
        value = record.public_send(attribute) if record.respond_to?(attribute)
        return value.to_s.first(255) if value.present?
      end
      record.id
    end
    private_class_method :display_name

    def self.summary(record, action:, field:, new_value:)
      name = display_name(record)
      return "Created #{record.class.name.underscore.humanize} #{name}" if action.to_sym == :create
      return "Deleted #{record.class.name.underscore.humanize} #{name}" if action.to_sym == :delete
      return "Updated #{record.class.name.underscore.humanize} #{name}" if field.blank?

      label = field.to_s.delete_suffix("_id").humanize
      value = presentation_value(record, field, new_value)
      "Changed #{label.downcase}#{" to #{value}" if value.present?} on #{record.class.name.underscore.humanize} #{name}"
    end
    private_class_method :summary

    def self.presentation_value(record, field, value)
      association = record.class.reflect_on_all_associations(:belongs_to).find { |candidate| candidate.foreign_key.to_s == field.to_s }
      target = association&.klass&.find_by(id: value)
      target ? RecordPresentation.display_name(target) : value.to_s.truncate(100)
    rescue NameError
      value.to_s.truncate(100)
    end
    private_class_method :presentation_value
  end
end
