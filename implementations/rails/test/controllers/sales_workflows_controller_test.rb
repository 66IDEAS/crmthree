# frozen_string_literal: true

require "test_helper"

class SalesWorkflowsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    seed_crm!
    @auth = AuthUser.create!(email: "sales-web@example.com", password: "correct-horse-battery")
    @owner = create_profile(email: @auth.email, auth_uid: @auth.id)
    @account = create_account(owner: @owner, name: "Web Sales AG")
    @lead = Current.set(profile: @owner) do
      Lead.create!(first_name: "Grace", last_name: "Hopper", company: "Compiler Works", email: "grace@example.com",
        source: "Web", status: "New", score: 72, owner: @owner)
    end
    @product = Current.set(profile: @owner) do
      Product.create!(name: "Compiler Cloud", unit_of_measure: "EA", base_price: 500, currency: "CHF",
        product_type: "Subscription", status: "Active")
    end
    @opportunity = Current.set(profile: @owner) do
      Opportunity.create!(name: "Web sales journey", account: @account,
        stage: PipelineStage.find_by!(name: "Qualification"), currency: "CHF", owner: @owner, result: "Open")
    end
    post session_path, params: {email: @auth.email, password: "correct-horse-battery"}
  end

  test "lead detail renders quick activities and a prefilled conversion dialog" do
    get record_path(object_type: "Lead", id: @lead.id)

    assert_response :success
    assert_select ".quick-action-bar", text: /Log Call/
    assert_select ".quick-action-bar", text: /New Task/
    assert_select "dialog h2", "Convert Lead"
    assert_select "input[name='conversion[account_name]'][value='Compiler Works']"
    assert_select "input[name='conversion[opportunity_name]'][value='Grace Hopper']"
  end

  test "lead conversion redirects to the opportunity and presents converted records" do
    assert_difference ["Account.count", "Contact.count", "Opportunity.count"], 1 do
      post lead_conversion_path(lead_id: @lead.id), params: {conversion: {
        account_name: "Compiler Works GmbH", create_opportunity: "1", opportunity_name: "Compiler renewal",
        idempotency_key: "web-lead-conversion"
      }}
    end

    opportunity = @lead.reload.converted_opportunity
    assert_redirected_to record_path(object_type: "Opportunity", id: opportunity.id)

    get record_path(object_type: "Lead", id: @lead.id)
    assert_response :success
    assert_select ".conversion-summary", text: /Compiler Works GmbH/
    assert_select "button[disabled]", text: /Convert Lead/
    assert_select "dialog h2", {text: "Convert Lead", count: 0}
  end

  test "inline line-item endpoints create update and remove rows on the parent" do
    assert_difference "LineItem.count", 1 do
      post line_items_path(parent_type: "Opportunity", parent_id: @opportunity.id), params: {
        idempotency_key: "web-line-create",
        line_item: {product_id: @product.id, quantity: 2, unit_price: 500, discount_percent: 10}
      }
    end
    assert_redirected_to record_path(object_type: "Opportunity", id: @opportunity.id)
    item = @opportunity.line_items.first
    assert_equal "000010", item.item_number
    assert_equal BigDecimal("900"), @opportunity.reload.amount

    patch line_item_path(parent_type: "Opportunity", parent_id: @opportunity.id, id: item.id), params: {
      line_item: {product_id: @product.id, quantity: 3, unit_price: 400, discount_percent: 0}
    }
    assert_redirected_to record_path(object_type: "Opportunity", id: @opportunity.id)
    assert_equal BigDecimal("1200"), item.reload.total_price

    assert_difference "LineItem.count", -1 do
      delete line_item_path(parent_type: "Opportunity", parent_id: @opportunity.id, id: item.id)
    end
    assert_equal BigDecimal("0"), @opportunity.reload.amount
  end

  test "opportunity detail renders inline line items and document dialogs" do
    Current.set(profile: @owner) do
      LineItem.create!(parent: @opportunity, product: @product, quantity: 1, unit_price: 500, discount_percent: 0)
    end

    get record_path(object_type: "Opportunity", id: @opportunity.id)

    assert_response :success
    assert_select ".line-items-card"
    assert_select ".line-items-table th", text: /Net value/
    assert_select "input[name='line_item[quantity]']"
    assert_equal ["Create Quotation from Opportunity", "Create Sales Order from Opportunity"],
      css_select("dialog h2").map { |heading| heading.text.strip }
    assert_select ".quick-action-bar", text: /Create Quotation/
  end

  test "document conversion endpoint copies line items and redirects to the target" do
    Current.set(profile: @owner) do
      LineItem.create!(parent: @opportunity, product: @product, quantity: 2, unit_price: 500, discount_percent: 5)
    end

    assert_difference "Quotation.count", 1 do
      post document_conversion_path(source_type: "Opportunity", source_id: @opportunity.id, target_type: "Quotation"),
        params: {conversion: {idempotency_key: "web-quote"}}
    end

    quote = Quotation.order(:created_at).last
    assert_redirected_to record_path(object_type: "Quotation", id: quote.id)
    assert_equal @opportunity.id, quote.opportunity_id
    assert_equal BigDecimal("950"), quote.total_amount
    assert_equal 1, quote.line_items.count

    get record_path(object_type: "Quotation", id: quote.id)
    assert_response :success
    assert_select "h1", "#{Quotation.crm_display_number(quote.quotation_number)} (#{@account.name1})"
  end

  test "changing the pipeline stage derives and audits the commercial outcome" do
    won_stage = PipelineStage.find_by!(name: "Closed Won")
    events = []
    Crm::DomainEvents.subscribe { |event| events << event }

    patch record_path(object_type: "Opportunity", id: @opportunity.id), params: {record: {
      stage_id: won_stage.id, loss_reason: ""
    }}

    assert_redirected_to record_path(object_type: "Opportunity", id: @opportunity.id)
    @opportunity.reload
    assert_equal "won", @opportunity.result
    assert_equal 100, @opportunity.probability
    assert_equal Date.current, @opportunity.actual_close_date
    audited_fields = AuditLog.where(object_type: "Opportunity", object_id: @opportunity.id, action: "Update").pluck(:field_name)
    assert_includes audited_fields, "stage_id"
    assert_includes audited_fields, "result"
    assert_includes audited_fields, "probability"
    assert events.any? { |event| event.name == "opportunity.stage_changed" && event.record_id == @opportunity.id }
  end

  test "contextual activity form hides and preserves its parent context" do
    get new_record_path(object_type: "Activity", activity_type: "Call", parent_field: "opportunity_id",
      parent_id: @opportunity.id, context_label: @opportunity.name,
      return_to: record_path(object_type: "Opportunity", id: @opportunity.id))

    assert_response :success
    assert_select "input[name='activity_type'][value='Call']"
    assert_select "select[name='record[type]']", count: 0
    assert_select "select[name='record[opportunity_id]']", count: 0
    assert_select "input[name='record[subject]'][value='Call: Web sales journey']"

    assert_difference "Activity.count", 1 do
      post records_path(object_type: "Activity"), params: {
        activity_type: "Call", parent_field: "opportunity_id", parent_id: @opportunity.id,
        return_to: record_path(object_type: "Opportunity", id: @opportunity.id),
        record: {subject: "Discovery follow-up", status: "Planned", priority: "Medium"}
      }
    end
    activity = Activity.order(:created_at).last
    assert_equal "call", activity.type
    assert_equal @opportunity.id, activity.opportunity_id
    assert_redirected_to record_path(object_type: "Opportunity", id: @opportunity.id)
  end

  test "an unrelated user cannot invoke a sales conversion URL" do
    other_auth = AuthUser.create!(email: "sales-intruder@example.com", password: "correct-horse-battery")
    create_profile(email: other_auth.email, auth_uid: other_auth.id)
    delete session_path
    post session_path, params: {email: other_auth.email, password: "correct-horse-battery"}

    assert_no_difference ["Account.count", "Contact.count", "Opportunity.count"] do
      post lead_conversion_path(lead_id: @lead.id), params: {conversion: {
        account_name: "Stolen", create_opportunity: "1", opportunity_name: "Stolen", idempotency_key: "denied"
      }}
    end
    assert_response :not_found
    refute @lead.reload.converted?

    assert_no_difference "Quotation.count" do
      post document_conversion_path(source_type: "Opportunity", source_id: @opportunity.id, target_type: "Quotation"),
        params: {conversion: {idempotency_key: "denied-quote"}}
    end
    assert_response :not_found

    assert_no_difference "LineItem.count" do
      post line_items_path(parent_type: "Opportunity", parent_id: @opportunity.id), params: {
        idempotency_key: "denied-line",
        line_item: {product_id: @product.id, quantity: 1, unit_price: 1, discount_percent: 0}
      }
    end
    assert_response :not_found
  end

  test "sales endpoints reject model names outside their explicit allowlists" do
    assert_no_difference ["Quotation.count", "LineItem.count"] do
      post document_conversion_path(source_type: "UserProfile", source_id: @owner.id, target_type: "Quotation"),
        params: {conversion: {idempotency_key: "invalid-source-model"}}
      assert_response :not_found

      post line_items_path(parent_type: "UserProfile", parent_id: @owner.id), params: {
        idempotency_key: "invalid-parent-model",
        line_item: {product_id: @product.id, quantity: 1, unit_price: 1, discount_percent: 0}
      }
      assert_response :not_found
    end
  end
end
