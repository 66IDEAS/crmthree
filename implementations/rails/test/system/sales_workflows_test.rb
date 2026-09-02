# frozen_string_literal: true

require "application_system_test_case"

class SalesWorkflowsSystemTest < ApplicationSystemTestCase
  setup do
    page.current_window.resize_to(1440, 900)
    Rails.cache.clear
    seed_crm!
    @auth = AuthUser.create!(email: "sales-system-admin@example.com", password: "correct-horse-battery")
    @admin = create_profile(email: @auth.email, auth_uid: @auth.id, role: Role.find_by!(name: "Admin"))
    @product = Current.set(profile: @admin) do
      Product.create!(name: "CRM Transformation Package", unit_of_measure: "EA", base_price: 500,
        currency: "CHF", product_type: "Service", status: "Active")
    end
    @lead = Current.set(profile: @admin) do
      Lead.create!(first_name: "Katherine", last_name: "Johnson", company: "Orbital Analytics",
        email: "katherine@orbital.example", source: "Referral", status: "New", score: 90, owner: @admin)
    end
  end

  test "complete lead to invoice journey with inline pricing and conversions" do
    sign_in_as(@auth)
    visit record_path(object_type: "Lead", id: @lead.id)

    within(".record-actions") { click_button "Convert Lead" }
    within("dialog[open]") do
      check "Create an opportunity"
      fill_in "Account name", with: "Orbital Analytics AG"
      fill_in "Opportunity name", with: "Orbital CRM transformation"
      click_button "Convert"
    end

    assert_text "Lead converted successfully"
    assert_text "Orbital CRM transformation"
    opportunity = @lead.reload.converted_opportunity

    within(".line-items-card") do
      click_button "Add new"
      within(".line-item-new-row") do
        find("select[data-field='product']").select(@product.name)
        find("input[data-field='quantity']").fill_in(with: "2")
        find("input[data-field='discount']").fill_in(with: "10")
        assert_equal "900", find("[data-line-items-target~='value']")["data-raw-value"]
        click_button "Add"
      end
    end

    assert_text "Line item added"
    assert_equal BigDecimal("900"), opportunity.reload.amount
    capture_line_items("phase3-opportunity.png") if ENV["PHASE3_SCREENSHOTS"]
    quote = convert_visible_document("Create Quotation", Quotation)
    assert_equal opportunity.id, quote.opportunity_id
    assert_equal BigDecimal("900"), quote.total_amount

    order = convert_visible_document("Create Sales Order", SalesOrder)
    assert_equal quote.id, order.quotation_id
    assert_equal BigDecimal("900"), order.total_amount

    invoice = convert_visible_document("Create Invoice", Invoice)
    assert_equal order.id, invoice.sales_order_id
    assert_equal BigDecimal("900"), invoice.total_amount
    assert_text "Orbital Analytics AG"
    assert_selector ".line-items-card tbody tr:not(.line-item-new-row)[data-line-items-target~='row']", count: 1
    capture_line_items("phase3-invoice.png") if ENV["PHASE3_SCREENSHOTS"]

    audited_types = AuditLog.where(object_id: [opportunity.id, quote.id, order.id, invoice.id]).distinct.pluck(:object_type)
    assert_includes audited_types, "Opportunity"
    assert_includes audited_types, "Quotation"
    assert_includes audited_types, "SalesOrder"
    assert_includes audited_types, "Invoice"
  end

  private

  def capture_line_items(filename)
    line_items = find(".line-items-card")
    page.execute_script("arguments[0].scrollIntoView({ block: 'center' })", line_items.native)
    save_screenshot(Rails.root.join("tmp/screenshots", filename))
  end

  def convert_visible_document(button_label, model)
    previous_ids = model.pluck(:id)
    within(".record-actions") { click_button button_label }
    within("dialog[open]") { click_button button_label }
    assert_text "#{model.name.underscore.humanize} created successfully", wait: 5
    model.where.not(id: previous_ids).order(:created_at).last!
  end
end
