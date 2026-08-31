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

-- Seed registry (shared architecture, section 13): which bundled language codes have ever
-- been seeded into this instance. Written only over the owner connection at server start;
-- the application role has no access at all, so registration is permanent from the app's
-- point of view and a deleted language stays deleted.
create table if not exists translation_seed (
  code text primary key,
  seeded_at timestamptz not null default now()
);
alter table translation_seed enable row level security;
