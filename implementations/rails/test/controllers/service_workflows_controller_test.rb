# frozen_string_literal: true

require "test_helper"

class ServiceWorkflowsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    seed_crm!
    @auth = AuthUser.create!(email: "service-web-admin@example.com", password: "correct-horse-battery")
    @admin = create_profile(email: @auth.email, auth_uid: @auth.id, role: Role.find_by!(name: "Admin"))
    @agent_auth = AuthUser.create!(email: "service-web-agent@example.com", password: "correct-horse-battery")
    @agent = create_profile(email: @agent_auth.email, auth_uid: @agent_auth.id)
    @unrelated_auth = AuthUser.create!(email: "service-web-unrelated@example.com", password: "correct-horse-battery")
    @unrelated = create_profile(email: @unrelated_auth.email, auth_uid: @unrelated_auth.id)
    @account = create_account(owner: @admin, name: "Web Service AG")
    @sla = Current.set(profile: @admin) do
      SLA.create!(name: "Web Critical", response_time_hours: 1, resolution_time_hours: 8,
        applies_to_priorities: ["Critical"], business_hours_only: false, active: true)
    end
    @ticket = Current.set(profile: @admin) do
      Ticket.create!(subject: "Customer portal authentication fails", status: TicketStatus.find_by!(name: "New"),
        priority: "Critical", category: "Access", account: @account, assignee: @agent, owner: @admin)
    end
    sign_in(@auth)
  end

  test "settings renders and creates ticket statuses and SLA rules" do
    get settings_path

    assert_response :success
    assert_select ".settings-section h2", text: "Ticket statuses"
    assert_select ".settings-section h2", text: "Service level agreements"
    assert_select "a", text: /Add status/
    assert_select "a", text: /Add SLA/
    assert_includes response.body, "Web Critical"

    assert_difference "TicketStatus.count", 1 do
      post records_path(object_type: "TicketStatus"), params: {
        return_to: settings_path,
        record: {name: "Customer Validation", sort_order: 35, is_resolved: "0", is_closed: "0", active: "1"}
      }
    end
    assert_redirected_to settings_path

    assert_difference "SLA.count", 1 do
      post records_path(object_type: "SLA"), params: {
        return_to: settings_path,
        record: {name: "Priority Plus", response_time_hours: 2, resolution_time_hours: 12,
          applies_to_priorities: ["High", "Critical"], business_hours_only: "1", active: "1"}
      }
    end
    created = SLA.find_by!(name: "Priority Plus")
    assert_equal %w[High Critical], created.applies_to_priorities
    assert created.business_hours_only?
  end

  test "ticket forms use active status choices and hide derived timestamps" do
    inactive = Current.set(profile: @admin) do
      TicketStatus.create!(name: "Legacy", sort_order: 90, is_resolved: false, is_closed: false, active: false)
    end

    get new_record_path(object_type: "Ticket")

    assert_response :success
    assert_select "select[name='record[status_id]'] option[value='#{inactive.id}']", count: 0
    assert_select "select[name='record[status_id]'] option", text: "New"
    %w[sla_response_deadline sla_resolution_deadline first_response_at resolved_at closed_at].each do |field|
      assert_select "[name='record[#{field}]']", count: 0
    end
  end

  test "ticket detail shows SLA state and lifecycle updates derive timestamps" do
    get record_path(object_type: "Ticket", id: @ticket.id)
    assert_response :success
    assert_select ".sla-card", text: /Web Critical/
    assert_select ".sla-card", text: /Within target/
    assert_select "button[disabled]", text: /Create Knowledge Article/

    patch record_path(object_type: "Ticket", id: @ticket.id), params: {record: {
      status_id: TicketStatus.find_by!(name: "In Progress").id,
      closed_at: 1.year.ago
    }}
    assert_redirected_to record_path(object_type: "Ticket", id: @ticket.id)
    assert @ticket.reload.first_response_at
    assert_nil @ticket.closed_at

    patch record_path(object_type: "Ticket", id: @ticket.id), params: {record: {
      status_id: TicketStatus.find_by!(name: "Resolved").id,
      resolution: "Reset the identity provider metadata and verified sign-in."
    }}
    assert @ticket.reload.resolved_at
    assert AuditLog.where(object_type: "Ticket", object_id: @ticket.id, field_name: "status_id").exists?
  end

  test "resolved ticket conversion opens one draft article for editing" do
    Current.set(profile: @admin) do
      @ticket.update!(status: TicketStatus.find_by!(name: "Resolved"), resolution: "Replaced expired signing metadata.")
    end

    assert_difference ["KnowledgeArticle.count", "TicketKnowledgeArticle.count"], 1 do
      post ticket_knowledge_conversion_path(ticket_id: @ticket.id), params: {
        conversion: {idempotency_key: "web-case-conversion"}
      }
    end

    article = @ticket.knowledge_articles.find_by!(source: "Case Conversion")
    assert_redirected_to edit_record_path(object_type: "KnowledgeArticle", id: article.id,
      return_to: record_path(object_type: "Ticket", id: @ticket.id))
    assert article.status_draft?
    assert_equal @admin, article.author

    assert_no_difference "KnowledgeArticle.count" do
      post ticket_knowledge_conversion_path(ticket_id: @ticket.id), params: {
        conversion: {idempotency_key: "second-browser-submit"}
      }
    end
  end

  test "knowledge details track views and helpful feedback" do
    article = Current.set(profile: @admin) do
      KnowledgeArticle.create!(title: "Restore portal access", content: "Refresh the provider metadata.",
        category: "Access", status: "Published", source: "Manual", author: @admin,
        views_count: 0, helpful_count: 0)
    end

    get record_path(object_type: "KnowledgeArticle", id: article.id)
    assert_response :success
    assert_equal 1, article.reload.views_count
    assert_select ".knowledge-feedback", text: /Helpful · 0/

    assert_difference -> { article.reload.helpful_count }, 1 do
      post knowledge_article_helpful_path(knowledge_article_id: article.id)
    end
    assert_redirected_to record_path(object_type: "KnowledgeArticle", id: article.id)
  end

  test "knowledge search returns published articles and the user's drafts without leaking other drafts" do
    published = create_article(author: @unrelated, title: "Telemetry recovery published", status: "Published")
    own_draft = create_article(author: @agent, title: "Telemetry recovery draft", status: "Draft")
    hidden_draft = create_article(author: @unrelated, title: "Telemetry recovery private", status: "Draft")
    sign_in(@agent_auth)

    get records_path(object_type: "KnowledgeArticle", q: "Telemetry recovery")

    assert_response :success
    assert_includes response.body, published.title
    assert_includes response.body, own_draft.title
    refute_includes response.body, hidden_draft.title
    assert_select "input[name='q'][value='Telemetry recovery']"
  end

  test "an assignee can open a ticket but an unrelated user cannot" do
    sign_in(@agent_auth)
    get record_path(object_type: "Ticket", id: @ticket.id)
    assert_response :success

    sign_in(@unrelated_auth)
    get record_path(object_type: "Ticket", id: @ticket.id)
    assert_response :not_found

    assert_no_difference "KnowledgeArticle.count" do
      post ticket_knowledge_conversion_path(ticket_id: @ticket.id), params: {
        conversion: {idempotency_key: "unrelated-conversion"}
      }
    end
    assert_response :not_found
  end

  test "non-admin users cannot mutate service configuration through direct URLs" do
    sign_in(@agent_auth)

    assert_no_difference ["TicketStatus.count", "SLA.count"] do
      post records_path(object_type: "TicketStatus"), params: {
        record: {name: "Injected", sort_order: 95, is_resolved: "0", is_closed: "0", active: "1"}
      }
      assert_response :not_found

      post records_path(object_type: "SLA"), params: {
        record: {name: "Injected SLA", response_time_hours: 1, resolution_time_hours: 2,
          business_hours_only: "0", active: "1"}
      }
      assert_response :not_found
    end
  end

  test "linking an existing article supplies junction metadata automatically" do
    article = create_article(author: @admin, title: "Linkable resolution", status: "Published")

    assert_difference "TicketKnowledgeArticle.count", 1 do
      post record_relationship_path(object_type: "Ticket", id: @ticket.id, relationship_name: "knowledge_articles"),
        params: {related_id: article.id}
    end

    link = TicketKnowledgeArticle.find_by!(ticket: @ticket, article:)
    assert_equal @admin, link.linker
    assert link.linked_at
  end

  private

  def sign_in(auth)
    delete session_path
    post session_path, params: {email: auth.email, password: "correct-horse-battery"}
  end

  def create_article(author:, title:, status:)
    Current.set(profile: author) do
      KnowledgeArticle.create!(title:, content: "Telemetry recovery steps and verification.", category: "Integration",
        status:, source: "Manual", author:, views_count: 0, helpful_count: 0)
    end
  end
end
