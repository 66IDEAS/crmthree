# frozen_string_literal: true

require "test_helper"

class DemoDataTest < ActiveSupport::TestCase
  test "creates believable related records and remains idempotent" do
    first_report = Crm::DemoData.run!(count: 4)
    second_report = Crm::DemoData.run!(count: 4)

    Crm::DemoData::TARGET_MODELS.each do |model_name|
      assert_equal 4, first_report.fetch(model_name), "expected four demo #{model_name} records"
      assert_equal 4, second_report.fetch(model_name), "expected rerun to preserve four demo #{model_name} records"
    end

    account = Account.find_by!(name1: "Alpine Systems")
    contact = Contact.find_by!(account: account)
    opportunity = Opportunity.find_by!(account: account)
    invoice = Invoice.find_by!(account: account)
    ticket = Ticket.find_by!(account: account)

    assert_match(/@alpine-systems\.example\z/, contact.email)
    assert_equal account, opportunity.lead.account
    assert_equal contact, opportunity.opportunity_contacts.first.contact
    assert_equal opportunity, invoice.sales_order.opportunity
    assert_equal account, ticket.asset.account
    assert_equal account, ticket.service_contract.account
    assert_equal ticket, ticket.ticket_knowledge_articles.first.ticket
    assert_includes [Account, Contact, Opportunity, Quotation, SalesOrder, Invoice, Ticket, KnowledgeArticle, DealRoom], Document.first.parent.class
    assert_not_equal "Test", account.name1
  end
end
