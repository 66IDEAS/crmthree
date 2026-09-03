# Plain Functional Specifications

This document defines how the **Plain** implementation realizes the functional stories defined in `specifications.md`.

The Plain implementation delivers CRMTHREE as a **single-file, zero-dependency HTML application** that stores its entire state in browser `localStorage`. Every core functional domain from the product specification is represented. Where client-only execution in a web browser requires adaptations or imposes technical boundaries, those are explicitly detailed below.

---

## 1. Sales Workflow

| Story | Feature | Plain Implementation & Mechanisms | Status & Limitations |
|---|---|---|---|
| **1** | **Account Management** | Full CRUD for company accounts. Supports parent/child account hierarchy tree lookups and links to all dependent entities. | **Supported**. Stored in `c3.tbl.Account`. |
| **2** | **Contact Management** | Full CRUD for contacts. Direct account link via `account_id`, plus many-to-many associations via `ContactAccount` junction table. | **Supported**. Stored in `c3.tbl.Contact`. |
| **3** | **Lead Management & Conversion** | Full lifecycle: New → Contacted → Qualified/Unqualified → Converted. Header action opens the "Convert Lead" modal pre-populating Contact, Account, and optional Opportunity. | **Supported**. Atomic transaction updates Lead status to "Converted" and creates child records in `localStorage`. |
| **4** | **Opportunity Management** | Pipeline tracking with stages. Inline line-item editor auto-calculating item net value and document total. Conversions to Quotation and Sales Order. | **Supported**. Line items stored in `c3.tbl.LineItem` with parent reference. |
| **5** | **Quotation Management** | Identified by auto-number (`0000000010` displayed as `10`), with Account as primary field, inline line items, and conversion to Sales Order. | **Supported**. |
| **6** | **Sales Order Management** | Identified by auto-number, inline line items with net value auto-calculation, and conversion to Invoice. | **Supported**. |
| **7** | **Invoice Management** | Standalone creation or created from Sales Order. Inline line items with net calculation. | **Supported**. |
| **8** | **Product Management** | Product catalog referenced in opportunity, quote, order, and invoice line items with unit prices. | **Supported**. |
| **9** | **Activity Management** | Logging calls, emails, meetings, tasks. Filtered chronological timeline embedded in related record views. | **Supported**. |

---

## 2. Service Workflow

| Story | Feature | Plain Implementation & Mechanisms | Status & Limitations |
|---|---|---|---|
| **10** | **Ticket Management** | Service ticket CRUD with subject, priority, category, account, contact, and status transitions. Auto-number identification. | **Supported**. |
| **11** | **SLA Management** | SLA target resolution and first response tracking. In-memory timer checks highlight overdue tickets with colored warning chips. | **Supported**. In-browser date comparisons. |
| **12** | **Knowledge Base** | Article authoring, categorization, and search. One-click linking to tickets via `TicketKnowledgeArticle`. | **Supported**. |
| **13** | **Service Contract Management** | Contract dates, coverage, and account linkages. | **Supported**. |
| **14** | **Asset Management** | Equipment and asset tracking with serial numbers and account ownership. | **Supported**. |

---

## 3. Workspaces: Deal Rooms & Case Rooms

| Story | Feature | Plain Implementation & Mechanisms | Status & Limitations |
|---|---|---|---|
| **33** | **Deal Rooms** | Dedicated workspace view for high-value opportunities. Header with stage progress stepper, two-column layout: left column with activity timeline and team discussion thread; right column with deal metrics, key contacts, and documents. | **Supported**. Embedded team comments persist in `c3.tbl.Comment`. |
| **34** | **Case Rooms** | Workspace view for Tickets (`/case-room?id=...`). Reuses Deal Room layout with ticket details, SLA countdown, linked articles, and internal notes. | **Supported**. Virtual navigation entry rendering ticket workspace. |
| **35** | **User Timeline** | Chronological feed of the current user's activities and audit events (`c3.tbl.AuditLog`), with type filters and XP gain chips. | **Supported**. In-memory union and sort of activities and audit events. |
| **36** | **Team Timeline** | Manager/admin feed of all team members' activities and events with member filtering. | **Supported**. Accessible only to users with Manager/Admin roles. |

---

## 4. Cross-Cutting & Shell

| Story | Feature | Plain Implementation & Mechanisms | Status & Limitations |
|---|---|---|---|
| **15** | **Dashboard & Reporting** | KPI cards (Pipeline Value, Open Opps, Tickets, Leads, Activities, Leaderboard), horizontal bar chart (Opps by Stage), donut chart (Tickets by Priority), line chart (Activity Trend). | **Supported**. Rendered with compact native SVG shapes and CSS bars without external chart libraries. |
| **16** | **Global Search** | Instant debounced multi-collection search across names, auto-numbers, emails, and subjects with grouped drop-up results. | **Supported**. In-memory string scan across all collections. |
| **17** | **Notifications** | Bell icon with unread count badge, notification popover panel, mark as read, and desktop notification dispatch via browser Notification API. | **Supported**. Auto-generated client-side on record save triggers and synced across tabs via `storage` events. |
| **18** | **Role-Based Access Control** | Roles (Admin, Manager, User). Governs ribbon navigation item visibility and view/edit permissions. | **Supported**. Enforced by client-side guard module. |
| **18b** | **Email/Domain Whitelist** | Whitelist entries configured in Settings. Sign-in / session switch checks email against whitelist. | **Supported**. |
| **19** | **Data Import & Export** | List view CSV export. Settings CSV import with column-to-field mapping and progress preview. Full JSON database backup and restore. | **Supported**. Export streams Blob URLs; import uses HTML5 FileReader API. |
| **20** | **AI Assistant** | Multi-turn chat assistant in the bottom persistent bar. Heuristic auto-detects questions vs. keyword search. | **Supported with Limitation**. Direct browser `fetch()` to configured AI provider API (OpenAI/Anthropic/Gemini). User provides their own key. |
| **58** | **Linked Records on Cards** | Detail views show related records as stacked data grid cards with row navigation, quick "+ Add", and link/unlink dialogs. | **Supported**. |

---

## 5. Gamification & Motivation Engine

| Story | Feature | Plain Implementation & Mechanisms | Status & Limitations |
|---|---|---|---|
| **37** | **Leaderboards** | Dedicated page and home KPI widget ranking users by XP Total, Deals Closed, Activities Logged, and Tickets Resolved. | **Supported**. |
| **38** | **Points & Achievements** | Actions (log activity, close deal, resolve ticket) award XP defined in `XPEvent` configs. | **Supported**. Awarded automatically upon save. |
| **39** | **Levels & Progression** | XP thresholds define level progression (Rookie, Pro, Master, etc.) with profile progress bars. | **Supported**. |
| **40** | **Badges & Trophies** | Visual badge awards in profile Trophy Case. Earned vs locked states. | **Supported**. |
| **41** | **Celebration Animations** | Non-blocking confetti animation upon deal close, level up, or badge achievement. | **Supported**. Hand-rolled 25-line CSS keyframe particle animation; no canvas libraries. |
| **42** | **Monthly Challenges** | Active challenge card on profile. AI-generated or system-assigned targets with progress bars. | **Supported**. |
| **43** | **Streak Tracking** | Daily activity streak tracking (current streak and longest streak) shown in TopBar with fire icon. | **Supported**. Stored in `c3.tbl.Streak`. |
| **44** | **Performance Portfolio** | Leaderboard with per-window stats plus the profile trophy case and AI performance narrative. | **Adapted**. No dedicated manager portfolio page; served by leaderboard and team timeline. |
| **55** | **Personal Bests** | Track and celebrate personal records (most deals closed, fastest ticket resolution). | **Supported**. |

---

## 6. AI Intelligence Layer

| Story | Feature | Plain Implementation & Mechanisms | Status & Limitations |
|---|---|---|---|
| **21** | **Contextual Intelligence Briefing** | On-demand "Generate Briefing" button on record detail pages (Accounts, Contacts, Leads, Opportunities, Tickets). | **Supported with Limitation**. Direct client-side API call. Requires user to input AI key in Settings. |
| **22** | **Multi-Level AI Summaries** | Summarizes account relationships and opportunity risks into 3–5 actionable sentences. | **Supported with Limitation**. Browser-executed prompt template. |
| **23** | **AI Semantic Search** | Semantic natural language query resolution. | **Adapted**. Plain uses an enhanced in-memory token similarity search, with optional AI query expansion when an AI key is active. |
| **24** | **AI Pipeline Coaching** | Stage-by-stage deal advice based on opportunity age, amount, and activity history. | **Supported with Limitation**. Prompts active AI provider via browser fetch. |
| **25** | **AI-Generated KB Articles** | Converts resolved ticket summaries into draft Knowledge Articles. | **Supported with Limitation**. Browser fetch. |
| **26** | **AI Meeting Summaries** | Meeting content is summarized through the multi-turn AI assistant over the record context. | **Adapted**. No dedicated per-activity button; served by the assistant chat and briefing cards. |
| **27** | **Smart Email Parsing** | Parses raw email text into structured contact or lead fields. | **Supported with Limitation**. Browser fetch. |
| **28** | **AI Performance Narratives** | Generates monthly gamification and sales performance narrative for user profile. | **Supported with Limitation**. Browser fetch. |

---

## 7. Data Integration & Administration

| Story | Feature | Plain Implementation & Mechanisms | Status & Limitations |
|---|---|---|---|
| **29** | **SAP-Compatible Data Model** | All 39 objects retain SAP field lengths, types, and annotations in schema metadata. Auto-numbers pad with leading zeros in storage. | **Supported**. Strictly matches `specs/data-model.json`. |
| **30** | **Pluggable Data Source Layer** | Settings table configuring Local vs External data sources per object type. | **Supported with Limitation**. External calls use browser `fetch()`. Target servers must support CORS. |
| **31** | **Bi-Directional Integration** | Inbound reads with field mapping via replication and read-through sources. | **Adapted**. Inbound only; outbound write-through is not in this version. CORS applies. |
| **32** | **Open REST API** | Programmatic interface over the CRM data. | **Adapted**. Substituted with `window.CRM` JavaScript API and complete JSON database import/export endpoints. A static file cannot listen on an HTTP port. |
| **50** | **Reverse Data Entry** | Create leads by pasting raw email text (AI extraction into a prefilled form). | **Adapted**. Email intake implemented; website URL and business-card image intake are not in this version. |
| **53** | **Intelligent Duplicate Management** | In-memory similarity detection (Levenshtein / Trigram matching on names and emails) highlighting potential duplicates on detail views. | **Supported**. Pure client-side algorithm. |
| **54** | **Trend Analytics** | 7-day and 30-day directional indicators on dashboard metrics. | **Supported**. Calculated in-memory from record timestamps. |
| **56–57** | **Agentic Engineering (System Config & Feature Dev)** | — | **Not implemented**, matching the reference implementation, where both stories are open as well. |
| **59** | **Data Replication from External Systems** | Admin-triggered replication fetching external JSON, mapping fields, and upserting into `localStorage`. | **Supported with Limitation**. Requires CORS-enabled external web services. |
| **60** | **Multi-Language UI Labels** | Translatable UI catalog keyed to the shared 821-key label catalog. User language selector on profile switches labels immediately. Admin label editor in Settings with AI batch translation. | **Supported**. All eight product language packs are embedded in the file (gzip-compressed, inflated via `DecompressionStream`) and seeded through the per-language registry, per shared architecture section 13. |
| **61** | **Pessimistic Record Locking** | Prevents concurrent edits. Lock acquired on edit mode entry with 15-minute TTL; other tabs show lock indicator and disable edit button. | **Supported**. Synced across tabs via `c3.locks` and browser `storage` events. |
| **62** | **User Management** | Admin settings section to list users, invite by email, assign roles, and activate/deactivate accounts. Profile claiming simulated on first sign-in. | **Supported**. |
| **63** | **Configurable Default List Sort Order** | Admin settings section configuring default sort field (Number vs Name) and direction per object type, with incomplete data warning and backfill. | **Supported**. Stored in `c3.cfg.listSort`. |

---

## 8. Summary of Physical Browser Boundaries

Because the Plain flavour runs exclusively inside a sandboxed client browser without a server process:
1. **API Keys are not server-isolated:** Keys entered in Settings are kept in `localStorage`.
2. **CORS:** Direct HTTP calls to external integration services (Replication, Reverse Data Entry) require permissive CORS headers from the remote server.
3. **Storage Quota:** Overall storage is limited by the browser's `localStorage` quota (~5MB). File attachments are stored as Base64 strings, intended for lightweight documents and profile pictures rather than massive archives. Full backup/restore via JSON file download is provided to mitigate data loss.

