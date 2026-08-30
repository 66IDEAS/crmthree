-- Step 3. Table privileges for the application role. Run after schema.sql and before
-- policies.sql, because policies.sql narrows ai_provider_config afterwards and a blanket
-- grant applied later would silently undo that.
grant usage on schema public to crm_app;
grant select, insert, update, delete on all tables in schema public to crm_app;
grant usage, select on all sequences in schema public to crm_app;
