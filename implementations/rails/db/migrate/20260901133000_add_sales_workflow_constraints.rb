# frozen_string_literal: true

class AddSalesWorkflowConstraints < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :leads, "score IS NULL OR score BETWEEN 0 AND 100", name: "chk_leads_score_range"
    add_check_constraint :opportunities, "probability IS NULL OR probability BETWEEN 0 AND 100", name: "chk_opportunities_probability_range"
    add_check_constraint :pipeline_stages,
      "(default_probability IS NULL OR default_probability BETWEEN 0 AND 100) AND NOT (is_won = 1 AND is_closed = 0)",
      name: "chk_pipeline_stages_probability_and_result"
    add_check_constraint :line_items, "quantity > 0", name: "chk_line_items_quantity_positive"
    add_check_constraint :line_items, "unit_price >= 0", name: "chk_line_items_unit_price_nonnegative"
    add_check_constraint :line_items,
      "discount_percent IS NULL OR discount_percent BETWEEN 0 AND 100",
      name: "chk_line_items_discount_range"
    add_check_constraint :line_items, "total_price IS NULL OR total_price >= 0", name: "chk_line_items_total_nonnegative"
    add_check_constraint :invoices, "paid_amount IS NULL OR paid_amount >= 0", name: "chk_invoices_paid_nonnegative"
    add_check_constraint :invoices,
      "paid_amount IS NULL OR total_amount IS NULL OR paid_amount <= total_amount",
      name: "chk_invoices_paid_not_above_total"
  end
end
