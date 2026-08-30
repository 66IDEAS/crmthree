-- Step 6. Pessimistic record locking (story 61, P9).
--
-- Infrastructure rather than domain data, like the auth tables, so it is not part of
-- specs/data-model.json and is defined here by hand. A surrogate id exists only so the
-- generic app.notify_change trigger, which publishes row ids, works unchanged; the real
-- identity is (object_type, record_id).

create table record_lock (
  id uuid primary key default gen_random_uuid(),
  object_type text not null,
  record_id uuid not null,
  locked_by uuid not null references user_profile(id) on delete cascade,
  locked_by_name text not null,
  locked_at timestamptz not null default now(),
  expires_at timestamptz not null,
  unique (object_type, record_id)
);

alter table record_lock enable row level security;

-- Everyone signed in may see locks: the whole point is showing other users the indicator.
create policy record_lock_select on record_lock for select
  using (app.current_profile_id() is not null);
-- A user manages only their own locks, with one exception: anyone may delete an expired
-- lock, which is how a stale lock left by a crashed session is taken over.
create policy record_lock_insert on record_lock for insert
  with check (locked_by = app.current_profile_id());
create policy record_lock_update on record_lock for update
  using (locked_by = app.current_profile_id());
create policy record_lock_delete on record_lock for delete
  using (locked_by = app.current_profile_id() or expires_at < now());

grant select, insert, update, delete on record_lock to crm_app;

-- Live lock indication: viewers of the same record see a lock appear and disappear without
-- polling. Payload carries ids only, like every other channel.
create trigger record_lock_notify
  after insert or update or delete on record_lock
  for each row execute function app.notify_change();
