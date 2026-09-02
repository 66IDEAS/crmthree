# frozen_string_literal: true

module Crm
  class DashboardSnapshot
    Snapshot = ::Data.define(
      :pipeline_value, :open_opportunities, :open_tickets, :open_leads, :activities_this_week,
      :inactive_assets, :opportunities_by_stage, :tickets_by_priority, :activity_trend,
      :revenue_by_invoice_status
    )

    def initialize(identity:)
      @identity = identity
    end

    def call
      opportunities = scope_for("Opportunity")
      tickets = scope_for("Ticket")
      leads = scope_for("Lead")
      activities = scope_for("Activity")
      assets = scope_for("Asset")
      invoices = scope_for("Invoice")
      open_opportunities = opportunities.where(result: "Open")
      open_tickets = tickets.joins(:status).where(ticket_statuses: {is_closed: false})
      week = 6.days.ago.to_date..Date.current

      Snapshot.new(
        pipeline_value: open_opportunities.sum(:amount),
        open_opportunities: open_opportunities.count,
        open_tickets: open_tickets.count,
        open_leads: leads.where.not(status: "Converted").count,
        activities_this_week: activities.where(start_date: week.begin.beginning_of_day..week.end.end_of_day).count,
        inactive_assets: assets.where(status: "Inactive").count,
        opportunities_by_stage: stage_totals(opportunities),
        tickets_by_priority: enum_counts(tickets, :priority),
        activity_trend: date_counts(activities, week),
        revenue_by_invoice_status: invoices.group(:status).sum(:total_amount).transform_keys { |value| enum_label(Invoice, :status, value) }
      )
    end

    private

    attr_reader :identity

    def scope_for(object_type)
      result = DataSourceRouter.for(object_type:, identity:)
      raise ActiveRecord::RecordNotFound unless result.success?

      scope = result.value.dashboard_scope
      raise ActiveRecord::RecordNotFound unless scope.success?

      scope.value
    end

    def stage_totals(opportunities)
      opportunities.joins(:stage).group("pipeline_stages.name", "pipeline_stages.sort_order")
        .order("pipeline_stages.sort_order").count.transform_keys(&:first)
    end

    def enum_counts(relation, field)
      relation.group(field).count.transform_keys { |value| enum_label(relation.model, field, value) }
    end

    def enum_label(model, field, value)
      model.defined_enums.fetch(field.to_s, {}).fetch(value.to_s, value.to_s).to_s
    end

    def date_counts(activities, range)
      timestamps = range.begin.beginning_of_day..range.end.end_of_day
      counts = activities.where(start_date: timestamps).group("DATE(start_date)").count
      range.to_h { |date| [I18n.l(date, format: :short), counts.fetch(date.iso8601, 0)] }
    end
  end
end
