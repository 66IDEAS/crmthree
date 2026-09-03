# CRMTHREE — Plain implementation

The fourth proof, at the far end of the spectrum: the complete CRMTHREE specification in
**HTML, JavaScript and CSS - no frameworks, no external dependencies**, all in one file. No
build step, no server, no database engine; `index.html` opens straight from disk (`file:///`)
or from any static host, everything runs on native browser primitives, and all state lives in
`localStorage`. Developed by Google Gemini and Claude.
See [`../../specs/plain.architecture.md`](../../specs/plain.architecture.md).

## Run it

Open `index.html` in a modern browser. That is the whole setup.

For a release-shaped copy, `index.min.html` is the same file with styles and scripts
minified - the golfing pass. Regenerate it after changes with `node scripts/minify.mjs`.

## Size

**The entire CRM is 319 kB** - one file, transferred once, with no second request. For
comparison, opening a Salesforce Lightning page pulls roughly **13 MB** before the first
record appears: about forty times the weight of this whole application, for one screen of one
CRM. Everything here is in that single file: 39 object types, the generic list, detail and
creation views, deal and case rooms, the dashboard and its charts, the gamification engine,
the AI layer, and all eight language packs.

| Artifact | Size | gzipped |
|---|---|---|
| `index.html` (readable source) | 392 kB | 170 kB |
| `index.min.html` (release) | **319 kB** | 157 kB |

Roughly 140 kB of either file is the embedded, gzip-compressed set of all eight product
language packs (shared architecture, section 13) plus the English catalog - so the
application code and its complete user interface are around 180 kB of it.

## What is inside

- The full object model, **generated from `specs/data-model.json`** into an embedded data
  block by `scripts/generate-model.mjs` (39 objects, SAP field lengths, enums, references,
  relationship cards). Regenerate deliberately after blueprint changes; the browser never
  runs the generator.
- Generic list / detail / create views over the registry, quick actions, inline SAP-style
  line items, the Lead conversion dialog and the Opportunity → Quotation → Sales Order →
  Invoice chain.
- Deal Rooms and Case Rooms, SLA deadline stamping and countdowns, knowledge drafts from
  tickets, user and team timelines, audit trail.
- Cross-tab realtime over `storage` events, pessimistic record locks (15-minute TTL),
  notifications with optional desktop delivery, role guards, email/domain whitelist,
  user management and per-object default sorting.
- Dashboard with hand-rolled SVG/CSS charts, and the gamification engine: XP events,
  levels, streaks, badges, personal bests, monthly challenges, leaderboard, confetti.
- The shared 821-key label catalog with **all eight language packs embedded** (gzip +
  `DecompressionStream`), seeded through the per-language registry; instant language
  switching and an admin label editor with AI batch translation.
- An AI layer speaking OpenAI, Anthropic and Google wire formats directly from the browser
  with the user's own key; assistant chat, record briefings, pipeline coaching, lead-from-
  email extraction, case-to-article drafts and performance narratives.
- Read-through external data sources and admin-triggered replication with field mapping
  (CORS applies), CSV import/export, full JSON backup and restore, a storage meter, and
  the programmatic `window.CRM` API.

## Honest boundaries

A browser page cannot hold server secrets or enforce authorization against a determined
local user. AI keys live in `localStorage` and are sent directly to the provider; role
checks are a usability contract, not a security barrier; external calls are bound by CORS;
storage is quota-bound (~5 MB) with backup/restore as the durability answer. All of this
is deliberate and documented as divergences D1-D8 in the architecture file.
