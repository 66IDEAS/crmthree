-- Step 7. Server-side notification triggers (story 17, P8, divergence 2).
--
-- The reference implementation compares field values in the browser after a save and writes
-- the notification from the client, so notifications only happen for users of the web UI.
-- Here the comparison is a trigger, so every writer produces them: the UI, the REST API,
-- an import, replication.
--
-- SECURITY DEFINER, because the writer usually has no create permission on Notification and
-- should not need one; being notified is a side effect of someone else's action, not a
-- privilege of the actor. The actor is new.updated_by, which every write already carries.

create or replace function app.emit_notification(
  target uuid, actor uuid, kind notification_type, title text, message text,
  link_type text, link_id uuid
) returns void
  language plpgsql security definer set search_path = public as $$
declare
  prefs jsonb;
begin
  -- No target, or acting on your own record: nothing to say.
  if target is null or target = actor then return; end if;
  -- Respect the target's preferences; unset means enabled.
  select notification_preferences into prefs from user_profile where id = target;
  if prefs is not null and coalesce((prefs ->> kind::text)::boolean, true) = false then
    return;
  end if;
  insert into notification
    (created_at, updated_at, created_by, updated_by, user_id, type, title, message, link_type, link_id)
  values (now(), now(), actor, actor, target, kind, title, message, link_type, link_id);
exception when others then
  -- A notification must never block the save that caused it.
  null;
end;
$$;

create or replace function app.notify_ticket_assigned() returns trigger
  language plpgsql security definer set search_path = public as $$
begin
  -- On insert there is no old row; plpgsql raises if it is touched.
  if (tg_op = 'INSERT' and new.assigned_to is not null)
     or (tg_op = 'UPDATE' and new.assigned_to is distinct from old.assigned_to) then
    perform app.emit_notification(
      new.assigned_to, new.updated_by, 'TicketAssigned',
      'A ticket was assigned to you', new.subject, 'Ticket', new.id);
  end if;
  return new;
end;
$$;

create or replace function app.notify_deal_stage() returns trigger
  language plpgsql security definer set search_path = public as $$
begin
  if new.stage_id is distinct from old.stage_id then
    perform app.emit_notification(
      new.owner_id, new.updated_by, 'DealStageChange',
      'Deal stage changed', new.name, 'Opportunity', new.id);
  end if;
  return new;
end;
$$;

create or replace function app.notify_lead_assigned() returns trigger
  language plpgsql security definer set search_path = public as $$
begin
  if (tg_op = 'INSERT' and new.owner_id is not null)
     or (tg_op = 'UPDATE' and new.owner_id is distinct from old.owner_id) then
    perform app.emit_notification(
      new.owner_id, new.updated_by, 'LeadAssigned',
      'A lead was assigned to you', trim(new.first_name || ' ' || new.last_name), 'Lead', new.id);
  end if;
  return new;
end;
$$;

-- Assignment on creation notifies too; the reference implementation misses that case.
create trigger ticket_assigned_notify after insert or update on ticket
  for each row execute function app.notify_ticket_assigned();
create trigger deal_stage_notify after update on opportunity
  for each row execute function app.notify_deal_stage();
create trigger lead_assigned_notify after insert or update on lead
  for each row execute function app.notify_lead_assigned();
