# Plain Implementation Architecture

The Plain implementation is the proof at the far end of the spectrum: the complete CRMTHREE
specification as **one HTML file** with zero dependencies - no build step, no package manager,
no server process, no framework, no database engine. `implementations/plain/index.html` opens
from disk (`file:///`) or from any static host and is, by itself, the entire deliverable.
Where the Firebase implementation proves the spec on a managed platform, Postgres on a
self-hosted stack and Rails on a batteries-included framework, Plain proves that the
specification survives even when the whole runtime is a browser.

## Scope and Stack

### PL1. Single-File, Zero-Dependency Runtime
The application is a single `index.html` containing all markup, styles and scripts. No
external runtime libraries, stylesheets, fonts, icon sets or CDN assets are referenced; icons
are inline SVG, charts are hand-rolled SVG/CSS, and typography uses the system font stack.
The file runs offline from `file:///` and equally from any static web host - a directory
listing, an object store, or GitHub Pages. There is nothing to install and nothing to deploy
beyond copying one file.

### PL2. Technology Stack
Vanilla HTML5, CSS custom properties and ES2020+ JavaScript in one IIFE. Native browser
primitives replace every dependency: `localStorage` for persistence, `storage` events for
realtime, `<dialog>` for modals, `crypto.randomUUID()` for identity, `Blob`/`FileReader` for
file exchange, `fetch` for the AI and integration boundaries, `DecompressionStream` for the
embedded language packs, and the Notification API for desktop notifications.

### PL3. Storage Engine
All state lives in `localStorage` under the `c3.` prefix: one JSON array per object type at
`c3.tbl.<Object>`, sequences at `c3.seq`, configuration at `c3.cfg`, record locks at
`c3.locks`, the session identity at `c3.auth` and bookkeeping at `c3.meta`. A small data
access layer (`DB`) provides `list`, `getById`, `create`, `update`, `remove` and stamps the
five common audit fields on every write. Auto-numbers allocate from `c3.seq`, stored
zero-padded to the SAP-compatible field length and displayed with padding stripped.

### PL4. Query Engine
Lists never render raw collections: an in-memory query engine provides pagination, sorting
(numeric-aware collation), predicate filters and substring search over every collection, and
returns page data plus total counts - the same contract the other implementations get from
their databases (R3).

### PL5. Cross-Tab Realtime
`localStorage` writes fire `storage` events in every other tab of the same browser. A pub/sub
bus turns those events into the same change notifications used for in-tab reactivity, so open
tabs re-render affected views, refresh notification badges and reflect record locks live.
This is the R4 substitution: the push channel is the browser itself, and the payload is the
changed table name - views re-read state, they never trust event payloads.

### PL6. Model Registry Generated from the Blueprint
The object model is not hand-written. `scripts/generate-model.mjs` reads
`specs/data-model.json` and the shared label catalog and rewrites a marked data block inside
`index.html`: object definitions with SAP field lengths, enum value lists, reference targets,
required flags, list columns and relationship cards. Generic list, detail, create and linked
views render any object from this registry, so the specification remains the single source of
truth even inside one flat file. Regeneration is deliberate, reviewed and diffable.

### Code Golfing
Every byte counts and identifiers carry no runtime meaning: variable names, internal helper
names and CSS class names are kept as short as possible. The DOM and event helpers are one
to two characters (`$`, `$$`, `h`), internal state and loop variables are single letters
where scope is small, and longer names are reserved for the public `window.CRM` surface and
for the generated model data, which must stay reviewable. Development happens in readable
form; a deliberate golfing pass (Phase 8) compacts identifiers before release, verified by
the full regression, so compactness never trades against correctness.

## Capability Mapping

| Requirement | Plain mechanism |
|---|---|
| R1 | The file itself; any static host or `file:///` serves the complete application |
| R2 | Profile-based session switching with email/domain whitelist checks (see D6) |
| R3 | In-memory query engine over `localStorage` collections (PL4) |
| R4 | `storage` events fan out changes to every open tab (PL5) |
| R5 | Not satisfiable in a browser - keys stay client-side, disclosed prominently (D1) |
| R6 | Documents stored as base64 data URLs inside records (D7) |
| R7 | Client-side role guards over navigation, views and actions (D6) |
| R8 | Direct `fetch` to external endpoints, subject to CORS (D2) |
| R9 | `window.CRM` JavaScript API plus full JSON export/import (D3) |

## Identity, Authorization and Security

### PL7. Profiles and Session Switching
User profiles are records like any other. "Sign in" selects the active profile into
`c3.auth`; registration does not exist, and administrators create profiles in Settings. The
email/domain whitelist is evaluated on every profile switch. Roles (Admin, Manager, User)
gate navigation items, settings sections and mutating actions through a client-side guard.

### PL8. Honest Security Boundaries
A browser page cannot hold server-side secrets or enforce authorization against a determined
local user. The implementation does not pretend otherwise: AI provider keys are stored in
`localStorage` with an explicit warning (D1), role enforcement is a usability boundary rather
than a security one (D6), and the README states both plainly. This is a deliberate,
documented consequence of the architecture, not an oversight.

## Application Behaviour

### PL9. Views
A hash-free in-memory router drives four generic view kinds (list, detail, create, settings)
plus purpose-built views: home dashboard, Deal Room, Case Room, user and team timelines,
leaderboard and profile. Detail pages compose a quick-action bar, an AI briefing card, the
progressive-disclosure details card, inline line items for document objects, and stacked
linked-record cards - the shared UX contract, hand-rolled.

### PL10. Business Operations
Lead conversion, the document chain (Opportunity → Quotation → Sales Order → Invoice with
line items copied and item numbers in SAP style), ticket resolution stamps, XP awards, streak
updates, notification emission and audit logging run as synchronous multi-record operations
inside the data layer, so every entry path - UI, `window.CRM`, CSV import, replication -
produces the same side effects.

### PL11. Gamification, Notifications and Audit
Save-path triggers award XP from `XPEvent` configuration, maintain streaks, evaluate level
progression, badges and personal bests, emit notifications and append audit entries. The
dashboard, leaderboard, profile trophy case and timelines read these collections.

### PL12. AI Boundary
One AI client speaks OpenAI, Anthropic and Google Gemini wire formats directly from the
browser with the user's own key (D1). Briefings, chat, semantic query expansion, pipeline
coaching, meeting summaries, email parsing, case-to-article drafts, performance narratives
and batch label translation all flow through it; without a configured provider every AI
surface degrades to a quiet hint and the rest of the product works unchanged.

### PL13. Internationalisation
The shared catalog applies unchanged (shared architecture, section 13), but only its **English**
labels are embedded - as a gzip-compressed, base64-encoded blob inflated natively with
`DecompressionStream`. A `t()` helper resolves catalog keys against the selected language with
English fallbacks; enum storage stays English. Further languages are added at runtime, either by
AI-translating the catalog through the configured provider or by importing a pack file, and are
stored in `c3.tbl.Translation` like any other record. See divergence D8 for why the packs are
not bundled.

### PL14. Backup, Restore and Quota
Settings provides one-click export of the entire database to a JSON file and restore from
one, a storage usage meter against the ~5MB `localStorage` quota, and a guarded reset (D4,
D5). Backup/restore is the operational answer to a storage medium the browser may clear.

## Deliberate Divergences

1. **D1 - AI keys live in the browser.** There is no server to hold secrets (R5). Keys are
   stored in `localStorage`, entered by the user, marked write-only in the UI and called
   directly from the page. The Settings screen says exactly that.
2. **D2 - Integrations are CORS-bound.** Replication and external data sources call
   endpoints straight from the page; targets must send permissive CORS headers. The Settings
   screens carry that guidance.
3. **D3 - `window.CRM` replaces the REST API.** A static file cannot listen on a port. The
   full data layer, query engine and business operations are exposed as a typed JavaScript
   API, and complete JSON export/import covers programmatic exchange (R9 in spirit).
4. **D4 - Storage is quota-bound.** `localStorage` holds ~5MB; a usage meter, size-aware
   document handling and full backup/restore make the boundary visible and survivable.
5. **D5 - Backup is a file.** Durability is delegated to the user: one click exports
   everything, one click restores it.
6. **D6 - Authentication is simulated.** Profiles switch without passwords; the whitelist
   and role guards run client-side. In a browser-only artifact, authorization is a
   usability contract, not a security barrier - stated openly (PL8).
7. **D7 - Files are base64 records.** Documents and images embed as data URLs inside their
   records instead of a file store (R6), sized for business documents rather than archives.
8. **D8 - Only English is bundled; other languages are added in the app.** Section 13 has each
   implementation ship the product's eight language packs inside its build artifact. Here the
   artifact is the file the user downloads, and the packs weighed 127 kB - two thirds of the
   application - to carry seven languages a given installation will not use. So the file embeds
   the English catalog alone (the source text for the label editor and for translation), and a
   language is added in one step in Settings: AI-translate the catalog with the configured
   provider, or import a pack in the shipped `{ code, language_name, labels }` shape, including
   the reviewed packs in `specs/translations/`. The per-language seed registry disappears with
   the seeding it guarded. This is the one place where the single-file constraint outweighs a
   shared-architecture default, and it is the constraint's whole point: in a stack whose
   deliverable is measured in kilobytes, what ships has to earn its weight.

Divergences D1 and D6 are the honest price of the stack; D3 and D8 are the interesting
results - the REST surface and the language packs both survive translation into a world with
no server at all.
