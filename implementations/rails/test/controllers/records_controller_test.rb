# frozen_string_literal: true

require "test_helper"

class RecordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    seed_crm!
    @owner_auth = AuthUser.create!(email: "web-owner@example.com", password: "correct-horse-battery")
    @owner = create_profile(email: @owner_auth.email, auth_uid: @owner_auth.id)
    @other = create_profile(email: "web-other@example.com")
    @owned = create_account(owner: @owner, name: "Owned web account")
    @unrelated = create_account(owner: @other, name: "Private web account")
    post session_path, params: {email: @owner_auth.email, password: "correct-horse-battery"}
  end

  test "redirects a guest to local sign in" do
    delete session_path
    get root_path

    assert_redirected_to new_session_path
  end

  test "reads an owned record through the authorized router" do
    get record_path(object_type: "Account", id: @owned.id), as: :json

    assert_response :success
    assert_equal @owned.id, response.parsed_body.fetch("id")
  end

  test "renders metadata-driven list detail and form pages" do
    get records_path(object_type: "Account")
    assert_response :success
    assert_select "h1", "Accounts"
    assert_select "table.data-table"
    assert_includes response.body, "Owned web account"

    get new_record_path(object_type: "Account")
    assert_response :success
    assert_select "label", text: /Primary name/
    assert_select "select[name='record[owner_id]']"

    get record_path(object_type: "Account", id: @owned.id)
    assert_response :success
    assert_select "h1", "Owned web account"
    assert_select ".detail-panel"
    assert_select ".linked-card"
  end

  test "creates and inline-updates a generic record" do
    assert_difference "Account.count", 1 do
      post records_path(object_type: "Account"), params: {record: {name1: "Created in browser", status: "Active"}}
    end
    created = Account.find_by!(name1: "Created in browser")
    assert_redirected_to record_path(object_type: "Account", id: created.id)
    assert_equal @owner.id, created.owner_id

    patch record_path(object_type: "Account", id: created.id), params: {
      record: {city: "Zurich"}, return_to: records_path(object_type: "Account")
    }
    assert_redirected_to records_path(object_type: "Account")
    assert_equal "Zurich", created.reload.city
  end

  test "uses a manifest enum named type without Rails STI" do
    activity = Current.set(profile: @owner) do
      Activity.create!(type: "Task", subject: "Follow up", status: "Planned", owner: @owner)
    end

    assert_instance_of Activity, activity
    assert_equal "task", activity.type
    assert_equal "Task", activity.read_attribute_before_type_cast("type")
  end

  test "renders foundational CRM forms and records through the generic framework" do
    records = Current.set(profile: @owner) do
      contact = Contact.create!(first_name: "Katherine", last_name: "Johnson", account: @owned, owner: @owner, status: "Active")
      product = Product.create!(name: "Launch planning", unit_of_measure: "EA", product_type: "Service", status: "Active")
      [
        @owned,
        contact,
        ContactAccount.create!(contact: contact, account: @owned, role: "Analyst", is_primary: true),
        product,
        PricebookEntry.create!(product: product, account: @owned, price: 125, currency: "USD", active: true),
        PipelineStage.create!(name: "Qualified", sort_order: 1, is_closed: false, is_won: false, active: true),
        Activity.create!(type: "Meeting", subject: "Planning", account: @owned, owner: @owner, status: "Planned"),
        Document.create!(name: "Plan.pdf", file_path: "/local/plan.pdf", parent: @owned, uploader: @owner),
        Comment.create!(parent: @owned, content: "Ready for review", author: @owner)
      ]
    end

    records.each do |crm_record|
      get new_record_path(object_type: crm_record.class.name)
      if crm_record.is_a?(PipelineStage)
        assert_response :not_found, "pipeline stage configuration is admin-only"
      else
        assert_response :success, "new form for #{crm_record.class.name}"
      end

      get record_path(object_type: crm_record.class.name, id: crm_record.id)
      assert_response :success, "detail for #{crm_record.class.name}"
      assert_select ".detail-panel"
    end
  end

  test "a temporary manifest relationship changes rendering without page code" do
    child = create_account(owner: @owner, name: "Manifest child")
    Current.set(profile: @owner) { child.update!(parent_account: @owned) }
    fixture_manifest = Crm::ModelRegistry.manifest.deep_dup
    account_fixture = fixture_manifest.fetch("objects").fetch("Account")
    relationship = account_fixture.fetch("relationships").find { |candidate| candidate.fetch("name") == "child_accounts" }
    account_fixture["relationships"] = account_fixture.fetch("relationships") - [relationship]

    Crm::ModelRegistry.with_manifest(fixture_manifest) do
      get record_path(object_type: "Account", id: @owned.id)
      assert_response :success
      assert_select ".linked-card h2", {text: /Child accounts/, count: 0}

      account_fixture["relationships"] << relationship
      get record_path(object_type: "Account", id: @owned.id)
      assert_response :success
      assert_select ".linked-card h2", text: /Child accounts/
      assert_includes response.body, "Manifest child"
    end
  end

  test "linked record tables display reference names instead of UUIDs" do
    opportunity = Current.set(profile: @owner) do
      Opportunity.create!(
        name: "Reference label check",
        account: @owned,
        stage: PipelineStage.find_by!(name: "Qualification"),
        result: "Open",
        owner: @owner
      )
    end

    get record_path(object_type: "Account", id: @owned.id)

    assert_response :success
    opportunity_card = css_select(".linked-card").find { |card| card.at_css("h2")&.text&.include?("Opportunities") }
    assert opportunity_card, "expected an Opportunities linked-record card"
    assert_includes opportunity_card.text, @owned.name1
    refute_includes opportunity_card.text, @owned.id
    assert_includes opportunity_card.text, opportunity.name
  end

  test "invoice line items show commercial fields and hide parent internals" do
    invoice, product, line_item = Current.set(profile: @owner) do
      product = Product.create!(
        name: "CRM Consulting",
        unit_of_measure: "EA",
        currency: "CHF",
        product_type: "Service",
        status: "Active"
      )
      invoice = Invoice.create!(
        account: @owned,
        status: "Draft",
        invoice_date: Date.current,
        due_date: 30.days.from_now.to_date,
        currency: "CHF",
        owner: @owner
      )
      line_item = LineItem.create!(
        parent: invoice,
        product: product,
        quantity: 2,
        unit_price: 125,
        discount_percent: 10,
        total_price: 225,
        unit_of_measure: "EA"
      )
      [invoice, product, line_item]
    end

    get record_path(object_type: "Invoice", id: invoice.id)

    assert_response :success
    line_items_card = css_select(".linked-card").find { |card| card.at_css("h2")&.text&.include?("Line items") }
    assert line_items_card, "expected a Line items linked-record card"
    assert_equal ["Item #", "Product", "Quantity", "Net price", "Discount %", "Net value", "Actions"],
      line_items_card.css("th").map { |header| header.text.strip }
    assert_includes line_items_card.text, product.name
    assert_includes line_items_card.text, LineItem.crm_display_number(line_item.item_number)
    assert_equal "125.0", line_items_card.at_css("input[name='line_item[unit_price]']")["value"]
    assert_includes line_items_card.text, "CHF 225"
    refute_includes line_items_card.text, invoice.id
    refute_includes line_items_card.text, "Parent type"
  end

  test "user notification preferences render and edit as friendly controls" do
    Current.set(profile: @owner) do
      @owner.update!(notification_preferences: {"desktop" => true, "email" => false})
    end

    get record_path(object_type: "UserProfile", id: @owner.id)

    assert_response :success
    assert_select ".preference-status", count: 2
    assert_select ".preference-status", text: /Desktop\s*On/
    assert_select ".preference-status", text: /Email\s*Off/
    assert_select ".detail-field pre", {text: /desktop/, count: 0}

    get edit_record_path(object_type: "UserProfile", id: @owner.id)

    assert_response :success
    assert_select "input[name='record[notification_preferences][desktop]'][type='checkbox'][checked]"
    assert_select "input[name='record[notification_preferences][email]'][type='checkbox']:not([checked])"

    patch record_path(object_type: "UserProfile", id: @owner.id), params: {
      record: {notification_preferences: {desktop: "false", email: "true"}}
    }

    assert_redirected_to record_path(object_type: "UserProfile", id: @owner.id)
    assert_equal({"desktop" => false, "email" => true}, @owner.reload.notification_preferences)
  end

  test "conceals an unrelated record on a direct URL" do
    get record_path(object_type: "Account", id: @unrelated.id), as: :json

    assert_response :not_found
    refute_includes response.body, "Private web account"
  end

  test "denies unrelated HTML and Turbo mutations without changing the record" do
    patch record_path(object_type: "Account", id: @unrelated.id),
      params: {record: {name1: "Stolen"}}, headers: {"Accept" => "text/vnd.turbo-stream.html"}

    assert_response :not_found
    assert_equal "Private web account", @unrelated.reload.name1
  end

  test "denies direct file and stream capability URLs" do
    %w[file stream].each do |capability|
      get record_capability_path(object_type: "Account", id: @unrelated.id, capability: capability), as: :json
      assert_response :not_found
    end
  end

  test "sends restrictive browser security headers" do
    get root_path

    assert_response :success
    assert_includes response.headers.fetch("Content-Security-Policy"), "default-src 'self'"
    assert_equal "SAMEORIGIN", response.headers["X-Frame-Options"]
  end
end
