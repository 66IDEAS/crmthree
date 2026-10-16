# Task List — CRM System

> Generated from: specifications.md (58 stories), architecture.md (20 requirements), ux.md (37 requirements)

## Foundation & Infrastructure

- [x] A1 — Blueprint-Based Delivery
- [x] A2 — Customer Workflow
- [x] A3 — Customization Before Build
- [x] A4 — Rebuild and Evolution
- [x] A5 — Update Mechanism
- [x] A6 — Specifications Package
- [x] A7 — Data Model (JSON)
- [x] A8 — UX Templates
- [x] A9 — Architecture Templates
- [ ] A10 — Deployment Templates
- [ ] A11 — Test Templates
- [ ] A12 — The Skill
- [x] A13 — Firebase Stack (React/Vite 7/MUI 7/Material React Table 3)
- [x] A14 — Database-Agnostic Data Model
- [x] A15 — SAP-Compatible Field Definitions

## Application Shell & Layout

- [x] UX1 — Modern and Clean Visual Style (Light + Dark Themes, C3 Logo)
- [x] UX2 — Top Bar (Logo, Notifications, Gamification, Profile, Sign Out)
- [x] UX3 — Left Ribbon Navigation (Hamburger Toggle with Orange Icon at Top)
- [x] UX4 — AI/Search Bar (Persistent Bottom)
- [x] UX5 — Main Content Area
- [x] UX15 — Role-Based Ribbon Items
- [x] UX16 — Ribbon on Mobile
- [x] UX25 — Theme Selection on Profile Page (Light/Dark/System Dropdown)
- [x] UX26 — Login Page (Email/Password + Google Sign-In)
- [x] UX27 — Navigation History Breadcrumbs (Last 5 + Dropdown for 10 More)

## Authentication & Access Control

- [x] F18 — Role-Based Access Control (Admin, Manager, User, Custom Roles)
- [x] F18b — Email/Domain Whitelist (Access Control in Settings)

## Core Sales Objects

- [x] F1 — Account Management (CRUD, Hierarchies)
- [x] F2 — Contact Management (CRUD, Multi-Account)
- [x] F3 — Lead Management (CRUD, Scoring, Conversion)
- [x] F4 — Opportunity Management (CRUD, Pipeline Stages, Line Items, Conversion)
- [x] F5 — Quotation Management (CRUD, Line Items, Conversion)
- [x] F6 — Sales Order Management (CRUD, Line Items)
- [x] F7 — Invoice Management (CRUD, Line Items)
- [x] F8 — Product Management (CRUD, Catalog)
- [x] F9 — Activity Management (Calls, Emails, Meetings, Tasks)

## Core Service Objects

- [x] F10 — Ticket Management (CRUD, Configurable Statuses)
- [x] F11 — SLA Management (Response/Resolution Targets)
- [x] F12 — Knowledge Base (CRUD, Categories, Search)
- [x] F13 — Service Contract Management (CRUD, Coverage)
- [x] F14 — Asset Management (CRUD, Product Reference)

## Record Views & Navigation

- [x] UX6 — Record Detail Header (Object Name + ID, Smart Display Name Resolution)
- [x] UX9 — Object Details Card
- [x] UX10 — Linked Records Section (Cards per Type)
- [x] F58 — Linked Records on Cards (All Object Relationships)
- [x] UX29 — Inline Line Item Editing (Auto Item #, Auto Net Value, Product Autocomplete)
- [x] UX11 — Table-Based List View (Sort, Filter, Paginate, Inline Edit)
- [x] UX12 — Full-Page Record Creation (Progressive Disclosure)
- [x] UX21 — Default Column Selection (5 Curated Columns per Object Type)
- [x] UX22 — Dropdowns Show Options on Click (Reference + Enum)
- [x] UX23 — Colored Status and Enum Chips
- [x] UX24 — Auto-Number Display Without Leading Zeros
- [x] UX30 — Human-Readable Validation Messages and Date Defaults
- [x] UX32 — Document Conversion Buttons and Dialog (Opp→Quote, Opp→SO, Quote→SO, SO→Invoice)
- [x] UX8 — Quick Action Bar (Floating Action Buttons)

## Home Screen

- [x] UX13 — AI Priority Summary (Functional with AI Generate Briefing)
- [x] UX14 — Dashboard & Trend Analytics on Home
- [x] A23 — Client-Side Dashboard Aggregation

## Cross-Cutting Features

- [x] F15 — Dashboard & Reporting (Configurable, Role-Aware)
- [x] F16 — Global Search
- [x] F17 — Notifications (In-App + Desktop, Client-Side Triggers, Preferences)
- [x] UX18 — Notification Bell (Badge, Panel, Mark Read, Time-Ago, Desktop Notifications)
- [x] UX36 — Notification Preferences in Settings (All Users)
- [x] A21 — Real-Time Notification Delivery (onSnapshot, NotificationContext)
- [x] A22 — Client-Side Notification Triggers
- [x] F19 — Data Import & Export (CSV)
- [x] UX34 — Export Button on List View
- [x] UX35 — Data Import Section in Settings (Admin Only)
- [x] UX37 — Ticket Status Configuration in Settings (Admin Only)
- [x] F47 — Progressive Disclosure on Forms (Adaptive Learning Deferred)
- [x] F48 — Role-Adaptive UI (Per-Role Layouts)
- [x] F49 — Responsive-First Design
- [x] F45 — One-Tap Contextual Actions (Quick Actions, Swipe Deferred)

## AI Architecture & Features

- [x] A19 — Pluggable AI Provider
- [x] A20 — AI Service Interface
- [x] F20 — AI Assistant (Always-Visible Command Interface)
- [x] F20b — Data-Aware AI Context Injection (Server-Side)
- [x] F20c — Chat-Style AI Conversation UI
- [x] UX7 — AI Summary on Record Detail
- [x] UX19 — Search Results Drop-Up
- [x] F21 — Contextual Intelligence Briefing
- [ ] F22 — Multi-Level AI Summaries (User ✓, Account ✓, Lead/Opp ✓, Deal Room — partial)
- [x] F23 — AI-Powered Semantic Search
- [ ] F24 — AI Pipeline Coaching
- [ ] F25 — AI-Generated Knowledge Articles
- [ ] F26 — AI Meeting Summaries
- [ ] F27 — Smart Email Parsing
- [ ] F28 — AI Personal Performance Narratives

## Data Integration

- [x] F59 — Data Replication from External Systems
- [x] UX33 — Data Replication Section in Settings

## SAP Integration & Data Layer

- [x] F29 — SAP-Compatible Data Model
- [x] A16 — Pluggable Data Source Layer
- [x] F30 — Pluggable Data Source Layer (Per-Object Config)
- [x] A17 — Bi-Directional Data Integration
- [x] F31 — Bi-Directional Data Integration
- [x] A18 — Open REST API
- [x] F32 — Open API (REST, CRUD, Auto-Documented)
- [x] UX34b — Data Sources Section in Settings

## Unified Workspaces

- [x] F33 — Deal Rooms
- [x] F34 — Case Rooms
- [x] F35 — User Timeline (Cross-Object, Filterable)
- [x] F36 — Team Timeline (Manager View, Filterable)

## Gamification & Motivation Engine

- [x] F37 — Leaderboards (Multi-Dimensional, Time Periods)
- [x] F38 — Points and Achievements (XP for Interactions)
- [x] F39 — Levels and Progression (Rookie → Legend, Unlocks)
- [x] F40 — Collectible Badges and Trophies (Trophy Case)
- [x] F41 — Celebration Animations
- [x] UX20 — Confetti Celebration Animations
- [x] UX17 — Gamification Status Display (Points, Badge, Streak in Top Bar)
- [x] F42 — AI-Assigned Monthly Challenges
- [x] F43 — Streak Tracking (Habits → Outcomes)
- [x] F44 — Gamification-Based Performance Reviews

## Self-Growing Knowledge & Data Quality

- [ ] F50 — Reverse Data Entry (URL, Business Card, LinkedIn)
- [ ] F51 — Case-to-Knowledge-Base Conversion (One-Click)
- [ ] F52 — Auto-Logging from Email (Outlook/Gmail)
- [ ] F53 — Intelligent Duplicate Management (AI Auto-Link, Merge)
- [ ] F54 — Trend Analytics (Direction, Projections)
- [x] F55 — Personal Bests (Track and Celebrate)

## Internationalization

- [x] A21 — i18n Architecture (TranslationService, TranslationContext, labels catalog)
- [x] A21b — i18n: Wrap page component strings with t() calls (HomePage, LoginPage, SettingsPage, ObjectListPage, ObjectDetailPage, ObjectCreatePage, App.jsx)
- [x] A21c — i18n: Wrap dialog and settings component strings with t() calls (LeadConvertDialog, DocumentConvertDialog, CsvImportDialog, AiSummaryPlaceholder, NotificationPanel, NotificationPreferencesSection, AIProviderSection, TicketStatusSection, AccessControlSection, ImportSection, ReplicationSection, DataSourceSection)
- [x] F60 — Multi-Language UI Labels
- [x] UX35 — Language Management Section in Settings
- [x] UX36 — Language and Appearance on Profile Page

- [x] UX50 — Case Room Workspace View
- [x] UX51 — User Timeline on Profile Page
- [x] UX52 — Team Timeline Page
- [x] UX53 — Leaderboard Card on Home Screen

## Record Locking

- [x] F61 — Pessimistic Record Locking (Lock/Unlock, TTL, Heartbeat)
- [x] A24 — Record Locking Architecture (onSnapshot, RecordLockService)
- [x] UX54 — Record Lock Indicator on Detail Header

## Performance

- [x] A25 — Server-Side Pagination (listPage, count, usePaginatedList, MRT manual mode)

## Code Review

- [ ] CR1 — Firestore rules: replace blanket allow with collection-level role/ownership checks (Critical)
- [ ] CR2 — REST API: add server-side authorization middleware with role checks (Critical)
- [ ] CR3 — Replication proxy: restrict to admin-only + allowlist hosts to prevent SSRF (Critical)
- [ ] CR4 — Secrets: move API keys/passwords to Secret Manager, return redacted DTOs to clients (High)
- [ ] CR5 — AI context: apply per-user authorization filters before context injection (High)
- [x] CR6 — AIProviderSection: fix broken delete action (`DataService.delete` → `DataService.remove`) (Medium)
- [x] CR7 — LinkedRecordCard: fix hook rules violation in `OneToManyCard` (Medium)
- [ ] CR8 — AuthService: make first-user bootstrap race-safe with backend transaction (Medium)
- [x] CR9 — Hook dependency warnings: resolve all `react-hooks/exhaustive-deps` lint warnings (Low)

## User Management

- [ ] F58 — User Management section in Settings (list, invite, role change, activate/deactivate, delete)
- [x] F62 — Configurable Default List Sort Order (per-object Number/Name + direction, admin Settings section, incomplete-data warning and backfill)
- [ ] A27 — Profile claiming architecture (pending profiles with empty auth_uid, claim-by-email on first sign-in, deactivation check)
- [x] A28 — List sort configuration (`listViewSettings` collection, `ListSortService` session cache, mode→field resolution, hidden-record detection via orderBy-constrained count)

## Opportunities

- [ ] F63 - Opportunity Kanban board (specifications 64, UX 58): Table/Kanban toggle, stage columns with per-currency totals, cards with activity alerts, drag or menu to move with the stage rules, audit/notification/XP like a record-page stage change, lock check

## Agentic Engineering

- [ ] F56 — AI-Powered System Configuration (Natural Language → Config)
- [ ] F57 — AI-Powered Feature Development (Natural Language → Feature)

## Deployment

- [x] A26 - Multi-Instance Deployment Architecture (per-instance Firebase project, Vite env mode, isolated build output)
- [x] D11 - Upgrade global `firebase-tools` to 15.26.0 (old 13.13.2 could not parse the firebase-functions v6 build spec, breaking functions deploys on all instances)
- [ ] D12 - Remove stale `firebase-tools` 13.13.2 at `/usr/local/bin/firebase`; nvm's 15.26.0 wins in interactive shells, but any context without nvm loaded (cron, plain `sh`, GUI-launched tooling) resolves the old binary and functions deploys fail again
