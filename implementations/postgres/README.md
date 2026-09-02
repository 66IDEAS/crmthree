# CRMTHREE - Postgres implementation

The second implementation of the CRMTHREE specification, and the architecture proof: the
same spec as the Firebase reference, on a stack that shares nothing with it.

| Layer | Choice |
|---|---|
| Frontend | Svelte 5 (runes) + SvelteKit, TypeScript, Tailwind |
| Backend | SvelteKit server routes on Node - no separate functions runtime |
| Database | PostgreSQL, any instance, local by default |
| Authentication | Better Auth, sessions in Postgres, cookie-based |
| Real-time | Postgres `listen`/`notify` bridged to server-sent events |
| Authorization | Row Level Security, generated from the model, enforced in the database |
| Storage | Filesystem behind an authorising route |

**No vendor anywhere.** A Postgres server and a Node process are the whole system. It runs
on a laptop with no cloud account, and deploys unchanged to any host that offers Node and
Postgres - a VM, a container, or a managed Postgres with a Node platform. Design and divergences from the reference:
[`specs/postgres.architecture.md`](../../specs/postgres.architecture.md).

## Run it

Prerequisites: Node 20+, PostgreSQL 15+ running locally, `psql` on the path.

```bash
# 1. Database: role, schema, policies, auth tables, triggers - all generated from the spec
createdb crmthree_local
cd db && ./apply.sh crmthree_local && cd ..

# 2. App configuration
cd app
cp .env.example .env          # fill BETTER_AUTH_SECRET and AI_KEY_ENCRYPTION_KEY
                              # (both: openssl rand -base64 32)
npm install

# 3. Go
npm run dev                   # http://localhost:5173
```

The first account created on the empty instance becomes the Admin (`POST /api/users`, or
just sign in - the login page explains). Every later user is provisioned by an admin in
Settings.

Two generators keep the database honest: `db/generate-ddl.mjs` and
`db/generate-policies.mjs` both read `specs/data-model.json`, so a model change becomes a
schema and policy change by regeneration, never by hand-editing.

## What to look at

- **Authorization lives in the database.** One policy set covers the UI, the REST API
  (`/api/v1/...`), search, exports and AI context. Revoke a permission in Settings and
  every surface narrows at once.
- **Real-time without a broker.** Notifications, comment threads and record locks update
  live across sessions; the push channel carries ids only, so it cannot leak a row the
  reader's policies would refuse.
- **The write is the event.** Audit history, XP awards, notifications and streaks are
  database triggers - the REST API and imports produce them exactly like the UI.
- **SAP-shaped integration.** The data source router serves any object type live from an
  external system, and replication upserts external feeds by key field in one transaction.
