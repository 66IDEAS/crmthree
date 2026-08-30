# Database

No vendor, no managed service. A Postgres server and this SQL are the entire backend.

`schema.sql` and `policies.sql` are generated. Do not edit them by hand.

```bash
node db/generate-ddl.mjs      > db/schema.sql
node db/generate-policies.mjs > db/policies.sql
createdb crmthree_local && ./db/apply.sh crmthree_local
```

Both generators read `specs/data-model.json`, the single source of truth for all 38 objects.

## Apply order matters

`apply.sh` runs the files in a fixed order, and the order is load-bearing:

1. `00-role.sql` creates `crm_app`, the role the application connects as.
2. `schema.sql` creates tables, enums, sequences and foreign keys.
3. `10-grants.sql` gives `crm_app` table privileges.
4. `policies.sql` creates the `app` helper schema and the policies, then narrows
   `ai_provider_config`.

Step 4 must follow step 3. A blanket table grant applied afterwards would silently re-grant
`select` on the provider key column and undo the restriction, because a table-level privilege
covers every column.

## Identity

Row level security reads a transaction-scoped session setting rather than any platform
function. Server routes open a transaction and call
`set_config('app.user_id', '<profile id>', true)` before touching data. Verified: after the
transaction commits, the identity is gone and the same connection sees nothing, so nothing
leaks between pooled connections.

The application must never connect as the database owner, because owners are exempt from RLS.

## Bootstrap

Foreign keys are `deferrable initially deferred` because the object graph is cyclic: every row
carries `created_by` referencing UserProfile, and `UserProfile.role_id` references Role, whose
own `created_by` points back at UserProfile. The first user and the default roles are therefore
seeded inside one transaction. Deferral only spans an explicit transaction, so a seed script
that relies on autocommit will fail.

## Verified against Postgres 15

38 tables, 30 enum types, 13 auto-number sequences, 148 deferrable foreign keys, 147 policies.
A Sales role with `read_all: false` sees only its own records, an admin sees all, a session
with no identity sees none, and the provider key column is unreadable by `crm_app` while
remaining writable.
