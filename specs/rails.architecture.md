# Rails Implementation Architecture

This document describes how the Rails implementation realises the product architecture in
`architecture.md`. It is the third stack-specific architecture alongside
`firebase.architecture.md` and `postgres.architecture.md`.

The Rails implementation is a **local-development architecture proof**. It deliberately uses
one cohesive application and no hosted infrastructure: the web server, database, jobs, cache,
real-time transport, files, and tests all run on a developer's Mac. The implementation lives in
`implementations/rails/` and is generated from the same functional, UX, data-model, style, and
translation specifications as the other implementations.

## Scope and Stack

### RA1. Self-Contained Runtime

The application runs self-contained on a single machine and has no cloud-hosting requirement;
any host that runs Ruby serves it unchanged. Puma
serves the Rails application; SQLite persists local state; attachments use the local filesystem.
Internet access is needed only when a developer explicitly exercises Google sign-in, an AI
provider, or an external integration. There is no Docker requirement for ordinary development.

### RA2. Technology Stack

| Layer | Choice |
|---|---|
| Language | Ruby 3.4.x, with the exact patch pinned in `.ruby-version` |
| Framework | Rails 8.1 monolith |
| Rendering | Action View with Hotwire: Turbo Drive, Turbo Frames, Turbo Streams, and Stimulus |
| Styling | Tailwind CSS compiled locally, with tokens derived from both shared style guides |
| Browser dependencies | Importmap and vendored/browser ESM modules; no Node runtime is required |
| Charts | Chart.js driven by Stimulus, substituting for the React-specific Recharts references |
| Database | SQLite through Active Record |
| Authentication | Rails session authentication with email/password; Google OAuth is added last |
| Authorization | Pundit policies and mandatory policy scopes |
| Real-time | Action Cable with Solid Cable and authorised Turbo Stream subscriptions |
| Background work | Active Job with Solid Queue |
| Cache | Solid Cache |
| Files | Active Storage Disk service |
| API | Versioned Rails JSON controllers under `/api/v1` |
| Tests | Minitest, Rails integration tests, and browser system tests |

### RA3. Shared Capability Mapping

| Requirement | Rails mechanism |
|---|---|
| R1 | Puma serves the complete application on localhost |
| R2 | Database-backed email/password sessions plus Google OAuth; registration is disabled |
| R3 | Active Record queries provide server pagination, sorting, filtering, and counts over SQLite |
| R4 | Action Cable, Solid Cable, and Turbo Streams push authorised changes to browsers |
| R5 | Rails controllers, services, and jobs hold provider secrets exclusively on the server |
| R6 | Active Storage uses private local disk storage and authorised download routes |
| R7 | Pundit policies and policy scopes enforce role, ownership, and team access server-side |
| R8 | Server-side HTTP adapters perform outbound reads and writes to configured systems |
| R9 | `/api/v1` exposes the same authorised service layer as the HTML interface |

### RA4. Implementation Layout

The Rails application uses conventional Rails boundaries under `implementations/rails/`:

- `app/models` contains persistence models and small record-local invariants.
- `app/controllers` contains HTML, Turbo, authentication, and JSON request adapters.
- `app/policies` contains Pundit policies and scopes.
- `app/services/crm` contains business transactions, data-source routing, search, AI, imports,
  conversions, gamification, notifications, and external integrations.
- `app/jobs` contains retryable asynchronous and recurring work.
- `app/components` contains reusable server-rendered view components.
- `app/javascript/controllers` contains small Stimulus controllers for browser-only behaviour.
- `config/crm` contains generated, runtime-safe manifests derived from the shared specifications.
- `lib/tasks/crm` contains generation, seeding, verification, bootstrap, import, and backup tasks.

Controllers do not contain business transactions, and views do not query models directly.

## Data Architecture

### RA5. Data Model as the Source of Truth

`specs/data-model.json` remains authoritative. A deterministic generator validates it and emits:

- reviewed Active Record migrations;
- a normalised model manifest for runtime generic screens;
- model validations, associations, enum declarations, and display metadata;
- foreign-key, unique, check, and supporting indexes;
- searchable-field, list-column, reference-option, and relationship-card metadata;
- parity tests proving that every declared object and field is represented.

Generated migrations are reviewed and committed. Specification changes never execute arbitrary
schema changes automatically at application boot.

### RA6. SQLite Type Mapping

The mapper applies these rules consistently:

| Blueprint type | SQLite / Rails representation |
|---|---|
| `uuid` | 36-character text, generated with `SecureRandom.uuid` before insert |
| `string` | text/varchar with Rails length validation and a database length check |
| `text` | text |
| `integer` | integer |
| `decimal` | decimal with declared precision and scale |
| `currency` | decimal with declared precision and scale; never binary floating point |
| `boolean` | boolean with non-null checks when required |
| `date` | date |
| `datetime` | UTC datetime with application-level ISO 8601 serialisation |
| `enum` | English string value with Rails inclusion validation and a database check constraint |
| `reference` | indexed UUID text foreign key |
| `json` | JSON-encoded text with typed Active Record access and JSON-shape validation |

SAP lengths and English enum storage values are preserved exactly. SQLite foreign keys are
enabled for every connection.

### RA7. Associations and Referential Integrity

One table is created for every object in `data-model.json`. References become real foreign keys.
Junction objects such as `ContactAccount`, `OpportunityContact`, and
`TicketKnowledgeArticle` remain first-class models with composite uniqueness constraints.
Polymorphic relationships such as `LineItem`, `Document`, and `Comment` use the declared
`parent_type` plus UUID `parent_id`; allowed parent types are constrained to the blueprint enum.

Delete behaviour is explicit per relationship. Destructive cascades are limited to true owned
records such as junction rows; business records default to restrict or nullify so deleting a user
or parent cannot silently erase CRM history.

### RA8. Audit Fields and Bootstrap Cycles

All domain records keep the required common fields `created_by`, `updated_by`, `created_at`, and
`updated_at`. Controllers and services derive actor fields from the authenticated profile rather
than accepting them from request parameters.

The initial Role/UserProfile cycle is handled by a privileged, idempotent bootstrap task using
pre-generated UUIDs and deferred foreign-key checking in one transaction. The schema is not
weakened for the one-time empty-database case.

### RA9. Auto-Numbers

Auto-numbers remain strings at their SAP-compatible declared lengths. An infrastructure table
stores the next integer per object type. Allocation occurs inside an immediate write transaction,
formats locally generated values with leading zeros, and enforces uniqueness. Imported
alphanumeric SAP identifiers are accepted. Presentation helpers remove leading zeros only from
purely numeric values.

Gaps are permitted after failed transactions or imported values. Uniqueness and concurrency
safety take precedence over contiguous numbering.

### RA10. SQLite Topology and Connection Settings

Rails uses its standard separated local databases under `implementations/rails/storage/`:

- `development.sqlite3` for CRM and authentication data;
- `development_queue.sqlite3` for Solid Queue;
- `development_cache.sqlite3` for Solid Cache;
- `development_cable.sqlite3` for Solid Cable.

Production-named local databases may be used for a production-mode smoke test, but they are not a
deployment target. Connections enable foreign keys, WAL journal mode, a bounded busy timeout, and
sensible synchronous durability. Database files, attachments, logs, credentials keys, and runtime
backups are gitignored.

### RA11. Pagination, Sorting, Filtering, and Counts

Default lists use database-side ordering, a deterministic `id` tie-breaker, `LIMIT`/`OFFSET`
pagination for numbered pages, and a separate count query. The configured Number/Name default is
resolved through the model manifest; missing sort values are counted and repairable as specified.

Normal browsing loads only one page. Activating global search or column filters requests the full
matching result set from Rails and switches the rendered table to its specified client-side mode.
Exports run as enumerators so a large CSV is not assembled entirely in memory.

### RA12. Model Registry and Generic UI

A `Crm::ModelRegistry` loads the generated manifest. Generic list, detail, create, edit, linked
record, import, export, API, search, and reference-option services resolve models only through this
allowlist; user input is never constantized directly.

Relationships declared in the manifest generate parent cards, child cards, junction link/unlink
operations, and contextual creation automatically. Custom workspaces and business conversions use
explicit controllers and components while reusing the same registry and services.

### RA13. Data Access and Pluggable Sources

`Crm::DataSourceRouter` selects a `LocalActiveRecordAdapter` or an
`ExternalHttpAdapter` per object type. Both implement the same operations: `find`, `list`,
`list_page`, `count`, `create`, `update`, and `delete`. The local adapter always applies the caller's
policy scope. External responses are mapped and validated against the same manifest before reaching
views or callers.

The HTML interface, REST API, CSV operations, AI context loader, dashboards, and relationships use
this service boundary rather than querying arbitrary models independently.

### RA14. Transactional Business Operations

Lead conversion, quotation/order/invoice conversion, line-item copying, ticket timestamp changes,
link/unlink actions, XP awards, audit entries, notifications, and configuration approvals are
explicit service objects. Each compound operation is atomic in an Active Record transaction and
returns a typed result. Side effects that contact external services are enqueued only after commit.

Idempotency keys protect conversion, replication, import, and integration endpoints from duplicate
submission.

## Identity, Authorization, and Security

### RA15. Authentication Architecture

Authentication uses a separate `AuthUser` identity model and database-backed `Session` records;
names are deliberately separated from CRM Account and UserProfile models. Passwords use Rails'
`has_secure_password`. Session cookies are encrypted, HTTP-only, same-site, and secure whenever the
local server uses HTTPS. Self-service registration does not exist.

Email/password authentication and an idempotent CLI administrator bootstrap support every earlier
implementation phase. Google OAuth is an additional provider implemented only in the final phase;
its localhost callback joins the same session and profile-resolution pipeline.

### RA16. User Provisioning and Profile Resolution

Authentication identity and CRM profile remain separate. An administrator provisions profiles;
local password identities are created explicitly by an administrator or CLI task. Pending profiles
may exist without `auth_uid`. Sign-in resolves in this order:

1. profile already linked by `auth_uid`;
2. unclaimed active profile matching the normalised email;
3. the one-time empty-instance bootstrap path;
4. refusal with the signed-in email shown.

Inactive profiles and whitelist failures are rejected before a session becomes usable. Claiming a
pending profile is atomic and cannot attach two identities to one profile.

### RA17. Server-Enforced Authorization

Pundit is the declarative authorization boundary. Every controller action calls `authorize`, and
every collection calls `policy_scope`; development and test environments fail requests that omit
either check. Policies express object/action permissions from Role JSON plus ownership and team
visibility: users see their own scoped records, managers see team records, and administrators see
all permitted records.

The same policies protect HTML, Turbo, downloads, Action Cable subscriptions, AI context, exports,
imports, and REST API calls. Service objects receive the current profile and start from an
authorised scope. Application-level policies are the Rails substitute for Postgres RLS; exhaustive
role/ownership/team tests are therefore an architectural requirement.

### RA18. Secret Storage

The Rails master key remains outside version control. Developer bootstrap stores fixed application
secrets in encrypted Rails credentials. Administrator-entered AI and external-source credentials
use Active Record Encryption and are write-only through controllers and JSON serializers. Logs,
exceptions, audit records, and Turbo responses filter secret parameter names and never echo stored
keys.

### RA19. Web Security

Rails CSRF protection applies to HTML and Turbo mutations. API bearer tokens are random, stored as
digests, scoped, revocable, and compared using constant-time helpers. Strong Parameters and the
model registry allowlist prevent mass assignment and arbitrary class access. Content Security
Policy, secure headers, upload size/type checks, output escaping, request throttling on login and AI
endpoints, and safe outbound-URL validation are enabled before feature work is considered complete.

Outbound integration requests reject loopback, link-local, and private-network destinations unless
the developer explicitly enables them for the local test instance.

## Web, Real-Time, and Background Execution

### RA20. Server-Rendered Hotwire Interface

Rails renders semantic HTML through ViewComponent-style reusable components and Action View
partials. Turbo Drive accelerates navigation; Turbo Frames isolate forms, linked cards, tables,
dialogs, and settings panels; Turbo Streams apply server-authoritative updates. Stimulus is limited
to behaviour that must occur in the browser, including dialogs, keyboard shortcuts, live line-item
math, table interaction, charts, browser notifications, theme changes, and celebrations.

The browser owns no parallel domain model. Successful mutations return the same rendered components
used by a normal page load, preventing HTML and JavaScript representations from drifting.

### RA21. Authorised Real-Time Streams

Action Cable uses Solid Cable's SQLite-backed adapter. Subscriptions are created only after the
connection resolves an active UserProfile and the requested record or workspace passes its policy.
Stream identifiers are signed and opaque.

Notifications use per-user streams. Locks, comments, Deal Rooms, and Case Rooms use authorised
record streams. Broadcasts occur after commit and contain either a safe rendered component or an
invalidation that makes the client reload through an authorised route. Broad object-type streams
that could expose unauthorised rows are prohibited.

### RA22. Pessimistic Record Locks

`RecordLock` is an infrastructure model unique on `(object_type, record_id)` with holder, timestamps,
and expiry. Acquisition is an atomic upsert that succeeds for an absent, expired, or same-holder
lock and returns conflict otherwise. A Stimulus controller renews the lock while edit mode is
active, releases it on save/cancel and best-effort page exit, and treats a lock older than 15
minutes as expired. Lock changes broadcast after commit to authorised record viewers.

Database transaction locks are not used because an edit lock must survive across HTTP requests.

### RA23. Notifications and Domain Events

Business services publish typed in-process domain events after successful commits. Notification
handlers check recipient preferences, persist Notification records, and broadcast to the
recipient's stream. Notification failure is logged and does not roll back the originating CRM
save. Audit, XP, badge, streak, challenge, and personal-best handlers consume the same explicit
events, avoiding duplicated controller callbacks.

### RA24. Jobs and Scheduling

Solid Queue runs locally either through Puma's plugin or as the `bin/jobs` process included in
`bin/dev`. Jobs cover AI work, imports, replication, email ingestion, document processing, SLA
checks, monthly challenges, duplicate analysis, and other retryable operations. Recurring schedules
are configuration, not operating-system cron entries. Jobs are idempotent, carry the initiating
profile where relevant, report progress in persisted records, and apply the same authorisation and
data-source rules as synchronous requests.

### RA25. Search Architecture

The generated manifest identifies every searchable string and text field. Keyword search performs
case-insensitive database queries across navigable object types, applies policy scopes, requires two
characters, and returns at most five results per type. The local data volume favours correctness over
a separate search service. SQLite FTS5 may provide a derived acceleration index, but it cannot
replace the required substring behaviour.

Semantic search is a separate AI service operation. It receives only policy-scoped compact records,
validates returned JSON against a strict schema, and resolves every result through authorised
lookup before display.

### RA26. File Storage

Active Storage's private Disk service stores binary content below the Rails `storage/` directory.
Document remains the CRM metadata object and has one attached blob; its `file_path` stores a logical
blob reference, never an absolute developer-machine path. Downloads and previews pass through an
authorised controller. Content type, extension, and byte-size limits are validated before attach.

The service boundary permits a later switch to S3-compatible storage without changing domain
models, but no remote storage is configured for this implementation.

## AI, Integrations, API, and Configuration

### RA27. AI Provider Boundary

`Crm::Ai::Provider` defines chat and structured-output operations. OpenAI, Google, Anthropic, and
Moonshot adapters translate that interface to provider HTTP APIs. Exactly one encrypted
AIProviderConfig is active. Provider keys never reach browser code. If no provider is active, AI
features return an explicit unavailable result and the combined bar continues as keyword search.

Context builders select at most the permitted object types and fields, apply policy scopes, cap
record counts, and format compact prompts. Responses are treated as untrusted input, escaped before
rendering, and validated before they can propose configuration or data changes.

### RA28. External Integration Boundary

Outbound integrations use a shared HTTP client with timeouts, bounded response sizes, retry policy,
redacted logging, and typed error results. DataSourceConfig auth material is encrypted. Replication
maps external responses through the model manifest, validates every row, upserts by the configured
key, and records a run summary. Bi-directional writes use an outbox job after the local transaction
commits.

SAP annotations remain metadata available to import/export and integration adapters; the Rails
schema preserves their lengths and value representations.

### RA29. Open REST API

Routes under `/api/v1/:object_type` and `/api/v1/:object_type/:id` expose major objects using the
same data-source router, validators, transactions, serializers, and policies as HTML requests.
Collection responses include pagination metadata and stable error envelopes. An OpenAPI document is
checked into the implementation and verified by request tests. API tokens are managed locally by an
administrator and never grant more access than their associated profile.

### RA30. Audit and Reversibility

Create, update, delete, conversion, reassignment, stage/status change, import, replication, and
configuration approval operations write AuditLog records with the acting profile and human-readable
summary. Sensitive values are redacted. Audit writes share the domain transaction when possible.

AI-proposed configuration and feature changes are stored as drafts with a preview and explicit
approval state. Approval produces a versioned manifest/migration change and a reversible audit
entry; AI output is never evaluated as Ruby and never writes application files directly at runtime.

### RA31. Internationalisation

English defaults ship as a generated artifact, `config/crm/catalog.en.json`, produced from the
reference implementation's catalog exporter so keys and English values are identical across
implementations; the key-generation rules remain as fallback for keys the artifact does not know. Bundled translation files in
`specs/translations/` are validated and seeded into one Translation record per language. A seed
registry adopts an existing language and never overwrites or resurrects an administrator-modified
language. A translation service merges the selected database labels over English fallbacks once per
session. Enum storage stays English while presentation uses translated labels.

The implementation includes catalog parity tests against the shared key-generation rules.

### RA32. Configuration Records

Infrastructure tables store email/domain whitelist entries, record locks, list sorting settings,
translation seed state, authentication identities and sessions, API tokens, import/replication job
state, and approved configuration versions. They are deliberately absent from `data-model.json`
because they have no CRM list/detail pages or auto-numbers. Domain configuration that is already in
the blueprint remains in its declared models.

## Local Operation and Quality

### RA33. Local Developer Workflow

The repository exposes these stable entry points from `implementations/rails/`:

- `bin/setup` installs dependencies, prepares databases, seeds defaults and language packs, and
  creates the first local administrator when requested;
- `bin/dev` starts Puma, Tailwind watch mode, Solid Queue, and any required local process;
- `bin/rails test` runs unit and integration tests;
- `bin/rails test:system` runs browser acceptance tests;
- `bin/ci` runs formatting, static analysis, security scans, all tests, and specification parity;
- `bin/rails crm:backup` and `crm:restore` manage explicit local backups.

Commands are non-destructive by default and work on Apple Silicon. No runtime service is installed
outside the repository except Ruby, SQLite, and a browser used for system tests.

### RA34. Backup and Recovery

The backup task uses SQLite's online backup mechanism for each database and copies the attachment
tree into a timestamped archive with a manifest and checksums. Restore validates the archive,
requires explicit confirmation before replacing current local data, and runs an integrity check
afterward. Backups live outside active database paths and are never committed.

### RA35. Test Strategy

Tests are generated with the application and include:

- manifest parity and migration-schema tests for every object, field, relationship, and constraint;
- model tests for validations, numbering, associations, and SAP representations;
- policy matrices for admin, manager, team member, owner, unrelated user, inactive user, and guest;
- service tests for every compound transaction and failure rollback;
- request-contract tests shared between HTML/Turbo and REST paths;
- Action Cable tests proving stream authorisation and absence of cross-user leakage;
- job tests for idempotency, retry, and redaction;
- system tests for the critical desktop and mobile workflows in the UX specification;
- import/export, translation-pack, AI-adapter fake, and external-adapter contract tests;
- RuboCop, Brakeman, dependency audit, and Rails' local CI checks.

No automated test calls a billable AI or external provider; adapters use recorded contract fixtures
or local fakes unless a developer explicitly opts into a manual integration test.

### RA36. Deliberate Rails Divergences

The Rails proof intentionally differs from both references:

1. One server-rendered monolith replaces a static SPA/BaaS and a SvelteKit/Postgres split.
2. SQLite removes the database-server prerequisite and makes the complete system laptop-native.
3. Hotwire sends rendered HTML rather than maintaining a second client-side domain model.
4. Solid Queue, Cache, and Cable replace hosted queues, Redis, and database notification bridges.
5. Chart.js substitutes for the React-specific Recharts reference while preserving chart behaviour.
6. Authorization is application-enforced rather than Firestore rules or Postgres RLS; policy-scope
   verification and matrix tests compensate for the lack of database-native row security.
7. Local disk replaces object storage while retaining the Active Storage abstraction.
8. There is no deployment template for this implementation; local setup and operation scripts are
   the delivery mechanism.
9. Google sign-in is intentionally the final implementation step, allowing all earlier work to be
   developed and reviewed with local password identities.

These divergences are part of the architecture proof: the common specifications remain the product,
while Rails uses its native strengths instead of imitating either reference implementation.
