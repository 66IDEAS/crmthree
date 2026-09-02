# frozen_string_literal: true

class AddServiceWorkflowConstraints < ActiveRecord::Migration[8.1]
  def change
    add_index :ticket_statuses, :name, unique: true
    add_index :ticket_statuses, :sort_order, unique: true
    add_index :slas, :name, unique: true

    add_check_constraint :ticket_statuses, "sort_order >= 0", name: "chk_ticket_statuses_sort_order_nonnegative"
    add_check_constraint :ticket_statuses, "NOT is_closed OR is_resolved", name: "chk_ticket_statuses_closed_is_resolved"
    add_check_constraint :slas, "response_time_hours > 0", name: "chk_slas_response_positive"
    add_check_constraint :slas, "resolution_time_hours > 0", name: "chk_slas_resolution_positive"
    add_check_constraint :slas, "response_time_hours <= resolution_time_hours", name: "chk_slas_response_before_resolution"
    add_check_constraint :knowledge_articles, "views_count >= 0", name: "chk_knowledge_articles_views_nonnegative"
    add_check_constraint :knowledge_articles, "helpful_count >= 0", name: "chk_knowledge_articles_helpful_nonnegative"
    add_check_constraint :service_contracts, "end_date >= start_date", name: "chk_service_contracts_date_order"
    add_check_constraint :assets,
      "warranty_end_date IS NULL OR install_date IS NULL OR warranty_end_date >= install_date",
      name: "chk_assets_warranty_after_install"
    add_check_constraint :tickets,
      "sla_resolution_deadline IS NULL OR sla_response_deadline IS NULL OR sla_resolution_deadline >= sla_response_deadline",
      name: "chk_tickets_sla_deadline_order"
    add_check_constraint :tickets,
      "closed_at IS NULL OR resolved_at IS NOT NULL",
      name: "chk_tickets_closed_requires_resolved"
  end
end
