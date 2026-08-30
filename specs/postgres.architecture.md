# Postgres Implementation Architecture

This document describes how a Postgres implementation realises the product architecture
defined in `architecture.md`. It is the second stack-specific architecture alongside
`firebase.architecture.md`.

Its purpose is an **architecture proof**: the specification, not the code, is the product,
so a second stack sharing no technology with the first must be able to satisfy the same
requirements. Where this implementation could imitate the Firebase one but a native
approach is better, it takes the native approach and records the divergence in the final
section. Those divergences are the evidence.

Named for the technology rather than the platform. Postgres here is hosted on Supabase,
but the architecture survives a move to Neon or a self-hosted cluster.

## Stack

### P1. Postgres Stack

| Layer | Choice |
|---|---|
| Frontend | Svelte 5 (runes), SvelteKit, TypeScript |
| Styling | Tailwind CSS with shadcn-svelte, deliberately not Material |
| Data grid | TanStack Table, Svelte adapter, headless |
| Hosting | Cloudflare Pages and Workers, `adapter-cloudflare` |
| Database | Postgres, hosted on Supabase |
| Authentication | Supabase Auth, cookie sessions via `@supabase/ssr` |
| Real-time | Supabase Realtime over Postgres logical replication |
| File storage | Supabase Storage |
| Server compute | SvelteKit server routes running on the Workers runtime |
| AI integration | Same pluggable provider set, proxied through server routes |

### P2. How the requirements are met

| Req | Mechanism | Contrast with Firebase |
|---|---|---|
| R1 | SvelteKit server-rendered, on Cloudflare Pages | Firebase serves a static SPA |
| R2 | Supabase Auth, cookie-based server sessions | Firebase holds the token client-side |
| R3 | Postgres with keyset pagination and `count(*)` | Firestore cursor snapshots and `getCountFromServer` |
| R4 | Supabase Realtime channels | Firestore `onSnapshot` |
| R5 | SvelteKit server routes with secret bindings | Separate Cloud Functions |
| R6 | Supabase Storage buckets with policies | Firebase Storage |
| R7 | Row Level Security in the database | Firestore security rules |
| R8 | Outbound `fetch` from server routes | Callable Cloud Functions |
| R9 | Server routes under `/api/v1` | An Express app inside a Cloud Function |

## Data Architecture

### P3. Relational mapping of the data model

`data-model.json` stays the single source of truth. A mapper generates SQL DDL from it, as
section 7 of the shared architecture requires of every template.

- One table per object type, snake_case, with a `uuid` primary key.
- Relationships become real foreign keys with `on delete` behaviour stated per relationship,
  rather than loose id strings.
- Many-to-many relationships become junction tables (`contact_account`,
  `opportunity_contact`), which the relational model expresses natively.
- Enumerations become Postgres `enum` types, so invalid values are rejected by the database
  rather than by convention.
- Timestamps are `timestamptz`, not ISO strings.
- **Auto-numbers become sequences.** The Firebase implementation stores them as
  zero-padded strings and strips the padding for display. Here the column is an integer
  from a per-object sequence and the padding is applied at render time. This is the cleanest
  evidence that `data-model.json` is genuinely database-agnostic: the same field definition
  produces a different, idiomatic physical representation.

### P4. Server-side pagination, sorting and counts

List views use **keyset pagination**: `where (sort_key, id) > (:last_sort, :last_id) order by
sort_key, id limit :page_size`. The client carries the last row's sort key and id rather than
an opaque cursor object. Totals come from `count(*)`, optionally `count(*) over ()` in the
same round trip.

Two consequences worth noting against the reference implementation:

- Sorting on any column is free. Firestore needs a composite index per sort and filter
  combination, which is why `firestore.indexes.json` exists; that file has no counterpart here.
- Keyset pagination is stable and O(1) at any depth, unlike `offset`, and unlike Firestore it
  does not require holding a document snapshot to resume.

### P5. Pluggable data source layer

`ModelRegistry`, `DataService` and `DataSourceRouter` are framework-agnostic modules in the
reference implementation and port across almost unchanged. Only the mapper is rewritten:
`FirestoreMapper` becomes `PostgresMapper`, exposing the same interface (`list`, `listPage`,
`count`, `get`, `create`, `update`, `remove`).

This is a deliberate structural point. The seam that story 30 introduced for external systems
of record turns out to be the same seam that makes a second implementation cheap, which is
itself a finding about the architecture.

### P6. Open REST API

Server routes under `/api/v1/:objectType[/:id]` mirror the route shape and payloads of the
reference implementation, so existing API consumers are unaffected. Requests authenticate
with a bearer JWT, verified server-side, and then run under the caller's RLS context so the
API cannot return more than the user could see in the UI.

Supabase also exposes PostgREST over the same schema for free. It is not used as the public
interface, because the specification fixes the route shape, but it remains available for
ad-hoc integration work.

## Authorization

### P7. Row Level Security

Authorization moves into the database. Every table carries policies keyed to `auth.uid()`,
resolved to a role through `user_profiles`, with a `stable` helper function returning the
current user's role name.

This is the most significant improvement over the reference implementation, whose rules
currently grant every authenticated user full access to every document, with real
authorization enforced only in the client. Under RLS the same policies apply to the UI, to
the REST API and to real-time subscriptions, because all three reach the data through
Postgres. One authorization model instead of one rule set plus client-side convention.

## Real-time

### P8. Realtime subscriptions

Tables that need pushing are added to the `supabase_realtime` publication, and clients
subscribe with `postgres_changes` filters, for example `user_id=eq.<id>` for notifications.
Supabase Realtime enforces RLS on the replication stream, so a subscription cannot deliver a
row the subscriber could not select.

Notification triggers move server-side. The reference implementation compares field values in
the browser after a save and writes the notification from the client; here a Postgres trigger
on the watched columns writes the notification row, so it fires for every writer including the
REST API, not only for users of the web UI.

### P9. Record locking

A `record_locks` table with primary key `(object_type, record_id)` and columns `locked_by`,
`locked_by_name`, `locked_at`, `expires_at`. Clients subscribe to it for live indication, and
an expired lock is one whose `expires_at` has passed.

Postgres advisory locks are deliberately not used: they are scoped to a database session,
whereas these locks must outlive a stateless HTTP request and be visible to other users.
Expired rows are reaped by a scheduled job rather than being left for clients to ignore.

## Server-side compute

### P10. SvelteKit server routes

Requirements R5, R8 and R9 are met inside the web framework rather than beside it. There is no
separate functions deployment, no second runtime and no second deploy step. The AI proxy, the
replication proxy, the external data source adapter and the REST API are all `+server.ts`
endpoints on the Workers runtime.

### P11. AI provider proxy and secret handling

Provider, model and active flag live in a configuration table and stay administrator-editable
through the UI, as story 20 requires. The API key does not sit in the database in clear text.
It is stored as ciphertext, and the key material that decrypts it is a Cloudflare secret
binding available only to the server route. Decryption happens in the Worker, so the
encryption key is never sent to the database and the provider key never reaches the browser.

The Supabase service role key is likewise a secret binding, never a client-visible variable.

## Frontend

### P12. Svelte 5 and SvelteKit

Runes (`$state`, `$derived`, `$effect`) replace React hooks; `setContext`/`getContext` replaces
React context; SvelteKit's file-based routing with `load` functions replaces React Router with
client-side fetching. Data for a page is resolved server-side in `load` before render, which
removes most of the loading-spinner states the reference implementation needs.

### P13. Model-driven UI

Unchanged in principle and essential to the product: generic list, detail and create pages are
driven by `ModelRegistry` reading `data-model.json`, not hand-written per object type. Only the
rendering primitives differ.

### P14. Design system and data grid

Tailwind with shadcn-svelte, chosen so the result is visibly not the reference implementation.
The grid is TanStack Table through its Svelte adapter, headless, with the presentation supplied
by the design system.

Worth recording: Material React Table is itself built on TanStack Table, so the two
implementations share a table engine while looking nothing alike. That is a useful data point
about where the real cost of a UI port sits, which is the component library rather than the
grid.

### P15. Internationalisation

Unchanged in approach: one row per language holding the label map, one read per session,
preference stored on the user profile.

## User provisioning

Self-service registration is disabled in Supabase Auth, matching the reference implementation.
Accounts are created by an administrator through a server route that calls the Supabase admin
API with the service role key.

The Firebase implementation is constrained here: its Auth user list is readable only through
the Admin SDK, so a user-management screen needs a Cloud Function. The same constraint exists
in Supabase, but since server routes are already part of this stack it costs nothing extra.

First sign-in claims a pending profile by matching email, and deactivated users are refused at
sign-in.

## Instance deployment

One Supabase project and one Cloudflare Pages project per instance, as section 26 requires of
any implementation. Instances share no data. All per-instance values are environment variables
and secret bindings; no instance identifier appears in source.

## Deliberate divergences from the Firebase implementation

These are the findings the proof exists to produce.

1. **Authorization moved into the database.** RLS covers UI, REST API and subscriptions
   uniformly, where the reference implementation relies on client-side enforcement.
2. **Notification triggers moved server-side**, so they fire for every writer rather than only
   for the web client.
3. **Auto-numbers became sequences** instead of zero-padded strings, showing the data model
   maps idiomatically rather than literally.
4. **Server compute merged into the web framework**, removing a runtime, a deployment artefact
   and a deploy step.
5. **Secrets left the database**, held as platform secret bindings with only ciphertext stored.
6. **No index configuration file**, because arbitrary sorting needs no declared composite index.
7. **Server-side rendering**, so first paint carries data rather than a spinner.

Items 1, 2 and 5 are improvements the reference implementation could adopt. That is a useful
result: the second implementation is not only a proof of portability but a source of feedback
on the first.
