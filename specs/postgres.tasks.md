# Postgres Implementation Tasks

Tracks `implementations/postgres/`. Gitignored: project state, not product specification.
Architecture: `specs/postgres.architecture.md`. Requirements R1-R9: `specs/architecture.md`.

## Done

- [x] PT1 - Scaffold SvelteKit app (Svelte 5.56, Kit 2.63, TypeScript, runes forced)
- [x] PT2 - Switch to `adapter-cloudflare`, drop `adapter-auto`; build emits `_worker.js` (R1)
- [x] PT3 - Add Tailwind CSS via `@tailwindcss/vite`; verified in build output
- [x] PT4 - Install `@supabase/supabase-js`, `@supabase/ssr`, `@tanstack/svelte-table` v9 (Svelte 5 peer)
- [x] PT5 - DDL generator `db/generate-ddl.mjs` from `specs/data-model.json` (P3)
- [x] PT6 - Validate generated schema against live Postgres 15: 38 tables, 30 enum types,
      13 sequences, 148 foreign keys, RLS enabled on all 38 tables
- [x] PT7 - Make foreign keys `deferrable initially deferred` so the first-user bootstrap
      is possible; proved by seeding Role plus UserProfile in one transaction
- [x] PT8 - Verify auto-numbers: sequence-backed integer, `lpad` to the display form

- [x] PT9 - `auth_uid` made optional in `data-model.json`. The Firebase implementation
      already ships pending profiles carrying `auth_uid: ''`, so `required: true` described
      neither implementation. Verified: two pending profiles coexist with null `auth_uid`,
      claiming works, a duplicate uid is rejected, and an empty string would have collided
      on the unique index, so the representation of absence is load-bearing.
- [x] PT11 - RLS policies generated from the model by `db/generate-policies.mjs`. 147
      policies, driven by `Role.permissions` so there is one definition of who may do what.
      Verified behaviourally: a Sales role with `read_all: false` sees only its own
      accounts, an admin sees all, an unauthenticated session sees none, and the provider
      key column is unreadable by the `authenticated` role while remaining writable.

## Open

- [x] PT10 - Decided: `created_by` / `updated_by` stay required everywhere. Audit
      provenance is part of the model's contract; the cyclic bootstrap is handled by
      deferrable constraints, not by weakening the columns.

## Next

- [x] PT12 - Vendor dependency removed. No Supabase, no Cloudflare: `adapter-node`,
      Better Auth, Postgres `listen`/`notify`, filesystem storage. Whole stack runs locally.
- [x] PT21 - Identity moved from a platform function to a transaction-scoped session
      setting. Verified it does not survive commit, so it cannot leak across a pool.
- [x] PT22 - Apply order fixed and scripted in `db/apply.sh`; a blanket grant applied after
      the policies would have silently undone the provider-key column restriction.
- [x] PT23 - Better Auth wired to Postgres (R2). Verified end to end: bootstrap creates the
      first admin, sign-in returns a session, `/api/me` resolves account and profile,
      anonymous user creation is refused with 403, an admin can create a second user who
      signs in with their own role, and self-service sign-up returns 400.
- [x] PT26 - Auth tables namespaced `auth_*`. Unnamespaced, the schema generator emitted
      `alter table "account" add column "password"` against the 27-column CRM account table.
- [x] PT27 - Auth DDL generated from the installed library, not `@better-auth/cli`. The CLI
      lags the library (1.4.21 against 1.7.2) and omits `account.issuer`, which the runtime
      writes, so the CLI schema fails at insert time.
- [x] PT28 - Bootstrap privilege-escalation hole closed. `isUnprovisioned()` counted profiles
      under RLS, which hides everything from an unauthenticated caller, so every instance
      looked empty and anonymous callers could keep creating admins.
- [x] PT24 - Realtime working end to end: `pg_notify` triggers, one dedicated `listen`
      connection, server-sent events. Verified an insert and an update both reach a browser
      stream carrying only table, op and id.
- [x] PT25 - File storage. Bytes under a server-generated uuid on disk, metadata in the
      Document record, both up and down behind the profile check. Verified: anonymous upload
      and download refused with 401, round-trip intact, traversal-shaped id rejected.
- [x] PT13 - `PostgresMapper` plus `/api/v1` routes. Verified: three records created,
      sequence-assigned auto-numbers, count, keyset pagination across two pages, and
      unauthenticated access refused with 401. SQL identifiers are whitelisted through
      ModelRegistry, since identifiers cannot be parameterised.
- [x] PT14 - `ModelRegistry` ported and typed; client `DataService` keeps the reference
      interface over HTTP. The "moves nearly unchanged" expectation was half right and the
      spec is corrected: the interface ports, the implementation splits, because a browser
      cannot hold a Postgres connection.
- [x] PT29 - Data model read from `specs/data-model.json` through a Vite alias, never forked
      into the implementation.
- [x] PT30 - Data model fork reconciled and eliminated. The spec absorbed the drift (39
      objects, DealRoom, Moonshot provider, language_preference, AuditLog summary fields,
      Contact.account_id, LineItem auto item numbers), keeping only the `auth_uid` fix where
      the spec was ahead. `specs/specifications.md` lines 57, 72 and 86 settled the three
      genuine conflicts: quotations, sales orders and invoices explicitly have no title
      field, so the spec's data model contradicted its own specification and the app was
      right. Both implementations now read `specs/data-model.json` through an alias; the copy
      under the reference implementation is deleted, so the fork cannot recur.
- [x] PT31 - Confirmed: line item ordering lives in `item_number` (auto 10, 20, 30, SAP
      POSNR style). Recorded as divergence 10 in the architecture document.

## Data migration

- [x] PT35 - Business data copied from the Firebase instance: 3441 of 3447 Firestore
      documents imported (172 accounts, 2878 products, 251 assets, plus all other business
      objects). Six assets were unimportable: their required account reference held free
      text. The migration tooling lives in tmp/ (firestore-to-postgres.py), reads the
      Firestore REST API with a token minted from the firebase-tools credential store, and
      imports in one deferred transaction.
- [x] PT36 - Auto-numbers redesigned from integer sequences to sequence-backed padded
      strings: the live dataset carries alphanumeric SAP identifiers (DE10002345) that an
      integer column cannot hold. Display strips padding from purely numeric values only.
- [x] PT37 - Model defaults now apply server-side on create, so API-first consumers get the
      same behaviour as the form and validation checks the record actually stored.
- [x] PT38 - Source data repaired at the source and root cause fixed. Firestore
      (project crmthree): 3443 patches stamped audit fields everywhere and anchored 165
      ownerless accounts; a deleted account and a deleted product were restored as stubs
      under their original ids, preserving the 11 records that referenced them; 6
      doubly-corrupt assets (free-text account references, column-shifted values) were
      deleted; 3 missing auto-numbers assigned. avatar_url was widened to 2048 in the model
      instead of truncating a real URL. Root cause: the reference DataService never stamped
      created_by/updated_by on any write - fixed centrally with a current-actor singleton
      set by AuthContext, plus explicit stamps in the raw-setDoc seed paths. Proof: the
      export now imports into Postgres with zero repairs and zero skips (3443 of 3443).

## Tier 1 + Tier 2 feature build

- [x] PT39 - Related-record cards from model relationships (one-to-many, polymorphic via
      condition, many-to-many with link/unlink); activity timelines came along for free
- [x] PT40 - Conversions: lead convert and the document chain, single transaction each
- [x] PT41 - Settings: user management (provision UI, roles inline, deactivate, pending
      chips) and role permission matrix, verified biting through RLS live
- [x] PT42 - Global search, ILIKE per navigable type under RLS
- [x] PT43 - Dashboard: KPI tiles, pipeline-by-stage and tickets-by-priority bars, built to
      the dataviz method with a validator-stepped sequential ramp
- [x] PT44 - Deal Room workspace with stage stepper; live comment threads on every
      commentable type over the change channel
- [x] PT45 - AI briefing card and data-aware context injection under the caller's RLS
- [x] PT46 - CSV export (keyset-streamed) and import (server-validated, per-line errors)
- [x] PT47 - Settings: ticket statuses, AI provider UI (write-only key), email/domain
      whitelist with sign-in enforcement via security definer, verified locking a signed-in
      user out and back in live

## Full-specification build (second phase)

- [x] PT48 - Profile page, dark mode via token retint, notification preferences gating the
      triggers end to end
- [x] PT49 - Document upload on the Documents cards
- [x] PT50 - Audit trail as one generic trigger on 27 tables, settings viewer, own-rows
      timeline on the profile
- [x] PT51 - Case Room workspace; virtual navigation entries introduced
- [x] PT52 - Gamification engine in the database, leaderboard, badges, challenges card,
      Team Timeline
- [x] PT53 - Internationalisation: t() singleton, model-generated catalog, AI batch
      translate, SSR-rendered translations; verified in German
- [x] PT54 - Semantic search, duplicate detection (pg_trgm), monthly trend chart
- [x] PT55 - Data source router inside the mapper and transactional replication, verified
      against a mock SAP-style service both directions
- [x] PT56 - Role-adaptive navigation, mobile overlay rail; fixed jsonb array binding
      (arrays bound as Postgres array literals, empty arrays silently became {})
- [x] PT57 - Inline editing on lists
- [x] PT58 - AI features: coaching, meeting summaries, case-to-article, email parsing,
      performance narratives. Stories 56/57 not implemented - open in the reference's own
      task list too.
- [x] PT59 - README covers both implementations; postgres implementation README written
- [x] PT60 - Fresh-clone proof: apply.sh builds 47 tables, 159 policies, 43 triggers from
      committed SQL alone; production build clean; 13-page sweep all 200
- [x] PT61 - Language packs: shared 821-key catalog exported from the reference
      implementation, translated into eight languages (de, fr, es, nl, pt, it, ja, zh),
      stored in specs/translations/, importers for both implementations, imported into
      all three instances (postgres local and both hosted Firebase instances). Gemini free-tier
      quota died
      after de/fr; the remaining six languages and the de/fr gap-fix were translated by
      Claude directly, validated for key parity and placeholder integrity
- [x] PT62 - Re-key the postgres UI to the shared reference label catalog: per-object
      field keys, enum values, relationship names, ported static labels, full t() sweep
      of the Svelte UI; parity with the reference exporter asserted (821/821 keys, zero
      value diffs); CSV headers pinned to deterministic English; search API returns
      objectType and the client translates
- [x] PT63 - Bundled packs seed themselves: per-language seed registry in both
      implementations (translation_seed table / translations_meta doc), postgres boot
      seeding over the owner connection, firebase build-copied packs with admin-session
      seeding; adding a pack file later auto-appears, deletions stick. Verified on
      postgres (adoption, deletion stickiness, empty-store reseed at boot) and deployed
      to both Firebase instances with hosted packs and pre-adopted registries
- [x] PT64 - Navigation rail always opens collapsed: dropped the per-browser persistence
      that reopened it expanded; expansion now lasts for the session only, matching the
      shared UX default and the reference behaviour
- [x] PT65 - Dashboard stage chart includes closed stages: the query filtered to
      result='Open', so Closed Won and Closed Lost always charted zero; the UX spec names
      the widget "Opportunities by Stage" with no such filter (Pipeline Value KPI stays
      open-only by design)
- [x] PT66 - Dashboard chart polish: bar tracks reserve space for the end-of-bar value
      labels so a full-length bar never clips its number; label column narrowed from
      144px to 112px to remove dead space left of the bars
- [x] PT67 - Restore plugins: [react()] in the reference app's vite config: the data-model
      reconcile commit dropped it while adding the $model alias, so every JSX file compiled
      to bare React.createElement and the first public-repo hosting deploy shipped a blank
      page; caught on crmthree.web.app, fixed, redeployed and verified live (the second hosted
      instance builds from a separate config that kept the plugin and was never affected)
