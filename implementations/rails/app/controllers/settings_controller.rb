# frozen_string_literal: true

class SettingsController < ApplicationController
  def index
    authorize :settings, :show?
    @notification_preferences = current_profile.notification_preferences.to_h.stringify_keys
    @admin = ApplicationPolicy.new(pundit_user, Role).admin?
    return unless @admin

    @pipeline_stages = PipelineStage.order(:sort_order, :id)
    @ticket_statuses = TicketStatus.order(:sort_order, :id)
    @slas = SLA.order(:response_time_hours, :resolution_time_hours, :name, :id)
    @sort_rows = Crm::ModelRegistry.navigable_object_names.map { |object_type| Crm::ListSort.for(object_type) }
    @roles = Role.order(:name, :id)
    @access_rules = EmailAccessRule.order(:rule_type, :value)
    @users = UserProfile.where.not(id: Crm::Seeds::SYSTEM_PROFILE_ID).includes(:role).order(:last_name, :first_name, :id)
    @translations = Translation.order(:language_name, :language_code)
    @xp_events = XPEvent.order(:event_type, :id)
    @level_definitions = LevelDefinition.order(:level, :id)
    @badges = Badge.order(:category, :name, :id)
    @ai_provider_configs = AIProviderConfig.order(is_active: :desc, provider: :asc)
    @data_source_configs = DataSourceConfig.order(:object_type)
    @replication_configs = ReplicationConfig.includes(:replication_runs).order(:object_type, :created_at)
    @configuration_proposals = ConfigurationProposal.includes(:configuration_versions).order(created_at: :desc).limit(30)
  end
end
