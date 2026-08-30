-- Step 8. Email/domain whitelist (story 18b). Infrastructure like the auth tables, so not
-- part of data-model.json.

create table email_whitelist (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('email', 'domain')),
  value text not null unique,
  created_at timestamptz not null default now(),
  created_by uuid not null references user_profile(id) on delete cascade
);

alter table email_whitelist enable row level security;
create policy email_whitelist_all on email_whitelist for all
  using (app.is_admin()) with check (app.is_admin());
grant select, insert, delete on email_whitelist to crm_app;

-- Sign-in enforcement runs before any identity exists, so it cannot read the table through
-- RLS; SECURITY DEFINER, and deliberately answering only yes or no. An empty whitelist
-- allows everyone, per the specification.
create or replace function app.email_allowed(candidate text) returns boolean
  language sql stable security definer set search_path = public as $$
  select case
    when not exists (select 1 from email_whitelist) then true
    else exists (
      select 1 from email_whitelist w
       where (w.kind = 'email' and lower(w.value) = lower(candidate))
          or (w.kind = 'domain' and lower(candidate) like '%@' || lower(w.value))
    )
  end;
$$;
grant execute on function app.email_allowed(text) to crm_app;
