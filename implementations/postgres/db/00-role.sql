-- Step 1. The application database role. Run before the schema.
-- The Node server connects as crm_app; migrations run as the owner. Row level security
-- exempts table owners, which is why the application must never connect as the owner.
do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'crm_app') then
    create role crm_app login;
  end if;
end $$;
