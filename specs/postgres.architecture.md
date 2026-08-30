# Postgres Implementation Architecture

This document describes how a Postgres implementation realises the product architecture
defined in `architecture.md`. It is the second stack-specific architecture alongside
`firebase.architecture.md`.

Its purpose is an **architecture proof**: the specification, not the code, is the product,
so a second stack sharing no technology with the first must be able to satisfy the same
requirements. Where this implementation could imitate the Firebase one but a native
approach is better, it takes the native approach and records the divergence in the final
section. Those divergences are the evidence.

Named for the technology rather than the platform, and it depends on no vendor at all.
The only infrastructure it requires is a Postgres server and a Node runtime, both of which
run on a laptop. There is no managed backend, no platform SDK and no hosting account. That
independence is itself part of the proof: the specification needs a database, not a
Backend-as-a-Service.

## Stack

### P1. Postgres Stack

| Layer | Choice |
|---|---|
| Frontend | Svelte 5 (runes), SvelteKit, TypeScript |
| Styling | Tailwind CSS with shadcn-svelte, deliberately not Material |
| Data grid | TanStack Table, Svelte adapter, headless |
| Hosting | Self-hosted Node server, `adapter-node`. Runs locally or on any machine |
| Database | Postgres, any instance, local by default |
| Authentication | Better Auth, sessions stored in Postgres |
| Real-time | Postgres `listen` / `notify`, delivered to clients over server-sent events |
| File storage | Filesystem behind a server route, S3-compatible optional |
| Server compute | SvelteKit server routes on Node |
| AI integration | Same pluggable provider set, proxied through server routes |

### P2. How the requirements are met

| Req | Mechanism | Contrast with Firebase |
|---|---|---|
| R1 | SvelteKit server-rendered on a self-hosted Node server | Firebase serves a static SPA |
| R2 | Better Auth, sessions in Postgres, cookie-based | Firebase holds the token client-side |
| R3 | Postgres with keyset pagination and `count(*)` | Firestore cursor snapshots and `getCountFromServer` |
| R4 | Postgres `listen` / `notify` bridged to server-sent events | Firestore `onSnapshot` |
| R5 | SvelteKit server routes reading process environment | Separate Cloud Functions |
| R6 | Filesystem behind an authorising server route | Firebase Storage |
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

`ModelRegistry` and the validators are framework-agnostic and port across unchanged.
`FirestoreMapper` becomes `PostgresMapper` behind the same operation names (`getById`,
`list`, `listPage`, `count`, `create`, `update`, `remove`).

`DataService` is the qualification. Its *interface* ports; its implementation does not. In
the reference stack the browser holds a database client and DataService talks to Firestore
directly. A browser cannot hold a Postgres connection, so the same interface becomes an HTTP
client and the mapper moves to the server. The seam is real, but it sits one layer lower than
a reading of the reference implementation suggests.

That split is an improvement rather than a tax: every read and write now crosses a server
boundary that establishes identity, so the UI and the public API reach data by the same
authorised path instead of the UI having a private one.

`listPage` also changes shape. The reference returns `{ data, lastDoc }` where `lastDoc` is a
Firestore `DocumentSnapshot`, an object that cannot leave the server. Here it returns
`{ data, cursor }` where the cursor is the last row's sort value and id, plain values that
survive a round trip to the browser and back.

This is a deliberate structural point. The seam that story 30 introduced for external systems
of record turns out to be the same seam that makes a second implementation cheap, which is
itself a finding about the architecture.

### P6. Open REST API

Server routes under `/api/v1/:objectType[/:id]` mirror the route shape and payloads of the
reference implementation, so existing API consumers are unaffected. Requests authenticate
with a bearer token, verified server-side against the session store, and then run under the
caller's RLS context so the API cannot return more than the user could see in the UI.

No generated API layer is used. The specification fixes the route shape, and a hand-written
route also keeps the API inside the same authorization path as the UI.

## Authorization

### P7. Row Level Security

Authorization moves into the database. Identity reaches Postgres as a per-request session
setting: the server route opens a transaction and calls
`set_config('app.user_id', <profile id>, true)` before touching data, so the value is scoped
to that transaction and cannot leak between pooled connections. Every table carries policies
reading that setting, resolved to a role through `user_profile`, with a `stable` helper
function returning the
current user's role name.

This is the most significant improvement over the reference implementation, whose rules
currently grant every authenticated user full access to every document, with real
authorization enforced only in the client. Under RLS the same policies apply to the UI, to
the REST API and to real-time subscriptions, because all three reach the data through
Postgres. One authorization model instead of one rule set plus client-side convention.

## Real-time

### P8. Realtime subscriptions

Postgres already ships the mechanism. A trigger on each watched table calls `pg_notify` on a
channel named for the object type, carrying the row id and the operation. One dedicated
connection in the Node server holds `listen` on those channels and fans events out to
connected browsers over server-sent events, which need no extra protocol and reconnect on
their own.

Authorization is preserved because the notification payload carries only an id. The browser
re-reads the row through the normal authorised path, so a client is never handed data its
policies would refuse. That is a deliberate trade of one extra round trip for the guarantee
that the realtime path cannot become a hole in the authorization model.

Notification triggers move server-side. The reference implementation compares field values in
the browser after a save and writes the notification from the client; here a Postgres trigger
on the watched columns writes the notification row, so it fires for every writer including the
REST API, not only for users of the web UI.

### P9. Record locking

A `record_lock` table, unique on `(object_type, record_id)`, with `locked_by`,
`locked_by_name`, `locked_at` and `expires_at`. It is infrastructure rather than domain data,
so like the auth tables it is not part of `data-model.json`. Acquiring is an upsert whose
update arm only fires for the holder, so the same call is also the heartbeat; a lock held by
someone else answers 409. An expired lock reads as unlocked and may be deleted by anyone,
which is how a lock left by a crashed session is taken over, without any scheduled reaper.
The change-notification trigger publishes lock changes, so other viewers of the record see
the indicator appear and disappear live.

Postgres advisory locks are deliberately not used: they are scoped to a database session,
whereas these locks must outlive a stateless HTTP request and be visible to other users.

## Server-side compute

### P10. SvelteKit server routes

Requirements R5, R8 and R9 are met inside the web framework rather than beside it. There is no
separate functions deployment, no second runtime and no second deploy step. The AI proxy, the
replication proxy, the external data source adapter and the REST API are all `+server.ts`
endpoints in the same Node process.

### P11. AI provider proxy and secret handling

Provider, model and active flag live in a configuration table and stay administrator-editable
through the UI, as story 20 requires. The API key does not sit in the database in clear text.
It is stored as ciphertext, and the key material that decrypts it comes from the server
process environment, never from the database. Decryption happens in the server route, so the
encryption key is never sent to Postgres and the provider key never reaches the browser.

The key column is additionally made **write-only for clients** through column privileges: an
administrator can set it, and no client role can read it back. This needs care, because a
column-level `revoke select` is silently a no-op while the role still holds table-level
`select`. The application connects as a restricted role holding exactly the privileges it
needs, and the migration that creates it grants no blanket table access. The table grant is
therefore
withdrawn and rebuilt column by column, omitting the key from `select` while keeping it in
`insert` and `update`. Server routes read it with the service role, which bypasses both RLS
and these grants.

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

Tailwind with a small set of hand-rolled components, visibly not the reference
implementation: dark slate rail with a teal accent instead of the orange-on-light Material
ribbon, square-ish corners, filled enum chips, and a system font stack, so the UI is
vendor-free down to the typography.

Both shadcn-svelte and TanStack Table were considered and set aside once the pages took
shape. The lists are server-rendered with sort and cursor in the URL, so the grid needs no
client-side table engine at all; and the component inventory a model-driven CRM needs is
small enough (inputs, chips, cards, one table) that a component library would be the heavier
dependency. TanStack becomes worth revisiting when client-side column filtering lands.

Worth recording anyway: Material React Table is itself built on TanStack Table, so a
TanStack-based build would have shared a table engine with the reference implementation
while looking nothing alike. The real cost of a UI port sits in the component library, not
the grid.

### P15. Internationalisation

Unchanged in approach: one row per language holding the label map, one read per session,
preference stored on the user profile.

## User provisioning

Self-service registration is disabled, matching the reference implementation. Accounts are
created by an administrator through a server route, which writes directly to the account and
profile tables inside one transaction.

The Firebase implementation is constrained here: its Auth user list is readable only through
the Admin SDK, so a user-management screen needs a privileged backend. That constraint
disappears entirely when the identity store is a table in the same database. The
user-management screen can list, search and join accounts to profiles with ordinary SQL, and
the profile-claiming indirection exists only because the reference stack could not do this.

First sign-in claims a pending profile by matching email, and deactivated users are refused at
sign-in.

**Table namespacing.** The authentication tables are named `auth_user`, `auth_session`,
`auth_account` and `auth_verification`. This is not cosmetic: `data-model.json` defines an
Account object, so an auth library defaulting to a table called `account` targets the customer
accounts table. Left unnamespaced, schema generation emits
`alter table "account" add column "password"` against live CRM data. Renaming also sidesteps
`user`, which is a reserved word in SQL.

**Bootstrap is privileged.** An empty instance cannot create its first user through the
ordinary path, because every insert policy asks what the caller may do and there is no caller
yet. Rather than carve a permanent hole in the policies for a state that occurs once in an
instance's lifetime, the bootstrap runs on a separate owner connection, which is exempt from
row level security. Nothing else uses that connection.

**Session resolution runs ahead of identity.** Resolving a profile from an authentication id,
and asking whether the instance is empty, both happen before any identity exists, so ordinary
queries would be filtered to nothing by the very policies they are establishing identity for.
Both go through narrow `security definer` functions. The second matters for more than
convenience: an unauthenticated caller sees no profiles under RLS, so a plain count reports
every instance as empty and offers the bootstrap path to anyone who asks.

## Instance deployment

One Postgres database and one Node process per instance, as section 26 requires of any
implementation. Instances share no data. All per-instance values are environment variables; no
instance identifier appears in source. An instance is a connection string and a port, so
running several side by side on one machine is routine rather than an act of provisioning.

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
8. **No vendor and no platform SDK.** The stack is a Postgres server and a Node process. The
   whole system runs on a laptop with no account, no cloud project and no network dependency,
   which is the strongest available evidence that the specification, not a platform, is the
   product.
9. **Realtime carries ids, not rows.** Clients re-read through the authorised path, so the
   push channel cannot become a hole in the authorization model.
10. **Line item ordering lives in `item_number`.** The pre-reconciliation specification
    carried a separate `sort_order`; the reference implementation never had it and instead
    auto-numbers items 10, 20, 30 in SAP style, which the merged model keeps. One field
    fewer, and the ordering survives an export to SAP unchanged.
11. **Auto-numbers have gaps.** Sequences do not roll back, so a failed insert consumes a
    number. The reference implementation derives the next number by counting, which produces
    contiguous values but races under concurrency. Uniqueness and gaps were preferred to
    contiguity and a race.

Items 1, 2 and 5 are improvements the reference implementation could adopt. That is a useful
result: the second implementation is not only a proof of portability but a source of feedback
on the first.
