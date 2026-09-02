# Rails Implementation Tasks

This task list implements `specs/rails.architecture.md` in `implementations/rails/`. It is
derived from the shared technical requirements (`R`), Rails architecture requirements (`RA`),
functional specifications (`F`), and UX requirements (`UX`).

The implementation is local-only. Do not add cloud hosting, deployment, container, or remote
database work. Google sign-in is intentionally isolated as the final implementation task.

## Working Rules

- `[ ]` means not started, `[-]` means in progress, and `[x]` means complete.
- Complete tasks in phase order unless a review explicitly approves a change.
- Every phase ends with a review gate. Stop there, run the listed evidence, review the diff with
  the user, record resulting tasks here, and obtain approval before starting the next phase.
- A phase is not complete while tests are skipped, required behaviour is stubbed without being
  identified, or its requirement references lack evidence.
- Keep `specs/data-model.json`, not generated Ruby, authoritative for domain shape.
- Do not add Google OAuth code, gems, credentials, or callbacks before Phase 8. The earlier phases
  use local email/password identities and the administrator bootstrap task.

## Phase 0 — Rails Foundation and Generated Schema

- [x] **T0.1 Scaffold the local Rails application.** Create `implementations/rails/` with the
  pinned Ruby version, Rails 8.1, SQLite, Propshaft, Importmap, Hotwire, Tailwind, Minitest, and the
  conventional directories defined by the architecture. Exclude deployment and container files
  that are not needed locally. (`R1`, `RA1`, `RA2`, `RA3`, `RA4`, `RA33`, `RA36`)
- [x] **T0.2 Establish local process commands.** Implement idempotent `bin/setup`, `bin/dev`, and
  `bin/ci`; make them work from a fresh Apple Silicon Mac after Ruby is installed. Start Puma,
  Tailwind watch mode, and Solid Queue from the local process file. (`R1`, `R5`, `RA1`, `RA24`,
  `RA33`)
- [x] **T0.3 Configure the four SQLite databases.** Add primary, queue, cache, and Cable database
  configuration with foreign keys, WAL, bounded busy timeouts, runtime paths under `storage/`, and
  safe gitignore rules. Install and initialise Solid Queue, Solid Cache, and Solid Cable. (`R3`,
  `R4`, `RA10`, `RA21`, `RA24`)
- [x] **T0.4 Build the blueprint validator and generator.** Parse and validate
  `specs/data-model.json`; reject unknown types, missing targets, invalid enums, duplicate fields,
  invalid lengths, and inconsistent relationships; emit a deterministic normalised manifest into
  `config/crm`. (`R3`, `RA5`, `RA6`, `RA7`, `RA12`)
- [x] **T0.5 Generate and review domain migrations.** Create all object tables, common audit
  fields, UUID keys, foreign keys, check constraints, junction uniqueness, polymorphic constraints,
  indexes, and SAP-compatible lengths. Generate migrations for infrastructure tables separately.
  (`F29`, `R3`, `RA5`–`RA8`)
- [x] **T0.6 Implement safe auto-number allocation.** Add the counter table, atomic allocator,
  padded string storage, alphanumeric-import support, display formatting, and concurrency tests.
  (`F1`–`F14`, `UX24`, `RA9`)
- [x] **T0.7 Generate model metadata and parity tests.** Produce model declarations, associations,
  validations, enum definitions, display-name rules, searchable fields, default list columns, and
  relationships; prove every blueprint object and field is represented exactly once. (`F1`–`F14`,
  `F29`, `F58`, `R3`, `RA5`, `RA12`, `RA35`)
- [x] **T0.8 Seed technical and domain defaults.** Add idempotent seeds for system roles, pipeline
  stages, ticket statuses, levels, XP event definitions, standard badges, and translation seed
  registry infrastructure without overwriting later administrator changes. (`F4`, `F10`, `F37`–
  `F40`, `F60`, `RA8`, `RA31`, `RA32`)
- [x] **T0.9 Install baseline quality controls.** Configure RuboCop, Brakeman, dependency audit,
  schema checks, test coverage reporting, secret filtering, and a local CI command that fails on
  errors. (`RA18`, `RA19`, `RA35`)
- [x] **T0.10 Implement local backup and restore commands.** Use SQLite's online backup mechanism,
  include all four databases and attachments in a checksummed archive, validate archives before
  restore, require confirmation before replacement, and run database integrity checks afterward.
  (`RA33`, `RA34`)

### Review Gate 0 — Foundation Review

- [x] Run `bin/setup` twice to prove idempotency, then run `bin/ci` from a clean local database.
- [x] Review the generated schema against every object, field, relationship, enum, constraint, and
  SAP annotation in `specs/data-model.json`.
- [x] Review all runtime paths and the Git diff to prove no database, attachment, secret, or backup
  file can be committed.
- [x] Record review findings as new tasks in the appropriate phase and obtain approval before Phase 1.

Review findings resolved during Gate 0:

- [x] **RF0.1 Route Solid Queue explicitly in development and test.** The process smoke test found
  that the queue schema existed but the worker model initially resolved against the primary
  database. The route is now explicit and covered by the database health check and tests.
- [x] **RF0.2 Exercise Solid Cable through its dedicated test database.** Randomised test order
  exposed that the test adapter could bypass the Cable database. Test and development now use the
  same dedicated Solid Cable route, with repeated-seed regression coverage.

## Phase 1 — Local Identity, Authorization, and Service Boundaries

- [x] **T1.1 Implement local email/password authentication.** Add separately named AuthUser and
  Session models, secure password hashing, encrypted session cookies, sign-in/sign-out, rate
  limiting, password reset suitable for local development, and no registration route. Do not add
  Google OAuth yet. (`F18`, `F18b`, `F62`, `R2`, `RA15`, `RA19`)
- [x] **T1.2 Implement the first-administrator CLI bootstrap.** Create an idempotent task that
  establishes the initial system roles, password identity, and self-referencing administrator
  profile in one safe transaction. Refuse ambiguous or partially populated states. (`F18`, `F62`,
  `RA8`, `RA16`, `RA33`)
- [x] **T1.3 Implement profile and session resolution.** Resolve AuthUser to UserProfile, enforce
  active status, normalise email addresses, present the pending-access state with the signed-in
  email, and cover every non-Google branch of the defined resolution order. (`F18b`, `F62`, `UX56`,
  `RA15`, `RA16`)
- [x] **T1.4 Implement Pundit authorization.** Add base policies, mandatory `authorize` and
  `policy_scope` verification, JSON action permissions, owner scope, manager/team scope, admin
  scope, and explicit protections for settings and configuration models. (`F18`, `F48`, `R7`,
  `RA17`, `RA19`)
- [x] **T1.5 Build the authorization matrix tests.** Cover guest, inactive, ordinary owner,
  unrelated ordinary user, teammate, team manager, administrator, and API identity for reads,
  writes, relationships, files, streams, exports, AI context, and settings. (`F18`, `F18b`, `R7`,
  `RA17`, `RA35`)
- [x] **T1.6 Implement actor stamping and audit infrastructure.** Derive created/updated actors from
  the current profile, build the AuditLog writer, redact sensitive fields, and capture create,
  update, delete, reassignment, status, and stage events transactionally. (`F35`, `F36`, `RA8`,
  `RA23`, `RA30`)
- [x] **T1.7 Implement the local data adapter and router.** Build the authorised
  LocalActiveRecordAdapter and DataSourceRouter interfaces used by HTML, API, search, dashboards,
  AI, import/export, and related records. (`F30`, `R3`, `R7`, `R8`, `RA11`, `RA13`)
- [x] **T1.8 Establish transactional service conventions.** Add typed results, error mapping,
  idempotency-key support, after-commit domain events, and rollback tests for multi-record business
  operations. (`F3`–`F7`, `F17`, `F31`, `F38`, `RA14`, `RA23`)
- [x] **T1.9 Add encrypted application configuration.** Configure Rails credentials, Active Record
  Encryption, write-only serializers, log parameter filtering, and safe placeholders for AI and
  external-source secrets. (`F20`, `F30`, `F59`, `R5`, `RA18`, `RA19`)

### Review Gate 1 — Security and Boundaries Review

- [x] Run the complete policy matrix and demonstrate that an unrelated user cannot read or mutate
  another user's record through HTML, Turbo, service calls, files, or a direct URL.
- [x] Review authentication, session, CSRF, parameter filtering, encryption, audit, and bootstrap
  code as a security-focused pull request.
- [x] Verify controllers contain no business transactions and services cannot bypass policy scopes.
- [x] Record findings and obtain approval before Phase 2.

Review findings resolved during Gate 1:

- [x] **RF1.1 Preserve optional blueprint semantics in generated models.** Matrix setup exposed that
  optional unique and enum fields were being rejected at the Rails validation layer even though the
  blueprint and SQLite schema permitted `NULL`. The generator and shared concern now preserve the
  required/optional distinction, with deterministic parity checks still green.
- [x] **RF1.2 Configure encrypted attributes independently of model load order.** Randomised tests
  exposed that merely populating the Rails configuration object was too late for some model-loading
  orders. The credential-derived keys now configure Active Record Encryption directly as well as its
  Rails configuration, and repeated random-seed tests cover encrypted string and JSON fields.
- [x] **RF1.3 Make every external entry point use the same boundary.** HTML/Turbo and bearer-token API
  endpoints now share one controller concern, a model-derived strong-parameter allowlist, Pundit
  verification, the data-source router, actor stamping, and transactional audit behavior. Direct URL,
  file/stream capability, read-only API, revoked-token, and unrelated-record denial tests are green.
- [x] **RF1.4 Harden local integration configuration.** The review added strict CSP nonces, UUID/JSON
  database constraints for identity infrastructure, password-reset throttling and token cleanup,
  whitelist value validation, and rejection of non-HTTPS, unresolvable, private, loopback, link-local,
  multicast, and reserved external endpoints unless local private networking is explicitly enabled.

## Phase 2 — Application Shell and Model-Driven CRUD

- [x] **T2.1 Implement the shared visual tokens and themes.** Translate both style guides into CSS
  custom properties and Tailwind configuration, bundle fonts and logos locally, implement Light,
  Dark, and System themes, and prevent theme flash. (`UX1`, `UX25`, `UX36`, `RA20`)
- [x] **T2.2 Build the responsive application shell.** Implement the fixed Top Bar, collapsed-first
  Ribbon with role-filtered items, sticky content/header regions, bottom AI/Search shell, desktop
  layout, and mobile overlay behaviour. (`F18`, `F48`, `F49`, `UX2`–`UX5`, `UX15`, `UX16`,
  `UX40`, `RA20`)
- [x] **T2.3 Build navigation and history.** Add model-registry routes, home navigation, icon and
  monogram fallbacks, Settings placement, Case Room route semantics, back behaviour, and the
  session-only 5+10 detail-page history trail. (`UX3`, `UX5`, `UX27`, `RA12`, `RA20`)
- [x] **T2.4 Build reusable field and record components.** Render every field type, references,
  enums, dates, currency, JSON, human-readable validation messages, default dates, hidden empty
  read values, edit-mode fields, auto-number chips, and translated labels. (`F47`, `F60`, `UX6`,
  `UX9`, `UX22`, `UX23`, `UX24`, `UX30`, `RA12`, `RA20`)
- [x] **T2.5 Implement generic create, detail, edit, and delete flows.** Use full-page creation,
  progressive disclosure, sticky detail headers, optimistic Turbo responses, confirmation for
  deletion, policy checks, and accessible error focus. (`F1`–`F14`, `F45`, `F47`, `F49`, `UX6`,
  `UX9`, `UX12`, `UX30`, `UX40`)
- [x] **T2.6 Implement generic list views.** Add the five-column defaults, responsive essential
  columns, server-side paging/count/sort, client-side filter mode, inline editing, column visibility,
  URL state, empty/loading/error states, and deterministic ordering. (`F1`–`F14`, `F49`, `F63`,
  `UX11`, `UX21`–`UX24`, `UX40`, `UX57`, `R3`, `RA11`)
- [x] **T2.7 Implement linked-record cards.** Generate parent and child cards from relationship
  metadata, put parent cards first, support many-to-many junction fields, link/unlink existing
  records, contextual Add New, return-to-parent navigation, and policy filtering. (`F58`, `UX10`,
  `RA7`, `RA12`)
- [x] **T2.8 Complete foundational CRM records.** Verify full CRUD, hierarchy, relationships, and
  display rules for Account, Contact, ContactAccount, Product, PricebookEntry, PipelineStage,
  Activity, Document, and Comment using the generic framework. (`F1`, `F2`, `F8`, `F9`, `F58`)
- [x] **T2.9 Add accessibility and responsive system tests.** Cover keyboard navigation, labels,
  focus management, dialogs, contrast-sensitive themes, narrow layouts, inline editing, and linked
  cards at representative desktop and mobile sizes. (`F49`, `UX1`–`UX12`, `UX16`, `UX40`, `RA35`)

### Review Gate 2 — Generic UX Review

- [x] Run `bin/ci` and the desktop/mobile system-test suite.
- [x] Visually compare the shell, themes, generic lists, details, forms, and linked cards with
  `specs/UIMockup.png`, both style guides, and UX1–UX12, UX15–UX16, UX21–UX25, UX27, UX30, UX40.
- [x] Demonstrate that adding a test relationship or field to a fixture manifest changes generic
  rendering without hand-written page code, then remove the fixture change.
- [x] Record findings and obtain approval before Phase 3.

Review findings recorded during Gate 2:

- [x] **RF2.1 Normalize blank optional form values before persistence.** Browser-level creation
  exposed that blank UUID references arrived as empty strings and could fail SQLite foreign-key
  constraints. Generic form parameters now convert optional blanks to native `NULL` values.
- [x] **RF2.2 Preserve blueprint `type` fields without Rails inheritance collisions.** Generated
  Activity and Notification models now disable STI when a blueprint declares a `type` field, while
  polymorphic `parent_type` fields remain raw class names with explicit inclusion validation.
- [x] **RF2.3 Make list ordering deterministic and configurable.** Every list now adds an ID
  tie-breaker, supports admin-configured Number/Name and Asc/Desc defaults, reports missing generated
  numbers, and offers a repair operation.
- [x] **RF2.4 Verify metadata-driven extension and responsive UX.** A temporary manifest relationship
  changes the rendered linked cards without page code and is restored after the test. Automated
  Chrome checks pass at 1440×900 and 390×844; the visual comparison found no blocking divergence.
- [x] **RF2.5 Add reproducible, relationship-rich local demo data.** A development-only command now
  creates 100 believable records for each operational CRM object, plus teams and SLA reference data.
  Stable identifiers make reruns idempotent, and automated tests verify the cross-object graph.
- [x] **RF2.6 Render reference names in linked-record tables.** Child cards now resolve reference
  fields through the same authorization-aware label catalog used by lists and details, preventing
  raw UUIDs from appearing for accounts, contacts, owners, stages, and other related records.
- [x] **RF2.7 Curate useful list columns for every CRM object.** All 39 metadata objects now have
  reviewed business-facing defaults instead of schema-order guesses. Linked cards render the full
  selection; line items show Item #, Product, Quantity, Net Price, Discount %, and Net Value while
  hiding technical parent fields.
- [x] **RF2.8 Present notification preferences as user controls.** User profile details display
  compact Desktop and Email On/Off states, and generic profile editing uses checkboxes while the
  JSON persistence format remains hidden from users.
- [x] **RF2.9 Use the official CRMTHREE brand assets.** The application header uses the shared
  theme-aware CRMTHREE wordmark, and local sign-in uses the matching CRMTHREE by 66IDEAS lockup
  already shipped by the Firebase and Postgres reference implementations.

## Phase 3 — Sales Workflows

- [x] **T3.1 Complete lead management.** Implement lead scoring, allowed status transitions,
  ownership, related activities, and converted-record presentation. (`F3`)
- [x] **T3.2 Implement atomic lead conversion.** Build the pre-filled dialog, optional opportunity,
  account/contact creation, owner inheritance, conversion fields, duplicate-submit protection,
  navigation, disabled converted state, and rollback tests. (`F3`, `UX8`, `UX31`, `RA14`)
- [x] **T3.3 Complete opportunity and pipeline management.** Add configurable stages, probabilities,
  results, owner scope, contacts with roles, pipeline transitions, and stage-driven audit and domain
  events. (`F4`, `F17`, `F24`)
- [x] **T3.4 Implement inline line items and pricing.** Add rows in place, item numbers 10/20/30,
  product references, quantity/price/discount validation, live Stimulus totals, persisted decimal
  recomputation, deletion, ordering, and document totals. (`F4`–`F8`, `UX29`)
- [x] **T3.5 Complete quotation management.** Implement number-based identity, account-first forms,
  contacts, opportunity origin, statuses, dates, line items, and totals. (`F5`)
- [x] **T3.6 Complete sales-order management.** Implement number-based identity, account-first forms,
  opportunity/quotation origin, contacts, order dates, statuses, line items, and totals. (`F6`)
- [x] **T3.7 Complete invoice management.** Implement standalone and order-origin invoices,
  account-first forms, contacts, due dates, payment fields, statuses, line items, and totals. (`F7`)
- [x] **T3.8 Implement document conversions.** Build Opportunity→Quotation,
  Opportunity→SalesOrder, Quotation→SalesOrder, and SalesOrder→Invoice services and dialogs with
  field mapping, line-item copying, idempotency, loading/errors, rollback, and navigation. (`F4`–
  `F7`, `UX8`, `UX32`, `RA14`)
- [x] **T3.9 Implement contextual activity actions.** Add one-click Log Call, Log Email, Log Meeting,
  and New Task flows with hidden/pre-filled parent context and correct return navigation. (`F9`,
  `F45`, `UX8`)
- [x] **T3.10 Add sales acceptance tests.** Cover critical CRUD, lead conversion, every document
  conversion, line-item math, permissions, numbering, related cards, and failure rollback. (`F3`–
  `F9`, `UX8`, `UX29`, `UX31`, `UX32`, `RA35`)

Phase 3 implementation findings:

- [x] **RF3.1 Protect paid invoices during repricing and demo refresh.** The 100-record development
  refresh exposed that recalculated line-item totals must never fall below an invoice's already-paid
  amount. Reject that edit with a business validation and keep deterministic demo prices consistent
  with their parent document totals.
- [x] **RF3.2 Keep review screenshots compatible with Rails system tests.** Phase 3 visual review
  exposed an unsupported full-page keyword in Capybara's screenshot helper; use the supported local
  capture API and scroll to the line-item card so optional review evidence is both reliable and
  useful.
- [x] **RF3.3 Restrict workflow model resolution to explicit sales allowlists.** The final security
  audit flagged request-derived class reflection in document conversion and line-item endpoints.
  Replace it throughout the controllers and services with fixed model maps, add malicious-model
  regression tests, and verify that Brakeman reports zero warnings.

### Review Gate 3 — Sales Review

- [x] Run `bin/ci` and demonstrate one complete Lead→Opportunity→Quotation→Sales Order→Invoice
  journey with line items and audit history.
- [x] Review transaction boundaries, decimal calculations, idempotency, owner inheritance, and all
  negative-permission cases.
- [x] Compare every sales screen and dialog with F3–F9 and UX8, UX29, UX31, and UX32.
- [x] Record findings and obtain approval before Phase 4.

## Phase 4 — Service Workflows

Phase 4 implementation findings:

- [x] **RF4.1 Align service acronyms and demo relationships with enforced domain rules.** Rails'
  configured `SLA` acronym requires autoloaded behavior, policy, service, and job constants to use
  the same spelling. The new active-contract validation also exposed expired contracts attached to
  demo tickets; keep those contracts as historical records but do not select them on active tickets.
- [x] **RF4.2 Generate explicit owner keys for many-to-many junctions.** Case conversion exposed that
  a junction field named `article_id` cannot be inferred from the owning class name
  `KnowledgeArticle`. Resolve the owner-side reference from the blueprint and emit its explicit
  foreign key for every generated many-to-many association.
- [x] **RF4.3 Normalize enum keys at SLA rule boundaries.** The browser acceptance journey exposed
  that Rails forms submit the enum key `critical` while administrator-defined SLA rules store the
  business label `Critical`. Match priority values case-insensitively so HTML and direct service
  calls select the same SLA, with the full ticket journey retained as regression coverage.

- [x] **T4.1 Complete ticket management.** Implement account/contact links, assignment, priorities,
  categories, configurable status, relevant timestamps, activities, and assignment notifications.
  (`F10`, `F17`)
- [x] **T4.2 Implement ticket-status administration.** Build the admin-only status table and editor,
  ordering, active/resolved/closed flags, safe deletion checks, and immediate use in ticket forms.
  (`F10`, `UX37`)
- [x] **T4.3 Implement SLA definition and assignment.** Add priority/account rule evaluation,
  response and resolution deadlines, business-hour strategy, elapsed-state display, and idempotent
  recurring breach checks. (`F11`, `F17`, `RA24`)
- [x] **T4.4 Complete the knowledge base.** Implement CRUD, category/status handling, authorised
  search, view/helpful counters, publishing state, and ticket junction links. (`F12`)
- [x] **T4.5 Complete service contracts.** Implement coverage periods, entitlements, account links,
  SLA reference, active-contract validation, and ticket selection. (`F13`)
- [x] **T4.6 Complete asset management.** Implement account/contact/product links, installed-product
  fields, status, warranty information, and ticket relationships. (`F14`)
- [x] **T4.7 Implement case-to-knowledge conversion.** Create an editable draft article from a
  resolved ticket, retain author/source links, support linking recurring cases, and protect against
  duplicate submission. (`F51`)
- [x] **T4.8 Add service acceptance tests.** Cover ticket lifecycles, status timestamps, SLA states
  and breaches, contracts, assets, knowledge links, conversion, permissions, and error rollback.
  (`F10`–`F14`, `F51`, `UX37`, `RA35`)

### Review Gate 4 — Service Review

- [x] Run `bin/ci` and demonstrate Ticket creation through SLA response, resolution, closure, and
  draft knowledge-article conversion.
- [x] Review deadline calculations, recurring jobs, timestamp transitions, assignments,
  notifications, and linked-record authorization.
- [x] Compare the implementation with F10–F14, F17, F51, and UX37.
- [x] Record findings and obtain approval before Phase 5.

## Phase 5 — Cross-Cutting Product Capabilities

Phase 5 implementation findings:

- [x] **RF5.1 Declare CSV explicitly on modern Ruby.** Ruby 3.4 and later no longer guarantee that
  the CSV standard library ships in the default gem set. Add the dependency explicitly so local
  import/export boots consistently on the pinned Ruby version and on a fresh Mac.

- [x] **RF5.2 Vendor the Chart.js UMD build for offline development.** The generated import-map
  module graph referenced an unavailable transitive file. Pin the self-contained local UMD build
  so charts render without a CDN or network connection.

- [x] **RF5.3 Prevent access-rule self-lockout.** When the first restrictive whitelist rule would
  exclude the current administrator, atomically retain an exact-email rule for that administrator
  so the next request cannot unexpectedly end their session.

- [x] **RF5.4 Keep file import outside Turbo navigation and avoid framework-reserved attributes.**
  Submit the multipart preview as a normal form, duplicate uploaded bytes before encoding repair,
  and store row failures in `error_details` rather than Active Record's `errors` API.

- [x] **RF5.5 Ignore a user's own lock-acquisition broadcast.** Include the lock holder in authorised
  record broadcasts so the page being opened for editing does not react to its own acquisition by
  reloading back to the record detail view.

- [x] **T5.1 Implement dashboards and configurable widgets.** Add role-aware defaults, KPI cards,
  Chart.js charts, skeletons, click-through filters, persisted widget visibility, and the local
  substitute for Recharts. Leave AI summary generation for Phase 7. (`F15`, `F54`, `UX13`, `UX14`,
  `RA20`)
- [x] **T5.2 Implement keyword global search.** Add 400 ms debounce, two-character minimum,
  Cmd/Ctrl+K, all navigable object types and string/text fields, policy scopes, grouped five-result
  panels, loading/empty/close behaviour, and safe navigation. (`F16`, `UX4`, `UX19`, `RA25`)
- [x] **T5.3 Implement real-time in-app notifications.** Create user-scoped Action Cable streams,
  unread badge/panel, read/delete/mark-all, preference checks, assignment and stage-change domain
  events, silent non-blocking failures, and browser Notification API integration. (`F17`, `UX18`,
  `UX36`, `R4`, `RA21`, `RA23`)
- [x] **T5.4 Implement role and ribbon administration.** Add custom roles, action permissions,
  ribbon checkboxes, visible cards/layout JSON, system-role protections, immediate session-safe
  updates, and policy tests. (`F18`, `F48`, `UX15`, `UX42`, `RA17`)
- [x] **T5.5 Implement email/domain access control.** Add admin-only whitelist management, empty-list
  behaviour, normalised exact/domain matching, sign-in refusal, and sign-out path. (`F18b`, `UX28`,
  `RA16`)
- [x] **T5.6 Implement CSV export.** Export all filtered records for every navigable object with
  human-readable headers, translated labels where appropriate, unpadded numbers, safe spreadsheet
  values, policy scopes, and streaming output. (`F19`, `UX34`, `RA11`)
- [x] **T5.7 Implement CSV import.** Build the admin object selector, local upload, five-row preview,
  CRM-field-centric mapping, auto-mapping, fixed/default values, required-field enforcement,
  progress, row validation, policy-safe creation, and result summary. (`F19`, `UX35`, `RA14`,
  `RA24`)
- [x] **T5.8 Implement translations and language management.** Generate the shared label catalog,
  validate and seed all eight packs, preserve admin changes through the seed registry, add the
  accordion editor, fallbacks, translated enums, user preference, and full-page string coverage.
  Leave AI Translate All execution for Phase 7. (`F60`, `UX35`, `UX36`, `UX38`, `UX39`, `RA31`)
- [x] **T5.9 Implement pessimistic edit locks.** Add atomic acquire/renew/release, 15-minute TTL,
  heartbeat, best-effort unload release, authorised Turbo broadcasts, lock indicator, disabled Edit,
  expiry takeover, and race tests. (`F61`, `UX54`, `R4`, `RA22`)
- [x] **T5.10 Implement local user management.** Add the admin-only list, role changes, status,
  local password identity creation, pending profile invitations, whitelist warning/addition,
  deactivate/reactivate/delete rules, self-protection, instruction copy, and pending counts. Pending
  Google profile claiming remains unimplemented until Phase 8. (`F62`, `UX55`, `UX56`, `RA16`)
- [x] **T5.11 Implement configurable list sorting.** Add one setting per navigable object, exact
  Number/Name and direction choices, manifest-resolved field display, immediate save, defaults,
  hidden-record count, repair action, and whole-collection database ordering. (`F63`, `UX57`,
  `RA11`, `RA32`)
- [x] **T5.12 Complete responsive and accessibility coverage.** Verify all generic and cross-cutting
  pages at the defined breakpoints, full-screen mobile dialogs, compact search, hidden mobile
  gamification region, accordion settings, keyboard operation, focus restoration, and screen-reader
  labels. (`F49`, `UX16`, `UX18`, `UX19`, `UX35`–`UX40`)

### Review Gate 5 — Cross-Cutting Review

- [x] Run `bin/ci`, notification/lock concurrency tests, translation parity, CSV security tests, and
  desktop/mobile system tests.
- [x] Demonstrate two simultaneous browser users with different roles, real-time notifications,
  record lock handoff/expiry, scoped search/export, user administration, and list-sort repair.
- [x] Review every Settings accordion and profile preference against F15–F19, F48–F49, F58,
  F60–F63 and UX13–UX19, UX28, UX34–UX40, UX42, UX54–UX57.
- [x] Record findings and obtain approval before Phase 6.

## Phase 6 — Workspaces, Timelines, and Gamification

Phase 6 implementation findings:

- [x] **RF6.1 Give gamification events durable identities.** The original in-process domain-event
  shape could not prove an award had been processed only once. Add UUID event identities and a
  unique receipt ledger so replayed callbacks, retries, and duplicate delivery cannot award XP,
  challenges, badges, streaks, or celebrations twice.

- [x] **RF6.2 Exercise workspace updates through real browser subscriptions.** The two-session
  acceptance journey exposed a reference to an import-map module that did not exist. Create the
  Action Cable consumer from the vendored Rails module, disconnect it with the Stimulus lifecycle,
  ignore the actor's own invalidations, and retain policy checks on every subscription.

- [x] **RF6.3 Keep Phase 6 challenge behavior provider-independent.** Persist monthly uniqueness,
  progress, rewards, and completion now, and use a deterministic role-aware local assignment only
  in tests and explicit local calls. Do not expose a Generate button or imply an AI assignment until
  the provider-backed Phase 7 operation exists.

- [x] **RF6.4 Make performance history factual and export-safe.** Present reached levels, badge and
  challenge history, streak records, personal bests, and measured during-streak outcomes without
  claiming causation. Prefix spreadsheet formula characters and scope every portfolio to the same
  manager boundary as the HTML profile.

- [x] **T6.1 Implement Deal Rooms.** Add opt-in creation from Opportunity, list navigation, custom
  sticky workspace, authorised Turbo updates, manual close, stage progress, quick actions, activity
  timeline, comments, contacts with roles, documents, and mobile layout. (`F33`, `UX41`, `R4`)
- [x] **T6.2 Implement Case Rooms.** Add the Ticket-backed workspace route, status/priority header,
  status timestamp logic, activities, comments, asset/contract/knowledge cards, quick actions,
  authorised Turbo updates, and mobile layout. (`F34`, `UX50`, `R4`)
- [x] **T6.3 Implement user and team timelines.** Merge Activity and AuditLog feeds, add date/type and
  member filters, context chips, relative time, profile navigation, manager/admin gates, and stable
  chronological pagination. (`F35`, `F36`, `UX51`, `UX52`, `RA30`)
- [x] **T6.4 Implement XP events and achievements.** Award configurable XP from domain events,
  prevent duplicate awards, evaluate badge criteria, render profiles and trophy cases, and provide
  admin initialisation/editing. (`F38`, `F40`, `UX17`, `UX43`, `UX45`, `UX46`, `RA23`)
- [x] **T6.5 Implement levels and progression.** Calculate level changes transactionally, show
  progress and unlock metadata, notify level-up, and protect administrator definitions. (`F39`,
  `UX43`, `UX45`, `UX46`)
- [x] **T6.6 Implement leaderboards.** Calculate dimension and period rankings with policy-aware
  team visibility, highlight the current user and top three, create the full page, and add the
  configurable home card. (`F37`, `UX47`, `UX53`)
- [x] **T6.7 Implement streaks and personal bests.** Update from idempotent domain events, retain
  current/longest values, show outcome context, notify new records, and expose profile history.
  (`F43`, `F55`, `UX43`, `UX46`)
- [x] **T6.8 Implement challenge persistence and progress.** Add monthly uniqueness, progress and
  rewards, profile card, completion events, and a deterministic local test provider. Actual
  AI-assignment is completed in Phase 7. (`F42`, `UX48`)
- [x] **T6.9 Implement performance portfolios.** Add manager read-only profile views, level/badge/
  challenge/streak/personal-best history, and safe CSV export. (`F44`, `UX49`)
- [x] **T6.10 Implement celebrations.** Add non-blocking confetti and accessible snackbar messages
  for Won deals, badges, levels, challenges, streaks, and personal bests without duplicate playback.
  (`F41`, `UX20`, `UX44`)
- [x] **T6.11 Add workspace and gamification acceptance tests.** Cover opt-in Deal Rooms, Ticket Case
  Rooms, two-user comments, timeline permissions, event idempotency, rankings, awards, progress, and
  mobile layouts. (`F33`–`F44`, `F55`, `UX41`–`UX53`, `RA35`)

### Review Gate 6 — Collaboration and Motivation Review

- [x] Run `bin/ci` and demonstrate a two-user Deal Room and Case Room session with live comments,
  lock-safe quick actions, timeline events, XP, a badge, level-up, streak, and celebration.
- [x] Review event idempotency, ranking queries, manager boundaries, mobile workspace layouts, and
  the absence of unauthorised broadcast content.
- [x] Compare the implementation with F33–F44, F55 and UX41–UX53.
- [x] Record findings and obtain approval before Phase 7.

## Phase 7 — AI, External Systems, and Open API

- [x] **T7.1 Implement the pluggable AI provider layer.** Add encrypted administrator configuration,
  single-active-provider enforcement, OpenAI/Google/Anthropic/Moonshot adapters, timeouts, redacted
  errors, structured responses, fakes, and silent no-provider fallback. (`F20`, `R5`, `RA18`,
  `RA27`)
- [x] **T7.2 Implement the conversational AI/Search bar.** Add the classification heuristics,
  Enter-to-send, cleared input, multi-turn history, user/assistant bubbles, thinking state, keyword
  results below conversation, Escape/outside reset, and compact mobile version. (`F20`, `UX4`,
  `RA20`, `RA27`)
- [x] **T7.3 Implement policy-scoped AI context.** Detect relevant object types, cap at three types
  and 200 compact records each, default to Account/Opportunity, select safe fields, preserve
  ownership/team restrictions, and test prompt-injection boundaries. (`F20`, `R5`, `R7`, `RA27`)
- [x] **T7.4 Implement contextual briefings and summaries.** Add on-demand record briefings,
  user/dashboard priority briefing, account/lead/opportunity/ticket/document prompts, refresh,
  collapse, loading, no-provider hiding, and stale-data refresh. (`F21`, `F22`, `UX7`, `UX13`)
- [x] **T7.5 Implement semantic search.** Distinguish search intent from conversation, call the
  structured AI operation, validate result JSON, re-authorise every result, group and explain
  matches, and fail safely on malformed output. (`F23`, `UX4`, `UX19`, `RA25`, `RA27`)
- [x] **T7.6 Implement AI pipeline coaching and performance narratives.** Derive recommendations
  from company history, show stage-specific evidence, generate user narratives, and avoid claims
  unsupported by available data. (`F24`, `F28`)
- [x] **T7.7 Implement AI-generated knowledge and meeting summaries.** Draft editable win/loss and
  segment articles, ingest configured meeting transcripts, extract reviewable action items, link
  relevant records, and require confirmation before finalisation. (`F25`, `F26`)
- [x] **T7.8 Implement smart email parsing and auto-logging.** Add provider-neutral Gmail/Outlook
  ingestion interfaces, known-contact matching, removable auto-logged Activity records, suggested
  field changes, explicit confirmation, idempotent message handling, and fake-provider tests.
  Provider account OAuth is an integration concern and must not enable Google application sign-in.
  (`F27`, `F52`, `RA24`, `RA28`)
- [x] **T7.9 Implement reverse data entry.** Add URL, business-card image, and LinkedIn-profile
  intake adapters; process asynchronously; validate extracted fields; match accounts; and require a
  review/confirmation screen before saving. (`F50`, `R6`, `R8`, `RA24`, `RA26`, `RA28`)
- [x] **T7.10 Implement duplicate management.** Schedule policy-aware duplicate analysis, compute
  primary/completeness evidence, link candidates without hiding source data, and provide authorised
  merge and false-positive unlink operations with reversible audit history. (`F53`, `RA24`, `RA30`)
- [x] **T7.11 Complete trend analytics.** Add time-series queries, direction classification,
  projections with explainable inputs, pipeline/close/activity/response metrics, and dashboard
  navigation. (`F54`, `UX14`)
- [x] **T7.12 Implement AI challenge assignment.** Generate one personalised monthly mission,
  concrete target and reward from authorised role/behaviour data, persist it idempotently, and
  connect progress/completion to the Phase 6 engine. (`F42`, `UX48`, `RA24`, `RA27`)
- [x] **T7.13 Implement external data-source configuration.** Build admin UI and encrypted models for
  Local/External selection, endpoint, auth type, field mapping, active state, safe cache invalidation,
  and the ExternalHttpAdapter. (`F30`, `UX34`, `R8`, `RA13`, `RA18`, `RA28`)
- [x] **T7.14 Implement bi-directional external writes.** Present external records natively, route
  writes transparently, use an after-commit outbox, surface recoverable failures, and prove UI/API
  parity with contract fakes. (`F31`, `R8`, `RA14`, `RA28`)
- [x] **T7.15 Implement data replication.** Add admin configuration, JSON request templates, mapping,
  match keys, delete-flag skip, authorised manual Run, background progress, idempotent upsert, and
  created/updated/skipped/error summary. (`F59`, `UX33`, `R8`, `RA24`, `RA28`)
- [x] **T7.16 Verify SAP compatibility.** Add schema, import/export, and integration contract tests
  for all annotated fields, lengths, decimals, dates, padded/alphanumeric identifiers, and field
  mappings. (`F29`, `RA6`, `RA9`, `RA28`)
- [x] **T7.17 Implement the open REST API.** Add hashed bearer tokens, `/api/v1` CRUD for major
  objects, pagination metadata, stable errors, policy scopes, data-source routing, conversion action
  endpoints where specified, OpenAPI documentation, and request-contract tests. (`F32`, `R9`,
  `RA13`, `RA19`, `RA29`)
- [x] **T7.18 Implement AI-assisted translation.** Batch only untranslated labels, persist progress,
  validate keys and output language, preserve manual edits, handle partial failure, and reuse the
  active provider boundary. (`F60`, `UX35`, `RA27`, `RA31`)
- [x] **T7.19 Implement AI configuration proposals.** Accept natural-language field/configuration
  requests, generate a constrained manifest delta, preview validation/layout effects, require admin
  approval, apply versioned reversible changes, and prohibit runtime Ruby evaluation. (`F56`,
  `RA30`)
- [x] **T7.20 Implement AI feature-development proposals.** Produce reviewable specification,
  schema, UI, logic, and test scaffolding as a versioned local change set; require explicit admin
  approval and provide a rollback path. Never write or execute unreviewed AI output. (`F57`,
  `RA30`)
- [x] **T7.21 Add AI/integration/API acceptance tests.** Use only local fakes or opt-in developer
  credentials; cover provider switching, secret non-disclosure, policy-scoped context, malformed AI
  output, SSRF prevention, retries, idempotency, REST parity, and rollback. (`F20`–`F32`, `F42`,
  `F50`, `F52`–`F54`, `F56`, `F57`, `F59`, `F60`, `R5`, `R8`, `R9`, `RA35`)

### Review Gate 7 — Intelligence and Integration Review

- [x] Run `bin/ci` with all external adapters faked, then run any explicitly authorised manual
  provider smoke tests without recording credentials or billable output in fixtures.
- [x] Review AI data minimisation, prompt/response validation, secret handling, SSRF controls,
  idempotency, API-policy parity, SAP representations, and configuration rollback.
- [x] Compare implementation evidence with F20–F32, F42, F50, F52–F54, F56–F60 and the associated
  UX requirements.
- [ ] Record findings and obtain approval before Phase 8.

Review evidence recorded during Gate 7:

- [x] **RF7.1 Verify the complete local quality gate.** `bin/ci` passes with 176 Rails tests and
  3,006 assertions; schema generation, autoloading, SQLite integrity, seed idempotency, RuboCop,
  dependency audits, and Brakeman all pass. Ten desktop/mobile system workflows add 151 assertions.
- [x] **RF7.2 Keep provider testing explicit and cost-safe.** Provider, mailbox, external-data, and
  replication contracts use local fakes. No provider credentials were read and no manual or
  billable provider smoke test was run because none was explicitly authorised.
- [x] **RF7.3 Close integration review findings.** External calls enforce HTTPS/SSRF controls,
  bounded retries and redacted errors; AI context is policy-scoped and bounded; structured output
  is validated; secrets are encrypted/write-only; REST routes share policy/data-source boundaries;
  outbox, replication, email, and challenge operations are idempotent; SAP mappings and reversible
  configuration/duplicate changes have regression coverage.
- [x] **RF7.4 Give Home and Leads distinct navigation semantics.** Replace their shared sparkle icon
  with a conventional house for Home and a person-plus symbol for newly acquired Leads, keeping
  both distinct from Contacts and Opportunities. Verification initially used an invalid
  `test:system TEST=...` argument form, then a file-only run hit the expected whole-suite coverage
  threshold despite green assertions. The correct complete system suite passes.

## Phase 8 — Google Sign-In (Deferred)

- [x] **T8.1 Skip Google authentication for now.** Deferred by user decision on 2026-09-01; Google
  OAuth dependencies, callbacks, buttons, profile claiming, and provider tests are intentionally
  not implemented. Local email/password authentication remains the supported sign-in method. If
  resumed later, implement and verify the original scope against `F18`, `F18b`, `F62`, `UX26`,
  `UX55`, `UX56`, `R2`, `RA15`, `RA16`, `RA19`, and `RA36`.

There are no remaining implementation tasks. Only the final review remains.

### Review Gate 8 — Final Product Review

- [ ] Run `bin/ci` from a fresh setup and from an upgraded database containing representative data.
- [ ] Verify email/password sign-in remains functional and record the deferred Google sign-in matrix
  as an explicitly accepted follow-up.
- [ ] Perform a full requirement trace: `R1`–`R9`, `RA1`–`RA36`, every functional specification ID,
  and `UX1`–`UX57`; link each item to an automated test, reviewed manual evidence, or an explicitly
  accepted follow-up.
- [ ] Perform final architecture, security, accessibility, responsive, data-integrity, and UX reviews.
- [ ] Obtain explicit user acceptance of the Rails implementation.
