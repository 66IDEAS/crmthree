-- Step 9. Audit trail as a database concern.
--
-- The reference implementation writes audit entries from the browser after saves, so only
-- the web UI produces history. Here one generic trigger audits every writer - UI, REST
-- API, imports - by diffing old and new rows in the database itself. SECURITY DEFINER:
-- recording history is not a privilege of the actor.

create or replace function app.audit_change() returns trigger
  language plpgsql security definer set search_path = public as $$
declare
  affected record;
  actor uuid;
  changed text[];
  label text;
begin
  affected := case when tg_op = 'DELETE' then old else new end;
  actor := case when tg_op = 'DELETE' then old.updated_by else new.updated_by end;

  if tg_op = 'UPDATE' then
    select array_agg(n.key) into changed
      from jsonb_each(to_jsonb(new)) n join jsonb_each(to_jsonb(old)) o on o.key = n.key
     where n.value is distinct from o.value
       and n.key not in ('updated_at', 'updated_by',
                         -- gamification counters churn constantly and are not history
                         'xp_total', 'level', 'level_name', 'current_streak_days', 'longest_streak_days');
    if changed is null then return new; end if;   -- heartbeat writes leave no history
  end if;

  -- Display-name resolution order, database edition.
  label := coalesce(
    to_jsonb(affected) ->> 'name', to_jsonb(affected) ->> 'name1',
    trim(concat(to_jsonb(affected) ->> 'first_name', ' ', to_jsonb(affected) ->> 'last_name')),
    to_jsonb(affected) ->> 'subject', to_jsonb(affected) ->> 'title');
  if label = '' then label := null; end if;

  insert into audit_log
    (created_at, updated_at, created_by, updated_by, object_type, object_id, action,
     field_name, user_id, "timestamp", object_name, summary)
  values
    (now(), now(), actor, actor, initcap(replace(tg_table_name, '_', ' ')), affected.id,
     (case tg_op when 'INSERT' then 'Create' when 'UPDATE' then 'Update' else 'Delete' end)::audit_log_action,
     case when changed is not null then array_to_string(changed, ', ') end,
     actor, now(), label,
     case tg_op
       when 'INSERT' then 'created'
       when 'DELETE' then 'deleted'
       else 'changed ' || array_to_string(changed, ', ')
     end);
  return affected;
exception when others then
  return affected;   -- history must never block the write it records
end;
$$;

-- Business tables only: infrastructure (locks, whitelist, auth) and the log itself are
-- excluded, as are notifications, which are already an event stream.
do $audit$
declare tab text;
begin
  for tab in select unnest(array[
    'account','contact','contact_account','lead','opportunity','opportunity_contact',
    'deal_room','quotation','sales_order','invoice','line_item','product',
    'pricebook_entry','activity','ticket','sla','knowledge_article',
    'ticket_knowledge_article','service_contract','asset','document','comment',
    'user_profile','role','team','pipeline_stage','ticket_status'])
  loop
    execute format('drop trigger if exists %I on %I', tab || '_audit', tab);
    execute format('create trigger %I after insert or update or delete on %I
                    for each row execute function app.audit_change()', tab || '_audit', tab);
  end loop;
end $audit$;
