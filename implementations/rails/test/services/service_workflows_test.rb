# frozen_string_literal: true

require "test_helper"

class ServiceWorkflowsTest < ActiveSupport::TestCase
  setup do
    seed_crm!
    @owner = create_profile(email: "service-owner@example.com")
    @agent = create_profile(email: "service-agent@example.com")
    @account = create_account(owner: @owner, name: "Orbital Service AG")
    @product = Current.set(profile: @owner) do
      Product.create!(name: "Telemetry Gateway", unit_of_measure: "EA", base_price: 800,
        currency: "CHF", product_type: "Physical", status: "Active")
    end
    @new_status = TicketStatus.find_by!(name: "New")
    @progress_status = TicketStatus.find_by!(name: "In Progress")
    @resolved_status = TicketStatus.find_by!(name: "Resolved")
    @closed_status = TicketStatus.find_by!(name: "Closed")
    @sla = Current.set(profile: @owner) do
      SLA.create!(name: "Critical Care", response_time_hours: 2, resolution_time_hours: 8,
        applies_to_priorities: ["Critical"], business_hours_only: false, active: true)
    end
  end

  test "business-hour deadlines skip nights and weekends" do
    friday = Time.zone.local(2026, 9, 4, 16, 0, 0)

    deadline = Crm::Service::BusinessHours.deadline(from: friday, hours: 4, business_hours_only: true)

    assert_equal Time.zone.local(2026, 9, 7, 12, 0, 0), deadline
    assert_equal friday + 4.hours,
      Crm::Service::BusinessHours.deadline(from: friday, hours: 4, business_hours_only: false)
  end

  test "ticket creation selects an SLA and derives deadlines" do
    ticket = create_ticket(priority: "Critical")

    assert_equal @sla, ticket.sla
    assert_in_delta 2.hours, ticket.sla_response_deadline - ticket.created_at, 2
    assert_in_delta 8.hours, ticket.sla_resolution_deadline - ticket.created_at, 2
    assert_equal :within, ticket.sla_snapshot.response
    assert_equal :within, ticket.sla_snapshot.resolution
  end

  test "an active account contract supplies the SLA before a priority rule" do
    contract_sla = Current.set(profile: @owner) do
      SLA.create!(name: "Contract Platinum", response_time_hours: 1, resolution_time_hours: 4,
        applies_to_priorities: [], business_hours_only: false, active: true)
    end
    contract = Current.set(profile: @owner) do
      ServiceContract.create!(name: "Orbital Premium", account: @account, start_date: Date.current - 1,
        end_date: Date.current + 365, status: "Active", sla: contract_sla, owner: @owner)
    end

    ticket = create_ticket(priority: "Critical", service_contract: contract)

    assert_equal contract_sla, ticket.sla
    assert_in_delta 1.hour, ticket.sla_response_deadline - ticket.created_at, 2
  end

  test "status changes set response resolution and close timestamps and closed tickets are terminal" do
    ticket = create_ticket(priority: "Critical")

    Current.set(profile: @owner) { ticket.update!(status: @progress_status) }
    assert ticket.first_response_at
    assert_nil ticket.resolved_at

    Current.set(profile: @owner) { ticket.update!(status: @resolved_status, resolution: "Restarted the gateway service.") }
    assert ticket.resolved_at
    assert_nil ticket.closed_at

    Current.set(profile: @owner) { ticket.update!(status: @closed_status) }
    assert ticket.closed_at
    assert_not ticket.update(status: @progress_status)
    assert_includes ticket.errors[:status], "cannot change after the ticket is closed"
  end

  test "resolved tickets require a resolution and related service records must match the account" do
    ticket = create_ticket(priority: "Critical")
    assert_not ticket.update(status: @resolved_status)
    assert_includes ticket.errors[:resolution], "is required when a ticket is resolved"

    other_account = create_account(owner: @owner, name: "Unrelated Customer")
    asset = Current.set(profile: @owner) do
      Asset.create!(name: "Other gateway", product: @product, account: other_account, status: "Active", owner: @owner)
    end
    ticket.asset = asset
    assert_not ticket.valid?
    assert_includes ticket.errors[:asset], "must belong to the selected account"
  end

  test "ticket assignment creates a non-blocking recipient notification" do
    ticket = create_ticket(priority: "Critical", assignee: @agent)

    notification = Notification.find_by!(user: @agent, type: "TicketAssigned", link_id: ticket.id)
    assert_equal "Ticket assigned", notification.title
    assert_equal "Ticket", notification.link_type
    refute notification.read?
  end

  test "SLA breach checks are idempotent" do
    ticket = create_ticket(priority: "Critical", assignee: @agent)
    response_deadline = 3.hours.ago
    ticket.update_columns(
      sla_response_deadline: response_deadline,
      first_response_at: response_deadline - 5.minutes,
      sla_resolution_deadline: 1.hour.ago,
      resolved_at: nil
    )

    assert_difference -> { Notification.where(type: "SLABreach", link_id: ticket.id).count }, 1 do
      SLABreachCheckJob.perform_now
      SLABreachCheckJob.perform_now
    end
    assert_equal "SLA resolution breached", Notification.where(type: "SLABreach", link_id: ticket.id).pick(:title)
  end

  test "case conversion creates one editable draft and links the source ticket atomically" do
    ticket = create_ticket(priority: "Critical", status: @resolved_status,
      resolution: "Applied firmware 8.4 and verified a clean synchronization.")
    converter = Crm::Service::CaseConverter.new(
      ticket_id: ticket.id, idempotency_key: "case-conversion", identity: identity(@owner)
    )

    first = converter.call
    second = converter.call

    assert first.success?, "#{first.code}: #{first.errors.inspect}"
    assert second.success?, "#{second.code}: #{second.errors.inspect}"
    article = KnowledgeArticle.find(first.value.fetch("article_id"))
    assert article.status_draft?
    assert article.source_case_conversion?
    assert_equal ticket.updater, article.author
    assert_includes article.content, ticket.ticket_number.to_i.to_s
    assert_equal [ticket.id], article.tickets.pluck(:id)
    assert_equal 1, KnowledgeArticle.where(title: ticket.subject).count
  end

  test "case conversion rolls back the article when the junction is not authorised" do
    restricted_role = create_role(name: "Restricted converter", permissions: {
      "Ticket" => {"read" => true, "update" => true},
      "KnowledgeArticle" => {"create" => true, "read" => true, "update" => true},
      "TicketKnowledgeArticle" => {"create" => false, "read" => true}
    })
    converter_profile = create_profile(email: "restricted-converter@example.com", role: restricted_role)
    account = create_account(owner: converter_profile, name: "Restricted Service")
    ticket = Current.set(profile: converter_profile) do
      Ticket.create!(subject: "Restricted conversion", status: @resolved_status, priority: "Critical",
        account:, owner: converter_profile, resolution: "A verified resolution")
    end

    assert_no_difference ["KnowledgeArticle.count", "TicketKnowledgeArticle.count"] do
      result = Crm::Service::CaseConverter.new(
        ticket_id: ticket.id, idempotency_key: "denied-link", identity: identity(converter_profile)
      ).call
      assert result.failure?
      assert_equal :not_found, result.code
    end
  end

  test "service reference models enforce dates publication state and safe status deletion" do
    contract = ServiceContract.new(start_date: Date.current, end_date: Date.current - 1)
    assert_not contract.valid?
    assert_includes contract.errors[:end_date], "must be on or after the start date"

    asset = Asset.new(install_date: Date.current, warranty_end_date: Date.current - 1)
    assert_not asset.valid?
    assert_includes asset.errors[:warranty_end_date], "must be on or after the install date"

    article = Current.set(profile: @owner) do
      KnowledgeArticle.create!(title: "Publishing lifecycle", content: "Verified content", status: "Published",
        source: "Manual", author: @owner, views_count: 0, helpful_count: 0)
    end
    assert article.published_at

    ticket = create_ticket(priority: "Critical")
    assert_not ticket.status.destroy
    assert_includes ticket.status.errors[:base], "Ticket status is in use and cannot be deleted"
  end

  private

  def create_ticket(priority:, status: @new_status, resolution: nil, service_contract: nil, assignee: nil)
    Current.set(profile: @owner) do
      Ticket.create!(
        subject: "Gateway reports intermittent telemetry", description: "Synchronization stops after several hours.",
        status:, priority:, category: "Integration", account: @account, service_contract:,
        assignee:, owner: @owner, resolution:
      )
    end
  end
end
