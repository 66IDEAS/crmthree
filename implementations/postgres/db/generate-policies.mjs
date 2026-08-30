#!/usr/bin/env node
/**
 * Generates Row Level Security policies from specs/data-model.json.
 *
 * Implements P7 of specs/postgres.architecture.md. Authorization lives in the database, so
 * the same rules cover the UI, the REST API and realtime subscriptions.
 *
 * The policies are driven by Role.permissions, the same JSON the UI reads, so there is one
 * definition of who may do what rather than a client copy and a server copy.
 *
 * Usage: node db/generate-policies.mjs > db/policies.sql
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const model = JSON.parse(readFileSync(resolve(here, '../../../specs/data-model.json'), 'utf8'));

const tableName = (name) =>
	name
		.replace(/([a-z0-9])([A-Z])/g, '$1_$2')
		.replace(/([A-Z]+)([A-Z][a-z])/g, '$1_$2')
		.toLowerCase();

const out = [];
const p = (s = '') => out.push(s);

p('-- Generated from specs/data-model.json by db/generate-policies.mjs. Do not edit by hand.');
p('-- Apply after schema.sql.');
p();
p('create schema if not exists app;');
p();
p('-- Identity arrives as a transaction-scoped session setting written by the server route:');
p("--   set_config('app.user_id', <profile id>, true)");
p('-- Being transaction-scoped, it cannot leak between pooled connections.');
p('--');
p('-- The lookups are SECURITY DEFINER so that reading the caller\'s own profile does not');
p('-- re-enter the policy on user_profile, which would recurse infinitely.');
p(`
create or replace function app.current_profile_id() returns uuid
  language sql stable as $$
  select nullif(current_setting('app.user_id', true), '')::uuid;
$$;

create or replace function app.current_permissions() returns jsonb
  language sql stable security definer set search_path = public as $$
  select r.permissions
  from user_profile u join role r on r.id = u.role_id
  where u.id = app.current_profile_id() and u.active
  limit 1;
$$;

create or replace function app.is_admin() returns boolean
  language sql stable security definer set search_path = public as $$
  select coalesce((
    select r.name = 'Admin'
    from user_profile u join role r on r.id = u.role_id
    where u.id = app.current_profile_id() and u.active
    limit 1), false);
$$;

-- Resolves a profile from an authentication id. SECURITY DEFINER because it runs before any
-- identity is established: the session lookup needs the profile in order to set the identity
-- that every other policy depends on. Deliberately narrow, returning one row for one uid, so
-- it cannot be used to enumerate profiles.
create or replace function app.profile_for_auth_uid(uid text) returns table (
  id uuid, email text, first_name text, last_name text, active boolean, role_name text
) language sql stable security definer set search_path = public as $$
  select p.id, p.email::text, p.first_name::text, p.last_name::text, p.active, r.name::text
  from user_profile p join role r on r.id = p.role_id
  where p.auth_uid = uid and p.active
  limit 1;
$$;

-- True when the instance has no profiles at all. SECURITY DEFINER for the same reason: an
-- unauthenticated caller sees no rows under RLS, so an ordinary count would report every
-- instance as empty and hand the bootstrap path to anyone who asked.
create or replace function app.is_unprovisioned() returns boolean
  language sql stable security definer set search_path = public as $$
  select not exists (select 1 from user_profile);
$$;

-- Reads Role.permissions, shaped { "Object": { "create": bool, "read": bool,
-- "read_all": bool, "update": bool, "delete": bool } }. Admins always pass.
create or replace function app.can(object_name text, action text) returns boolean
  language sql stable as $$
  select app.is_admin() or coalesce((app.current_permissions() -> object_name ->> action)::boolean, false);
$$;
`);

p('-- The application role reaches the helpers through the app schema.');
p('grant usage on schema app to crm_app;');
p('grant execute on all functions in schema app to crm_app;');
p();

const OWNED = new Set(
	Object.entries(model.objects)
		.filter(([, o]) => o.fields.some((f) => f.name === 'owner_id'))
		.map(([n]) => n)
);

// Tables needing something other than the generic role-driven treatment.
const SPECIAL = new Set(['AIProviderConfig', 'AuditLog', 'UserProfile', 'Notification']);

p('-- Generic per-object policies, driven by Role.permissions.');
for (const obj of Object.keys(model.objects)) {
	if (SPECIAL.has(obj)) continue;
	const t = tableName(obj);
	// read_all false means the user sees only records they own, where ownership exists.
	const readScope = OWNED.has(obj)
		? `app.can('${obj}', 'read') and (app.can('${obj}', 'read_all') or owner_id = app.current_profile_id())`
		: `app.can('${obj}', 'read')`;
	p(`create policy ${t}_select on ${t} for select using (${readScope});`);
	p(`create policy ${t}_insert on ${t} for insert with check (app.can('${obj}', 'create'));`);
	p(`create policy ${t}_update on ${t} for update using (app.can('${obj}', 'update'));`);
	p(`create policy ${t}_delete on ${t} for delete using (app.can('${obj}', 'delete'));`);
	p();
}

p(`-- UserProfile: every signed-in user may read profiles, because owner and assignee names
-- are shown throughout the UI. Users may update their own profile; only admins may create,
-- delete, or edit someone else's.
create policy user_profile_select on user_profile for select using (app.current_profile_id() is not null);
create policy user_profile_insert on user_profile for insert with check (app.is_admin());
create policy user_profile_update on user_profile for update
  using (app.is_admin() or id = app.current_profile_id());
create policy user_profile_delete on user_profile for delete using (app.is_admin());

-- Notifications are personal. You read, mark and delete your own, whatever your role says
-- about the Notification object; creation happens in SECURITY DEFINER triggers, so no
-- client insert policy exists at all.
create policy notification_select on notification for select
  using (user_id = app.current_profile_id());
create policy notification_update on notification for update
  using (user_id = app.current_profile_id());
create policy notification_delete on notification for delete
  using (user_id = app.current_profile_id());

-- AuditLog is append-only. Anyone may write an entry, only admins may read the trail, and
-- nobody may alter or remove one.
create policy audit_log_insert on audit_log for insert with check (app.current_profile_id() is not null);
create policy audit_log_select on audit_log for select using (app.is_admin());

-- AIProviderConfig holds provider credentials. No non-admin may read the row at all, and the
-- api_key column privilege is withdrawn as well, so that even a future permissive policy
-- cannot leak it to the application role.
create policy ai_provider_config_all on ai_provider_config for all
  using (app.is_admin()) with check (app.is_admin());
`);

// Column privileges for the provider key.
//
// A column-level REVOKE is a no-op while the role still holds table-level SELECT, which
// a blanket table grant would confer: table-level privilege covers every column.
// So the table grant is withdrawn and rebuilt column by column, omitting api_key from
// SELECT while keeping it in INSERT and UPDATE. The key can be written by an admin and
// never read back by any client. Server routes read it with the service role, which
// bypasses both RLS and these grants.
const aiCols = [...model.common_fields, ...model.objects.AIProviderConfig.fields].map((f) => f.name);
const readable = aiCols.filter((c) => c !== 'api_key');
p('-- Provider key is write-only for clients. See the comment in generate-policies.mjs.');
p('revoke all on ai_provider_config from crm_app;');
p(`grant select (${readable.join(', ')}) on ai_provider_config to crm_app;`);
p(`grant insert (${aiCols.join(', ')}) on ai_provider_config to crm_app;`);
p(`grant update (${aiCols.join(', ')}) on ai_provider_config to crm_app;`);
p('grant delete on ai_provider_config to crm_app;');

console.log(out.join('\n'));
