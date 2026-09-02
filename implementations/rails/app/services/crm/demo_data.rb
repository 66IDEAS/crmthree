# frozen_string_literal: true

require "digest"

module Crm
  class DemoData
    MAX_COUNT = 500
    TARGET_MODELS = %w[
      UserProfile Account Contact ContactAccount Lead Opportunity OpportunityContact Product
      PricebookEntry Quotation SalesOrder Invoice LineItem Activity Asset KnowledgeArticle Ticket
      TicketKnowledgeArticle ServiceContract DealRoom Document Comment Notification Challenge
      PersonalBest Streak UserBadge DashboardConfig AuditLog
    ].freeze

    FIRST_NAMES = %w[
      Amelia Noah Sofia Liam Emma Oliver Mia Elias Lina Mateo Nora Luca Clara Leo Hannah Finn
      Elena Jonas Maya Samuel Zoe Gabriel Anna David Layla
    ].freeze
    LAST_NAMES = %w[
      Keller Meier Schmid Rossi Dubois Weber Novak Fischer Wagner Baumann Moretti Laurent Jensen
      Steiner Costa Hoffmann Müller Pereira Schneider Martin
    ].freeze
    COMPANY_PREFIXES = %w[
      Alpine Meridian Helvetia Northstar BluePeak Cedar Quantum Atlas Silverline Horizon Nova Lakeside
      Summit Greenfield Redwood Stonebridge BrightPath Clearview Aurora Vertex
    ].freeze
    COMPANY_SUFFIXES = ["Systems", "Logistics", "Health", "Foods", "Manufacturing"].freeze
    LOCATIONS = [
      ["Zurich", "8001", "CH"], ["Basel", "4051", "CH"], ["Geneva", "1201", "CH"],
      ["Munich", "80331", "DE"], ["Berlin", "10115", "DE"], ["Vienna", "1010", "AT"],
      ["Amsterdam", "1012", "NL"], ["Copenhagen", "1050", "DK"], ["Paris", "75001", "FR"],
      ["Milan", "20121", "IT"], ["London", "EC1A", "GB"], ["Dublin", "D02", "IE"]
    ].freeze
    INDUSTRIES = [
      ["TECH", "Software & Technology"], ["MFG", "Industrial Manufacturing"],
      ["HLTH", "Healthcare"], ["LOG", "Transport & Logistics"], ["FIN", "Financial Services"],
      ["RETL", "Retail & Consumer"], ["ENER", "Energy & Utilities"], ["PROF", "Professional Services"]
    ].freeze
    PRODUCT_BASES = [
      "Cloud Desk", "Field Service", "Revenue Insights", "Support Hub", "Mobile Workspace",
      "Data Bridge", "Commerce Connect", "Secure Archive", "Planning Studio", "Analytics Core",
      "Customer Portal", "Document Flow", "Inventory Sync", "Billing Automator", "Sales Assistant",
      "Service Console", "Identity Gateway", "Integration Pack", "Training Academy", "Success Plan"
    ].freeze
    PRODUCT_TIERS = %w[Essential Professional Enterprise Premium Ultimate].freeze
    DEAL_THEMES = [
      "Customer platform rollout", "Service transformation", "Analytics modernization",
      "Field operations upgrade", "Commerce integration", "Data migration", "Support expansion",
      "Regional deployment", "Security renewal", "Process automation"
    ].freeze
    TICKET_SUBJECTS = [
      "Monthly billing run blocked", "Mobile offline sync failed", "Dashboard and export totals differ",
      "Workspace access for new employee", "Order confirmation email delayed", "Portal shows outdated contract",
      "Integration certificate rejected", "Wrong currency on quotation", "Asset warranty date missing",
      "Knowledge search misses articles"
    ].freeze
    KNOWLEDGE_TITLES = [
      "Resolve delayed billing runs", "Configure mobile offline synchronization",
      "Reconcile dashboard and export totals", "Provision a new workspace user",
      "Troubleshoot order confirmation delivery", "Refresh contract data in the customer portal",
      "Renew an integration certificate", "Correct quotation currency settings",
      "Maintain asset warranty information", "Improve knowledge search relevance"
    ].freeze
    ACTIVITY_SUBJECTS = [
      "Discovery call", "Solution workshop", "Proposal review", "Contract follow-up",
      "Quarterly business review", "Implementation planning", "Technical validation",
      "Executive alignment", "Renewal discussion", "Customer success check-in"
    ].freeze
    METRICS = %w[revenue_won meetings_completed tickets_resolved activities_logged pipeline_created].freeze

    def self.run!(count: 100, progress: nil)
      new(count: count, progress: progress).run!
    end

    def initialize(count:, progress: nil)
      @count = Integer(count)
      raise ArgumentError, "count must be between 1 and #{MAX_COUNT}" unless @count.between?(1, MAX_COUNT)

      @progress = progress || ->(_message) { }
      @today = Date.current
    end

    def run!
      Seeds.run!
      @system = UserProfile.find(Seeds::SYSTEM_PROFILE_ID)
      Current.set(profile: @system) do
        ApplicationRecord.transaction do
          create_people_and_teams
          create_sales_data
          create_service_data
          create_collaboration_data
          create_engagement_data
        end
      end
      report
    end

    private

    attr_reader :count, :progress, :today, :system

    def create_people_and_teams
      announce "people and teams"
      user_role = Role.find_by!(name: "User")
      manager_role = Role.find_by!(name: "Manager")
      @people = collection(UserProfile) do |index|
        first_name, last_name = person_name(index)
        level = 1 + (index % 4)
        {
          auth_uid: nil,
          email: "#{first_name}.#{last_name}.#{index + 1}@northstar.example".downcase,
          first_name: first_name,
          last_name: last_name,
          role: index < team_count ? manager_role : user_role,
          avatar_url: nil,
          xp_total: 180 + (index * 73 % 5_800),
          level: level,
          level_name: %w[Rookie Closer Dealmaker Legend][level - 1],
          current_streak_days: index % 14,
          longest_streak_days: 8 + (index % 35),
          active: index % 29 != 0,
          theme_preference: %w[System Light Dark][index % 3],
          notification_preferences: {"desktop" => true, "email" => index.even?},
          language_preference: index % 5 == 0 ? "de" : "en"
        }
      end
      @teams = Array.new(team_count) do |index|
        upsert(Team, index,
          name: ["Enterprise Sales", "Customer Success", "Field Service", "New Business", "Partner Growth",
            "Strategic Accounts", "Commercial Sales", "Solution Consulting", "Renewals", "Support Operations"][index],
          manager: @people[index],
          description: "Regional CRM team responsible for coordinated customer outcomes.",
          active: true)
      end
      @people.each_with_index do |person, index|
        person.update!(team: @teams[index % @teams.length]) if person.team_id != @teams[index % @teams.length].id
      end
    end

    def create_sales_data
      announce "accounts, contacts, products, and pipeline"
      @accounts = collection(Account) do |index|
        city, postal_code, country = LOCATIONS[index % LOCATIONS.length]
        industry, industry_description = INDUSTRIES[index % INDUSTRIES.length]
        company = company_name(index)
        {
          name1: company,
          name2: index % 6 == 0 ? "#{city} Operations" : nil,
          street: ["Market Street", "Station Road", "Innovation Avenue", "Harbour Lane"][index % 4],
          house_number: (10 + index % 87).to_s,
          postal_code: postal_code,
          city: city,
          region: country == "CH" ? %w[ZH BS GE][index % 3] : nil,
          country: country,
          phone: "+#{40 + index % 9} 44 555 #{format("%04d", index + 100)}",
          email: "hello@#{company.parameterize}.example",
          website: "https://www.#{company.parameterize}.example",
          industry: industry,
          industry_description: industry_description,
          company_size: %w[1-10 11-50 51-200 201-500 501-1000 1001-5000 5000+][index % 7],
          annual_revenue: 750_000 + (index * 375_000),
          currency: currency_for(country),
          parent_account: index >= 20 ? record(Account, index % 20) : nil,
          owner: owner(index),
          description: "#{company} is a #{industry_description.downcase} customer headquartered in #{city}.",
          status: index % 17 == 0 ? "Inactive" : "Active"
        }
      end
      @contacts = collection(Contact) do |index|
        first_name, last_name = person_name(index + 7)
        account = @accounts[index]
        city, postal_code, country = LOCATIONS[index % LOCATIONS.length]
        {
          title: %w[Ms Mr Dr Mr Ms][index % 5],
          first_name: first_name,
          last_name: last_name,
          department: %w[Operations Finance IT Procurement Sales Service][index % 6],
          position: ["Operations Director", "Finance Manager", "IT Lead", "Procurement Specialist", "VP Sales"][index % 5],
          phone: account.phone,
          mobile: "+41 79 555 #{format("%04d", index + 200)}",
          email: "#{first_name}.#{last_name}@#{account.name1.parameterize}.example".downcase,
          street: account.street,
          house_number: account.house_number,
          postal_code: postal_code,
          city: city,
          country: country,
          account: account,
          owner: owner(index),
          description: "Primary contact for commercial and operational coordination.",
          status: index % 23 == 0 ? "Inactive" : "Active"
        }
      end
      @contact_accounts = collection(ContactAccount) do |index|
        {
          contact: @contacts[index],
          account: @accounts[(index + 13) % count],
          role: ["Decision Maker", "Technical Contact", "Finance Contact", "Executive Sponsor"][index % 4],
          is_primary: false
        }
      end
      @products = collection(Product) do |index|
        product_type = %w[Physical Service Subscription License][index % 4]
        {
          name: "#{PRODUCT_BASES[index % PRODUCT_BASES.length]} #{tier_name(index)}#{edition_suffix(index)}",
          description: "A #{product_type.downcase} offering for #{DEAL_THEMES[index % DEAL_THEMES.length].downcase}.",
          product_group: %w[PLATFORM SERVICE DATA SECURITY ENABLE][index % 5],
          product_group_description: ["Core Platform", "Professional Services", "Data & Analytics", "Security", "Enablement"][index % 5],
          unit_of_measure: product_type == "Service" ? "DAY" : "EA",
          base_price: 350 + (index % 20) * 475,
          currency: "CHF",
          product_type: product_type,
          status: index % 31 == 0 ? "Discontinued" : "Active"
        }
      end
      @pricebook_entries = collection(PricebookEntry) do |index|
        product = @products[index]
        {
          product: product,
          account: index.even? ? @accounts[index] : nil,
          price: product.base_price * (index.even? ? 0.92 : 1),
          currency: product.currency,
          quantity_from: 1,
          quantity_to: index % 4 == 0 ? 100 : nil,
          discount_percent: index.even? ? 8 : 0,
          valid_from: today - (index % 60).days,
          valid_to: today + (365 - index % 60).days,
          active: index % 27 != 0
        }
      end
      @leads = collection(Lead) do |index|
        first_name, last_name = person_name(index + 41)
        account = @accounts[index]
        {
          first_name: first_name,
          last_name: last_name,
          company: account.name1,
          position: ["Head of Operations", "CIO", "Service Manager", "Finance Director"][index % 4],
          email: "#{first_name}.#{last_name}@#{account.name1.parameterize}.example".downcase,
          phone: account.phone,
          website: account.website,
          source: ["Web", "Referral", "Trade Show", "Partner", "Email Campaign"][index % 5],
          status: ["New", "Contacted", "Qualified", "Unqualified"][index % 4],
          score: 35 + (index * 7 % 65),
          account: account,
          contact: @contacts[index],
          owner: owner(index),
          description: "Interested in #{DEAL_THEMES[index % DEAL_THEMES.length].downcase}."
        }
      end
      stages = PipelineStage.order(:sort_order).to_a
      @opportunities = collection(Opportunity) do |index|
        outcome = index % 10
        stage = outcome < 2 ? stages.find(&:is_won) : (outcome == 2 ? stages.find { |candidate| candidate.is_closed && !candidate.is_won } : stages[index % 4])
        result = outcome < 2 ? "Won" : (outcome == 2 ? "Lost" : "Open")
        {
          name: "#{@accounts[index].name1} — #{DEAL_THEMES[index % DEAL_THEMES.length]}",
          account: @accounts[index],
          lead: @leads[index],
          stage: stage,
          amount: 18_000 + (index * 7_250),
          currency: currency_for(@accounts[index].country),
          probability: stage.default_probability,
          expected_close_date: today + (15 + index % 120).days,
          actual_close_date: result == "Open" ? nil : today - (index % 45).days,
          result: result,
          loss_reason: result == "Lost" ? "Timing and budget priorities changed" : nil,
          owner: owner(index),
          description: "Commercial opportunity for #{DEAL_THEMES[index % DEAL_THEMES.length].downcase}."
        }
      end
      @leads.each_with_index do |lead, index|
        next unless index % 5 == 0

        lead.conversion_in_progress = true
        lead.update!(status: "Converted", converted_account: @accounts[index], converted_contact: @contacts[index],
          converted_opportunity: @opportunities[index], converted_at: Time.current - (index % 20).days)
      end
      @opportunity_contacts = collection(OpportunityContact) do |index|
        {opportunity: @opportunities[index], contact: @contacts[index], role: ["Decision Maker", "Evaluator", "Champion", "Procurement"][index % 4]}
      end
      create_commercial_documents
    end

    def create_commercial_documents
      @quotations = collection(Quotation) do |index|
        amount = @opportunities[index].amount
        {
          account: @accounts[index], contact: @contacts[index], opportunity: @opportunities[index],
          status: %w[Draft Sent Accepted Rejected Expired][index % 5],
          valid_from: today - (index % 20).days, valid_to: today + (30 - index % 10).days,
          total_amount: amount, currency: @opportunities[index].currency,
          notes: "Pricing includes onboarding and the first year of support.", owner: owner(index)
        }
      end
      @sales_orders = collection(SalesOrder) do |index|
        {
          account: @accounts[index], contact: @contacts[index], opportunity: @opportunities[index], quotation: @quotations[index],
          status: ["Draft", "Confirmed", "In Progress", "Shipped", "Completed"][index % 5],
          order_date: today - (index % 75).days, total_amount: @quotations[index].total_amount,
          currency: @quotations[index].currency, notes: "Customer purchase order received and validated.", owner: owner(index)
        }
      end
      @invoices = collection(Invoice) do |index|
        status = ["Draft", "Sent", "Paid", "Partially Paid", "Overdue"][index % 5]
        amount = @sales_orders[index].total_amount
        {
          account: @accounts[index], contact: @contacts[index], sales_order: @sales_orders[index], status: status,
          invoice_date: today - (index % 60).days, due_date: today + (30 - index % 45).days,
          total_amount: amount, paid_amount: status == "Paid" ? amount : (status == "Partially Paid" ? amount / 2 : 0),
          currency: @sales_orders[index].currency, notes: "Payment terms: 30 days net.", owner: owner(index)
        }
      end
      parents = [@opportunities, @quotations, @sales_orders, @invoices]
      @line_items = collection(LineItem) do |index|
        parent = parents[index % parents.length][index]
        quantity = 1 + index % 12
        discount = index % 4 * 2.5
        parent_total = parent.respond_to?(:amount) ? parent.amount : parent.total_amount
        multiplier = BigDecimal(quantity.to_s) * (1 - BigDecimal(discount.to_s) / 100)
        unit_price = parent_total.present? ? (parent_total / multiplier).ceil(2) : @products[index].base_price
        {
          parent: parent, item_number: format("%06d", 10), product: @products[index], quantity: quantity,
          unit_price: unit_price, discount_percent: discount,
          total_price: quantity * unit_price * (1 - discount / 100), unit_of_measure: @products[index].unit_of_measure,
          comment: "Customer-specific standard pricing."
        }
      end
    end

    def create_service_data
      announce "assets, contracts, tickets, and knowledge"
      @slas = %w[Bronze Silver Gold Platinum].each_with_index.map do |name, index|
        upsert(SLA, index, name: "#{name} Support", description: "#{name} response and resolution coverage.",
          response_time_hours: [24, 8, 4, 1][index], resolution_time_hours: [72, 32, 16, 8][index],
          applies_to_priorities: %w[Low Medium High Critical].first(index + 1), business_hours_only: index < 2, active: true)
      end
      @knowledge_articles = collection(KnowledgeArticle) do |index|
        published = index % 5 != 0
        {
          title: "#{KNOWLEDGE_TITLES[index % KNOWLEDGE_TITLES.length]} — #{tier_name(index)}#{edition_suffix(index)}",
          content: "This article explains the verified steps, expected result, and escalation path for #{KNOWLEDGE_TITLES[index % KNOWLEDGE_TITLES.length].downcase}.",
          category: %w[Billing Mobile Reporting Access Orders Integrations][index % 6],
          status: published ? "Published" : "In Review", source: index % 7 == 0 ? "Case Conversion" : "Manual",
          author: owner(index), views_count: 24 + index * 13, helpful_count: 5 + index * 3,
          published_at: published ? Time.current - (index % 180).days : nil
        }
      end
      @assets = collection(Asset) do |index|
        {
          name: "#{PRODUCT_BASES[index % PRODUCT_BASES.length]} installation #{index + 1}",
          product: @products[index], account: @accounts[index],
          contact: @contacts[index], serial_number: "SN-#{today.year}-#{format("%06d", index + 1)}",
          install_date: today - (30 + index * 3).days, warranty_end_date: today + (180 + index * 5).days,
          functional_location: "#{@accounts[index].city}-#{format("%03d", index + 1)}",
          manufacturer: ["Northstar", "Contoso", "Fabrikam", "Adventure Works"][index % 4],
          model_number: "M#{1000 + index}", status: ["Active", "Active", "Active", "In Repair"][index % 4], owner: owner(index)
        }
      end
      @service_contracts = collection(ServiceContract) do |index|
        {
          name: "#{@accounts[index].name1} #{PRODUCT_TIERS[index % PRODUCT_TIERS.length]} Care",
          account: @accounts[index], start_date: today - (index % 200).days, end_date: today + (365 - index % 90).days,
          status: index % 18 == 17 ? "Expired" : "Active",
          entitlements: "Remote support, named success manager, quarterly service review, and priority escalation.",
          sla: @slas[index % @slas.length], owner: owner(index)
        }
      end
      statuses = TicketStatus.order(:sort_order).to_a
      @tickets = collection(Ticket) do |index|
        status = statuses[index % statuses.length]
        resolved = status.is_resolved
        contract = @service_contracts[index]
        {
          subject: "#{TICKET_SUBJECTS[index % TICKET_SUBJECTS.length]} #{index + 1}",
          description: "Customer reported the issue with supporting context and requested an update during the next business day.",
          status: status, priority: %w[Low Medium High Critical][index % 4],
          category: %w[Billing Mobile Reporting Access Orders Integration Assets Knowledge][index % 8],
          account: @accounts[index], contact: @contacts[index], asset: @assets[index],
          service_contract: contract.active_on?(today) ? contract : nil, sla: @slas[index % @slas.length],
          assignee: active_owner(index + 1), owner: owner(index),
          resolution: resolved ? "Configuration corrected and result confirmed with the customer." : nil,
          sla_response_deadline: Time.current + [24, 8, 4, 1][index % 4].hours,
          sla_resolution_deadline: Time.current + [72, 32, 16, 8][index % 4].hours,
          first_response_at: Time.current - (index % 8).hours,
          resolved_at: resolved ? Time.current - (index % 5).days : nil,
          closed_at: status.is_closed ? Time.current - (index % 4).days : nil
        }
      end
      @ticket_articles = collection(TicketKnowledgeArticle) do |index|
        {ticket: @tickets[index], article: @knowledge_articles[index], linked_at: Time.current - (index % 30).days, linker: owner(index)}
      end
      @activities = collection(Activity) do |index|
        complete = index % 4 == 2
        start_time = Time.current + (index - 50).hours
        {
          type: %w[Call Email Meeting Task][index % 4],
          subject: "#{ACTIVITY_SUBJECTS[index % ACTIVITY_SUBJECTS.length]} — #{@accounts[index].name1}",
          description: "Coordinate next steps, confirm responsibilities, and document the agreed timeline.",
          status: complete ? "Completed" : ["Planned", "In Progress", "Planned"][index % 3],
          priority: %w[Low Medium High][index % 3], start_date: start_time, end_date: start_time + (30 + index % 60).minutes,
          due_date: today + (index % 21).days, completed_at: complete ? Time.current - (index % 10).days : nil,
          duration_minutes: 30 + index % 60, account: @accounts[index], contact: @contacts[index],
          lead: @leads[index], opportunity: @opportunities[index], ticket: @tickets[index], owner: owner(index),
          is_auto_logged: index % 9 == 0
        }
      end
      @deal_rooms = collection(DealRoom) do |index|
        {name: "#{@accounts[index].name1} Deal Room", description: "Shared workspace for proposal, validation, and contracting activities.",
          opportunity: @opportunities[index], status: @opportunities[index].result == "Open" ? "Active" : "Closed", owner: owner(index)}
      end
    end

    def create_collaboration_data
      announce "documents and collaboration"
      document_parents = [@accounts, @contacts, @opportunities, @quotations, @sales_orders, @invoices, @tickets, @knowledge_articles, @deal_rooms]
      @documents = collection(Document) do |index|
        parent = document_parents[index % document_parents.length][index]
        {
          name: ["Proposal", "Meeting Notes", "Service Report", "Architecture", "Commercial Terms"][index % 5] + " #{index + 1}.pdf",
          file_path: "/demo/documents/#{parent.class.name.underscore}/#{id_for("Document", index)}.pdf",
          file_type: "application/pdf", file_size: 84_000 + index * 1_337, parent: parent, uploader: owner(index)
        }
      end
      comment_parents = [@accounts, @contacts, @leads, @opportunities, @quotations, @sales_orders, @invoices, @tickets, @knowledge_articles, @activities, @deal_rooms]
      comments = [
        "Customer confirmed the proposed timeline and asked for the next milestone summary.",
        "Finance reviewed the commercial assumptions; no blockers remain.",
        "Technical validation completed successfully in the customer sandbox.",
        "Follow up next week with the updated stakeholder list.",
        "Support reproduced the issue and attached a verified workaround."
      ]
      @comments = collection(Comment) do |index|
        {parent: comment_parents[index % comment_parents.length][index], content: comments[index % comments.length], author: owner(index)}
      end
    end

    def create_engagement_data
      announce "notifications, gamification, dashboards, and audit history"
      badges = Badge.order(:name).to_a
      notification_types = %w[TicketAssigned SLABreach DealStageChange MentionedInComment LeadAssigned ChallengeAssigned BadgeEarned LevelUp PersonalBest System]
      @notifications = collection(Notification) do |index|
        ticket = @tickets[index]
        {
          user: owner(index), type: notification_types[index % notification_types.length],
          title: ["Ticket assigned", "SLA needs attention", "Deal stage changed", "You were mentioned", "New lead assigned"][index % 5],
          message: "#{@accounts[index].name1}: #{ticket.subject}", read: index % 3 == 0,
          link_type: "Ticket", link_id: ticket.id, send_email: index % 4 == 0, email_sent: index % 8 == 0
        }
      end
      @challenges = collection(Challenge) do |index|
        target = 5 + index % 16
        current = index % (target + 1)
        {
          user: @people[index], title: "#{METRICS[index % METRICS.length].humanize} target",
          description: "Reach #{target} #{METRICS[index % METRICS.length].humanize.downcase} during #{today.strftime("%B %Y")}.",
          month: today.month, year: today.year, target_metric: METRICS[index % METRICS.length],
          target_value: target, current_value: current, status: current >= target ? "Completed" : "Active",
          reward_badge: badges[index % badges.length], reward_xp: 50 + (index % 5) * 25,
          completed_at: current >= target ? Time.current - (index % 10).days : nil
        }
      end
      @personal_bests = collection(PersonalBest) do |index|
        value = 10 + index * 2.5
        {user: @people[index], metric: METRICS[index % METRICS.length], value: value,
          achieved_at: Time.current - (index % 100).days, previous_value: value * 0.8,
          previous_achieved_at: Time.current - (100 + index % 80).days}
      end
      @streaks = collection(Streak) do |index|
        current = index % 18
        {user: @people[index], activity_type: METRICS[index % METRICS.length], current_count: current,
          longest_count: current + 3 + index % 9, last_activity_date: today - (index % 4).days}
      end
      @user_badges = collection(UserBadge) do |index|
        {user: @people[index], badge: badges[index % badges.length], earned_at: Time.current - (index % 180).days}
      end
      @dashboards = collection(DashboardConfig) do |index|
        {user: @people[index], name: "My Customer Portfolio", is_default: true,
          widgets: [
            {"type" => "pipeline", "title" => "Open Pipeline"},
            {"type" => "tasks", "title" => "My Next Actions"},
            {"type" => "tickets", "title" => "Service Attention"}
          ]}
      end
      @audit_logs = collection(AuditLog) do |index|
        account = @accounts[index]
        {
          object_type: "Account", object_id: account.id, action: index % 4 == 0 ? "Create" : "Update",
          field_name: index % 4 == 0 ? nil : %w[status city annual_revenue owner_id][index % 4],
          old_value: index % 4 == 0 ? nil : "Previous value", new_value: index % 4 == 0 ? nil : "Updated value",
          user: owner(index), timestamp: Time.current - (index * 3).hours,
          object_name: account.name1, summary: "#{index % 4 == 0 ? "Created" : "Updated"} #{account.name1}"
        }
      end
    end

    def collection(model)
      Array.new(count) { |index| upsert(model, index, yield(index)) }
    end

    def upsert(model, index, attributes)
      record = model.find_or_initialize_by(id: id_for(model.name, index))
      record.conversion_in_progress = true if record.is_a?(Lead)
      record.assign_attributes(attributes)
      record.save! if record.new_record? || record.changed?
      record
    end

    def record(model, index)
      model.find(id_for(model.name, index))
    end

    def id_for(model_name, index)
      hex = Digest::SHA256.hexdigest("crmthree-demo-v1/#{model_name}/#{index}").first(32)
      hex[12] = "4"
      hex[16] = "8"
      [hex[0, 8], hex[8, 4], hex[12, 4], hex[16, 4], hex[20, 12]].join("-")
    end

    def owner(index)
      @people[index % @people.length]
    end

    def active_owner(index)
      count.times do |offset|
        candidate = owner(index + offset)
        return candidate if candidate.active?
      end
      owner(index)
    end

    def person_name(index)
      [FIRST_NAMES[index % FIRST_NAMES.length], LAST_NAMES[(index * 7) % LAST_NAMES.length]]
    end

    def company_name(index)
      suffix = COMPANY_SUFFIXES[(index / COMPANY_PREFIXES.length) % COMPANY_SUFFIXES.length]
      "#{COMPANY_PREFIXES[index % COMPANY_PREFIXES.length]} #{suffix}#{edition_suffix(index)}"
    end

    def tier_name(index)
      PRODUCT_TIERS[(index / PRODUCT_BASES.length) % PRODUCT_TIERS.length]
    end

    def edition_suffix(index)
      cycle_size = COMPANY_PREFIXES.length * COMPANY_SUFFIXES.length
      index < cycle_size ? "" : " #{index / cycle_size + 1}"
    end

    def currency_for(country)
      {"CH" => "CHF", "GB" => "GBP", "DK" => "DKK"}.fetch(country, "EUR")
    end

    def team_count
      @team_count ||= [[(count / 10.0).ceil, 1].max, 10].min
    end

    def announce(section)
      progress.call("Creating #{section}…")
    end

    def report
      TARGET_MODELS.to_h do |model_name|
        model = ModelRegistry.model_for(model_name)
        ids = count.times.map { |index| id_for(model_name, index) }
        [model_name, model.where(id: ids).count]
      end.merge("Team" => @teams.size, "SLA" => @slas.size)
    end
  end
end
