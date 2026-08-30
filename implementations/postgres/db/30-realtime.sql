-- Step 5. Change notification (R4, P8).
--
-- Postgres already ships the mechanism, so no broker and no realtime service is needed. A
-- trigger calls pg_notify on a channel named for the table; the Node server holds one
-- dedicated LISTEN connection and fans events out to browsers over server-sent events.
--
-- The payload carries only an id and the operation, never row data. Clients re-read through
-- the normal authorised path, so the push channel cannot become a hole in the authorization
-- model: a listener learns that something changed, not what it says.

create or replace function app.notify_change() returns trigger
  language plpgsql as $$
declare
  payload text;
  affected record;
begin
  affected := case when tg_op = 'DELETE' then old else new end;
  payload := json_build_object(
    'table', tg_table_name,
    'op', lower(tg_op),
    'id', affected.id
  )::text;
  -- pg_notify caps payloads at 8000 bytes. Ids only, so the cap is unreachable.
  perform pg_notify('crm_change', payload);
  return affected;
end;
$$;

-- Watched tables. Driven by the stories that need live updates: notifications (17), and the
-- comment threads behind deal and case rooms (33, 34). Add a table here when a story needs
-- it, rather than notifying on everything and filtering later.
create trigger notification_notify
  after insert or update or delete on notification
  for each row execute function app.notify_change();

create trigger comment_notify
  after insert or update or delete on comment
  for each row execute function app.notify_change();
