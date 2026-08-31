-- Step 10. Gamification engine (stories 38-39, 43, 55) in the database.
--
-- The reference implementation awards XP from the browser after saves; here the award is a
-- side effect of the write itself, so the REST API and imports count too. XP values come
-- from the xp_event configuration table, levels from level_definition, and every function
-- is SECURITY DEFINER: being rewarded is not a privilege of the actor.

create or replace function app.award_xp(actor uuid, event text) returns void
  language plpgsql security definer set search_path = public as $$
declare
  points integer;
  new_total integer;
  old_level integer;
  new_level record;
begin
  if actor is null then return; end if;
  select xp_value into points from xp_event where event_type = event and active limit 1;
  if points is null or points = 0 then return; end if;

  update user_profile set xp_total = xp_total + points where id = actor
    returning xp_total, level into new_total, old_level;
  if new_total is null then return; end if;

  select level, name into new_level from level_definition
   where xp_threshold <= new_total order by level desc limit 1;
  if new_level.level is not null and new_level.level <> old_level then
    update user_profile set level = new_level.level, level_name = new_level.name where id = actor;
    perform app.emit_notification(actor, null, 'LevelUp',
      'Level up!', format('You reached level %s: %s', new_level.level, new_level.name), null, null);
  end if;

  -- Daily streak: consecutive days with any rewarded action.
  insert into streak (created_at, updated_at, created_by, updated_by, user_id, activity_type,
                      current_count, longest_count, last_activity_date)
  values (now(), now(), actor, actor, actor, 'daily', 1, 1, current_date)
  on conflict (user_id, activity_type) do update set
    current_count = case
      when streak.last_activity_date = current_date then streak.current_count
      when streak.last_activity_date = current_date - 1 then streak.current_count + 1
      else 1 end,
    longest_count = greatest(streak.longest_count, case
      when streak.last_activity_date = current_date - 1 then streak.current_count + 1
      else 1 end),
    last_activity_date = current_date,
    updated_at = now();
  update user_profile p set
    current_streak_days = s.current_count,
    longest_streak_days = greatest(p.longest_streak_days, s.longest_count)
  from streak s where s.user_id = actor and s.activity_type = 'daily' and p.id = actor;
exception when others then
  null;  -- a reward must never block the write that earned it
end;
$$;

-- The streak upsert needs a natural key.
create unique index if not exists streak_user_activity_key on streak (user_id, activity_type);

create or replace function app.gamify() returns trigger
  language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    perform app.award_xp(new.created_by, tg_argv[0]);
  end if;
  return new;
end;
$$;

create trigger account_xp after insert on account for each row execute function app.gamify('create_account');
create trigger contact_xp after insert on contact for each row execute function app.gamify('create_contact');
create trigger lead_xp after insert on lead for each row execute function app.gamify('create_lead');
create trigger opportunity_xp after insert on opportunity for each row execute function app.gamify('create_opportunity');
create trigger quotation_xp after insert on quotation for each row execute function app.gamify('create_quotation');
create trigger activity_xp after insert on activity for each row execute function app.gamify('log_activity');
create trigger knowledge_article_xp after insert on knowledge_article for each row execute function app.gamify('create_knowledge_article');

-- Milestones live on updates and carry their own rules.
create or replace function app.gamify_milestones() returns trigger
  language plpgsql security definer set search_path = public as $$
declare
  best numeric;
begin
  if tg_table_name = 'opportunity' and new.result = 'Won' and old.result is distinct from 'Won' then
    perform app.award_xp(new.updated_by, 'close_deal_won');
    -- Personal best on the largest won deal (story 55).
    if new.amount is not null then
      select value into best from personal_best
       where user_id = new.updated_by and metric = 'largest_deal' limit 1;
      if best is null then
        insert into personal_best (created_at, updated_at, created_by, updated_by,
                                   user_id, metric, value, achieved_at)
        values (now(), now(), new.updated_by, new.updated_by, new.updated_by, 'largest_deal', new.amount, now());
      elsif new.amount > best then
        update personal_best set previous_value = value, previous_achieved_at = achieved_at,
               value = new.amount, achieved_at = now(), updated_at = now()
         where user_id = new.updated_by and metric = 'largest_deal';
        perform app.emit_notification(new.updated_by, null, 'PersonalBest',
          'New personal best!', format('Largest won deal: %s', new.amount), 'Opportunity', new.id);
      end if;
    end if;
  elsif tg_table_name = 'ticket' and new.resolved_at is not null and old.resolved_at is null then
    perform app.award_xp(new.updated_by, 'resolve_ticket');
  elsif tg_table_name = 'lead' and new.status = 'Converted' and old.status is distinct from 'Converted' then
    perform app.award_xp(new.updated_by, 'convert_lead');
  end if;
  return new;
exception when others then
  return new;
end;
$$;

create trigger opportunity_milestone_xp after update on opportunity for each row execute function app.gamify_milestones();
create trigger ticket_milestone_xp after update on ticket for each row execute function app.gamify_milestones();
create trigger lead_milestone_xp after update on lead for each row execute function app.gamify_milestones();

-- One's own audit rows are one's activity timeline (story 35); full reads stay admin-only.
drop policy if exists audit_log_select_own on audit_log;
create policy audit_log_select_own on audit_log for select
  using (user_id = app.current_profile_id());
