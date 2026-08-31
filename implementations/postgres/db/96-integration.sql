-- Step 13. Replication run configuration (story 59). Infrastructure, like the auth tables:
-- the reference kept these outside its model too. data_source_config (story 30) is a model
-- object and already exists.
create table if not exists replication_config (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  object_type text not null,
  url text not null,
  request_body jsonb,
  key_field text not null,
  source_key_field text not null,
  delete_field text,
  field_mapping jsonb not null default '{}'::jsonb,
  defaults jsonb not null default '{}'::jsonb,
  last_run_at timestamptz,
  last_result text,
  created_at timestamptz not null default now(),
  created_by uuid references user_profile(id) on delete set null
);
alter table replication_config enable row level security;
drop policy if exists replication_config_all on replication_config;
create policy replication_config_all on replication_config for all
  using (app.is_admin()) with check (app.is_admin());
grant select, insert, update, delete on replication_config to crm_app;
