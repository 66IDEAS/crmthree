# frozen_string_literal: true

require "application_system_test_case"

class ServiceWorkflowsSystemTest < ApplicationSystemTestCase
  setup do
    page.current_window.resize_to(1440, 900)
    Rails.cache.clear
    seed_crm!
    @auth = AuthUser.create!(email: "service-system-admin@example.com", password: "correct-horse-battery")
    @admin = create_profile(email: @auth.email, auth_uid: @auth.id, role: Role.find_by!(name: "Admin"))
    @agent = create_profile(email: "service-system-agent@example.com")
    @account = create_account(owner: @admin, name: "Northstar Support AG")
    Current.set(profile: @admin) do
      SLA.create!(name: "Critical Response", response_time_hours: 1, resolution_time_hours: 8,
        applies_to_priorities: ["Critical"], business_hours_only: false, active: true)
    end
  end

  test "complete ticket response resolution knowledge and closure journey" do
    sign_in_as(@auth)
    visit new_record_path(object_type: "Ticket")

    fill_in "Subject", with: "Customer portal sign-in unavailable"
    find("summary", text: "Additional information").click
    fill_in "Description", with: "All customer users receive an identity-provider validation error."
    select "New", from: "Status"
    select "Critical", from: "Priority"
    fill_in "Category", with: "Access"
    select @account.name1, from: "Account"
    select Crm::RecordPresentation.display_name(@agent), from: "Assigned to"
    select Crm::RecordPresentation.display_name(@admin), from: "Owner"
    click_button "Create Ticket"

    assert_text "Ticket created"
    assert_text "Critical Response"
    assert_text "Within target"
    assert_button "Create Knowledge Article", disabled: true
    ticket = Ticket.find_by!(subject: "Customer portal sign-in unavailable")
    assert_equal @agent, ticket.assignee
    assert Notification.exists?(user: @agent, type: "TicketAssigned", link_id: ticket.id)

    click_link "Edit"
    select "In Progress", from: "Status"
    click_button "Save changes"
    assert_text "Ticket updated"
    assert ticket.reload.first_response_at

    click_link "Edit"
    select "Resolved", from: "Status"
    find("summary", text: "Additional information").click
    fill_in "Resolution", with: "Renewed the signing metadata and verified access with the customer."
    click_button "Save changes"
    assert_text "Ticket updated"
    assert ticket.reload.resolved_at

    click_button "Create Knowledge Article"
    assert_text "Draft knowledge article created"
    assert_field "Title", with: "Customer portal sign-in unavailable"
    assert_field "Status", with: "draft"
    fill_in "Content", with: "Renew the identity-provider signing metadata, clear the cached configuration, and verify customer access."
    click_button "Save changes"

    assert_text "Knowledge article updated"
    assert_link "Open Knowledge Article"
    article = ticket.knowledge_articles.find_by!(source: "Case Conversion")
    assert article.status_draft?
    assert_equal 1, ticket.ticket_knowledge_articles.count

    click_link "Edit"
    select "Closed", from: "Status"
    click_button "Save changes"
    assert_text "Ticket updated"
    assert ticket.reload.closed_at
    assert AuditLog.where(object_type: "Ticket", object_id: ticket.id, field_name: "status_id").count >= 3

    save_screenshot(Rails.root.join("tmp/screenshots/phase4-ticket.png")) if ENV["PHASE4_SCREENSHOTS"]
  end
end
