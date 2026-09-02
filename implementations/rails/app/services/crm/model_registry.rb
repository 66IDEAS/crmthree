# frozen_string_literal: true

require "json"

module Crm
  class ModelRegistry
    class UnknownObject < KeyError; end

    MANIFEST_PATH = Rails.root.join("config/crm/model_manifest.json")
    NAVIGABLE_OBJECT_NAMES = %w[
      Account Contact Lead Opportunity DealRoom Quotation SalesOrder Invoice Product Activity
      Ticket KnowledgeArticle Asset SLA ServiceContract
    ].freeze
    SEARCHABLE_OBJECT_NAMES = (NAVIGABLE_OBJECT_NAMES - ["DealRoom"]).freeze

    class << self
      def manifest
        ActiveSupport::IsolatedExecutionState[:crm_model_manifest] || (@manifest ||= JSON.parse(MANIFEST_PATH.read).freeze)
      end

      def with_manifest(temporary_manifest)
        previous = ActiveSupport::IsolatedExecutionState[:crm_model_manifest]
        ActiveSupport::IsolatedExecutionState[:crm_model_manifest] = temporary_manifest
        yield
      ensure
        ActiveSupport::IsolatedExecutionState[:crm_model_manifest] = previous
      end

      def reload!
        @manifest = nil
        manifest
      end

      def object_names
        manifest.fetch("objects").keys.freeze
      end

      def navigable_object_names
        NAVIGABLE_OBJECT_NAMES
      end

      def searchable_object_names
        SEARCHABLE_OBJECT_NAMES
      end

      def include?(object_name)
        manifest.fetch("objects").key?(object_name.to_s)
      end

      def fetch(object_name)
        manifest.fetch("objects").fetch(object_name.to_s)
      rescue KeyError
        raise UnknownObject, "Unknown CRM object: #{object_name.inspect}"
      end

      def model_for(object_name)
        definition = fetch(object_name)
        definition.fetch("model_class").constantize
      end

      def field(object_name, field_name)
        fetch(object_name).fetch("fields").find { |field| field.fetch("name") == field_name.to_s }
      end

      def writable_fields(object_name)
        fetch(object_name).fetch("specific_fields").reject { |field| field["auto_generated"] || field["primary_key"] }
      end
    end
  end
end
