-- Generated from specs/data-model.json by db/generate-policies.mjs. Do not edit by hand.
-- Apply after schema.sql.

create schema if not exists app;

-- Identity arrives as a transaction-scoped session setting written by the server route:
--   set_config('app.user_id', <profile id>, true)
-- Being transaction-scoped, it cannot leak between pooled connections.
--
-- The lookups are SECURITY DEFINER so that reading the caller's own profile does not
-- re-enter the policy on user_profile, which would recurse infinitely.

create or replace function app.current_profile_id() returns uuid
  language sql stable as $$
  select nullif(current_setting('app.user_id', true), '')::uuid;
$$;

create or replace function app.current_permissions() returns jsonb
  language sql stable security definer set search_path = public as $$
  select r.permissions
  from user_profile u join role r on r.id = u.role_id
  where u.id = app.current_profile_id() and u.active
  limit 1;
$$;

create or replace function app.is_admin() returns boolean
  language sql stable security definer set search_path = public as $$
  select coalesce((
    select r.name = 'Admin'
    from user_profile u join role r on r.id = u.role_id
    where u.id = app.current_profile_id() and u.active
    limit 1), false);
$$;

-- Resolves a profile from an authentication id. SECURITY DEFINER because it runs before any
-- identity is established: the session lookup needs the profile in order to set the identity
-- that every other policy depends on. Deliberately narrow, returning one row for one uid, so
-- it cannot be used to enumerate profiles.
create or replace function app.profile_for_auth_uid(uid text) returns table (
  id uuid, email text, first_name text, last_name text, active boolean, role_name text
) language sql stable security definer set search_path = public as $$
  select p.id, p.email::text, p.first_name::text, p.last_name::text, p.active, r.name::text
  from user_profile p join role r on r.id = p.role_id
  where p.auth_uid = uid and p.active
  limit 1;
$$;

-- True when the instance has no profiles at all. SECURITY DEFINER for the same reason: an
-- unauthenticated caller sees no rows under RLS, so an ordinary count would report every
-- instance as empty and hand the bootstrap path to anyone who asked.
create or replace function app.is_unprovisioned() returns boolean
  language sql stable security definer set search_path = public as $$
  select not exists (select 1 from user_profile);
$$;

-- Reads Role.permissions, shaped { "Object": { "create": bool, "read": bool,
-- "read_all": bool, "update": bool, "delete": bool } }. Admins always pass.
create or replace function app.can(object_name text, action text) returns boolean
  language sql stable as $$
  select app.is_admin() or coalesce((app.current_permissions() -> object_name ->> action)::boolean, false);
$$;

-- The application role reaches the helpers through the app schema.
grant usage on schema app to crm_app;
grant execute on all functions in schema app to crm_app;

-- Generic per-object policies, driven by Role.permissions.
create policy account_select on account for select using (app.can('Account', 'read') and (app.can('Account', 'read_all') or owner_id = app.current_profile_id()));
create policy account_insert on account for insert with check (app.can('Account', 'create'));
create policy account_update on account for update using (app.can('Account', 'update'));
create policy account_delete on account for delete using (app.can('Account', 'delete'));

create policy contact_select on contact for select using (app.can('Contact', 'read') and (app.can('Contact', 'read_all') or owner_id = app.current_profile_id()));
create policy contact_insert on contact for insert with check (app.can('Contact', 'create'));
create policy contact_update on contact for update using (app.can('Contact', 'update'));
create policy contact_delete on contact for delete using (app.can('Contact', 'delete'));

create policy contact_account_select on contact_account for select using (app.can('ContactAccount', 'read'));
create policy contact_account_insert on contact_account for insert with check (app.can('ContactAccount', 'create'));
create policy contact_account_update on contact_account for update using (app.can('ContactAccount', 'update'));
create policy contact_account_delete on contact_account for delete using (app.can('ContactAccount', 'delete'));

create policy lead_select on lead for select using (app.can('Lead', 'read') and (app.can('Lead', 'read_all') or owner_id = app.current_profile_id()));
create policy lead_insert on lead for insert with check (app.can('Lead', 'create'));
create policy lead_update on lead for update using (app.can('Lead', 'update'));
create policy lead_delete on lead for delete using (app.can('Lead', 'delete'));

create policy opportunity_select on opportunity for select using (app.can('Opportunity', 'read') and (app.can('Opportunity', 'read_all') or owner_id = app.current_profile_id()));
create policy opportunity_insert on opportunity for insert with check (app.can('Opportunity', 'create'));
create policy opportunity_update on opportunity for update using (app.can('Opportunity', 'update'));
create policy opportunity_delete on opportunity for delete using (app.can('Opportunity', 'delete'));

create policy opportunity_contact_select on opportunity_contact for select using (app.can('OpportunityContact', 'read'));
create policy opportunity_contact_insert on opportunity_contact for insert with check (app.can('OpportunityContact', 'create'));
create policy opportunity_contact_update on opportunity_contact for update using (app.can('OpportunityContact', 'update'));
create policy opportunity_contact_delete on opportunity_contact for delete using (app.can('OpportunityContact', 'delete'));

create policy deal_room_select on deal_room for select using (app.can('DealRoom', 'read') and (app.can('DealRoom', 'read_all') or owner_id = app.current_profile_id()));
create policy deal_room_insert on deal_room for insert with check (app.can('DealRoom', 'create'));
create policy deal_room_update on deal_room for update using (app.can('DealRoom', 'update'));
create policy deal_room_delete on deal_room for delete using (app.can('DealRoom', 'delete'));

create policy pipeline_stage_select on pipeline_stage for select using (app.can('PipelineStage', 'read'));
create policy pipeline_stage_insert on pipeline_stage for insert with check (app.can('PipelineStage', 'create'));
create policy pipeline_stage_update on pipeline_stage for update using (app.can('PipelineStage', 'update'));
create policy pipeline_stage_delete on pipeline_stage for delete using (app.can('PipelineStage', 'delete'));

create policy quotation_select on quotation for select using (app.can('Quotation', 'read') and (app.can('Quotation', 'read_all') or owner_id = app.current_profile_id()));
create policy quotation_insert on quotation for insert with check (app.can('Quotation', 'create'));
create policy quotation_update on quotation for update using (app.can('Quotation', 'update'));
create policy quotation_delete on quotation for delete using (app.can('Quotation', 'delete'));

create policy sales_order_select on sales_order for select using (app.can('SalesOrder', 'read') and (app.can('SalesOrder', 'read_all') or owner_id = app.current_profile_id()));
create policy sales_order_insert on sales_order for insert with check (app.can('SalesOrder', 'create'));
create policy sales_order_update on sales_order for update using (app.can('SalesOrder', 'update'));
create policy sales_order_delete on sales_order for delete using (app.can('SalesOrder', 'delete'));

create policy invoice_select on invoice for select using (app.can('Invoice', 'read') and (app.can('Invoice', 'read_all') or owner_id = app.current_profile_id()));
create policy invoice_insert on invoice for insert with check (app.can('Invoice', 'create'));
create policy invoice_update on invoice for update using (app.can('Invoice', 'update'));
create policy invoice_delete on invoice for delete using (app.can('Invoice', 'delete'));

create policy line_item_select on line_item for select using (app.can('LineItem', 'read'));
create policy line_item_insert on line_item for insert with check (app.can('LineItem', 'create'));
create policy line_item_update on line_item for update using (app.can('LineItem', 'update'));
create policy line_item_delete on line_item for delete using (app.can('LineItem', 'delete'));

create policy pricebook_entry_select on pricebook_entry for select using (app.can('PricebookEntry', 'read'));
create policy pricebook_entry_insert on pricebook_entry for insert with check (app.can('PricebookEntry', 'create'));
create policy pricebook_entry_update on pricebook_entry for update using (app.can('PricebookEntry', 'update'));
create policy pricebook_entry_delete on pricebook_entry for delete using (app.can('PricebookEntry', 'delete'));

create policy product_select on product for select using (app.can('Product', 'read'));
create policy product_insert on product for insert with check (app.can('Product', 'create'));
create policy product_update on product for update using (app.can('Product', 'update'));
create policy product_delete on product for delete using (app.can('Product', 'delete'));

create policy activity_select on activity for select using (app.can('Activity', 'read') and (app.can('Activity', 'read_all') or owner_id = app.current_profile_id()));
create policy activity_insert on activity for insert with check (app.can('Activity', 'create'));
create policy activity_update on activity for update using (app.can('Activity', 'update'));
create policy activity_delete on activity for delete using (app.can('Activity', 'delete'));

create policy ticket_select on ticket for select using (app.can('Ticket', 'read') and (app.can('Ticket', 'read_all') or owner_id = app.current_profile_id()));
create policy ticket_insert on ticket for insert with check (app.can('Ticket', 'create'));
create policy ticket_update on ticket for update using (app.can('Ticket', 'update'));
create policy ticket_delete on ticket for delete using (app.can('Ticket', 'delete'));

create policy ticket_status_select on ticket_status for select using (app.can('TicketStatus', 'read'));
create policy ticket_status_insert on ticket_status for insert with check (app.can('TicketStatus', 'create'));
create policy ticket_status_update on ticket_status for update using (app.can('TicketStatus', 'update'));
create policy ticket_status_delete on ticket_status for delete using (app.can('TicketStatus', 'delete'));

create policy sla_select on sla for select using (app.can('SLA', 'read'));
create policy sla_insert on sla for insert with check (app.can('SLA', 'create'));
create policy sla_update on sla for update using (app.can('SLA', 'update'));
create policy sla_delete on sla for delete using (app.can('SLA', 'delete'));

create policy knowledge_article_select on knowledge_article for select using (app.can('KnowledgeArticle', 'read'));
create policy knowledge_article_insert on knowledge_article for insert with check (app.can('KnowledgeArticle', 'create'));
create policy knowledge_article_update on knowledge_article for update using (app.can('KnowledgeArticle', 'update'));
create policy knowledge_article_delete on knowledge_article for delete using (app.can('KnowledgeArticle', 'delete'));

create policy ticket_knowledge_article_select on ticket_knowledge_article for select using (app.can('TicketKnowledgeArticle', 'read'));
create policy ticket_knowledge_article_insert on ticket_knowledge_article for insert with check (app.can('TicketKnowledgeArticle', 'create'));
create policy ticket_knowledge_article_update on ticket_knowledge_article for update using (app.can('TicketKnowledgeArticle', 'update'));
create policy ticket_knowledge_article_delete on ticket_knowledge_article for delete using (app.can('TicketKnowledgeArticle', 'delete'));

create policy service_contract_select on service_contract for select using (app.can('ServiceContract', 'read') and (app.can('ServiceContract', 'read_all') or owner_id = app.current_profile_id()));
create policy service_contract_insert on service_contract for insert with check (app.can('ServiceContract', 'create'));
create policy service_contract_update on service_contract for update using (app.can('ServiceContract', 'update'));
create policy service_contract_delete on service_contract for delete using (app.can('ServiceContract', 'delete'));

create policy asset_select on asset for select using (app.can('Asset', 'read') and (app.can('Asset', 'read_all') or owner_id = app.current_profile_id()));
create policy asset_insert on asset for insert with check (app.can('Asset', 'create'));
create policy asset_update on asset for update using (app.can('Asset', 'update'));
create policy asset_delete on asset for delete using (app.can('Asset', 'delete'));

create policy document_select on document for select using (app.can('Document', 'read'));
create policy document_insert on document for insert with check (app.can('Document', 'create'));
create policy document_update on document for update using (app.can('Document', 'update'));
create policy document_delete on document for delete using (app.can('Document', 'delete'));

create policy comment_select on comment for select using (app.can('Comment', 'read'));
create policy comment_insert on comment for insert with check (app.can('Comment', 'create'));
create policy comment_update on comment for update using (app.can('Comment', 'update'));
create policy comment_delete on comment for delete using (app.can('Comment', 'delete'));

create policy role_select on role for select using (app.can('Role', 'read'));
create policy role_insert on role for insert with check (app.can('Role', 'create'));
create policy role_update on role for update using (app.can('Role', 'update'));
create policy role_delete on role for delete using (app.can('Role', 'delete'));

create policy team_select on team for select using (app.can('Team', 'read'));
create policy team_insert on team for insert with check (app.can('Team', 'create'));
create policy team_update on team for update using (app.can('Team', 'update'));
create policy team_delete on team for delete using (app.can('Team', 'delete'));

create policy dashboard_config_select on dashboard_config for select using (app.can('DashboardConfig', 'read'));
create policy dashboard_config_insert on dashboard_config for insert with check (app.can('DashboardConfig', 'create'));
create policy dashboard_config_update on dashboard_config for update using (app.can('DashboardConfig', 'update'));
create policy dashboard_config_delete on dashboard_config for delete using (app.can('DashboardConfig', 'delete'));

create policy badge_select on badge for select using (app.can('Badge', 'read'));
create policy badge_insert on badge for insert with check (app.can('Badge', 'create'));
create policy badge_update on badge for update using (app.can('Badge', 'update'));
create policy badge_delete on badge for delete using (app.can('Badge', 'delete'));

create policy user_badge_select on user_badge for select using (app.can('UserBadge', 'read'));
create policy user_badge_insert on user_badge for insert with check (app.can('UserBadge', 'create'));
create policy user_badge_update on user_badge for update using (app.can('UserBadge', 'update'));
create policy user_badge_delete on user_badge for delete using (app.can('UserBadge', 'delete'));

create policy challenge_select on challenge for select using (app.can('Challenge', 'read'));
create policy challenge_insert on challenge for insert with check (app.can('Challenge', 'create'));
create policy challenge_update on challenge for update using (app.can('Challenge', 'update'));
create policy challenge_delete on challenge for delete using (app.can('Challenge', 'delete'));

create policy streak_select on streak for select using (app.can('Streak', 'read'));
create policy streak_insert on streak for insert with check (app.can('Streak', 'create'));
create policy streak_update on streak for update using (app.can('Streak', 'update'));
create policy streak_delete on streak for delete using (app.can('Streak', 'delete'));

create policy personal_best_select on personal_best for select using (app.can('PersonalBest', 'read'));
create policy personal_best_insert on personal_best for insert with check (app.can('PersonalBest', 'create'));
create policy personal_best_update on personal_best for update using (app.can('PersonalBest', 'update'));
create policy personal_best_delete on personal_best for delete using (app.can('PersonalBest', 'delete'));

create policy data_source_config_select on data_source_config for select using (app.can('DataSourceConfig', 'read'));
create policy data_source_config_insert on data_source_config for insert with check (app.can('DataSourceConfig', 'create'));
create policy data_source_config_update on data_source_config for update using (app.can('DataSourceConfig', 'update'));
create policy data_source_config_delete on data_source_config for delete using (app.can('DataSourceConfig', 'delete'));

create policy level_definition_select on level_definition for select using (app.can('LevelDefinition', 'read'));
create policy level_definition_insert on level_definition for insert with check (app.can('LevelDefinition', 'create'));
create policy level_definition_update on level_definition for update using (app.can('LevelDefinition', 'update'));
create policy level_definition_delete on level_definition for delete using (app.can('LevelDefinition', 'delete'));

create policy xp_event_select on xp_event for select using (app.can('XPEvent', 'read'));
create policy xp_event_insert on xp_event for insert with check (app.can('XPEvent', 'create'));
create policy xp_event_update on xp_event for update using (app.can('XPEvent', 'update'));
create policy xp_event_delete on xp_event for delete using (app.can('XPEvent', 'delete'));

-- UserProfile: every signed-in user may read profiles, because owner and assignee names
-- are shown throughout the UI. Users may update their own profile; only admins may create,
-- delete, or edit someone else's.
create policy user_profile_select on user_profile for select using (app.current_profile_id() is not null);
create policy user_profile_insert on user_profile for insert with check (app.is_admin());
create policy user_profile_update on user_profile for update
  using (app.is_admin() or id = app.current_profile_id());
create policy user_profile_delete on user_profile for delete using (app.is_admin());

-- Notifications are personal. You read, mark and delete your own, whatever your role says
-- about the Notification object; creation happens in SECURITY DEFINER triggers, so no
-- client insert policy exists at all.
create policy notification_select on notification for select
  using (user_id = app.current_profile_id());
create policy notification_update on notification for update
  using (user_id = app.current_profile_id());
create policy notification_delete on notification for delete
  using (user_id = app.current_profile_id());

-- AuditLog is append-only. Anyone may write an entry, only admins may read the trail, and
-- nobody may alter or remove one.
create policy audit_log_insert on audit_log for insert with check (app.current_profile_id() is not null);
create policy audit_log_select on audit_log for select using (app.is_admin());

-- AIProviderConfig holds provider credentials. No non-admin may read the row at all, and the
-- api_key column privilege is withdrawn as well, so that even a future permissive policy
-- cannot leak it to the application role.
create policy ai_provider_config_all on ai_provider_config for all
  using (app.is_admin()) with check (app.is_admin());

-- Provider key is write-only for clients. See the comment in generate-policies.mjs.
revoke all on ai_provider_config from crm_app;
grant select (id, created_at, updated_at, created_by, updated_by, provider, model, endpoint_url, is_active) on ai_provider_config to crm_app;
grant insert (id, created_at, updated_at, created_by, updated_by, provider, model, api_key, endpoint_url, is_active) on ai_provider_config to crm_app;
grant update (id, created_at, updated_at, created_by, updated_by, provider, model, api_key, endpoint_url, is_active) on ai_provider_config to crm_app;
grant delete on ai_provider_config to crm_app;
