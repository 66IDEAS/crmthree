# frozen_string_literal: true

require "test_helper"

class SalesWorkflowsTest < ActiveSupport::TestCase
  setup do
    seed_crm!
    @owner = create_profile(email: "sales-owner@example.com")
    @account = create_account(owner: @owner, name: "Alpine Signal AG")
    @identity = identity(@owner)
    @stage = PipelineStage.find_by!(name: "Qualification")
    @product = Current.set(profile: @owner) do
      Product.create!(name: "Revenue Insights", unit_of_measure: "EA", base_price: 250, currency: "CHF",
        product_type: "License", status: "Active")
    end
  end

  test "lead scoring and status transitions follow the qualification lifecycle" do
    lead = create_lead

    Current.set(profile: @owner) do
      lead.update!(status: "Contacted", score: 60)
      lead.update!(status: "Qualified", score: 85)
    end
    assert_equal "qualified", lead.status

    Current.set(profile: @owner) { lead.update(status: "New") }
    assert_includes lead.errors[:status], "cannot change from Qualified to New"

    lead.score = 101
    refute lead.valid?
    assert_includes lead.errors[:score], "must be in 0..100"
  end

  test "lead conversion is atomic idempotent and inherits ownership" do
    lead = create_lead
    converter = Crm::Sales::LeadConverter.new(
      lead_id: lead.id,
      account_name: "Northstar Robotics",
      create_opportunity: true,
      opportunity_name: "Northstar expansion",
      idempotency_key: "lead-conversion-1",
      identity: @identity
    )

    assert_difference ["Account.count", "Contact.count", "Opportunity.count", "OpportunityContact.count"], 1 do
      @result = converter.call
    end

    assert @result.success?, @result.errors.to_sentence
    lead.reload
    assert lead.converted?
    assert lead.converted_at.present?
    assert_equal @owner.id, lead.converted_account.owner_id
    assert_equal @owner.id, lead.converted_contact.owner_id
    assert_equal @owner.id, lead.converted_opportunity.owner_id
    assert_equal lead.id, lead.converted_opportunity.lead_id
    assert_equal lead.converted_contact.id, lead.converted_opportunity.contacts.first.id

    assert_no_difference ["Account.count", "Contact.count", "Opportunity.count"] do
      replay = converter.call
      assert replay.success?
      assert_equal :idempotent_replay, replay.code
      assert_equal lead.converted_opportunity_id, replay.value.fetch("target_id")
    end
  end

  test "failed lead conversion rolls back every business record" do
    lead = create_lead
    counts = [Account.count, Contact.count, Opportunity.count]
    result = Crm::Sales::LeadConverter.new(
      lead_id: lead.id,
      account_name: "Rollback Industries",
      create_opportunity: true,
      opportunity_name: "x" * 121,
      idempotency_key: "lead-conversion-invalid",
      identity: @identity
    ).call

    assert result.failure?
    assert_equal counts, [Account.count, Contact.count, Opportunity.count]
    refute lead.reload.converted?
  end

  test "pipeline stages set probability result close date and publish a stage event" do
    opportunity = create_opportunity
    won = PipelineStage.find_by!(name: "Closed Won")
    events = []
    Crm::DomainEvents.subscribe { |event| events << event }

    Current.set(profile: @owner) { opportunity.update!(stage: won) }

    opportunity.reload
    assert_equal 100, opportunity.probability
    assert_equal "won", opportunity.result
    assert_equal Date.current, opportunity.actual_close_date
    assert events.any? { |event| event.name == "opportunity.stage_changed" && event.record_id == opportunity.id }

    opportunity.result = "Lost"
    refute opportunity.valid?
    assert_includes opportunity.errors[:result], "must match the selected pipeline stage"

    refute Current.set(profile: @owner) { won.destroy }
    assert_includes won.errors[:base], "Pipeline stage is in use and cannot be deleted"
  end

  test "line items use scoped tens pricing math and persisted parent totals" do
    opportunity = create_opportunity
    manager = Crm::Sales::LineItemManager.new(parent_type: "Opportunity", parent_id: opportunity.id, identity: @identity)

    first = manager.create({product_id: @product.id, quantity: 2, unit_price: 250, discount_percent: 10}, idempotency_key: "line-1")
    second = manager.create({product_id: @product.id, quantity: 1.5, unit_price: 100, discount_percent: 0}, idempotency_key: "line-2")

    assert first.success?, first.errors.to_sentence
    assert second.success?, second.errors.to_sentence
    items = opportunity.line_items.reload.order(:item_number)
    assert_equal %w[000010 000020], items.pluck(:item_number)
    assert_equal BigDecimal("450"), items.first.total_price
    assert_equal BigDecimal("600"), opportunity.reload.amount

    updated = manager.update(items.first.id, {product_id: @product.id, quantity: 3, unit_price: 200, discount_percent: 25})
    assert updated.success?, updated.errors.to_sentence
    assert_equal BigDecimal("450"), updated.value.reload.total_price
    assert_equal BigDecimal("600"), opportunity.reload.amount

    deleted = manager.destroy(items.second.id)
    assert deleted.success?, deleted.errors.to_sentence
    assert_equal BigDecimal("450"), opportunity.reload.amount
  end

  test "document conversion maps origins copies line items and remains idempotent" do
    opportunity = create_opportunity
    line_manager = Crm::Sales::LineItemManager.new(parent_type: "Opportunity", parent_id: opportunity.id, identity: @identity)
    line_manager.create({product_id: @product.id, quantity: 4, unit_price: 250, discount_percent: 10}, idempotency_key: "journey-line")

    quote_result = convert(opportunity, "Quotation", "quote-key")
    quote = Quotation.find(quote_result.value.fetch("target_id"))
    assert_equal opportunity.id, quote.opportunity_id
    assert_equal 1, quote.line_items.count
    assert_equal BigDecimal("900"), quote.total_amount

    replay = convert(opportunity, "Quotation", "quote-key")
    assert_equal :idempotent_replay, replay.code
    assert_equal quote.id, replay.value.fetch("target_id")

    direct_order_result = convert(opportunity, "SalesOrder", "direct-order-key")
    direct_order = SalesOrder.find(direct_order_result.value.fetch("target_id"))
    assert_equal opportunity.id, direct_order.opportunity_id
    assert_nil direct_order.quotation_id
    assert_equal BigDecimal("900"), direct_order.total_amount

    order_result = convert(quote, "SalesOrder", "order-key")
    order = SalesOrder.find(order_result.value.fetch("target_id"))
    assert_equal quote.id, order.quotation_id
    assert_equal opportunity.id, order.opportunity_id
    assert_equal quote.line_items.pluck(:item_number), order.line_items.pluck(:item_number)

    invoice_result = convert(order, "Invoice", "invoice-key")
    invoice = Invoice.find(invoice_result.value.fetch("target_id"))
    assert_equal order.id, invoice.sales_order_id
    assert_equal BigDecimal("900"), invoice.total_amount
    assert_equal Date.current, invoice.invoice_date
    assert_equal 30.days.from_now.to_date, invoice.due_date
  end

  test "document conversion rolls its target back when a copied line is invalid" do
    opportunity = create_opportunity
    Crm::Sales::LineItemManager.new(parent_type: "Opportunity", parent_id: opportunity.id, identity: @identity)
      .create({product_id: @product.id, quantity: 1, unit_price: 250, discount_percent: 0}, idempotency_key: "rollback-line")
    invalid_converter = Class.new(Crm::Sales::DocumentConverter) do
      private

      def copied_line_attributes(line_item, target)
        super.merge(quantity: 0)
      end
    end

    assert_no_difference ["Quotation.count", "LineItem.count"] do
      result = invalid_converter.new(source_type: "Opportunity", source_id: opportunity.id, target_type: "Quotation",
        idempotency_key: "invalid-copy", identity: @identity).call
      assert result.failure?
      assert_equal :validation_failed, result.code
    end
  end

  test "repricing cannot reduce an invoice below its paid amount" do
    invoice = Current.set(profile: @owner) do
      Invoice.create!(account: @account, status: "Draft", invoice_date: Date.current,
        due_date: 30.days.from_now.to_date, paid_amount: 0, currency: "CHF", owner: @owner)
    end
    manager = Crm::Sales::LineItemManager.new(parent_type: "Invoice", parent_id: invoice.id, identity: @identity)
    created = manager.create({product_id: @product.id, quantity: 2, unit_price: 500, discount_percent: 0},
      idempotency_key: "paid-invoice-line")
    line_item = invoice.line_items.find(created.value.fetch("line_item_id"))
    Current.set(profile: @owner) { invoice.reload.update!(paid_amount: 1_000, status: "Paid") }

    result = manager.update(line_item.id, {product_id: @product.id, quantity: 1, unit_price: 500, discount_percent: 0})

    assert result.failure?
    assert_includes result.errors, "Line-item total cannot be lower than the amount already paid"
    assert_equal BigDecimal("1000"), line_item.reload.total_price
    assert_equal BigDecimal("1000"), invoice.reload.total_amount
    assert_equal BigDecimal("1000"), invoice.paid_amount
  end

  private

  def create_lead
    Current.set(profile: @owner) do
      Lead.create!(first_name: "Ada", last_name: "Lovelace", company: "Analytical Engines", email: "ada@example.com",
        source: "Referral", status: "New", score: 40, owner: @owner)
    end
  end

  def create_opportunity
    Current.set(profile: @owner) do
      Opportunity.create!(name: "Alpine rollout", account: @account, stage: @stage, currency: "CHF", owner: @owner, result: "Open")
    end
  end

  def convert(source, target, key)
    result = Crm::Sales::DocumentConverter.new(source_type: source.class.name, source_id: source.id,
      target_type: target, idempotency_key: key, identity: @identity).call
    assert result.success?, result.errors.to_sentence
    result
  end
end
