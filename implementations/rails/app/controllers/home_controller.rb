# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    authorize :home, :show?
    @dashboard = Crm::DashboardSnapshot.new(identity: pundit_user).call
    @dashboard_config = Crm::DashboardPreferences.for(current_profile)
    @visible_widgets = Crm::DashboardPreferences.visible_keys(@dashboard_config)
    @leaderboard_top = Crm::Leaderboard.new(viewer: current_profile).top_all_time
    @dashboard_filters = {
      "pipeline_value" => {result: "Open"},
      "open_opportunities" => {result: "Open"},
      "open_tickets" => {status_id: TicketStatus.where(is_closed: false).pluck(:id)},
      "open_leads" => {status: %w[New Contacted Qualified Unqualified]},
      "inactive_assets" => {status: "Inactive"}
    }
    @dashboard_chart_filters = {
      "opportunities_by_stage" => ["stage_id", PipelineStage.where(name: @dashboard.opportunities_by_stage.keys).pluck(:name, :id).to_h],
      "tickets_by_priority" => ["priority", @dashboard.tickets_by_priority.keys.index_with(&:itself)],
      "revenue_by_invoice_status" => ["status", @dashboard.revenue_by_invoice_status.keys.index_with(&:itself)]
    }
  end
end
