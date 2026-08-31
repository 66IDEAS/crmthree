-- Step 11. Translations (story 60). One row per language holding the full label map, one
-- read per session - the reference implementation's storage design, as a table.
create table if not exists translation (
  code text primary key,
  language_name text not null,
  labels jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references user_profile(id) on delete set null
);
alter table translation enable row level security;
drop policy if exists translation_select on translation;
create policy translation_select on translation for select
  using (app.current_profile_id() is not null);
drop policy if exists translation_write on translation;
create policy translation_write on translation for all
  using (app.is_admin()) with check (app.is_admin());
grant select, insert, update, delete on translation to crm_app;
