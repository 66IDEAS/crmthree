# frozen_string_literal: true

module Crm
  class Navigation
    Entry = ::Data.define(:key, :label, :object_type, :icon, :group, :path)

    ENTRIES = [
      Entry.new(key: "accounts", label: "Accounts", object_type: "Account", icon: "building", group: "crm", path: nil),
      Entry.new(key: "contacts", label: "Contacts", object_type: "Contact", icon: "users", group: "crm", path: nil),
      Entry.new(key: "leads", label: "Leads", object_type: "Lead", icon: "user-plus", group: "crm", path: nil),
      Entry.new(key: "opportunities", label: "Opportunities", object_type: "Opportunity", icon: "target", group: "crm", path: nil),
      Entry.new(key: "deal_rooms", label: "Deal Rooms", object_type: "DealRoom", icon: "briefcase", group: "crm", path: :deal_rooms_path),
      Entry.new(key: "quotations", label: "Quotes", object_type: "Quotation", icon: "document", group: "crm", path: nil),
      Entry.new(key: "sales_orders", label: "Sales Orders", object_type: "SalesOrder", icon: "cart", group: "crm", path: nil),
      Entry.new(key: "invoices", label: "Invoices", object_type: "Invoice", icon: "receipt", group: "crm", path: nil),
      Entry.new(key: "products", label: "Products", object_type: "Product", icon: "box", group: "crm", path: nil),
      Entry.new(key: "activities", label: "Activities", object_type: "Activity", icon: "calendar", group: "crm", path: nil),
      Entry.new(key: "case_rooms", label: "Case Rooms", object_type: "Ticket", icon: "lifebuoy", group: "service", path: :case_rooms_path),
      Entry.new(key: "knowledge", label: "Knowledge", object_type: "KnowledgeArticle", icon: "book", group: "service", path: nil),
      Entry.new(key: "assets", label: "Assets", object_type: "Asset", icon: "wrench", group: "service", path: nil),
      Entry.new(key: "contracts", label: "Contracts", object_type: "ServiceContract", icon: "shield", group: "service", path: nil)
    ].freeze

    def self.for(profile)
      configured = Array(profile.role&.ribbon_items)
      return ENTRIES if configured.include?("*")

      ENTRIES.select { |entry| configured.include?(entry.key) || configured.include?(entry.group) }
    end
  end
end
