# frozen_string_literal: true

require "securerandom"

module Crm
  module BlueprintModel
    extend ActiveSupport::Concern

    included do
      include Crm::ActorStamped
      self.primary_key = "id"

      before_validation :assign_crm_uuid, on: :create
      before_validation :assign_crm_auto_number, on: :create
      before_validation :normalize_crm_profile_email if name == "UserProfile"

      crm_definition.fetch("fields").each do |field|
        field_name = field.fetch("name")
        field_type = field.fetch("type")

        if field["required"] && !%w[id created_at updated_at].include?(field_name) && !%w[enum boolean json].include?(field_type)
          validates field_name, presence: true
        end
        validates field_name, inclusion: {in: [true, false]} if field["required"] && field_type == "boolean"
        if field_type == "enum" && field_name == "parent_type"
          validates field_name, inclusion: {in: field.fetch("values")}, allow_nil: !field["required"]
        end
        validates field_name, exclusion: {in: [nil]} if field["required"] && field_type == "json"
        validates field_name, length: {maximum: field.fetch("length")} if field_type == "string"
        if field["unique"] && !field["primary_key"]
          validates field_name, uniqueness: true, allow_nil: !field["required"]
        end
        validate -> { validate_crm_json_field(field_name) } if field_type == "json"
      end

      encrypts :api_key if name == "AIProviderConfig"
      encrypts :auth_config if name == "DataSourceConfig"

      include Crm::Sales::LeadBehavior if name == "Lead"
      include Crm::Sales::OpportunityBehavior if name == "Opportunity"
      include Crm::Sales::PipelineStageBehavior if name == "PipelineStage"
      include Crm::Sales::LineItemBehavior if name == "LineItem"
      include Crm::Sales::PricebookEntryBehavior if name == "PricebookEntry"
      include Crm::Sales::DocumentBehavior if name.in?(%w[Quotation SalesOrder Invoice])
      include Crm::Sales::ActivityBehavior if name == "Activity"
      include Crm::Service::TicketBehavior if name == "Ticket"
      include Crm::Service::TicketStatusBehavior if name == "TicketStatus"
      include Crm::Service::SLABehavior if name == "SLA"
      include Crm::Service::KnowledgeArticleBehavior if name == "KnowledgeArticle"
      include Crm::Service::TicketKnowledgeArticleBehavior if name == "TicketKnowledgeArticle"
      include Crm::Service::ServiceContractBehavior if name == "ServiceContract"
      include Crm::Service::AssetBehavior if name == "Asset"
      include Crm::RoleBehavior if name == "Role"
      include Crm::NotificationBehavior if name == "Notification"
      include Crm::AIProviderConfigBehavior if name == "AIProviderConfig"
      include Crm::DataSourceConfigBehavior if name == "DataSourceConfig"
    end

    class_methods do
      def policy_class
        case name
        when "AIProviderConfig", "DataSourceConfig", "Role" then SettingsPolicy
        when "XPEvent", "LevelDefinition", "Badge" then GamificationSettingPolicy
        when "PipelineStage" then PipelineStagePolicy
        when "TicketStatus" then TicketStatusPolicy
        when "SLA" then SLAPolicy
        when "Ticket" then TicketPolicy
        when "KnowledgeArticle" then KnowledgeArticlePolicy
        when "UserProfile" then UserProfilePolicy
        when "Notification" then NotificationPolicy
        when "Activity" then ActivityPolicy
        when "DashboardConfig" then DashboardConfigPolicy
        else ApplicationPolicy
        end
      end

      def crm_definition
        Crm::ModelRegistry.fetch(name)
      end

      def crm_display_number(value)
        NumberCounter.display(value)
      end
    end

    def serializable_hash(options = nil)
      hash = super
      self.class.crm_sensitive_fields.each { |field| hash.delete(field) }
      hash
    end

    private

    def assign_crm_uuid
      self.id ||= SecureRandom.uuid
    end

    def assign_crm_auto_number
      field_name = self.class.crm_definition["auto_number_field"]
      return unless field_name && public_send(field_name).blank?

      if self.class.name == "LineItem"
        self.item_number = Crm::Sales::Pricing.next_item_number(parent_type:, parent_id:)
        return
      end

      field = self.class.crm_definition.fetch("specific_fields").find do |candidate|
        candidate.fetch("name") == field_name
      end
      public_send("#{field_name}=", NumberCounter.allocate!(object_type: self.class.name, width: field.fetch("length")))
    end

    def normalize_crm_profile_email
      self.email = Crm::Email.normalize(email)
    end

    def validate_crm_json_field(field_name)
      value = public_send(field_name)
      return if value.nil? || value.is_a?(Hash) || value.is_a?(Array)

      errors.add(field_name, "must be a JSON object or array")
    end

    class_methods do
      def crm_sensitive_fields
        case name
        when "AIProviderConfig" then %w[api_key]
        when "DataSourceConfig" then %w[auth_config]
        else []
        end
      end
    end
  end
end
