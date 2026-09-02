# frozen_string_literal: true

module Crm
  class DashboardPreferences
    WIDGETS = %w[
      pipeline_value open_opportunities open_tickets open_leads activities_this_week inactive_assets
      opportunities_by_stage tickets_by_priority activity_trend revenue_by_invoice_status
      leaderboard
    ].freeze
    SALES = %w[pipeline_value open_opportunities open_leads activities_this_week opportunities_by_stage activity_trend revenue_by_invoice_status leaderboard].freeze
    SERVICE = %w[open_tickets activities_this_week inactive_assets tickets_by_priority activity_trend leaderboard].freeze

    class << self
      def for(profile)
        record = DashboardConfig.find_by(user_id: profile.id, is_default: true)
        return record if record

        Current.set(profile:) do
          DashboardConfig.create!(user: profile, name: "My Dashboard", is_default: true,
            widgets: default_widgets(profile).map { |key| {"type" => key, "visible" => true} })
        end
      end

      def visible_keys(record)
        Array(record.widgets).filter_map do |widget|
          widget = widget.to_h.stringify_keys
          widget["type"] if widget.fetch("visible", true)
        end
      end

      def update(profile:, selected:)
        record = self.for(profile)
        selected = Array(selected) & WIDGETS
        Current.set(profile:) do
          record.update!(widgets: WIDGETS.map { |key| {"type" => key, "visible" => key.in?(selected)} })
        end
        Result.success(record, code: :updated)
      rescue StandardError => error
        ErrorMapper.call(error)
      end

      private

      def default_widgets(profile)
        return WIDGETS if profile.role.name.in?(%w[Admin Manager])

        groups = Array(profile.role.ribbon_items)
        return SERVICE if groups.include?("service") && !groups.include?("crm")
        return SALES if groups.include?("crm") && !groups.include?("service")

        WIDGETS
      end
    end
  end
end
