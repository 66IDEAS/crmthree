-- Generated from specs/data-model.json by db/generate-ddl.mjs. Do not edit by hand.
-- Model version: 1.0
-- 38 objects

create extension if not exists "pgcrypto";

-- Enumerations. Invalid values are rejected by the database, not by convention.
create type account_company_size as enum ('1-10', '11-50', '51-200', '201-500', '501-1000', '1001-5000', '5000+');
create type account_status as enum ('Active', 'Inactive');
create type contact_status as enum ('Active', 'Inactive');
create type lead_source as enum ('Web', 'Referral', 'Trade Show', 'Cold Call', 'Email Campaign', 'Social Media', 'Partner', 'Other');
create type lead_status as enum ('New', 'Contacted', 'Qualified', 'Unqualified', 'Converted');
create type opportunity_result as enum ('Open', 'Won', 'Lost');
create type quotation_status as enum ('Draft', 'Sent', 'Accepted', 'Rejected', 'Expired');
create type sales_order_status as enum ('Draft', 'Confirmed', 'In Progress', 'Shipped', 'Completed', 'Cancelled');
create type invoice_status as enum ('Draft', 'Sent', 'Paid', 'Partially Paid', 'Overdue', 'Cancelled');
create type line_item_parent_type as enum ('Opportunity', 'Quotation', 'SalesOrder', 'Invoice');
create type product_product_type as enum ('Physical', 'Service', 'Subscription', 'License');
create type product_status as enum ('Active', 'Inactive', 'Discontinued');
create type activity_type as enum ('Call', 'Email', 'Meeting', 'Task');
create type activity_status as enum ('Planned', 'In Progress', 'Completed', 'Cancelled');
create type activity_priority as enum ('Low', 'Medium', 'High');
create type ticket_priority as enum ('Low', 'Medium', 'High', 'Critical');
create type knowledge_article_status as enum ('Draft', 'In Review', 'Published', 'Archived');
create type knowledge_article_source as enum ('Manual', 'AI Generated', 'Case Conversion');
create type service_contract_status as enum ('Draft', 'Active', 'Expired', 'Terminated');
create type asset_status as enum ('Active', 'Inactive', 'Retired', 'In Repair');
create type document_parent_type as enum ('Account', 'Contact', 'Opportunity', 'Quotation', 'SalesOrder', 'Invoice', 'Ticket', 'KnowledgeArticle');
create type comment_parent_type as enum ('Account', 'Contact', 'Lead', 'Opportunity', 'Quotation', 'SalesOrder', 'Invoice', 'Ticket', 'KnowledgeArticle', 'Activity');
create type user_profile_theme_preference as enum ('Light', 'Dark', 'System');
create type notification_type as enum ('TicketAssigned', 'SLABreach', 'DealStageChange', 'MentionedInComment', 'LeadAssigned', 'ChallengeAssigned', 'BadgeEarned', 'LevelUp', 'PersonalBest', 'System');
create type badge_category as enum ('Sales', 'Service', 'Data Quality', 'Collaboration', 'Milestone', 'Challenge', 'Special');
create type challenge_status as enum ('Active', 'Completed', 'Failed', 'Cancelled');
create type audit_log_action as enum ('Create', 'Update', 'Delete');
create type data_source_config_source_type as enum ('Local', 'External');
create type data_source_config_auth_type as enum ('None', 'BasicAuth', 'OAuth2', 'APIKey');
create type ai_provider_config_provider as enum ('OpenAI', 'Google', 'Anthropic');

-- Auto-number sequences. See P3: sequences replace zero-padded strings.
create sequence account_account_number_seq start 1;
create sequence contact_contact_number_seq start 1;
create sequence lead_lead_number_seq start 1;
create sequence opportunity_opportunity_number_seq start 1;
create sequence quotation_quotation_number_seq start 1;
create sequence sales_order_order_number_seq start 1;
create sequence invoice_invoice_number_seq start 1;
create sequence product_product_number_seq start 1;
create sequence activity_activity_number_seq start 1;
create sequence ticket_ticket_number_seq start 1;
create sequence knowledge_article_article_number_seq start 1;
create sequence service_contract_contract_number_seq start 1;
create sequence asset_asset_number_seq start 1;

-- Company or organization the business interacts with
create table account (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  account_number integer not null unique default nextval('account_account_number_seq'),
  name1 varchar(40) not null,
  name2 varchar(40),
  street varchar(60),
  house_number varchar(10),
  postal_code varchar(10),
  city varchar(40),
  region varchar(3),
  country varchar(3),
  phone varchar(30),
  fax varchar(30),
  email varchar(241),
  website varchar(132),
  industry varchar(10),
  industry_description varchar(100),
  company_size account_company_size,
  annual_revenue numeric(15,2),
  currency varchar(5),
  parent_account_id uuid,
  owner_id uuid not null,
  description text,
  status account_status not null default 'Active'::account_status
);

-- Individual person the business interacts with
create table contact (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  contact_number integer not null unique default nextval('contact_contact_number_seq'),
  title varchar(30),
  first_name varchar(40) not null,
  last_name varchar(40) not null,
  department varchar(40),
  position varchar(40),
  phone varchar(30),
  mobile varchar(30),
  email varchar(241),
  street varchar(60),
  house_number varchar(10),
  postal_code varchar(10),
  city varchar(40),
  country varchar(3),
  owner_id uuid not null,
  description text,
  status contact_status not null default 'Active'::contact_status
);

-- Junction table linking contacts to accounts (many-to-many)
create table contact_account (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  contact_id uuid not null,
  account_id uuid not null,
  role varchar(50),
  is_primary boolean not null default false
);

-- Potential sales prospect not yet qualified as a contact or opportunity
create table lead (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  lead_number integer not null unique default nextval('lead_lead_number_seq'),
  first_name varchar(40) not null,
  last_name varchar(40) not null,
  company varchar(40),
  position varchar(40),
  email varchar(241),
  phone varchar(30),
  mobile varchar(30),
  website varchar(132),
  source lead_source,
  status lead_status not null default 'New'::lead_status,
  score integer default 0,
  account_id uuid,
  contact_id uuid,
  converted_account_id uuid,
  converted_contact_id uuid,
  converted_opportunity_id uuid,
  converted_at timestamptz,
  owner_id uuid not null,
  description text
);

-- Sales deal tracked through a configurable pipeline
create table opportunity (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  opportunity_number integer not null unique default nextval('opportunity_opportunity_number_seq'),
  name varchar(120) not null,
  account_id uuid not null,
  lead_id uuid,
  stage_id uuid not null,
  amount numeric(15,2),
  currency varchar(5) not null default 'USD',
  probability integer,
  expected_close_date date,
  actual_close_date date,
  result opportunity_result not null default 'Open'::opportunity_result,
  loss_reason varchar(255),
  owner_id uuid not null,
  description text
);

-- Junction table linking opportunities to contacts with roles
create table opportunity_contact (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  opportunity_id uuid not null,
  contact_id uuid not null,
  role varchar(50)
);

-- Configurable pipeline stage for opportunities
create table pipeline_stage (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  name varchar(50) not null,
  sort_order integer not null,
  default_probability integer,
  is_closed boolean not null default false,
  is_won boolean not null default false,
  description varchar(255),
  active boolean not null default true
);

-- Formal price proposal sent to a customer
create table quotation (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  quotation_number integer not null unique default nextval('quotation_quotation_number_seq'),
  name varchar(120) not null,
  account_id uuid not null,
  contact_id uuid,
  opportunity_id uuid,
  status quotation_status not null default 'Draft'::quotation_status,
  valid_from date,
  valid_to date,
  total_amount numeric(15,2),
  currency varchar(5) not null default 'USD',
  notes text,
  owner_id uuid not null
);

-- Confirmed customer purchase order
create table sales_order (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  order_number integer not null unique default nextval('sales_order_order_number_seq'),
  name varchar(120) not null,
  account_id uuid not null,
  contact_id uuid,
  opportunity_id uuid,
  quotation_id uuid,
  status sales_order_status not null default 'Draft'::sales_order_status,
  order_date date not null,
  total_amount numeric(15,2),
  currency varchar(5) not null default 'USD',
  notes text,
  owner_id uuid not null
);

-- Customer billing document
create table invoice (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  invoice_number integer not null unique default nextval('invoice_invoice_number_seq'),
  name varchar(120) not null,
  account_id uuid not null,
  contact_id uuid,
  sales_order_id uuid,
  status invoice_status not null default 'Draft'::invoice_status,
  invoice_date date not null,
  due_date date not null,
  total_amount numeric(15,2),
  paid_amount numeric(15,2) default 0,
  currency varchar(5) not null default 'USD',
  notes text,
  owner_id uuid not null
);

-- Product line item on an Opportunity, Quotation, Sales Order, or Invoice
create table line_item (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  parent_type line_item_parent_type not null,
  parent_id uuid not null,
  item_number varchar(6) not null,
  product_id uuid,
  description varchar(40) not null,
  quantity numeric(13,3) not null default 1,
  unit_of_measure varchar(3),
  unit_price numeric(11,2) not null,
  discount_percent numeric(5,2) default 0,
  alternative_to varchar(6),
  total_price numeric(15,2) not null,
  sort_order integer not null
);

-- Price book entry defining the price for a product, optionally per customer and/or quantity range. Supports: (1) base price per product, (2) customer-specific price, (3) quantity-based pricing with either a fixed price or a discount percentage.
create table pricebook_entry (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  product_id uuid not null,
  account_id uuid,
  price numeric(15,2),
  currency varchar(5),
  quantity_from numeric(13,3),
  quantity_to numeric(13,3),
  discount_percent numeric(5,2),
  valid_from date,
  valid_to date,
  active boolean not null default true
);

-- Product or service in the catalog
create table product (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  product_number integer not null unique default nextval('product_product_number_seq'),
  name varchar(40) not null,
  description text,
  product_group varchar(9),
  product_group_description varchar(100),
  unit_of_measure varchar(3) not null default 'EA',
  base_price numeric(13,2),
  currency varchar(5),
  product_type product_product_type not null default 'Physical'::product_product_type,
  status product_status not null default 'Active'::product_status
);

-- Interaction or task (call, email, meeting, task) linked to CRM records
create table activity (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  activity_number integer not null unique default nextval('activity_activity_number_seq'),
  type activity_type not null,
  subject varchar(255) not null,
  description text,
  status activity_status not null default 'Planned'::activity_status,
  priority activity_priority default 'Medium'::activity_priority,
  start_date timestamptz,
  end_date timestamptz,
  due_date date,
  completed_at timestamptz,
  duration_minutes integer,
  account_id uuid,
  contact_id uuid,
  lead_id uuid,
  opportunity_id uuid,
  ticket_id uuid,
  owner_id uuid not null,
  is_auto_logged boolean not null default false
);

-- Service or support ticket tracking a customer issue
create table ticket (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  ticket_number integer not null unique default nextval('ticket_ticket_number_seq'),
  subject varchar(40) not null,
  description text,
  status_id uuid not null,
  priority ticket_priority not null default 'Medium'::ticket_priority,
  category varchar(50),
  account_id uuid not null,
  contact_id uuid,
  asset_id uuid,
  service_contract_id uuid,
  sla_id uuid,
  assigned_to uuid,
  owner_id uuid not null,
  resolution text,
  sla_response_deadline timestamptz,
  sla_resolution_deadline timestamptz,
  first_response_at timestamptz,
  resolved_at timestamptz,
  closed_at timestamptz
);

-- Configurable ticket status values
create table ticket_status (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  name varchar(50) not null,
  sort_order integer not null,
  is_closed boolean not null default false,
  is_resolved boolean not null default false,
  description varchar(255),
  active boolean not null default true
);

-- Service Level Agreement defining response and resolution time targets
create table sla (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  name varchar(100) not null,
  description text,
  response_time_hours numeric(5,1) not null,
  resolution_time_hours numeric(5,1) not null,
  applies_to_priorities jsonb,
  business_hours_only boolean not null default true,
  active boolean not null default true
);

-- Knowledge base article with solutions and information
create table knowledge_article (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  article_number integer not null unique default nextval('knowledge_article_article_number_seq'),
  title varchar(255) not null,
  content text not null,
  category varchar(100),
  status knowledge_article_status not null default 'Draft'::knowledge_article_status,
  source knowledge_article_source not null default 'Manual'::knowledge_article_source,
  author_id uuid not null,
  views_count integer not null default 0,
  helpful_count integer not null default 0,
  published_at timestamptz
);

-- Junction table linking tickets to knowledge articles
create table ticket_knowledge_article (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  ticket_id uuid not null,
  article_id uuid not null,
  linked_at timestamptz not null,
  linked_by uuid not null
);

-- Service agreement defining coverage and entitlements for a customer
create table service_contract (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  contract_number integer not null unique default nextval('service_contract_contract_number_seq'),
  name varchar(120) not null,
  account_id uuid not null,
  start_date date not null,
  end_date date not null,
  status service_contract_status not null default 'Draft'::service_contract_status,
  entitlements text,
  sla_id uuid,
  owner_id uuid not null
);

-- Installed product at a customer site
create table asset (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  asset_number integer not null unique default nextval('asset_asset_number_seq'),
  name varchar(40) not null,
  product_id uuid not null,
  account_id uuid not null,
  contact_id uuid,
  serial_number varchar(18),
  install_date date,
  warranty_end_date date,
  functional_location varchar(30),
  manufacturer varchar(30),
  model_number varchar(20),
  status asset_status not null default 'Active'::asset_status,
  owner_id uuid not null
);

-- File attachment linked to any CRM record
create table document (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  name varchar(255) not null,
  file_path varchar(500) not null,
  file_type varchar(50),
  file_size integer,
  parent_type document_parent_type not null,
  parent_id uuid not null,
  uploaded_by uuid not null
);

-- User comment or note on any CRM record
create table comment (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  parent_type comment_parent_type not null,
  parent_id uuid not null,
  content text not null,
  author_id uuid not null
);

-- CRM user profile extending the authentication identity
create table user_profile (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  auth_uid varchar(128) unique,
  email varchar(241) not null unique,
  first_name varchar(40) not null,
  last_name varchar(40) not null,
  role_id uuid not null,
  team_id uuid,
  avatar_url varchar(500),
  xp_total integer not null default 0,
  level integer not null default 1,
  level_name varchar(50) not null default 'Rookie',
  current_streak_days integer not null default 0,
  longest_streak_days integer not null default 0,
  active boolean not null default true,
  theme_preference user_profile_theme_preference not null default 'System'::user_profile_theme_preference,
  notification_preferences jsonb
);

-- User role defining permissions and UI configuration
create table role (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  name varchar(50) not null unique,
  description varchar(255),
  is_system_role boolean not null default false,
  permissions jsonb not null,
  ribbon_items jsonb not null,
  visible_cards jsonb,
  layout_config jsonb,
  active boolean not null default true
);

-- Group of users under a manager
create table team (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  name varchar(100) not null,
  manager_id uuid not null,
  description varchar(255),
  active boolean not null default true
);

-- In-app notification for a user
create table notification (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  user_id uuid not null,
  type notification_type not null,
  title varchar(255) not null,
  message varchar(500),
  read boolean not null default false,
  link_type varchar(50),
  link_id uuid,
  send_email boolean not null default false,
  email_sent boolean not null default false
);

-- User-specific dashboard layout configuration
create table dashboard_config (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  user_id uuid not null,
  name varchar(100) not null default 'My Dashboard',
  is_default boolean not null default true,
  widgets jsonb not null
);

-- Achievement badge that users can earn
create table badge (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  name varchar(100) not null unique,
  description varchar(255) not null,
  icon_url varchar(500),
  category badge_category not null,
  criteria jsonb not null,
  is_custom boolean not null default false,
  active boolean not null default true
);

-- Record of a badge earned by a user
create table user_badge (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  user_id uuid not null,
  badge_id uuid not null,
  earned_at timestamptz not null
);

-- AI-assigned monthly challenge for a user
create table challenge (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  user_id uuid not null,
  title varchar(255) not null,
  description text not null,
  month integer not null,
  year integer not null,
  target_metric varchar(100) not null,
  target_value numeric(10,2) not null,
  current_value numeric(10,2) not null default 0,
  status challenge_status not null default 'Active'::challenge_status,
  reward_badge_id uuid,
  reward_xp integer not null default 0,
  completed_at timestamptz
);

-- Tracks consecutive-day activity streaks per user and activity type
create table streak (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  user_id uuid not null,
  activity_type varchar(50) not null,
  current_count integer not null default 0,
  longest_count integer not null default 0,
  last_activity_date date
);

-- Tracks personal records for key performance metrics
create table personal_best (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  user_id uuid not null,
  metric varchar(100) not null,
  value numeric(15,2) not null,
  achieved_at timestamptz not null,
  previous_value numeric(15,2),
  previous_achieved_at timestamptz
);

-- Tracks all record changes for undo support and audit trail
create table audit_log (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  object_type varchar(50) not null,
  object_id uuid not null,
  action audit_log_action not null,
  field_name varchar(100),
  old_value text,
  new_value text,
  user_id uuid not null,
  timestamp timestamptz not null
);

-- Per-object configuration for the pluggable data source layer
create table data_source_config (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  object_type varchar(50) not null unique,
  source_type data_source_config_source_type not null default 'Local'::data_source_config_source_type,
  endpoint_url varchar(500),
  auth_type data_source_config_auth_type,
  auth_config jsonb,
  field_mapping jsonb,
  active boolean not null default true
);

-- Configuration for the pluggable AI provider
create table ai_provider_config (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  provider ai_provider_config_provider not null,
  model varchar(100) not null,
  api_key varchar(500) not null,
  endpoint_url varchar(500),
  is_active boolean not null default false
);

-- Defines the gamification levels and their XP thresholds
create table level_definition (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  level integer not null unique,
  name varchar(50) not null,
  xp_threshold integer not null,
  unlocks jsonb,
  icon_url varchar(500)
);

-- Defines how many XP points are awarded for different CRM actions
create table xp_event (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  created_by uuid not null,
  updated_by uuid not null,
  event_type varchar(100) not null unique,
  description varchar(255) not null,
  xp_value integer not null,
  active boolean not null default true
);

-- Foreign keys, added after all tables exist.
alter table account add constraint account_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table account add constraint account_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table account add constraint account_parent_account_id_fk foreign key (parent_account_id) references account(id) deferrable initially deferred;
alter table account add constraint account_owner_id_fk foreign key (owner_id) references user_profile(id) deferrable initially deferred;
alter table contact add constraint contact_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table contact add constraint contact_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table contact add constraint contact_owner_id_fk foreign key (owner_id) references user_profile(id) deferrable initially deferred;
alter table contact_account add constraint contact_account_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table contact_account add constraint contact_account_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table contact_account add constraint contact_account_contact_id_fk foreign key (contact_id) references contact(id) deferrable initially deferred;
alter table contact_account add constraint contact_account_account_id_fk foreign key (account_id) references account(id) deferrable initially deferred;
alter table lead add constraint lead_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table lead add constraint lead_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table lead add constraint lead_account_id_fk foreign key (account_id) references account(id) deferrable initially deferred;
alter table lead add constraint lead_contact_id_fk foreign key (contact_id) references contact(id) deferrable initially deferred;
alter table lead add constraint lead_converted_account_id_fk foreign key (converted_account_id) references account(id) deferrable initially deferred;
alter table lead add constraint lead_converted_contact_id_fk foreign key (converted_contact_id) references contact(id) deferrable initially deferred;
alter table lead add constraint lead_converted_opportunity_id_fk foreign key (converted_opportunity_id) references opportunity(id) deferrable initially deferred;
alter table lead add constraint lead_owner_id_fk foreign key (owner_id) references user_profile(id) deferrable initially deferred;
alter table opportunity add constraint opportunity_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table opportunity add constraint opportunity_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table opportunity add constraint opportunity_account_id_fk foreign key (account_id) references account(id) deferrable initially deferred;
alter table opportunity add constraint opportunity_lead_id_fk foreign key (lead_id) references lead(id) deferrable initially deferred;
alter table opportunity add constraint opportunity_stage_id_fk foreign key (stage_id) references pipeline_stage(id) deferrable initially deferred;
alter table opportunity add constraint opportunity_owner_id_fk foreign key (owner_id) references user_profile(id) deferrable initially deferred;
alter table opportunity_contact add constraint opportunity_contact_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table opportunity_contact add constraint opportunity_contact_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table opportunity_contact add constraint opportunity_contact_opportunity_id_fk foreign key (opportunity_id) references opportunity(id) deferrable initially deferred;
alter table opportunity_contact add constraint opportunity_contact_contact_id_fk foreign key (contact_id) references contact(id) deferrable initially deferred;
alter table pipeline_stage add constraint pipeline_stage_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table pipeline_stage add constraint pipeline_stage_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table quotation add constraint quotation_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table quotation add constraint quotation_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table quotation add constraint quotation_account_id_fk foreign key (account_id) references account(id) deferrable initially deferred;
alter table quotation add constraint quotation_contact_id_fk foreign key (contact_id) references contact(id) deferrable initially deferred;
alter table quotation add constraint quotation_opportunity_id_fk foreign key (opportunity_id) references opportunity(id) deferrable initially deferred;
alter table quotation add constraint quotation_owner_id_fk foreign key (owner_id) references user_profile(id) deferrable initially deferred;
alter table sales_order add constraint sales_order_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table sales_order add constraint sales_order_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table sales_order add constraint sales_order_account_id_fk foreign key (account_id) references account(id) deferrable initially deferred;
alter table sales_order add constraint sales_order_contact_id_fk foreign key (contact_id) references contact(id) deferrable initially deferred;
alter table sales_order add constraint sales_order_opportunity_id_fk foreign key (opportunity_id) references opportunity(id) deferrable initially deferred;
alter table sales_order add constraint sales_order_quotation_id_fk foreign key (quotation_id) references quotation(id) deferrable initially deferred;
alter table sales_order add constraint sales_order_owner_id_fk foreign key (owner_id) references user_profile(id) deferrable initially deferred;
alter table invoice add constraint invoice_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table invoice add constraint invoice_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table invoice add constraint invoice_account_id_fk foreign key (account_id) references account(id) deferrable initially deferred;
alter table invoice add constraint invoice_contact_id_fk foreign key (contact_id) references contact(id) deferrable initially deferred;
alter table invoice add constraint invoice_sales_order_id_fk foreign key (sales_order_id) references sales_order(id) deferrable initially deferred;
alter table invoice add constraint invoice_owner_id_fk foreign key (owner_id) references user_profile(id) deferrable initially deferred;
alter table line_item add constraint line_item_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table line_item add constraint line_item_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table line_item add constraint line_item_product_id_fk foreign key (product_id) references product(id) deferrable initially deferred;
alter table pricebook_entry add constraint pricebook_entry_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table pricebook_entry add constraint pricebook_entry_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table pricebook_entry add constraint pricebook_entry_product_id_fk foreign key (product_id) references product(id) deferrable initially deferred;
alter table pricebook_entry add constraint pricebook_entry_account_id_fk foreign key (account_id) references account(id) deferrable initially deferred;
alter table product add constraint product_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table product add constraint product_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table activity add constraint activity_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table activity add constraint activity_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table activity add constraint activity_account_id_fk foreign key (account_id) references account(id) deferrable initially deferred;
alter table activity add constraint activity_contact_id_fk foreign key (contact_id) references contact(id) deferrable initially deferred;
alter table activity add constraint activity_lead_id_fk foreign key (lead_id) references lead(id) deferrable initially deferred;
alter table activity add constraint activity_opportunity_id_fk foreign key (opportunity_id) references opportunity(id) deferrable initially deferred;
alter table activity add constraint activity_ticket_id_fk foreign key (ticket_id) references ticket(id) deferrable initially deferred;
alter table activity add constraint activity_owner_id_fk foreign key (owner_id) references user_profile(id) deferrable initially deferred;
alter table ticket add constraint ticket_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table ticket add constraint ticket_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table ticket add constraint ticket_status_id_fk foreign key (status_id) references ticket_status(id) deferrable initially deferred;
alter table ticket add constraint ticket_account_id_fk foreign key (account_id) references account(id) deferrable initially deferred;
alter table ticket add constraint ticket_contact_id_fk foreign key (contact_id) references contact(id) deferrable initially deferred;
alter table ticket add constraint ticket_asset_id_fk foreign key (asset_id) references asset(id) deferrable initially deferred;
alter table ticket add constraint ticket_service_contract_id_fk foreign key (service_contract_id) references service_contract(id) deferrable initially deferred;
alter table ticket add constraint ticket_sla_id_fk foreign key (sla_id) references sla(id) deferrable initially deferred;
alter table ticket add constraint ticket_assigned_to_fk foreign key (assigned_to) references user_profile(id) deferrable initially deferred;
alter table ticket add constraint ticket_owner_id_fk foreign key (owner_id) references user_profile(id) deferrable initially deferred;
alter table ticket_status add constraint ticket_status_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table ticket_status add constraint ticket_status_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table sla add constraint sla_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table sla add constraint sla_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table knowledge_article add constraint knowledge_article_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table knowledge_article add constraint knowledge_article_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table knowledge_article add constraint knowledge_article_author_id_fk foreign key (author_id) references user_profile(id) deferrable initially deferred;
alter table ticket_knowledge_article add constraint ticket_knowledge_article_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table ticket_knowledge_article add constraint ticket_knowledge_article_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table ticket_knowledge_article add constraint ticket_knowledge_article_ticket_id_fk foreign key (ticket_id) references ticket(id) deferrable initially deferred;
alter table ticket_knowledge_article add constraint ticket_knowledge_article_article_id_fk foreign key (article_id) references knowledge_article(id) deferrable initially deferred;
alter table ticket_knowledge_article add constraint ticket_knowledge_article_linked_by_fk foreign key (linked_by) references user_profile(id) deferrable initially deferred;
alter table service_contract add constraint service_contract_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table service_contract add constraint service_contract_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table service_contract add constraint service_contract_account_id_fk foreign key (account_id) references account(id) deferrable initially deferred;
alter table service_contract add constraint service_contract_sla_id_fk foreign key (sla_id) references sla(id) deferrable initially deferred;
alter table service_contract add constraint service_contract_owner_id_fk foreign key (owner_id) references user_profile(id) deferrable initially deferred;
alter table asset add constraint asset_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table asset add constraint asset_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table asset add constraint asset_product_id_fk foreign key (product_id) references product(id) deferrable initially deferred;
alter table asset add constraint asset_account_id_fk foreign key (account_id) references account(id) deferrable initially deferred;
alter table asset add constraint asset_contact_id_fk foreign key (contact_id) references contact(id) deferrable initially deferred;
alter table asset add constraint asset_owner_id_fk foreign key (owner_id) references user_profile(id) deferrable initially deferred;
alter table document add constraint document_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table document add constraint document_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table document add constraint document_uploaded_by_fk foreign key (uploaded_by) references user_profile(id) deferrable initially deferred;
alter table comment add constraint comment_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table comment add constraint comment_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table comment add constraint comment_author_id_fk foreign key (author_id) references user_profile(id) deferrable initially deferred;
alter table user_profile add constraint user_profile_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table user_profile add constraint user_profile_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table user_profile add constraint user_profile_role_id_fk foreign key (role_id) references role(id) deferrable initially deferred;
alter table user_profile add constraint user_profile_team_id_fk foreign key (team_id) references team(id) deferrable initially deferred;
alter table role add constraint role_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table role add constraint role_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table team add constraint team_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table team add constraint team_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table team add constraint team_manager_id_fk foreign key (manager_id) references user_profile(id) deferrable initially deferred;
alter table notification add constraint notification_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table notification add constraint notification_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table notification add constraint notification_user_id_fk foreign key (user_id) references user_profile(id) deferrable initially deferred;
alter table dashboard_config add constraint dashboard_config_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table dashboard_config add constraint dashboard_config_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table dashboard_config add constraint dashboard_config_user_id_fk foreign key (user_id) references user_profile(id) deferrable initially deferred;
alter table badge add constraint badge_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table badge add constraint badge_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table user_badge add constraint user_badge_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table user_badge add constraint user_badge_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table user_badge add constraint user_badge_user_id_fk foreign key (user_id) references user_profile(id) deferrable initially deferred;
alter table user_badge add constraint user_badge_badge_id_fk foreign key (badge_id) references badge(id) deferrable initially deferred;
alter table challenge add constraint challenge_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table challenge add constraint challenge_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table challenge add constraint challenge_user_id_fk foreign key (user_id) references user_profile(id) deferrable initially deferred;
alter table challenge add constraint challenge_reward_badge_id_fk foreign key (reward_badge_id) references badge(id) deferrable initially deferred;
alter table streak add constraint streak_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table streak add constraint streak_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table streak add constraint streak_user_id_fk foreign key (user_id) references user_profile(id) deferrable initially deferred;
alter table personal_best add constraint personal_best_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table personal_best add constraint personal_best_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table personal_best add constraint personal_best_user_id_fk foreign key (user_id) references user_profile(id) deferrable initially deferred;
alter table audit_log add constraint audit_log_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table audit_log add constraint audit_log_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table audit_log add constraint audit_log_user_id_fk foreign key (user_id) references user_profile(id) deferrable initially deferred;
alter table data_source_config add constraint data_source_config_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table data_source_config add constraint data_source_config_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table ai_provider_config add constraint ai_provider_config_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table ai_provider_config add constraint ai_provider_config_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table level_definition add constraint level_definition_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table level_definition add constraint level_definition_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;
alter table xp_event add constraint xp_event_created_by_fk foreign key (created_by) references user_profile(id) deferrable initially deferred;
alter table xp_event add constraint xp_event_updated_by_fk foreign key (updated_by) references user_profile(id) deferrable initially deferred;

-- Indexes on foreign keys, which list views filter and join on.
create index account_created_by_idx on account (created_by);
create index account_updated_by_idx on account (updated_by);
create index account_parent_account_id_idx on account (parent_account_id);
create index account_owner_id_idx on account (owner_id);
create index contact_created_by_idx on contact (created_by);
create index contact_updated_by_idx on contact (updated_by);
create index contact_owner_id_idx on contact (owner_id);
create index contact_account_created_by_idx on contact_account (created_by);
create index contact_account_updated_by_idx on contact_account (updated_by);
create index contact_account_contact_id_idx on contact_account (contact_id);
create index contact_account_account_id_idx on contact_account (account_id);
create index lead_created_by_idx on lead (created_by);
create index lead_updated_by_idx on lead (updated_by);
create index lead_account_id_idx on lead (account_id);
create index lead_contact_id_idx on lead (contact_id);
create index lead_converted_account_id_idx on lead (converted_account_id);
create index lead_converted_contact_id_idx on lead (converted_contact_id);
create index lead_converted_opportunity_id_idx on lead (converted_opportunity_id);
create index lead_owner_id_idx on lead (owner_id);
create index opportunity_created_by_idx on opportunity (created_by);
create index opportunity_updated_by_idx on opportunity (updated_by);
create index opportunity_account_id_idx on opportunity (account_id);
create index opportunity_lead_id_idx on opportunity (lead_id);
create index opportunity_stage_id_idx on opportunity (stage_id);
create index opportunity_owner_id_idx on opportunity (owner_id);
create index opportunity_contact_created_by_idx on opportunity_contact (created_by);
create index opportunity_contact_updated_by_idx on opportunity_contact (updated_by);
create index opportunity_contact_opportunity_id_idx on opportunity_contact (opportunity_id);
create index opportunity_contact_contact_id_idx on opportunity_contact (contact_id);
create index pipeline_stage_created_by_idx on pipeline_stage (created_by);
create index pipeline_stage_updated_by_idx on pipeline_stage (updated_by);
create index quotation_created_by_idx on quotation (created_by);
create index quotation_updated_by_idx on quotation (updated_by);
create index quotation_account_id_idx on quotation (account_id);
create index quotation_contact_id_idx on quotation (contact_id);
create index quotation_opportunity_id_idx on quotation (opportunity_id);
create index quotation_owner_id_idx on quotation (owner_id);
create index sales_order_created_by_idx on sales_order (created_by);
create index sales_order_updated_by_idx on sales_order (updated_by);
create index sales_order_account_id_idx on sales_order (account_id);
create index sales_order_contact_id_idx on sales_order (contact_id);
create index sales_order_opportunity_id_idx on sales_order (opportunity_id);
create index sales_order_quotation_id_idx on sales_order (quotation_id);
create index sales_order_owner_id_idx on sales_order (owner_id);
create index invoice_created_by_idx on invoice (created_by);
create index invoice_updated_by_idx on invoice (updated_by);
create index invoice_account_id_idx on invoice (account_id);
create index invoice_contact_id_idx on invoice (contact_id);
create index invoice_sales_order_id_idx on invoice (sales_order_id);
create index invoice_owner_id_idx on invoice (owner_id);
create index line_item_created_by_idx on line_item (created_by);
create index line_item_updated_by_idx on line_item (updated_by);
create index line_item_product_id_idx on line_item (product_id);
create index pricebook_entry_created_by_idx on pricebook_entry (created_by);
create index pricebook_entry_updated_by_idx on pricebook_entry (updated_by);
create index pricebook_entry_product_id_idx on pricebook_entry (product_id);
create index pricebook_entry_account_id_idx on pricebook_entry (account_id);
create index product_created_by_idx on product (created_by);
create index product_updated_by_idx on product (updated_by);
create index activity_created_by_idx on activity (created_by);
create index activity_updated_by_idx on activity (updated_by);
create index activity_account_id_idx on activity (account_id);
create index activity_contact_id_idx on activity (contact_id);
create index activity_lead_id_idx on activity (lead_id);
create index activity_opportunity_id_idx on activity (opportunity_id);
create index activity_ticket_id_idx on activity (ticket_id);
create index activity_owner_id_idx on activity (owner_id);
create index ticket_created_by_idx on ticket (created_by);
create index ticket_updated_by_idx on ticket (updated_by);
create index ticket_status_id_idx on ticket (status_id);
create index ticket_account_id_idx on ticket (account_id);
create index ticket_contact_id_idx on ticket (contact_id);
create index ticket_asset_id_idx on ticket (asset_id);
create index ticket_service_contract_id_idx on ticket (service_contract_id);
create index ticket_sla_id_idx on ticket (sla_id);
create index ticket_assigned_to_idx on ticket (assigned_to);
create index ticket_owner_id_idx on ticket (owner_id);
create index ticket_status_created_by_idx on ticket_status (created_by);
create index ticket_status_updated_by_idx on ticket_status (updated_by);
create index sla_created_by_idx on sla (created_by);
create index sla_updated_by_idx on sla (updated_by);
create index knowledge_article_created_by_idx on knowledge_article (created_by);
create index knowledge_article_updated_by_idx on knowledge_article (updated_by);
create index knowledge_article_author_id_idx on knowledge_article (author_id);
create index ticket_knowledge_article_created_by_idx on ticket_knowledge_article (created_by);
create index ticket_knowledge_article_updated_by_idx on ticket_knowledge_article (updated_by);
create index ticket_knowledge_article_ticket_id_idx on ticket_knowledge_article (ticket_id);
create index ticket_knowledge_article_article_id_idx on ticket_knowledge_article (article_id);
create index ticket_knowledge_article_linked_by_idx on ticket_knowledge_article (linked_by);
create index service_contract_created_by_idx on service_contract (created_by);
create index service_contract_updated_by_idx on service_contract (updated_by);
create index service_contract_account_id_idx on service_contract (account_id);
create index service_contract_sla_id_idx on service_contract (sla_id);
create index service_contract_owner_id_idx on service_contract (owner_id);
create index asset_created_by_idx on asset (created_by);
create index asset_updated_by_idx on asset (updated_by);
create index asset_product_id_idx on asset (product_id);
create index asset_account_id_idx on asset (account_id);
create index asset_contact_id_idx on asset (contact_id);
create index asset_owner_id_idx on asset (owner_id);
create index document_created_by_idx on document (created_by);
create index document_updated_by_idx on document (updated_by);
create index document_uploaded_by_idx on document (uploaded_by);
create index comment_created_by_idx on comment (created_by);
create index comment_updated_by_idx on comment (updated_by);
create index comment_author_id_idx on comment (author_id);
create index user_profile_created_by_idx on user_profile (created_by);
create index user_profile_updated_by_idx on user_profile (updated_by);
create index user_profile_role_id_idx on user_profile (role_id);
create index user_profile_team_id_idx on user_profile (team_id);
create index role_created_by_idx on role (created_by);
create index role_updated_by_idx on role (updated_by);
create index team_created_by_idx on team (created_by);
create index team_updated_by_idx on team (updated_by);
create index team_manager_id_idx on team (manager_id);
create index notification_created_by_idx on notification (created_by);
create index notification_updated_by_idx on notification (updated_by);
create index notification_user_id_idx on notification (user_id);
create index dashboard_config_created_by_idx on dashboard_config (created_by);
create index dashboard_config_updated_by_idx on dashboard_config (updated_by);
create index dashboard_config_user_id_idx on dashboard_config (user_id);
create index badge_created_by_idx on badge (created_by);
create index badge_updated_by_idx on badge (updated_by);
create index user_badge_created_by_idx on user_badge (created_by);
create index user_badge_updated_by_idx on user_badge (updated_by);
create index user_badge_user_id_idx on user_badge (user_id);
create index user_badge_badge_id_idx on user_badge (badge_id);
create index challenge_created_by_idx on challenge (created_by);
create index challenge_updated_by_idx on challenge (updated_by);
create index challenge_user_id_idx on challenge (user_id);
create index challenge_reward_badge_id_idx on challenge (reward_badge_id);
create index streak_created_by_idx on streak (created_by);
create index streak_updated_by_idx on streak (updated_by);
create index streak_user_id_idx on streak (user_id);
create index personal_best_created_by_idx on personal_best (created_by);
create index personal_best_updated_by_idx on personal_best (updated_by);
create index personal_best_user_id_idx on personal_best (user_id);
create index audit_log_created_by_idx on audit_log (created_by);
create index audit_log_updated_by_idx on audit_log (updated_by);
create index audit_log_user_id_idx on audit_log (user_id);
create index data_source_config_created_by_idx on data_source_config (created_by);
create index data_source_config_updated_by_idx on data_source_config (updated_by);
create index ai_provider_config_created_by_idx on ai_provider_config (created_by);
create index ai_provider_config_updated_by_idx on ai_provider_config (updated_by);
create index level_definition_created_by_idx on level_definition (created_by);
create index level_definition_updated_by_idx on level_definition (updated_by);
create index xp_event_created_by_idx on xp_event (created_by);
create index xp_event_updated_by_idx on xp_event (updated_by);

-- Row Level Security (P7). Policies are defined per table in db/policies.sql;
-- enabling RLS with no policy denies all access, which is the correct default.
alter table account enable row level security;
alter table contact enable row level security;
alter table contact_account enable row level security;
alter table lead enable row level security;
alter table opportunity enable row level security;
alter table opportunity_contact enable row level security;
alter table pipeline_stage enable row level security;
alter table quotation enable row level security;
alter table sales_order enable row level security;
alter table invoice enable row level security;
alter table line_item enable row level security;
alter table pricebook_entry enable row level security;
alter table product enable row level security;
alter table activity enable row level security;
alter table ticket enable row level security;
alter table ticket_status enable row level security;
alter table sla enable row level security;
alter table knowledge_article enable row level security;
alter table ticket_knowledge_article enable row level security;
alter table service_contract enable row level security;
alter table asset enable row level security;
alter table document enable row level security;
alter table comment enable row level security;
alter table user_profile enable row level security;
alter table role enable row level security;
alter table team enable row level security;
alter table notification enable row level security;
alter table dashboard_config enable row level security;
alter table badge enable row level security;
alter table user_badge enable row level security;
alter table challenge enable row level security;
alter table streak enable row level security;
alter table personal_best enable row level security;
alter table audit_log enable row level security;
alter table data_source_config enable row level security;
alter table ai_provider_config enable row level security;
alter table level_definition enable row level security;
alter table xp_event enable row level security;
