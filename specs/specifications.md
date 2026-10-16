# Functional Specifications — CRM System

## Sales

### 1. Account Management
As a user, I want to create and manage company accounts so that I can track the organizations I do business with.

**Data Model:** Account, ContactAccount → `specs/data-model.json`

**Acceptance Criteria:**
- User can create, view, edit, and delete accounts
- Accounts support hierarchical relationships (parent/child accounts)
- Accounts can be linked to contacts, opportunities, quotations, sales orders, invoices, tickets, assets, and activities

### 2. Contact Management
As a user, I want to create and manage individual contacts so that I can track the people I interact with.

**Data Model:** Contact, ContactAccount → `specs/data-model.json`

**Acceptance Criteria:**
- User can create, view, edit, and delete contacts
- Contacts can be associated with one or more accounts
- Contacts can be linked to opportunities, quotations, tickets, and activities

### 3. Lead Management
As a user, I want to capture and qualify leads so that I can identify new sales opportunities.

**Data Model:** Lead → `specs/data-model.json`

**Acceptance Criteria:**
- User can create, view, edit, and delete leads
- Leads track the source of origin
- Leads can be scored (manually via score field 0-100) and qualified (status transitions: New → Contacted → Qualified/Unqualified → Converted)
- A lead can be converted into a contact, account, and/or opportunity via a "Convert Lead" dialog accessible from the lead detail page header. The dialog pre-fills: Contact (first_name, last_name, email, phone, mobile, position), Account (company → name1), and optionally an Opportunity (user enters name). On conversion: records are created, lead status is set to "Converted", conversion fields are populated (converted_contact_id, converted_account_id, converted_opportunity_id, converted_at), and the user is navigated to the new opportunity (or contact if no opportunity). Already-converted leads show the "Convert" button as disabled. The lead's owner_id is inherited by all created records.

### 4. Opportunity Management
As a sales rep, I want to track deals through a configurable pipeline so that I can manage my sales process.

**Data Model:** Opportunity, OpportunityContact, PipelineStage, LineItem → `specs/data-model.json`

**Acceptance Criteria:**
- User can create, view, edit, and delete opportunities
- Opportunities progress through pipeline stages (e.g., Prospecting → Qualification → Proposal → Closed Won/Lost)
- An admin can configure the pipeline stages
- Opportunities support line items (products with quantities and prices) managed inline on the detail page
- Line item numbers auto-populate (10, 20, 30...) and net value auto-calculates live from quantity, price, and discount
- An opportunity can be converted into a quotation
- An opportunity can be converted into a sales order

### 5. Quotation Management
As a sales rep, I want to create quotations for customers so that I can formalize a proposed deal.

**Data Model:** Quotation, LineItem → `specs/data-model.json`

**Acceptance Criteria:**
- User can create, view, edit, and delete quotations
- Quotations do not have a title/name field — they are identified by their quotation number
- Account is the first field on the create form and detail view
- Quotations support line items (products with quantities and prices) managed inline on the detail page
- Line item numbers auto-populate and net value auto-calculates live
- Quotations are linked to an account and optionally a contact
- A quotation can be created from an opportunity
- A quotation can be converted into a sales order

### 6. Sales Order Management
As a user, I want to create sales orders so that I can track confirmed customer purchases.

**Data Model:** SalesOrder, LineItem → `specs/data-model.json`

**Acceptance Criteria:**
- User can create, view, edit, and delete sales orders
- Sales orders do not have a title/name field — they are identified by their order number
- Account is the first field on the create form and detail view
- Sales orders support line items (products with quantities and prices) managed inline on the detail page
- Line item numbers auto-populate and net value auto-calculates live
- A sales order can be created from a quotation and/or an opportunity
- Sales orders are linked to an account and optionally a contact

### 7. Invoice Management
As a user, I want to create invoices so that I can bill customers for products and services.

**Data Model:** Invoice, LineItem → `specs/data-model.json`

**Acceptance Criteria:**
- User can create, view, edit, and delete invoices
- Invoices do not have a title/name field — they are identified by their invoice number
- Account is the first field on the create form and detail view
- Invoices support line items managed inline on the detail page
- Line item numbers auto-populate and net value auto-calculates live
- An invoice can be created standalone for an account
- An invoice can be created from a sales order
- Invoices are linked to an account and optionally a contact

### 8. Product Management
As a user, I want to manage a product catalog so that products can be referenced in opportunities, quotations, sales orders, and invoices.

**Data Model:** Product, PricebookEntry → `specs/data-model.json`

**Acceptance Criteria:**
- User can create, view, edit, and delete products
- Products can be selected as line items on opportunities, quotations, sales orders, and invoices

### 9. Activity Management
As a user, I want to track calls, emails, meetings, and tasks so that I have a complete history of interactions with contacts and accounts.

**Data Model:** Activity → `specs/data-model.json`

**Acceptance Criteria:**
- User can create, view, edit, and delete activities (calls, emails, meetings, tasks)
- Activities can be linked to accounts, contacts, opportunities, tickets, and other objects
- Activities display in a timeline on related records

## Service

### 10. Ticket Management
As a support agent, I want to create and manage service tickets so that I can track and resolve customer issues.

**Data Model:** Ticket, TicketStatus → `specs/data-model.json`

**Acceptance Criteria:**
- User can create, view, edit, and delete tickets
- Tickets are linked to an account and optionally a contact
- Tickets have configurable statuses (default: New → In Progress → Resolved → Closed)
- An admin can configure ticket statuses
- Tickets support configurable categories and priorities

### 11. SLA Management
As a service manager, I want to define and track service level agreements so that response and resolution time targets are monitored.

**Data Model:** SLA → `specs/data-model.json`

**Acceptance Criteria:**
- An admin can define SLAs with response time and resolution time targets
- SLAs can be assigned to tickets based on rules (e.g., priority, account)
- The system tracks elapsed time against SLA targets
- Users can see whether a ticket is within or breaching its SLA

### 12. Knowledge Base
As a support agent, I want to access a knowledge base so that I can find solutions to common issues quickly.

**Data Model:** KnowledgeArticle, TicketKnowledgeArticle → `specs/data-model.json`

**Acceptance Criteria:**
- Users can create, view, edit, and delete knowledge base articles
- Articles can be categorized and searched
- Articles can be linked to tickets

### 13. Service Contract Management
As a user, I want to manage service contracts so that I can track what service agreements are in place for each customer.

**Data Model:** ServiceContract → `specs/data-model.json`

**Acceptance Criteria:**
- User can create, view, edit, and delete service contracts
- Contracts define coverage periods and entitlements
- Contracts are linked to accounts
- Tickets can reference an active service contract

### 14. Asset Management
As a user, I want to track which products a customer has installed so that service tickets can reference specific assets.

**Data Model:** Asset → `specs/data-model.json`

**Acceptance Criteria:**
- User can create, view, edit, and delete assets
- Assets are linked to an account and optionally a contact
- Assets reference a product from the product catalog
- Tickets can be linked to a specific asset

## Cross-Cutting

### 15. Dashboard & Reporting
As a user, I want to see dashboards with key performance indicators so that I can monitor business metrics at a glance.

**Data Model:** DashboardConfig → `specs/data-model.json`

**Acceptance Criteria:**
- The home page displays a dashboard with KPI number cards and Recharts-based charts
- KPI cards show: Pipeline Value (sum of open opportunity amounts), Open Opportunities count, Open Tickets count, Open Leads count
- Charts show: Opportunities by Stage (bar chart), Tickets by Priority (pie chart), Activity Trend over last 7 days (line chart), Revenue by Invoice Status (bar chart)
- An AI Priority Summary placeholder card is shown at the top (full width) with a sparkle icon and "coming soon" message
- Users can show or hide individual widgets via a settings gear icon that opens a dialog with checkboxes
- Widget visibility preferences are persisted per user in a DashboardConfig record
- Dashboards are role-aware: sales roles see sales widgets by default, service roles see service widgets by default, admin/manager roles see all widgets
- Data is loaded via DataService.list() and aggregated client-side in a useDashboardData hook
- Email notifications are deferred to a future release

### 16. Global Search
As a user, I want to search across all objects so that I can quickly find any record in the system.

**Acceptance Criteria:**
- The persistent AI/Search bar at the bottom of the application serves as the global search interface
- Search is triggered as the user types (debounced 400ms), no submit button needed
- Search queries all navigable object types (Account, Contact, Lead, Opportunity, Quotation, SalesOrder, Invoice, Product, Activity, Ticket, KnowledgeArticle, Asset, SLA, ServiceContract)
- Matching is case-insensitive and checks all string and text fields on each object type
- Results are grouped by object type in a drop-up panel above the search bar
- Each group shows up to 5 matching records with display name and auto-number
- Clicking a result navigates to the record's detail page
- The search bar can be focused with Ctrl+K / Cmd+K keyboard shortcut
- Minimum 2 characters required before search executes

### 17. Notifications
As a user, I want to receive notifications about important events so that I can respond promptly.

**Data Model:** Notification → `specs/data-model.json`

**Acceptance Criteria:**
- Users receive in-app notifications in real time via a database subscription filtered to the current user
- A bell icon in the Top Bar shows the unread notification count as a badge; clicking opens a notification panel (UX18)
- Clicking a notification navigates to the related record and marks it as read
- Users can mark all notifications as read or delete individual notifications
- Desktop browser notifications (via the Notification API) appear when new unread notifications arrive, if the user has granted permission
- Users can configure which notification types they receive via a Notification Preferences section in the Settings page, stored as `notification_preferences` JSON on their UserProfile
- Client-side triggers create notifications when: a ticket is assigned to another user (TicketAssigned), an opportunity stage changes (DealStageChange), or a lead is reassigned (LeadAssigned)
- Notification triggers check the target user's preferences before creating the notification; types default to enabled if preferences are not set
- Notification creation never blocks the save operation that triggers it (silent failure)
- Email notifications are deferred to a future release

### 18. Role-Based Access Control
As an admin, I want to manage user roles and permissions so that users only see and do what they are authorized for.

**Data Model:** Role, UserProfile, Team → `specs/data-model.json`

**Acceptance Criteria:**
- The system includes default roles: Admin, Manager, and User
- An admin can create additional custom roles
- Permissions control what objects and actions a role can access
- A sales rep sees only their own records by default; a manager sees their team's records
- An admin can configure ribbon items (navigation visibility) per role from the Settings page
- The ribbon items configuration shows all available navigation entries as checkboxes
- Changes to ribbon items take effect immediately for all users with that role

### 18b. Email/Domain Whitelist
As an admin, I want to restrict application access to specific email addresses or email domains so that only authorized users can sign in.

**Acceptance Criteria:**
- An admin can add individual email addresses (e.g., `john@example.com`) to an access whitelist
- An admin can add entire email domains (e.g., `example.com`) to allow all users from that domain
- When the whitelist is empty, all authenticated users can access the application (backwards compatible)
- When whitelist entries exist, only users whose email matches an entry or whose domain matches an entry are allowed
- Non-whitelisted users see a clear "not authorized" message with a sign-out option after authenticating
- The whitelist is managed from the Settings page and is visible only to admins

### 19. Data Import & Export
As a user, I want to import and export data in bulk so that I can migrate data or analyze it externally.

**Acceptance Criteria:**
- Users can export the currently visible list view records to a CSV file via an "Export" button in the list toolbar
- Export uses human-readable column headers (field descriptions) and formats auto-numbers without leading zeros
- Export includes all records matching the current filters, not just the visible page
- Export is available for all navigable object types
- Admins can import records from a CSV file via the "Data Import" section on the Settings page
- Import allows selecting the target object type, uploading a CSV file, previewing data, and adjusting field mappings
- Import auto-maps CSV column headers to CRM fields by matching field names and descriptions
- Import creates new records via DataService (auto-generates IDs and auto-numbers)
- After import, a results summary shows: records created, records skipped, and any validation errors with row numbers

### 20. AI Assistant
As a user, I want an always-visible AI command interface so that I can ask questions and get AI-powered responses alongside keyword search results.

**Data Model:** AIProviderConfig → `specs/data-model.json`

**Acceptance Criteria:**
- The persistent AI/Search bar at the bottom of the screen serves dual purpose: global keyword search (F16) and AI assistant
- The bar automatically detects whether input is a keyword search or an AI query using smart heuristics:
  - Input containing a question mark → AI query
  - Input starting with a question word (who, what, where, when, why, how, which, can, could, should, is, are, do, does, list, show, find, summarize, explain, help) → AI query
  - Input containing 4+ words → AI query
  - Short inputs without question words → keyword search
- Keyword search works as before: debounced instant results as the user types
- AI queries are sent on Enter: a response panel expands upward from the bar showing loading state, then the formatted AI response
- Keyword search results still appear below the AI response (both visible simultaneously)
- AI calls are routed through a server-side proxy, so API keys never reach the browser
- An admin configures the AI provider (OpenAI, Google, Anthropic, Moonshot), model, and API key in the Settings page
- Only one AI provider can be active at a time; activating one deactivates others
- If no AI provider is configured, all queries fall back to keyword search silently (no error messages)
- The system supports pluggable AI models: OpenAI (GPT), Google (Gemini), Anthropic (Claude), Moonshot (KIMI)
- The AI assistant receives a system prompt: "You are a CRM assistant helping users with their sales and service data. Be concise."
- The AI assistant is data-aware: the Cloud Function automatically detects which CRM object types are relevant to the user's question (via keyword matching), fetches up to 200 records per type (max 3 types) with key fields only, and injects the data as context into the AI prompt
- Keyword detection maps question terms to object types (e.g., "customer" → Account, "deal" → Opportunity, "ticket" → Ticket)
- If no keywords match, the system defaults to fetching Account and Opportunity data
- Data is formatted compactly (pipe-separated) to minimize token usage while giving the AI enough context to answer accurately
- The AI can answer questions like "Which is my largest customer by employees?", "How many open tickets do we have?", or "Show me deals closing this month"

### 58. Linked Records on Cards
As a user, I want every record layout to display its linked records in cards so that I can see all associated data without navigating away.

**Data Model:** All object relationships defined in → `specs/data-model.json`

**Acceptance Criteria:**
- Each object layout displays linked records grouped by type in cards (UI containers)
- Two types of linked record cards: parent reference cards (showing a single parent record the current object belongs to) and child relationship cards (showing multiple child records)
- Parent reference cards appear first, above child cards. They display key fields of the referenced parent record in a compact read-only row with a click-to-navigate link. Parent cards are auto-detected from reference fields on the current object that point to navigable object types.
- Account layouts show linked: Contacts, Leads, Opportunities, Quotations, Sales Orders, Invoices, Tickets, Assets, Activities, Service Contracts
- Opportunity layouts show linked: Account (parent), Contacts, Quotations, Sales Orders, Activities
- Quotation layouts show linked: Account (parent), Contact (parent), Opportunity (parent), Sales Orders, Line Items
- Sales Order layouts show linked: Account (parent), Contact (parent), Opportunity (parent), Quotation (parent), Invoices, Line Items
- Invoice layouts show linked: Account (parent), Contact (parent), Sales Order (parent), Line Items
- Contact layouts show linked: Accounts, Leads, Opportunities, Quotations, Tickets, Activities
- Lead layouts show linked: Activities (converted records shown via details card fields)
- Ticket layouts show linked: Account (parent), Contact (parent), Asset (parent), Service Contract (parent), Knowledge Base Articles, Activities
- Asset layouts show linked: Account (parent), Contact (parent), Product (parent), Tickets
- Service Contract layouts show linked: Account (parent), Tickets
- Linked record cards support inline actions (e.g., create new, view details)
- Clicking "Add New" on a linked record card pre-fills parent context fields (foreign key, parent_type) and hides them from the form
- After creating a linked record from a parent, the user is returned to the parent detail page
- Child object types (LineItem, Document, Comment) have URL routing but do not appear in the Ribbon navigation

## AI-First Intelligence Layer

### 21. Contextual Intelligence Briefing
As a user, I want to see an AI-generated briefing before every customer interaction so that I am prepared with the most relevant context without having to search for it.

**Acceptance Criteria:**
- When a user opens a record detail page for a supported object type (Account, Contact, Lead, Opportunity, Ticket, Quotation, SalesOrder, Invoice), the system displays a contextual AI briefing card between the header and quick action bar
- The briefing is generated by calling `AIService.chat()` with the current record's field data serialized as context and a type-specific system prompt
- The Cloud Function's existing data-aware context injection automatically enriches the AI prompt with related CRM records (activities, opportunities, tickets, etc.)
- Type-specific prompts tailor the briefing: Account (relationship health, pipeline value, activity patterns), Contact (role, interactions, open items), Opportunity (stage assessment, risks, next actions), Lead (qualification, engagement signals), Ticket (severity, SLA, resolution approach)
- The briefing updates when the record data changes (e.g., after an edit and refetch)
- The briefing is visible without additional clicks or navigation — it renders automatically on page load
- If no AI provider is configured, the briefing card is not shown

### 22. Multi-Level AI Summaries
As a user, I want AI-generated summaries at every level of the system so that I immediately understand the current state without reviewing individual records.

**Acceptance Criteria:**
- User level: the home screen shows an AI-generated priority briefing based on current dashboard metrics (pipeline value, open opportunities, tickets, leads, activities, invoices). The briefing is user-initiated via a "Generate Briefing" button, uses `AIService.chat()` with a user-level system prompt, and displays in a collapsible card with refresh controls. Falls back to a placeholder if no AI provider is configured.
- Account level: opening an account shows a relationship status summary with recommended actions
- Lead/Opportunity level: opening a lead or opportunity shows a status summary with next steps
- Deal Room: the first thing visible is a narrative summary of the deal
- Summaries refresh automatically as underlying data changes

### 23. AI-Powered Semantic Search
As a user, I want to search across all objects using natural language so that I can find records by intent, not just exact keywords.

**Acceptance Criteria:**
- The search understands intent (e.g., "that deal where the customer was worried about security" finds relevant records even if the word "security" was not used)
- Results span all objects: accounts, contacts, leads, opportunities, quotations, sales orders, invoices, tickets, assets, knowledge base articles, activities, emails, and documents
- Results are grouped by object type
- The AI/Search bar detects whether the user's natural language query is a search intent (e.g., "find deals in Germany", "open tickets for Acme") vs. a conversational question (e.g., "what is our pipeline value?")
- Search intent queries are routed to a `semanticSearch` Cloud Function operation that fetches records from all object types with IDs and key fields, sends them to the AI with a structured prompt, and returns matching records as JSON: `{ results: [{ type, id, name, reason }] }`
- Conversational queries continue to use the existing chat flow
- Semantic search results are displayed in the same grouped-by-type format as keyword results, with each result showing the record's display name, auto-number (if available), and a brief AI-generated reason for the match
- Results are clickable and navigate to the record's detail page
- An "AI Search Results" indicator with a sparkle icon distinguishes AI results from keyword results
- If the AI returns malformed JSON, the system falls back gracefully (empty results, no crash)
- Short keyword queries (1-3 words without question words) continue to use the existing debounced keyword substring search

### 24. AI Pipeline Coaching
As a sales rep, I want the system to recommend actions at each pipeline stage based on historical win/loss patterns so that I can increase my close rate.

**Acceptance Criteria:**
- The system analyzes historical deal data to identify patterns that lead to wins
- When a user views an opportunity, stage-specific recommendations are displayed (e.g., "Deals that included a technical demo at this stage close 3x more often")
- Recommendations are based on the company's own data, not generic advice

### 25. AI-Generated Knowledge Articles
As a user, I want the system to automatically generate knowledge base articles from CRM data so that the knowledge base grows without manual effort.

**Data Model:** KnowledgeArticle → `specs/data-model.json`

**Acceptance Criteria:**
- When a deal is closed (won or lost), the AI drafts a win/loss story with key decision factors, timeline, and objections
- When enough customers accumulate in a segment, the AI generates industry overview articles
- Generated articles are editable and must be reviewed before publishing

### 26. AI Meeting Summaries
As a user, I want the system to generate summaries from my meetings so that action items are automatically captured and linked to the relevant records.

**Data Model:** Activity → `specs/data-model.json`

**Acceptance Criteria:**
- After a Teams/Zoom call, the AI generates a summary with extracted action items
- The summary and action items are automatically linked to the relevant account, contact, and opportunity
- The user can review and edit the summary before it is finalized

### 27. Smart Email Parsing
As a user, I want the system to detect relevant data changes in incoming emails so that I can update records with one click instead of manual data entry.

**Acceptance Criteria:**
- The AI analyzes incoming emails and detects potential data updates (e.g., new budget mentioned, contact title changed)
- The system suggests the update with a one-click confirm action
- No data is changed without the user's explicit confirmation

### 28. AI Personal Performance Narratives
As a user, I want to see an AI-generated narrative about my personal performance so that I understand my progress and where to focus without interpreting charts.

**Acceptance Criteria:**
- Each user can view a performance narrative summarizing their activity, outcomes, and trends in natural language
- The narrative highlights strengths, gaps, and actionable recommendations
- The narrative is accessible from the user's dashboard

## SAP-Native Integration Architecture

### 29. SAP-Compatible Data Model
As an admin, I want the CRM data model to use SAP-compatible field types and lengths for shared objects so that data flows between CRM and SAP without transformation issues.

**Data Model:** SAP annotations on Account, Contact, Product, Quotation, SalesOrder, Invoice, LineItem, Asset, PricebookEntry → `specs/data-model.json`

**Acceptance Criteria:**
- Fields that have a counterpart in SAP (e.g., on Accounts/Business Partners, Products/Materials, Tickets/Notifications) match SAP's field types and lengths
- Data exchanged between CRM and SAP requires no truncation or type conversion

### 30. Pluggable Data Source Layer
As an admin, I want every CRM data call to be replaceable with a real-time service call to an external system of record so that the CRM can function as a native frontend for SAP or other systems.

**Data Model:** DataSourceConfig → `specs/data-model.json`

**Acceptance Criteria:**
- Each object's data source can be configured to read from the local CRM database or from an external system via a web service call
- The configuration can be set per object (e.g., accounts from SAP, tickets from local)
- Users experience no difference in the UI regardless of which data source is active

### 31. Bi-Directional Data Integration
As a user, I want to read data from and write data to external systems transparently within the CRM so that I work with live data without switching applications.

**Acceptance Criteria:**
- Data from external systems is presented natively in the CRM UI
- Changes made in the CRM can be written back to the external system of record
- The user does not need to know where the data originates

### 32. Open API
As a developer, I want the CRM to provide an open API so that external systems can integrate with the CRM bi-directionally.

**Acceptance Criteria:**
- The CRM exposes a REST API for all major objects
- The API supports read and write operations
- API documentation is available

## Unified Workspaces

### 33. Deal Rooms
As a sales rep, I want an optional, purpose-built workspace for important deals so that all related information, collaboration, and actions are in one place.

**Data Model:** DealRoom, Opportunity, Activity, Document, Comment, OpportunityContact → `specs/data-model.json`

**Acceptance Criteria:**
- Deal Rooms are opt-in: a user creates one from an Opportunity detail page via a "Create Deal Room" button; not every Opportunity has a Deal Room
- DealRoom is its own object type with fields: name (pre-filled from Opportunity, overridable), description, status (Active/Closed), opportunity_id (required reference)
- Deal Rooms have their own navigation entry in the left ribbon (after Opportunities) and a list view with columns: number, name, opportunity, amount, stage, status
- The Deal Room detail page is a custom workspace layout combining: AI-generated deal summary, quick actions (update stage, add note, schedule follow-up), pipeline stage progress visualization, activity timeline, team comment thread, deal info card, contacts with roles, and documents
- Once a Deal Room exists for an Opportunity, the Opportunity detail page shows "Open Deal Room" instead of "Create Deal Room"
- Deal Rooms are closed manually only — closing an Opportunity does not auto-close its Deal Room

### 34. Case Rooms
As a support agent, I want a single unified workspace per complex ticket so that all related information and collaboration are in one place.

**Data Model:** Ticket, Activity, Document, Comment, Asset, ServiceContract, KnowledgeArticle → `specs/data-model.json`

**Acceptance Criteria:**
- Each ticket has a Case Room view combining: interaction timeline, related assets and contracts, related knowledge base articles, and a team comment thread
- The Case Room displays an AI-generated case summary as the first visible element
- Users can perform key actions (update status, add note, link KB article) directly from the Case Room
- The Case Room is a VIEW of the Ticket (not a separate object) at route `/case-rooms/:ticketId`
- An "Open Case Room" button appears on the Ticket detail page using the same extra actions pattern as the Deal Room button on Opportunities
- The layout mirrors Deal Room: sticky header, AI summary, quick actions, two-column layout with activity timeline + comments on the left, ticket info + related records on the right
- Update Status quick action auto-sets `first_response_at`, `resolved_at`, `closed_at` timestamps based on the selected TicketStatus properties

### 35. User Timeline
As a user, I want to see a cross-object timeline of all my activities in a selected time period so that I can review my own work history.

**Data Model:** Activity, AuditLog → `specs/data-model.json`

**Acceptance Criteria:**
- The user timeline shows all activities (calls, emails, meetings, tasks) AND CRM events (record creations, status/stage changes, reassignments) across all objects
- CRM events are captured via AuditLogService triggered on every record create/update, writing to the AuditLog collection
- AuditLog records include: object_type, object_id, action (Create/Update), field_name, old_value, new_value, user_id, timestamp, object_name (display name), summary (human-readable description)
- Tracked field changes: Opportunity stage_id/result, Lead status, Ticket status_id/priority, any object owner_id reassignment
- The timeline is filterable by date range and event type (All, Activities Only, Events Only)
- The timeline is a standalone page at `/my-timeline`, accessible from the profile dropdown menu in the top bar
- Activity entries show type icon, subject, status chip, relative time, and parent record context
- CRM event entries show create/update icon, summary text, relative time, and object type chip
- All entries are merged and sorted chronologically (newest first)

### 36. Team Timeline
As a manager, I want to see a cross-object timeline of my team's activities and CRM events so that I can monitor team engagement and workload.

**Data Model:** Activity, AuditLog, Team → `specs/data-model.json`

**Acceptance Criteria:**
- The team timeline shows all activities across all team members
- The timeline is filterable by team member, date range, and activity type
- The timeline is a dedicated page at `/team-timeline`, accessible via a button on the Profile page for team managers
- Permission gate: only team managers (Team.manager_id == user) and admins can access
- Team members are loaded via `UserProfile.team_id`, activities by matching `owner_id` against that set of members

## Gamification & Motivation Engine

### 37. Leaderboards
As a user, I want to see leaderboards comparing my performance with colleagues across multiple dimensions so that I am motivated to improve.

**Data Model:** UserProfile, XPEvent → `specs/data-model.json`

**Acceptance Criteria:**
- Leaderboards are available for multiple dimensions (e.g., deals closed, data quality, responsiveness, collaboration)
- Leaderboards show rankings for configurable time periods (week, month, quarter)
- Users can see their own rank and trend
- A Leaderboard KPI card on the home screen shows the top 3 users by XP Total, with medal indicators, avatars, names, and XP values; clicking navigates to the full Leaderboard page

### 38. Points and Achievements
As a user, I want to earn points and achievements for CRM activities so that routine tasks feel rewarding.

**Data Model:** UserProfile (xp_total), XPEvent, Badge, UserBadge → `specs/data-model.json`

**Acceptance Criteria:**
- Users earn XP for CRM interactions (creating records, updating data, logging activities, closing deals, resolving tickets)
- Achievements are awarded for milestones (e.g., "First 100 Accounts", "SLA Warrior")
- Points and achievements are visible on the user's profile

### 39. Levels and Progression
As a user, I want to progress through levels based on my accumulated points so that I have a sense of growth and mastery.

**Data Model:** UserProfile (level, level_name), LevelDefinition → `specs/data-model.json`

**Acceptance Criteria:**
- Users advance through named levels (e.g., Rookie → Closer → Dealmaker → Legend)
- Leveling up can unlock additional system capabilities configured by the admin
- Current level and progress to the next level are visible on the user's profile

### 40. Collectible Badges and Trophies
As a user, I want to collect unique badges and trophies so that my accomplishments are visible and recognized.

**Data Model:** Badge, UserBadge → `specs/data-model.json`

**Acceptance Criteria:**
- Badges are awarded for specific accomplishments and milestones
- Badges and trophies are displayed on the user's profile as a trophy case
- An admin can create custom badges

### 41. Celebration Animations
As a user, I want to see visual celebrations when I hit milestones or personal bests so that accomplishments feel rewarding.

**Acceptance Criteria:**
- The system displays animations for key events (closing a deal, hitting a target, breaking a personal best, leveling up)
- Celebrations are non-intrusive and do not block workflow

### 42. AI-Assigned Monthly Challenges
As a user, I want to receive a personalized monthly challenge assigned by the AI so that I am motivated to build healthy work habits.

**Data Model:** Challenge → `specs/data-model.json`

**Acceptance Criteria:**
- Each month, the AI assigns a personalized challenge based on the user's data, role, and behavior patterns (e.g., "Contact 5 existing customers this month to check in")
- The challenge is presented as a mission with a specific award, not a suggestion
- Progress toward the challenge is tracked and visible
- Completing the challenge earns a unique award or badge

### 43. Streak Tracking
As a user, I want to see my activity streaks so that I can build and maintain productive habits.

**Data Model:** Streak, UserProfile (current_streak_days, longest_streak_days) → `specs/data-model.json`

**Acceptance Criteria:**
- The system tracks consecutive-day streaks for configurable activities (e.g., logging activities, contacting customers)
- Streaks are visible on the user's dashboard
- The connection between streaks and business outcomes is shown (e.g., "Your 18-day contact streak correlates with a 30% drop in churn")

### 44. Gamification-Based Performance Reviews
As a manager, I want to use gamification data (levels, badges, challenge completions, streaks) as part of performance reviews so that evaluations are backed by objective data.

**Data Model:** UserProfile, UserBadge, Challenge, Streak, PersonalBest → `specs/data-model.json`

**Acceptance Criteria:**
- Managers can view a performance portfolio for each team member showing their gamification history
- The portfolio includes levels reached, badges earned, challenges completed, and streak records
- The data is exportable for use in formal review processes

## Zero-Friction UX

### 45. One-Tap Contextual Actions
As a user, I want contextual quick actions available on every record so that I can perform common tasks with minimum clicks.

**Acceptance Criteria:**
- Each record type displays context-appropriate quick actions (e.g., "Log Call", "Send Quote", "Update Stage" on an opportunity)
- Actions are accessible with a single tap or click
- Activity-supporting types (Account, Contact, Lead, Opportunity, Ticket) show Log Call, Log Email, Log Meeting, New Task
- Document conversion actions are shown in the QuickActionBar: Opportunity shows New Quote + New Sales Order, Quotation shows New Sales Order, SalesOrder shows New Invoice
- Lead shows a Convert button in the QuickActionBar, disabled if already converted
- The QuickActionBar renders for any object type with at least one applicable action
- Mobile swipe gestures are deferred to a future release

### 47. Progressive Disclosure on Forms
As a user, I want forms to show only the most important fields by default so that data entry is fast and not overwhelming.

**Acceptance Criteria:**
- Record creation and edit forms display a minimal set of key fields by default
- Additional fields are revealed on demand
- The system learns which fields each user frequently uses and adapts the default view

### 48. Role-Adaptive UI
As an admin, I want to configure entirely different layouts, navigation, and default actions per role so that each user sees an interface tailored to their job.

**Data Model:** Role (ribbon_items, visible_cards, layout_config) → `specs/data-model.json`

**Acceptance Criteria:**
- Each role can have a distinct layout, navigation structure, and set of default actions
- A support agent sees a fundamentally different interface than a sales manager
- An admin can configure and assign role-based layouts

### 49. Responsive-First Design
As a user, I want the system to work seamlessly across desktop, tablet, and mobile so that I can use it on any device.

**Acceptance Criteria:**
- The UI adapts to the screen size and device type
- All core features are accessible on mobile, tablet, and desktop
- No separate mobile application is required

### 50. Reverse Data Entry
As a user, I want to create records by providing a website URL, a business card photo, or a LinkedIn profile link so that the system does the data entry for me.

**Data Model:** Account, Contact, Document → `specs/data-model.json`

**Acceptance Criteria:**
- Pasting a company website URL creates an account pre-filled with company name, address, industry, size, and description
- Uploading a business card photo creates a contact pre-filled with name, title, email, phone, and matched to an existing account
- Pasting a LinkedIn profile URL creates a contact pre-filled with public profile information
- The user reviews and confirms all pre-filled data before saving

## Self-Growing Knowledge & Data Quality

### 51. Case-to-Knowledge-Base Conversion
As a support agent, I want to convert a resolved case reply into a knowledge base article with one click so that proven solutions are captured without extra effort.

**Data Model:** Ticket, KnowledgeArticle, TicketKnowledgeArticle → `specs/data-model.json`

**Acceptance Criteria:**
- A one-click action on a resolved ticket creates a draft knowledge base article from the resolution
- The article includes a link to the original case and the user who resolved it
- Multiple cases can be linked to the same article over time, surfacing recurring issue patterns

### 52. Auto-Logging from Email
As a user, I want the system to automatically log emails from Outlook or Gmail as activities so that my interaction history is complete without manual entry.

**Data Model:** Activity (is_auto_logged) → `specs/data-model.json`

**Acceptance Criteria:**
- Emails sent to or received from known contacts are automatically logged as activities
- Logged emails are linked to the relevant contact and account
- The user can review and remove auto-logged items

### 53. Intelligent Duplicate Management
As a user, I want the system to automatically detect and manage duplicate records so that data stays clean without manual deduplication efforts.

**Acceptance Criteria:**
- The AI continuously scans for potential duplicate records
- The most complete record is shown as the primary in list views, searches, and reports
- Potential duplicates are linked to the primary record and shown on its detail page
- The user can merge duplicates or unlink false positives

### 54. Trend Analytics
As a user, I want to see trend-based analytics showing direction and projections so that I understand where I am heading, not just where I have been.

**Acceptance Criteria:**
- Analytics show trends over time with directional indicators (improving, declining, stable)
- Projections are displayed (e.g., "At your current pace, you'll hit 110% of your Q2 target")
- Trends are available for key metrics: pipeline value, close rate, activity volume, response times

### 55. Personal Bests
As a user, I want the system to track and celebrate my personal records so that I am aware of my peak performance.

**Data Model:** PersonalBest → `specs/data-model.json`

**Acceptance Criteria:**
- The system tracks personal bests for key metrics (e.g., deals closed in a quarter, fastest ticket resolution, largest deal)
- When a personal best is broken, the user is notified with a celebration
- Personal bests are visible on the user's profile

## Agentic Engineering

### 56. AI-Powered System Configuration
As an admin, I want to describe configuration changes in natural language and have the AI build them for my approval so that system customization is fast and accessible.

**Acceptance Criteria:**
- The admin describes a configuration need (e.g., "Add a competitor field to opportunities with a dropdown of known competitors")
- The AI creates the configuration (field, validation, layout update) and presents a preview
- The configuration is applied only after the admin explicitly approves

### 57. AI-Powered Feature Development
As an admin, I want to describe new feature requirements and have the AI scaffold them for my approval so that custom functionality can be developed without traditional coding.

**Acceptance Criteria:**
- The admin describes a feature need in natural language
- The AI scaffolds the feature (data model, UI, logic) and presents it for review
- The feature is deployed only after the admin explicitly approves
- Changes are reversible

## Data Integration

### 60. Multi-Language UI Labels
As a user, I want the CRM interface to be displayed in my preferred language so that I can work comfortably in my native language.

**Acceptance Criteria:**
- All UI labels (navigation, buttons, field labels, enum values, section headers, dashboard widgets, dialog text) are translatable
- English is the default language for all labels
- An admin can add target languages from a predefined list of ~30 common ISO languages
- An admin can manage translations for each language in Settings: view all labels in a two-column table (English | Target Language) and edit translations inline
- An admin can use an AI button to batch-translate all untranslated labels into a target language
- The AI translation shows progress per batch and saves results to the database
- Each user can select their preferred language on their Profile page
- When a user selects a language, all UI labels switch immediately to that language
- The language preference persists across sessions (stored on UserProfile)
- Enum values (e.g., "Active", "Draft") display translated but store English values in the database
- Translations are stored as one record per language for efficient loading (single read per session)
- If a translation is missing for a label, the English default is shown as fallback
- All page components (HomePage, LoginPage, SettingsPage, ObjectListPage, ObjectDetailPage, ObjectCreatePage, App.jsx) wrap hardcoded English strings with `t(key, fallback)` calls from TranslationService
- The label catalog (keys and English defaults) is shared across implementations, and the product ships reviewed language packs for eight languages (German, French, Spanish, Dutch, Portuguese, Italian, Japanese, Simplified Chinese) that can be imported into any instance by script; in-app AI translation remains the path for additional languages and for labels added after a pack was built
- A newly installed instance offers all bundled languages with no import or configuration step; a language pack added to the product later appears on existing instances after an upgrade, while languages an admin has edited or deleted are never overwritten or resurrected

### 59. Data Replication from External Systems
As an admin, I want to replicate data from external web services into CRMThree so that records from other systems (e.g., SAP) are available locally.

**Acceptance Criteria:**
- The Settings page includes a "Data Replication" section visible to admins
- Admin can configure a replication source per object type: web service URL, request body template, and field mapping (source field → CRM field)
- Admin can specify a key field used for matching (e.g., account_number for Accounts) to determine whether to create or update
- A "Run" button triggers replication: calls the web service, maps response fields to CRM fields, and upserts records (create if new, update if existing based on key field match)
- Records with a "Delete" flag in the source are skipped (not imported)
- After replication completes, a summary shows: records created, records updated, records skipped, and any errors
- Replication is available for all navigable object types
- Field mapping is configurable per replication source

### 61. Pessimistic Record Locking
As a user, I want records to be locked while another user is editing them so that we do not overwrite each other's changes.

**Acceptance Criteria:**
- When a user enters edit mode on a record, a lock is acquired in the database
- Other users viewing the same record see a lock indicator showing who is editing and cannot enter edit mode
- The lock is released when the editing user saves or cancels
- Locks have a TTL (15 minutes) to handle browser crashes or abandoned sessions
- A heartbeat extends the lock while the user is actively editing
- The lock is released on page navigation via `beforeunload`
- Expired locks are treated as unlocked

### 62. User Management
As an admin, I want to manage who can use the CRM from within the application so that provisioning a colleague does not require direct database access.

**Acceptance Criteria:**
- The Settings page includes a "User Management" section visible only to admins
- The section lists every user profile with name, email, role, status, level and XP
- Status distinguishes Active, Inactive, and Pending (invited but never signed in)
- An admin can change any user's role from the list; the change takes effect on that user's next session
- An admin can invite a user by email, first name, last name and role, creating a profile before that person has ever signed in
- When the invited person signs in with Google using that email, the existing profile is claimed automatically and they get straight in — no second provisioning step
- An admin can deactivate and reactivate a user; a deactivated user is refused at sign-in and sees an explanatory message
- An admin can delete a user profile; records created or owned by that user are unaffected
- An admin cannot change their own role, deactivate themselves, or delete themselves
- If the email whitelist is in use and an invited address does not match it, the invite dialog warns and offers to add the address to the whitelist in the same step
- Sign-in resolution order is: profile by `auth_uid`, then unclaimed profile by email, then first-user bootstrap, then rejection

### 63. Configurable Default List Sort Order
As a user, I want every list to open in a predictable order, and as an admin I want to choose that order per object, so that opening Accounts or Contacts does not present records in what looks like random sequence.

**Acceptance Criteria:**
- Every list page opens sorted; no list is served in raw database document order
- The Settings page includes a "List Sorting" section visible only to admins
- The section lists every object that has a list page, with its current sort setting
- For each object the admin chooses between exactly two sort bases: Number (the object's auto-number) or Name (the object's primary display field)
- For each object the admin chooses a direction: ascending or descending
- The section shows which database field each choice resolves to
- Changes save immediately and take effect the next time the list is opened
- With no setting saved, an object sorts by Number ascending
- A user can still click a column header to re-sort a list ad hoc; that choice is not persisted and does not change the configured default
- Sorting is applied by the database across the whole collection, not only to the page in view, so paging through a list follows one continuous order
- When a sorted list would omit records that lack the sorted field, the section warns the admin, states how many records are affected, and offers to assign the missing numbers

### 64. Opportunity Kanban Board
As a sales user, I want to see the pipeline as a board of stage columns and move a deal to another stage by dragging it, so that I can review and advance deals without opening each record.

**Acceptance Criteria:**
- The Opportunities list offers two displays, Table and Kanban, switched by a control on the list page; the choice is remembered in the user's browser
- The board shows one column per active pipeline stage in stage order, the closed stages (won and lost) included
- Each column header shows the stage name, the number of opportunities in it and their total amount; amounts in different currencies are totalled per currency and never added together
- Each card shows the opportunity name (which opens the record), the account, the amount with its currency, the expected close date and the owner
- Open opportunities carry alerts: one when the opportunity has an overdue open activity, another when it has no open activity at all
- Dragging a card onto another column moves the opportunity to that stage; a menu on each card offers the same move without dragging (keyboard and touch)
- A move applies the stage's rules: the probability takes the stage's default; a won stage sets the result to Won and the actual close date to today; a lost stage first asks for a loss reason, then sets the result to Lost and the actual close date to today; moving a closed opportunity back to an open stage sets the result to Open and clears the actual close date and the loss reason
- A move is audited, notifies and awards XP exactly like a stage change saved on the record page; winning a deal shows the celebration
- A move is refused with a message naming the user when another user holds the record's edit lock
- A search field above the board filters the cards by opportunity name and account name
- When the board is wider than the screen, holding a dragged card near its left or right edge scrolls the board

## Retrofit from a customer project (2026-10-16)

Generic capabilities first built in a customer project and adopted by the standard. UX in `ux.md` items 59 to 77.

### 65. Addresses, Browser Navigation and Deep Links
As a user, I want every page to have its own address so that the browser's back and forward buttons, reload and bookmarks work and I can send a colleague a link to a record.

**Acceptance Criteria:**
- Every page has an address: home, object lists (with search, paging, sort, favorites and filter in the query), record pages, new-record pages (with prefill), workspaces, settings, profile and timelines
- Navigating to another page adds a browser history entry; paging, sorting and searching within a list replace the current one; back from a record returns to the same list page
- Reloading a page shows the same page; edit mode is not restored (the record opens read-only)
- A link opened while signed out shows the sign-in page and then the linked page; signing out on purpose forgets the page
- A record the user may not see, or that does not exist, shows the usual not-found or no-access message
- The server answers every non-API address with the application; unknown API addresses stay 404
- Reference fields and reference columns are links to the referenced record (UX 59)

### 66. Favorites
As a user, I want to mark records as favorites and list them quickly so that the records I work on every day are one click away.

**Acceptance Criteria:**
- Any record of any object can be starred and unstarred by the signed-in user; favorites are stored per user on the server, without a fixed limit
- Every object list can be filtered to the user's favorites by the server, so search, sort, paging and export work at any table size
- The user's starred record ids are available when the application starts, so stars show on lists and record pages without extra requests
- A favorites list returns the user's most recent favorites (up to 50) that the user can still see, with name and number; deleted or no longer visible records are left out
- The home page shows the newest favorites and the count per object (UX 62)

### 67. Related Records at Scale
As a user, I want record pages to open fast even when a record has thousands of related records, and still reach all of them.

**Acceptance Criteria:**
- A record page loads at most 100 related records per object (the newest); documents load their line items complete
- The record page knows the true total per related object and offers "View all", which opens the object's list filtered to the record
- Related lists show number, title or description and a meaningful status (UX 63)

### 68. Action Preconditions and Double-Submit Protection
As a user, I want actions that cannot run to be disabled with their reasons, and every action to run exactly once, so that I do not run into errors or create records twice.

**Acceptance Criteria:**
- Each action with preconditions (document conversion, lead conversion, deal room creation and others) has a server-side check without side effects that returns the reasons it cannot run; the button is disabled with these reasons as tooltip (UX 65)
- The same checks run again when the action is submitted; a refused action returns its reasons
- While a changing request runs, the client blocks further clicks (UX 66)
- The server ignores an identical request from the same browser tab repeated within one second

### 69. Server-Granted Edit Lock and Unsaved Changes
As a user, I want edit mode to start only when the server granted me the lock, and to be asked before I lose unsaved changes, so that nobody overwrites anyone and nothing typed gets lost. Extends story 61.

**Acceptance Criteria:**
- Edit mode starts only after the server granted the lock; the server refuses changes to a locked record from anyone but the lock holder, including the same user in another browser tab
- Locks end after 15 minutes without activity; the editor is told so
- Administrators can release a lock someone else holds; the holder's browser leaves edit mode and is told why
- Leaving a record with unsaved changes (also by browser back) asks with an in-app dialog to stay or to discard (UX 68)

### 70. Code Lists as Data
As an administrator, I want value lists to be data with codes and labels per language so that changing a list needs no deployment, and as a user I want coded fields to show code and meaning.

**Acceptance Criteria:**
- The data model binds a field to a named code list; codes, labels per language, order and active flag are stored in the database
- Administrators maintain lists in Settings (UX 76); changes reach open browsers at once
- Fields show "CODE label"; long lists are searchable; stored values outside the list stay selectable and savable; a default outside the list is not preselected (UX 70)
- Existing enum fields keep working; a list can replace an enum without a data migration

### 71. Record Visibility: Private Deals, Opportunity Teams and Manager Hierarchy
As a sales manager, I want opportunities and their documents to be visible only to the people working on them and to their managers so that deals stay private.

**Acceptance Criteria:**
- Opportunities are private: a user sees an opportunity as its owner, as a member of its team, or above the owner in the manager hierarchy (each user profile names its manager)
- Quotes, sales orders and the other children of a deal follow their opportunity, or their own owner when they have none
- Administrators and holders of the permission "all deals" see every deal
- The owner, the managers above the owner and administrators maintain the opportunity team: members with access Edit or Read and a team role (UX 73); members with Read cannot edit
- Approvers of a record's approval requests and their delegates see that record (story 72)
- Visibility is enforced by the server on lists, record pages, global search, export, dashboard figures, record locks and the real-time stream; a hidden record answers "You do not have access to this record (it belongs to another team)."
- Accounts, contacts and assets stay visible to everyone with read access
- Each real-time event about a deal costs one visibility check per connected user without "all deals"; deployments with many such users need a cached visibility set

### 72. Approval Workflow
As a sales rep, I want records that exceed limits to go through approvals defined by rules, and as an approver I want to see and decide what waits for me, so that discounts and terms are controlled without e-mail ping-pong.

**Acceptance Criteria:**
- Administrators define approval rules per object: conditions on fields with thresholds, the approval level, and the approver (a user or a group); approvers name delegates for a period
- "Approval check" evaluates the rules on the record and lists which apply and why, without side effects
- "Submit for approval" creates the requests in level order with the submitter's comment; "Recall" withdraws open requests
- Approvers and their delegates decide with Approve or Reject and a comment; a rejection ends the round; the last approval completes it
- A record waiting for approval is read-only for the submitter until it is decided or recalled
- Every step is in the record's history and notifies the people concerned (in the application and by e-mail, story 73)
- The home page shows the user's waiting approvals (UX 74)

### 73. E-mail Outbox
As an administrator, I want the CRM to send its notifications by e-mail through the company's mail server, in each recipient's language, with a visible outbox, so that people learn about events without opening the CRM.

**Acceptance Criteria:**
- Notification e-mails (approvals, assignments, configurable events) are written to an outbox and sent in the background through the configured SMTP server and sender address
- Subject and text come from the language packs in the recipient's language (user or contact language, else the instance default) and link to the record
- An allow-list of addresses or domains (or all) decides which recipients receive mail, so test systems never write to real customers
- Failed mails keep their error and attempts; an administrator can retry them (UX 75)

### 74. Integration Connections, Call Log and Job Queue
As an administrator, I want every connection to an external system configured, tested and monitored in one place so that integration problems are found and fixed without a developer. Extends stories 30 (pluggable data sources), 31 (bi-directional integration) and 59 (data replication).

**Acceptance Criteria:**
- A connection has an address, a login whose password is encrypted with a master key kept outside the database, a mode (Live or Off as emergency switch), a timeout and a maximum of parallel calls
- "Test" and "Test all" check reachability and login and store the result
- Every call is logged with connection, operation, record, duration, HTTP status, outcome class (success, warning, business error, system error, transport error, empty answer, refused) and message
- Long-running or retryable work runs in a job queue with state and attempts; administrators retry or cancel jobs
- Productive and demo instances never answer calls with simulated data

### 75. User-Defined List Views
As a user, I want to create my own views of a list, choosing which columns appear, in which order, how the list is sorted and filtered, so that each list shows what I need without opening records.

**Acceptance Criteria:**
- A view belongs to one object and holds a name, the columns in order, the sort (field and direction) and filters (any field, the operators of the list filters, favorites only)
- Views are private, shared with the owner's team, or shared with everyone; sharing with everyone needs an admin right; only the owner (or an admin) changes or deletes a view
- "All" and "Favorites" are built-in views of every list; each user pins up to five views (built-in or saved) as tabs, stored per user and object on the server and delivered with the application start (All and Favorites when nothing is pinned)
- Each user marks one view per object as default, a built-in view included; administrators set the default view for everyone; without one the object's built-in columns and default sort (story 63) apply
- Only fields with a database index can be sorted or filtered in a view (the server refuses others), so views never make the database scan a large table; any field can be a column
- Filter values are entered like the field itself (record picker for references, value lists for coded fields), never as internal ids
- Filters and sorts of a view are applied by the server, so views scale with the table; export (CSV) follows the current view's filters, sort and columns
- The chosen view is part of the page address (story 65), so a link opens the list in that view
- Views referring to a field that no longer exists ignore that field and say so
- UX in `ux.md` item 78

