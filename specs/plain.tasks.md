# Plain Implementation Tasks

This task list defines the implementation plan for the **Plain** flavour in `implementations/plain/`. It is derived from `specs/plain.architecture.md`, `specs/plain.specifications.md`, and `specs/plain.ux.md`.

The Plain implementation is a **zero-dependency, single-file HTML application** storing all state in browser `localStorage`. Every byte counts: variable names, CSS classes, and internal data structures are optimized for extreme compactness and minimal file weight.

---

## Working Rules

- `[ ]` means not started, `[-]` means in progress, and `[x]` means complete.
- **Phase Order:** Complete tasks phase-by-phase.
- **Review Gates:** Every phase ends with a Review Gate. Stop at each gate, verify the implemented capabilities, report the findings to the user, and obtain explicit user approval before proceeding to the next phase.
- **Strict Independence:** No external runtime libraries, stylesheets, fonts, or CDN assets are permitted. Everything must be implemented in pure vanilla HTML5, CSS, and JavaScript within a single self-contained file (`implementations/plain/index.html`).
- **Storage:** All application state, schemas, configurations, and user data persist in `localStorage`.

---

## Phase 0 — Foundation, Golfed Framework & Storage Engine

- [x] **T0.1 Scaffold single-file application harness.** Create `implementations/plain/index.html` containing the foundational HTML structure, embedded `<style>`, and embedded `<script>`. Ensure the file can be opened directly from disk via `file:///` with zero dependencies. (`PL1`, `R1`)
- [x] **T0.2 Hand-roll golfed DOM and reactive helper utilities.** Build ultra-compact 1-to-2 character helpers for DOM selection, element creation, and event delegation (`$`, `$$`, `h`, `on`, `ev`). (`PL1`, Section "Code Golfing")
- [x] **T0.3 Build `localStorage` Data Access Layer (`DB`).** Implement JSON serialization and collection management under `c3.tbl.<Object>`, `c3.meta`, `c3.seq`, `c3.cfg`, `c3.locks`, and `c3.auth`. Include CRUD operations (`getById`, `list`, `create`, `update`, `remove`). (`PL3`, `R3`)
- [x] **T0.4 Implement atomic auto-number allocation.** Implement sequential auto-number allocation stored in `c3.seq`, padded with leading zeros for SAP parity (`0000000042`) and formatted on display by stripping padding (`42`). (`F1`–`F14`, `UX-P6`, `PL3`)
- [x] **T0.5 Implement in-memory Query Engine.** Support pagination (`page`, `pageSize`), multi-field sorting (`sortBy`, `sortDir`), filtering functions, and global search over `localStorage` collections. (`PL4`, `R3`, `F63`, `UX-P12`)
- [x] **T0.6 Seed technical and domain defaults.** Add idempotent initialization for system roles (`Admin`, `Manager`, `User`), default pipeline stages, ticket statuses, gamification levels, XP events, initial admin profile bootstrap, and sample demonstration records. (`F4`, `F10`, `F18`, `F38`–`F40`, `F62`, `PL3`)
- [x] **RG0.5 System bootstrap & seeding:** Verified automatic population of roles, pipeline stages, ticket statuses, gamification level tiers, XP events, admin profile, and initial demonstration records.

---

## Phase 1 — Visual System, Application Shell & Navigation

- [x] **T1.1 Implement hand-rolled micro CSS system.** Create pure CSS variables for Light and Dark themes, typography system stack, and compact utility classes. Include instant theme switching persisted in `c3.cfg.theme`. (`UX-P1`)
- [x] **RG1.1 Visual token fidelity:** Tested theme custom properties (`--bg`, `--surface`, `--primary`, `--accent` `#F7941D`, `--border`) with seamless instant Light/Dark switching.
- [x] **RG1.2 Top Bar layout:** Verified fixed header with 3px orange accent line, clickable wordmark, gamification metrics (`120 XP`, `Rookie`, `🔥 3d`), notification bell popover, and profile menu.
- [x] **RG1.3 Left Ribbon navigation:** Verified smooth collapsed (56px) to expanded (210px) toggle, pinned Settings section, and mobile slide-over drawer with backdrop overlay (<768px).
- [x] **RG1.4 Persistent Bottom AI/Search Bar:** Verified fixed bottom bar, `Cmd+K` / `Ctrl+K` keyboard shortcut, debounced multi-collection search grouping, and question-detection routing for AI prompts.
## Phase 2 — Generic Views, Data Grids & Core Record Lifecycle

- [x] **T2.1 Implement Table-Based List View.** Render clean HTML `<table>` with 5 default columns (auto-number first, display name second), semantic status chips, column-header sorting, and compact pagination controls (prev/next, page size selector). Honor default sort configuration from `c3.cfg`. (`UX-P12`, `UX-P13`, `F63`)
- [x] **T2.2 Implement Record Detail View & Progressive Disclosure Card.** Build sticky detail header (back button, headline, auto-number chip, Edit/Delete buttons) and two-column "Details" card hiding empty fields in read mode and showing native input fields in edit mode. Human-readable validation messages. (`UX-P6`, `UX-P9`, `F47`)
- [x] **T2.3 Implement Record Creation.** Build full-page and modal creation forms with minimal required fields and automatic date initialization to today's date. (`UX-P9`, `F47`)
- [x] **T2.4 Implement Linked Records Cards.** Render vertically stacked related record grids below the details card with compact tables, row click navigation, and "+ Add New" / "Link Existing" modal dialogs. (`UX-P11`, `F58`)

- [x] **RG2.6 CSV export & import:** Verified list view CSV export generating downloadable Blobs, and Settings CSV import with file reader, preview table, field mapping, and batch upsert.

---

## Phase 3 — Sales Workflow & Document Conversions

> The original T3.x items were lost to a truncated edit; reconstructed 2026-09-03 from
> `plain.specifications.md` and `plain.ux.md`. Continuous execution of the remaining phases
> (gates verified and recorded, no per-phase pause) authorized by the user on 2026-09-03.

- [x] **T3.0 Generate the Model Registry from the blueprint.** Add `scripts/generate-model.mjs` reading `specs/data-model.json` and the shared label catalog, rewriting the marked model block in `index.html`: SAP field lengths, enum values, references, required flags, list columns, linked cards, and the full ribbon object set (incl. Knowledge, Assets, SLAs, Contracts). Replace the hand-written `MODEL_DEFS`. (`PL6`, `F29`)
- [x] **T3.1 Implement the Quick Action Bar.** `Log Call` / `Log Email` / `Log Meeting` / `New Task` buttons pre-linking the parent record, plus per-type conversion buttons. (`UX-P8`, `F9`)
- [x] **T3.2 Implement inline line-item editing.** Item grid on Opportunity, Quotation, Sales Order and Invoice detail pages: SAP item numbering (10, 20, 30), product picker, live net-value calculation `qty * price * (1 - discount/100)`, footer total, row removal. (`UX-P10`, `F4`–`F7`)
- [x] **T3.3 Implement Lead conversion.** Modal with contact preview, editable account name and optional opportunity; atomic multi-record transaction marking the lead Converted. (`F3`, `UX-P17`)
- [x] **T3.4 Implement the document conversion chain.** Opportunity → Quotation → Sales Order → Invoice, copying line items with fresh item numbers and totals. (`F4`–`F7`, `UX-P17`)
- [x] **T3.5 Embed activity timelines on detail views.** Chronological activity feed on Account, Contact, Lead, Opportunity and Ticket details. (`F9`)

### Review Gate 3 — Sales Workflow Review
- Verify end-to-end sales lifecycle: Lead capture → Lead conversion → Opportunity pipeline.
- Verify inline line-item calculations and SAP item numbering.
- Verify document conversion sequence: Opp → Quote → Sales Order → Invoice.
- Verify activity logging and timeline display.
- Record findings and obtain user approval before starting Phase 4.

> **RG3 verified 2026-09-03 (browser):** model now generated from the blueprint (39 objects,
> parity labels); line item 3 × 1200 × 10% = 3240 calculated live with SAP item number
> 000010; conversion chain Opportunity → Quotation → Sales Order → Invoice copied items and
> totals at every step with source references set; lead conversion dialog created account,
> contact and opportunity atomically and marked the lead Converted; activities attach via
> quick actions and appear in linked cards. Full German label switch verified.

---

## Phase 4 — Service Workflow & Unified Workspaces

- [x] **T4.1 Implement Ticket & SLA Management.** Ticket CRUD with status transitions, priority chips, account/contact linking, and in-memory SLA target countdowns with overdue chips. (`F10`, `F11`, `F13`, `F14`)
- [x] **T4.2 Implement Knowledge Base & Case-to-Article Conversion.** Knowledge article views, tag filtering, and one-click action on resolved tickets to draft a KB article pre-filled with resolution notes. (`F12`, `F25`, `F51`)
- [x] **T4.3 Implement Deal Room Workspace.** Dedicated workspace layout for Opportunities: stage progress milestone stepper, two-column split layout (left: activity feed + team discussion comments thread; right: deal summary, contacts with roles, documents). (`F33`, `UX-P14`)
- [x] **T4.4 Implement Case Room Workspace.** Dedicated workspace layout for Tickets mirroring Deal Room layout with ticket details, SLA countdown, and linked articles. (`F34`, `UX-P14`)
- [x] **T4.5 Implement User and Team Timelines.** Build `/my-timeline` for current user and `/team-timeline` for managers, merging `Activity` and `AuditLog` records into a chronological feed with type filters and XP badges. (`F35`, `F36`)

### Review Gate 4 — Service & Workspaces Review
- Verify ticket lifecycle, SLA deadline highlighting, and Case-to-KB conversion.
- Verify Deal Room layout, stage progression, and discussion commenting.
- Verify Case Room layout and linked KB articles.
- Verify My Timeline and Team Timeline feeds.
- Record findings and obtain user approval before starting Phase 5.

> **RG4 verified 2026-09-03 (browser):** Case Room renders SLA countdown chips stamped by
> the create-hook from a matching SLA record (High -> 4h/24h), status selector, comment
> thread, KB card and Draft-KB action; Deal Room shows the 7-stage stepper (completed
> checks, current highlighted, close-stages update result and close date), activity feed,
> comments and deal info; My/Team timelines merge activities and the audit trail with type
> filter chips, team view gated to Manager/Admin.

---

## Phase 5 — Cross-Tab Real-Time Sync, Pessimistic Locking & Security

- [x] **T5.1 Implement Cross-Tab Real-Time Synchronization.** Wire `window.addEventListener('storage', ...)` to a reactive pub/sub event bus. When any tab mutates `localStorage`, all other tabs automatically refresh their visible views, unread notification counts, and record locks. (`PL5`, `R4`, `F17`)
- [x] **T5.2 Implement In-App Notifications.** Add notification trigger utility on record saves (ticket assigned, deal won, SLA breach). Display unread badge on bell, popover panel with relative timestamps ("5m ago"), mark all as read, and optional browser desktop notifications. (`F17`, `UX-P2`)
- [x] **T5.3 Implement Pessimistic Record Locking.** Acquire lock on entering edit mode with 15-minute TTL; sync across tabs via `c3.locks`. Display lock indicator (`"{User} is editing"`) on other tabs and disable their edit controls. Release lock on save, cancel, or page unload. (`F61`, `UX-P6`, `PL5`)
- [x] **T5.4 Implement Client-Side RBAC & Whitelist.** Guard routes and navigation items based on user role permissions (Admin, Manager, User). Enforce email/domain whitelist at session start. (`F18`, `F18b`, `UX-P3`)
- [x] **T5.5 Implement User Management in Settings.** Admin interface listing all user profiles with status (Active/Inactive/Pending), role editor dropdown, and user invitation dialog. (`F62`, `UX-P17`)
- [x] **T5.6 Implement Configurable Default List Sort Order in Settings.** Admin interface configuring default sort field (Number vs Name) and direction per object type, with hidden-records detection and auto-number backfill. (`F63`, `PL4`)

### Review Gate 5 — Real-Time & Security Review
- Verify real-time cross-tab updates by editing in Tab A and observing Tab B update instantly.
- Verify pessimistic locking across two open tabs on the same record.
- Verify notification creation and popover interactions.
- Verify user management, role switching, and default list sorting.
- Record findings and obtain user approval before starting Phase 6.

> **RG5 verified 2026-09-03 (browser):** storage-event bus re-renders open tabs; lock held
> by another tab shows the "is editing" note and disables Edit/Delete, with 15-minute TTL
> and beforeunload release; ticket assignment to another user creates their notification
> (bell badge, popover, mark-all-read, optional desktop notifications); profile switcher
> enforces whitelist and deactivation; user management, access control and per-object
> default list sorting live as admin accordions in Settings.

---

## Phase 6 — Home Dashboard, Micro-Charts & Gamification

- [x] **T6.1 Build Home Dashboard & Native SVG Micro-Charts.** Implement 12-column responsive dashboard with KPI summary cards and pure SVG/CSS charts: Opportunities by Stage (horizontal bars), Tickets by Priority (donut chart), Activity Trend (7-day line chart), and Revenue by Status (bar chart). Zero external charting dependencies. (`UX-P15`, `F15`, `F54`)
- [x] **T6.2 Build Gamification Engine.** Auto-calculate and award XP for activities, deal closings, and ticket resolutions based on `XPEvent` configs. Compute level progression (`Rookie` → `Pro` → `Master`). (`F38`, `F39`)
- [x] **T6.3 Build Top Bar Gamification Display & Streaks.** Render current XP, level badge chip, and daily streak flame icon (`🔥 3d`) in Top Bar. (`F43`, `UX-P2`)
- [x] **T6.4 Build Profile Trophy Case, Personal Bests & Monthly Challenges.** Render earned vs locked badges in a Trophy Case grid, personal best milestones, and active AI challenge progress card on the user's Profile page. (`F40`, `F42`, `F55`, `UX-P16`)
- [x] **T6.5 Build Leaderboard Page.** Render full leaderboard page ranking users across XP Total, Deals Closed, Activities Logged, and Tickets Resolved with time filters (Week, Month, Quarter) and top 3 medals. (`F37`, `UX-P16`)
- [x] **T6.6 Build Celebration Confetti Animation.** Create non-blocking 15-particle CSS keyframe confetti flutter animation triggered when winning a deal, leveling up, or earning a badge. (`F41`, `UX-P16`)

### Review Gate 6 — Dashboard & Gamification Review
- Verify dashboard KPI cards and SVG micro-charts render accurately with proper theme colors.
- Verify XP awards, level progression, and streak calculations.
- Verify Profile Trophy Case and Leaderboard page.
- Verify confetti celebration triggers without blocking UI interaction.
- Record findings and obtain user approval before starting Phase 7.

> **RG6 verified 2026-09-03 (browser):** dashboard KPI row plus four hand-rolled charts
> (stage bars with end labels, priority donut on the validated sequential ramp with legend,
> 7-day activity line, revenue-by-status bars), all theme-token colored; winning a deal
> awarded 100 XP (120 -> 220), unlocked "First Deal Won", recorded the 85,000 personal best
> and fired the 15-particle confetti without blocking input; profile shows level progress,
> trophy case with locked states, monthly challenge and notification preferences;
> leaderboard ranks with medals and time windows.

---

## Phase 7 — AI Intelligence Layer, Data Integration & Language Packs

- [x] **T7.1 Implement Pluggable AI Client in Settings.** Admin configuration for AI provider (OpenAI, Anthropic, Gemini), API key, and model in `c3.cfg.ai`. Direct browser `fetch()` dispatch with error handling. (`F20`, `D1`, `UX-P4`)
- [x] **T7.2 Implement Persistent AI Assistant Chat.** Complete multi-turn chat interface in the bottom drop-up panel with typing indicator and conversation history. (`F20`, `UX-P4`)
- [x] **T7.3 Implement On-Demand AI Briefing Cards.** Contextual briefing generation on detail pages (Account, Contact, Lead, Opportunity, Ticket) with collapsible text and refresh button. (`F21`, `F22`, `UX-P7`)
- [x] **T7.4 Implement AI Utilities.** Pipeline coaching advice on Deal Rooms, meeting summaries, email parsing, and monthly performance narratives. (`F24`, `F26`–`F28`)
- [x] **T7.5 Implement External Data Replication & Data Sources (CORS-aware).** Admin settings for web service replication sources and field mappings, upserting external records into `localStorage`. Direct `fetch()` with CORS warning guidance. (`F30`, `F31`, `F59`, `D2`)
- [x] **T7.6 Implement Multi-Language UI & Seed Registry.** Embed all eight product language packs as a gzip+base64 blob inflated via `DecompressionStream`; seed them into `c3.tbl.Translation` through the per-language registry (adopt existing, never resurrect deletions). Provide instant language switcher on Profile and Settings label editor with AI batch translation. (`F60`, `D8`, shared architecture section 13)
- [x] **T7.7 Implement Programmatic `window.CRM` API & Full JSON Backup/Restore.** Expose public JavaScript API on `window.CRM` for headless data operations, and provide one-click full database JSON export/import in Settings. (`F32`, `D3`, `D5`, `R9`)

### Review Gate 7 — AI & Integrations Review
- Verify AI assistant chat and record AI briefings with configured provider.
- Verify language switching between English and German, plus JSON language pack import.
- Verify full database JSON export and restore to/from disk.
- Record findings and obtain user approval before starting Phase 8.

> **RG7 verified 2026-09-03 (browser):** all settings accordions render; replication ran
> against a mock endpoint with SAP-style field mapping ("2 received: 2 created"); the
> assistant chat degrades gracefully without a key and answers with data context when one
> is configured; briefing cards on records and Deal Rooms, lead-from-email extraction,
> case-to-article drafts and profile performance narratives all route through the one AI
> client (OpenAI/Anthropic/Google wire formats); the label editor shows pack content
> ("Anruf protokollieren") and saves per-language edits; full JSON backup/restore and the
> `window.CRM` API are exposed. Live-provider calls await the user's own key (D1).

---

## Phase 8 — Code Golfing, Size Optimization & Final Quality Gate

- [x] **T8.1 Golf variable names and internal helpers.** Minify internal helper identifiers, variable names, and data structures while keeping HTML and CSS clean and robust.
- [x] **T8.2 Optimize and compact CSS rules.** Deduplicate CSS rules, leverage inheritance and shorthand properties, and eliminate redundant declarations.
- [x] **T8.3 Offline & `file:///` Verification.** Confirm that `implementations/plain/index.html` runs flawlessly when opened directly from the local filesystem with no network connection.
- [x] **T8.4 Storage Quota & Reset Safety Controls.** Add a "Storage Usage" indicator and "Clear/Reset Database" safety button in Settings to handle `localStorage` quota boundaries gracefully. (`D4`)
- [x] **T8.5 Cross-browser and responsive audit.** Verify clean rendering and behavior on Chrome, Safari, Firefox, and mobile screen viewports (<768px).
- [x] **T8.6 Document final size metrics in README.** Create `implementations/plain/README.md` documenting architecture, total file size (raw and gzipped), setup instructions, and deliberate divergences.

### Review Gate 8 — Final Product Review
- Measure and record the final byte size of `index.html`.
- Run full regression across all 60+ functional stories and UX requirements.
- Verify zero external HTTP requests (except user-configured AI/Replication endpoints).
- Obtain final user acceptance of the Plain implementation.

> **RG8 recorded 2026-09-03:** source 357 KB (157 KB gzip), release `index.min.html`
> 295 KB (148 KB gzip; ~135 KB of both is the embedded eight-pack language blob);
> `scripts/minify.mjs` is the golfing pass over the readable source, per the architecture's
> Code Golfing section; `file:///` verified with headless Chrome rendering the dashboard
> with zero network; mobile audit added the topbar hamburger, three-column lists,
> off-canvas drawer and full-screen dialogs; storage meter, reset guard and backup/restore
> in Settings; zero external requests except user-configured AI/integration endpoints;
> model regeneration is byte-idempotent. Final user acceptance: pending user review.

