# Firebase Implementation Architecture

This document describes how `implementations/firebase/` realises the product architecture
defined in `architecture.md`. It is one stack-specific architecture among several; the
shared document stays technology-independent and lists the capabilities every
implementation must provide.

Section numbers are preserved from the original combined document, so existing references
(A19 to A28) remain valid.

## Reference Architecture: Firebase

### 13. Firebase Stack
The reference architecture uses the Google Firebase ecosystem:
- **Frontend:** React (JSX, not TypeScript), Vite 7, React Router, Material-UI (MUI) 7, Emotion CSS-in-JS, Material React Table 3 for all tables/list views/grids — hosted on Firebase Hosting as a static SPA
- **Backend:** Firebase Cloud Functions
- **Database:** Firestore
- **Authentication:** Firebase Auth
- **File Storage:** Firebase Storage (documents, business card photos, attachments)
- **AI Integration:** Pluggable AI provider via API calls from Cloud Functions

## Data Architecture

### 16. Pluggable Data Source Layer
Every data access call is routed through an abstraction layer. Each object's data source is configurable: it can read from and write to the local database or transparently redirect to a real-time web service call to an external system of record (e.g., SAP). Configuration is per-object.

**Reference:** DataSourceConfig → `specs/data-model.json`

**Client-side routing:** `DataService` delegates all operations to `routeOperation()` in `DataSourceRouter`. The router loads `DataSourceConfig` entries from the `dataSourceConfigs` Firestore collection and caches them. If `source_type === 'External'` and `active !== false`, the operation is routed to `ExternalSourceAdapter`; otherwise to `FirestoreMapper`. If no config exists for an object type, it defaults to Local.

**Secure external proxy:** `ExternalSourceAdapter` does NOT make direct HTTP calls from the browser. Instead, it calls the `externalDataProxy` Firebase Cloud Function via `httpsCallable`. The Cloud Function fetches the `DataSourceConfig` from Firestore server-side (keeping credentials safe), applies authentication headers based on `auth_type` (None/BasicAuth/OAuth2/APIKey), builds the HTTP request using standard REST conventions (GET for reads, POST for creates, PUT for updates, DELETE for removes), transforms request/response fields using `field_mapping`, and returns CRM-formatted data.

**Field mapping:** `field_mapping` in `DataSourceConfig` stores `{ externalFieldName: crmFieldName }`. For read operations, external field names are mapped to CRM field names. For write operations, the mapping is reversed dynamically. Unmapped fields pass through unchanged.

**Admin UI:** A "Data Sources" section in Settings (admin-only) displays configured data sources in a table with columns: Object Type, Source Type, Endpoint URL, Auth Type, Active, and Actions. An add/edit dialog allows configuring each object type's data source including endpoint URL, authentication, and field mappings. Saving clears the client-side config cache.

### 17. Bi-Directional Data Integration
The data source abstraction supports both read and write operations against external systems. Data from external systems is presented natively in the CRM UI. Users do not need to know the origin of the data. The `externalDataProxy` Cloud Function handles all five CRUD operations (getById, list, create, update, remove) against the configured external endpoint, providing full bi-directional integration.

### 18. Open REST API
The generated application exposes a REST API for all major objects. The API supports CRUD operations and is auto-documented. The API layer sits above the pluggable data source layer, meaning API consumers also benefit from the data source abstraction.

**Implementation:** An Express.js application is exported as a Firebase Cloud Function (`api`) using `onRequest`. The API is versioned at `/api/v1/`.

**Authentication:** All endpoints require a Firebase Auth ID token in the `Authorization: Bearer <token>` header. The middleware verifies the token using `getAuth().verifyIdToken()`.

**Endpoints:**
- `GET /api/v1/_docs` — Auto-documentation listing all available object types, their endpoints, and supported query parameters
- `GET /api/v1/:objectType` — List records (query params: `pageSize`, `sortField`, `sortDir`)
- `GET /api/v1/:objectType/:id` — Get single record by ID
- `POST /api/v1/:objectType` — Create record (auto-generates id, timestamps, auto-numbers)
- `PUT /api/v1/:objectType/:id` — Update record (auto-sets `updated_at`)
- `DELETE /api/v1/:objectType/:id` — Delete record

**Data source routing:** Each route checks the `DataSourceConfig` for the requested object type. Local sources are read from/written to Firestore directly via the Admin SDK. External sources are proxied to the configured external endpoint using the same authentication and field mapping logic as the `externalDataProxy` function.

**Object type resolution:** URL slugs (e.g., `accounts`, `sales-orders`) are mapped to ModelRegistry object types (e.g., `Account`, `SalesOrder`) via a server-side mapping that mirrors the client-side `navigation.js`. CORS is enabled for cross-origin requests.

## Server-Side Pagination Architecture

### 25. Server-Side Pagination
Main list views (ObjectListPage) use server-side pagination and sorting to handle large datasets efficiently. Only the current page of records (25/50/100) is fetched from Firestore per request, using cursor-based pagination via `startAfter(DocumentSnapshot)`. A `listPage()` method on FirestoreMapper returns `{ data, lastDoc }` where `lastDoc` is the raw DocumentSnapshot used as cursor for the next page. A `count()` method uses Firestore's `getCountFromServer()` to return total record counts for pagination UI display. A `usePaginatedList` React hook manages pagination state, sort state, and cursor caching (a `useRef` map of `pageIndex → DocumentSnapshot`). Material React Table is configured with `manualPagination` and `manualSorting` when server-side mode is active. Column filters are disabled in server-paginated mode since only the current page's records are in memory. CSV export fetches all records on demand when triggered. Embedded/related data tables (LinkedRecordCard, LineItemsCard, timelines) continue to use bounded client-side pagination with fixed page sizes since their result sets are naturally limited by parent-record filters.

## Real-Time Notifications Architecture

### 21. Notification Delivery
In-app notifications use a Firestore `onSnapshot` real-time listener filtered to the current user's ID and ordered by `created_at DESC` (limit 50). A `NotificationContext` React context wraps the authenticated app, providing `notifications`, `unreadCount`, and action methods (`markAsRead`, `markAllAsRead`, `deleteNotification`) to all components. The context subscribes to the listener when the user is authenticated and unsubscribes on logout. A composite Firestore index on `notifications` collection (`user_id ASC, created_at DESC`) is required for the query. Desktop browser notifications are dispatched from the context when new unread notifications are detected in the snapshot diff. A `NotificationService` module encapsulates all Firestore notification operations (subscribe, CRUD) and is consumed by the context.

### 22. Client-Side Notification Triggers
A `NotificationTrigger` utility is called after successful record saves in `RecordDetailsCard`. It compares pre-save and post-save field values to detect notification-worthy changes: `assigned_to` changes on Ticket (→ TicketAssigned), `stage_id` changes on Opportunity (→ DealStageChange), `owner_id` changes on Lead (→ LeadAssigned). Before creating a notification, the trigger loads the target user's `notification_preferences` from their UserProfile and skips creation if the type is explicitly disabled. Self-notifications are suppressed (target user !== current user). Trigger failures are caught silently and never block saves.

## Dashboard Architecture

### 23. Client-Side Dashboard Aggregation
Dashboard KPIs and chart data are computed by a `useDashboardData` hook that fetches records from multiple object types in parallel via `DataService.list()` (pageSize 1000) and aggregates client-side (count, sum, group-by). This avoids the need for server-side aggregation endpoints. A `DashboardService` manages per-user widget visibility preferences stored in the `DashboardConfig` Firestore collection. Role-aware default layouts determine which widgets are visible by default based on the user's role name (sales roles see sales widgets, service roles see service widgets, admin/manager see all).

## AI Architecture

### 19. Pluggable AI Provider
The AI integration layer supports multiple AI providers (OpenAI, Google, Anthropic, Moonshot). An admin configures provider, model, API key, and optional endpoint URL via the Settings page. Configuration is stored in the `AIProviderConfig` Firestore collection. Only one provider can be active at a time — activating one deactivates others. API keys are stored in Firestore and only accessed server-side by Cloud Functions; they never reach the browser client.

**Admin UI:** A Settings section (admin-only) displays configured providers in a table with add/edit/delete. The add/edit dialog includes: Provider dropdown (OpenAI/Google/Anthropic/Moonshot), Model text field (with placeholder examples), API Key (password field), optional Endpoint URL, and Active toggle.

**Reference:** AIProviderConfig → `specs/data-model.json`

### 20. AI Service Interface
All AI calls are routed through a Firebase Cloud Function (`callAIProvider`) that acts as a secure proxy. The function accepts `{ operation, params }`, fetches the active `AIProviderConfig` from Firestore, builds provider-specific HTTP requests, and returns normalized responses `{ content, model, tokens_used }`.

**Provider adapters:**
- **OpenAI:** POST to `https://api.openai.com/v1/chat/completions` with `Authorization: Bearer {key}`
- **Google:** POST to `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}`
- **Anthropic:** POST to `https://api.anthropic.com/v1/messages` with `x-api-key: {key}` and `anthropic-version: 2023-06-01`
- **Moonshot:** POST to `https://api.moonshot.cn/v1/chat/completions` with `Authorization: Bearer {key}` (OpenAI-compatible format)

**Client-side abstraction:** An `AIService` module provides standard operations (`chat`, `summarize`, `generate`, `isConfigured`) that call the Cloud Function via `httpsCallable`. The `isConfigured()` method checks for an active provider and caches the result.

**Data-aware context injection:** For `chat` and `semanticSearch` operations, the Cloud Function automatically enriches the AI prompt with relevant CRM data from Firestore. Record document IDs are included in the data context to enable record-level references. A `detectRelevantTypes(messages)` function scans user messages for keywords that map to object types (e.g., "customer/company/client" → Account, "deal/pipeline" → Opportunity, "ticket/case" → Ticket). For `chat`, up to 3 matched types are queried (200 records each, key fields only). For `semanticSearch`, all object types are queried (100 records each) to enable cross-type semantic matching. A `formatContextText(data)` function converts records into compact pipe-separated text with IDs. The context is prepended as a system message before the AI call. If no keywords match, Account + Opportunity are fetched as defaults.

**Semantic search operation:** The `semanticSearch` operation instructs the AI to return structured JSON results (`{ results: [{ type, id, name, reason }] }`) identifying records that match the user's natural language query by intent, not just keywords. The Cloud Function parses the AI's JSON response (stripping markdown fences if present) and returns the structured results to the client. The client `AIService.semanticSearch()` method handles JSON parsing with graceful fallback to empty results on parse errors.

### 21. Internationalization (i18n) Architecture
The i18n system uses a singleton + React context hybrid pattern. A `TranslationService` module-level singleton provides a `t(key, fallback)` function callable from anywhere — both React components and pure utility functions like `formatFieldLabel()`. A `TranslationContext` React context wraps the app, reads the user's `language_preference` from their UserProfile, loads translations from Firestore, and initializes the singleton. This dual approach is necessary because the three core label functions in `fieldUtils.js` (`formatFieldLabel`, `getObjectLabel`, `formatRelationshipName`) are pure functions without React context access, yet they drive ~70% of all visible labels.

**Translation storage:** Firestore collection `translations`, one document per ISO 639-1 language code (e.g., `translations/de`). Each document contains `{ language_code, language_name, labels: { key: translatedText } }`. This yields exactly one Firestore read per user session to load all translations for a language.

**Master label catalog:** A `labels.js` config file defines all translatable label keys with English defaults. Static UI labels (~120 keys for nav, buttons, sections, dashboard, dialogs) are defined directly. Dynamic labels (~350+ keys for field labels, enum values, object type names, relationship names) are generated at runtime from `ModelRegistry` and `dataModel.json` via a `getAllLabels()` function. Label keys use a dotted prefix convention: `nav.`, `ui.`, `section.`, `field.{ObjectType}.{fieldName}`, `enum.{Value}`, `object.{ObjectType}`, `rel.{name}`.

**Language preference:** Stored as `language_preference` (string, ISO 639-1 code, default `"en"`) on the `UserProfile` object. When the user changes language, the context loads the new translation document and re-renders the entire UI.

**AI batch translation:** Uses the existing `AIService.generate()` to translate labels in batches of ~50. The prompt requests JSON output with same keys and translated values. Results are merged and saved to the Firestore translation document.

**Bundled language packs:** The eight product packs live in `specs/translations/<code>.json` (shared architecture, section 13) and are generated from this implementation's catalog, which defines the product-wide key set. `scripts/export-label-catalog.mjs` emits the exact runtime catalog by bundling `labels.js` with esbuild - the config imports the data model through the `$model` alias and navigation through MUI icon modules, so plain Node cannot import it directly. `scripts/import-translations.mjs` writes the packs as `translations/<code>` documents through the Firestore REST API; it takes the target project id as an argument and an OAuth bearer token from the environment, so the one script serves every instance of this implementation. An import replaces the whole document, so manual translation edits survive only until the next import.

**First-run seeding:** the build copies `specs/translations/*.json` into `public/translations/` together with a generated `index.json` listing the bundled codes (the folder is generated, not committed), so every hosting deploy physically ships the packs. When an administrator signs in, a seeder compares the bundled codes against the `translations` collection and a seed-registry document (`translations_meta/seed`, an array of codes): a code in the registry is skipped, a code with an existing document is adopted into the registry, and a code with neither gets its pack fetched from hosting and written as a translation document, then registered. Seeding runs client-side under admin permissions, is idempotent, and never resurrects a language an admin deleted.

**Page-level i18n wrapping:** All page components (`HomePage`, `LoginPage`, `SettingsPage`, `ObjectListPage`, `ObjectDetailPage`, `ObjectCreatePage`, `App.jsx`) import the shorthand `t()` function from `TranslationService` and wrap all user-visible hardcoded English strings with `t('key', 'English fallback')` calls. Keys follow the dotted prefix convention: `dashboard.*` for home page widgets, `login.*` for login page strings, `settings.*` for settings page, `ui.*` for common UI labels, `dialog.*` for dialog text, `app.*` for application-level messages. Brand names (CRM, THREE) and CSS/structural values are not wrapped.

### 24. Record Locking Architecture

**Pessimistic locking** prevents concurrent edits via a `recordLocks` Firestore collection. Lock documents use deterministic IDs (`{objectType}_{recordId}`) and store: `locked_by` (userId), `locked_by_name`, `locked_at`, `expires_at` (TTL 15 min). A `RecordLockService` provides `acquireLock`, `releaseLock`, and `heartbeat` functions. A `useRecordLock` hook uses Firestore `onSnapshot` for real-time lock watching — when one user acquires a lock, all other users viewing the same record see the lock indicator immediately. Heartbeat interval (every 5 min) extends the TTL while editing. Locks are released on save, cancel, or `beforeunload`. Expired locks are treated as unlocked client-side.

**Dialog and settings component i18n wrapping:** All dialog components (`LeadConvertDialog`, `DocumentConvertDialog`, `CsvImportDialog`) and settings sections (`AiSummaryPlaceholder`, `NotificationPanel`, `NotificationPreferencesSection`, `AIProviderSection`, `TicketStatusSection`, `AccessControlSection`, `ImportSection`, `ReplicationSection`, `DataSourceSection`) import the shorthand `t()` function from `TranslationService` and wrap all user-visible hardcoded English strings with `t('key', 'English fallback')` calls. Keys follow the dotted prefix convention: `dialog.*` for dialog text, `ui.*` for common buttons (Cancel, Save, Close), `menu.*` for notification panel labels, `settings.notifications.*` for notification preferences, `settings.ai.*` for AI provider settings, `settings.ticket.*` for ticket status settings, `settings.access.*` for access control, `settings.import.*` for data import, `settings.replication.*` for data replication, `settings.datasource.*` for data source configuration, `dashboard.*` for dashboard components. Placeholder examples (e.g., "john@example.com", "example.com", model placeholders) are not wrapped.

## Instance Deployment Architecture

### 26. Multi-Instance Deployment
The application is deployed as one or more **independent instances**. Each instance is a separate Firebase project with its own Firestore database, Auth user pool, Cloud Functions, and Hosting site. Instances share nothing at runtime: no data, no users, no configuration. They are built from the same source tree and differ only in the Firebase configuration injected at build time.

**Instance registry:**

| Alias | Firebase project | Hosting site | URL |
|---|---|---|---|
| `default` | `your-project` | `your-project` | https://your-project.web.app |
| `<alias>` | `your-second-project` | `your-second-site` | https://your-second-site.web.app |

Aliases are declared in `.firebaserc` under `projects` and selected per command with `--project <alias>`.

**Per-instance frontend configuration:** No Firebase project identifier is hardcoded in application source. `app/src/config/firebase.js` reads all six values (`apiKey`, `authDomain`, `projectId`, `storageBucket`, `messagingSenderId`, `appId`) from `VITE_FIREBASE_*` environment variables. Each instance owns a Vite env file: `app/.env` for `default`, `app/.env.<alias>` for every other instance. Builds select the instance with `vite build --mode <alias>`; Vite loads `.env` first and `.env.<alias>` overrides it, so every instance file must define all six variables. Env files are excluded from version control.

**Per-instance build output:** Each instance builds to its own directory (`app/dist` for `default`, `app/dist-<alias>` otherwise). Separate output directories prevent an instance from deploying another instance's bundle, which would silently point one customer's URL at another customer's Firestore database.

**Per-instance Firebase config:** Each non-default instance has its own `firebase.<alias>.json` selected with `--config`. It sets that instance's `hosting.site` and `hosting.public`, and references the shared `firestore.rules`, `firestore.indexes.json`, and `functions/` source by relative path, so security rules, indexes, and backend code stay identical across all instances while hosting stays instance-specific. `firebase.json` remains the `default` instance's config and is never parameterized.

**Fixed region:** All instances provision Firestore and deploy Cloud Functions in `europe-west1`. The region is hardcoded client-side in `app/src/config/firebase.js` (`getFunctions(app, 'europe-west1')`), so an instance whose functions are deployed elsewhere cannot reach them.

**Instance bootstrap:** A new instance starts with an empty Firestore. The first user to sign in triggers `setupFirstUser()` in `AuthService`, which seeds the default roles (Admin/Manager/User) and pipeline stages and assigns that user the Admin role. No manual data seeding is required. Instance-scoped runtime configuration that lives in Firestore - AI provider credentials, data source configs, languages, whitelist entries - is not replicated between instances and must be configured per instance through Settings.

**Manual provisioning steps per instance:** Creating an instance requires actions that cannot be scripted through the Firebase CLI and must be performed in the Firebase console: upgrading the project to the Blaze billing plan (Cloud Functions v2 cannot deploy on the Spark plan) and enabling the Email/Password and Google sign-in providers. Enabling the Firestore API and creating the database require an authenticated `gcloud` session.

## User provisioning

**Constraint:** Firebase Authentication's user list is only readable through the Admin SDK. The browser client cannot enumerate Auth accounts, so a user-management screen cannot show "people who signed in but have no profile" without a privileged backend. Rather than add a Cloud Function and an admin-only callable, provisioning is inverted: an admin creates the `UserProfile` first, and the Auth account attaches itself on first sign-in.

**Profile claiming.** A `UserProfile` created by an admin carries `auth_uid: ''` — a *pending* profile. `resolveUserSession()` in `AuthService` resolves an authenticated Firebase user against Firestore in this order:

1. `fetchUserProfile(uid)` — profile whose `auth_uid` matches; the normal path.
2. `claimPendingProfile(user)` — a profile whose `email` equals the signed-in email (case-insensitive) and whose `auth_uid` is empty. The uid is written to that profile and it is returned. Claiming is the only path that writes `auth_uid` after creation.
3. `setupFirstUser(user)` — only when no profiles exist at all.
4. Rejection.

Because only admins can create profiles, pre-creating one for an address is not a privilege escalation: the profile is claimed only when Google authenticates a user holding that verified address. The email comparison is lowercased on both sides.

**Deactivation** is a `UserProfile.active` flag checked in `resolveUserSession` after the profile is found. An inactive user is rejected with `rejected: 'deactivated'` and keeps their records, XP and history.

**Whitelist interaction.** `emailWhitelist` is evaluated on *every* sign-in, not only the first, and applies to users who already hold a profile. An empty whitelist allows everyone. Since an invited address that does not match an active whitelist would be rejected despite having a valid profile, the invite flow checks the whitelist and offers to add the address in the same transaction.

**What the screen deliberately cannot do:** it cannot list Firebase Auth accounts, reset passwords, or revoke sessions — all Admin SDK operations. Deleting a profile removes CRM access but leaves the Auth account intact, so the person can still sign in and will land on the "not provisioned" screen.

## List sort configuration

**Why lists looked random.** `usePaginatedList` initialised its sorting state to `[]`, so `FirestoreMapper.listPage` added no `orderBy` clause. Firestore then returns documents in `__name__` order — document ID order — and IDs are v4 UUIDs. The order was arbitrary but stable, which is why it read as random rather than as a bug.

**Storage.** Settings live in a `listViewSettings` Firestore collection, one document per object type with the object type as the document ID, holding `object_type`, `sort_by` (`'number' | 'name'`), `sort_direction` (`'asc' | 'desc'`), `updated_at` and `updated_by`. Like `emailWhitelist`, this collection is deliberately **not** in `dataModel.json`: it is application configuration rather than CRM data, so it needs no list page, no detail page, no auto-number and no place in the object model the CRM skill exposes. `ListSortService` owns all access and caches the whole collection in a module-level map for the session, since every list page open reads it.

**Resolution.** `getSortFieldForMode(fields, mode)` in `fieldUtils` maps the two user-facing choices onto a single Firestore field, because `orderBy` takes one field and a composite `first_name + last_name` cannot be expressed. `'number'` resolves to the auto-number field, falling back to `created_at`. `'name'` resolves to `name` / `name1`, then `last_name` where a `first_name` + `last_name` pair exists, then `title` / `subject` / `label`, and finally to the number field for document objects that carry no name. The resolved field name is surfaced in the settings UI so the mapping is visible rather than implicit.

**Application.** `usePaginatedList` resolves the setting before its first fetch and seeds the MRT `sorting` state from it, so a list issues exactly one query on open rather than an unsorted query followed by a sorted one. Manual column-header sorting continues to overwrite that state for the session and is not persisted.

**Index cost is nil.** A list page applies no filters, so the query is a single-field `orderBy` plus `limit`, served by Firestore's automatic single-field indexes. No composite index is needed and `firestore.indexes.json` is unchanged. A filtered list switches to the existing client-side mode, where the full collection is fetched unsorted and MRT sorts in the browser.

**Sorted queries omit documents.** Firestore does not return documents that lack the `orderBy` field — they are not sorted last, they are absent, and the unfiltered `count()` still includes them, so the total would disagree with what paging can reach. This is not hypothetical: on the demo instance three records created 2026-02-22 carry no auto-number. `ListSortService.countHiddenBySort()` therefore compares `getCountFromServer` with and without the `orderBy` constraint, and the settings section reports the difference and offers a backfill that assigns numbers from the object's `counters/<ObjectType>` document. Any future import that writes documents directly, bypassing `DataService.create`, must populate the auto-number field or its records will be invisible in sorted lists.
