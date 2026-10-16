# UX Requirements

## General Style

1. **Modern and Clean Visual Style**
   The application uses a modern, clean visual style. Two themes are supported: a light theme and a dark theme. Colors, fonts, and visual tokens for each theme are defined in the style guides (`specs/styles/style-guide-light.md` and `specs/styles/style-guide-dark.md`). The style guides define colors and typography only — not application structure or layout. The application uses the official full CRMTHREE wordmark and CRMTHREE by 66IDEAS lockup shared by the reference implementations, with light-background and dark-background variants that switch automatically with the active theme.

## Application Shell

2. **Top Bar**
   The application has a fixed top bar. The left side displays the official full CRMTHREE wordmark, which links to the home screen. The right side displays (from right to left): the user profile icon (opens a menu with profile link and sign out), a notification bell icon, and the gamification status (points, latest badge, streak). The top bar does not contain navigation controls — the hamburger toggle and theme switch are located elsewhere (see UX3 and UX25). The bottom border of the top bar is a bold (3px) orange line (#F7941D) to visually separate the header from the content below.

3. **Left Ribbon Navigation**
   The left side of the application has a vertical navigation bar called the Ribbon. The Ribbon displays navigation items as icons with labels. The first item at the top of the Ribbon is a hamburger toggle button with an orange icon (#F7941D, matching the C3 logo accent color). When expanded, the hamburger item shows the label "Navigation" in bold. The hamburger is separated from the navigation items below by a divider. Clicking the hamburger toggles the Ribbon between expanded (icons + labels) and collapsed (icons only) states. The default state of the Ribbon is collapsed (icons only). The Ribbon contains navigation items for all main objects (e.g., Accounts, Contacts, Leads, Opportunities, Quotes, Sales Orders) as well as workspace views (Deal Rooms, Case Rooms). The Case Rooms ribbon item lists all Tickets but navigates to Case Room workspace views instead of Ticket detail pages. A Settings item is pinned to the bottom of the Ribbon, separated from the main navigation items by a divider.

4. **AI/Search Bar**
   A persistent AI and search bar is displayed at the bottom of the application, visible on every screen. It has an "Ask" label and a text input field with placeholder text "Ask AI or search across all records...". The bar serves dual purpose: global keyword search (F16) and AI assistant (F20). The bar automatically detects whether the input is a keyword search or an AI query using heuristics: inputs containing a question mark, starting with question words (who, what, why, how, etc.), or containing 4+ words are treated as AI queries when the user presses Enter. Short keywords trigger instant debounced search as before. When an AI query is detected: the input is cleared immediately, the user's message appears right-aligned in a chat bubble (primary color background, white text) in the drop-up panel, and the AI response appears left-aligned below it with an "AI Assistant" label and orange accent. The conversation thread is scrollable and supports multi-turn conversation — follow-up questions are appended to the thread and the AI receives the full history for context. A "Thinking..." indicator shows while waiting for the AI response. Keyword search results appear below the chat thread, separated by a divider. If no AI provider is configured, all inputs fall back to keyword search only. Pressing Escape or clicking outside closes the panel and clears the chat history. The search input can also be focused with Ctrl+K / Cmd+K keyboard shortcut.

5. **Main Content Area**
   The main content area occupies the space between the Top Bar, Ribbon, and AI/Search Bar. All views (home, list views, detail views, dashboards) render inside this area. The content area is scrollable. Navigation history breadcrumbs are displayed above the scrollable area and do not scroll. On detail and list views, the page header (back button, headline, action buttons on detail views; title on list views) is sticky and remains visible at the top while only the cards and table content scroll.

## Record Detail View

6. **Record Detail Header**
   At the top of a record detail view, a single row displays: a back button (navigates to the previous page), the record's display name as an h5 headline, the auto-number as a chip, and Edit/Delete action buttons. The display name is resolved using the primary display field for the object type: `name` or `name1` for objects with a name field, composite `first_name + last_name` for person-type objects (Contact, Lead), `title` or `subject` for other objects, and the auto-number for document-type objects without a name field (Quotation, Sales Order, Invoice). Document-type objects that have no name field display their auto-number followed by the account name in brackets as the headline — e.g., "42 (Acme Corp)". All elements are vertically centered on the same line. Edit is triggered from the header; the details card only shows Save/Cancel when in edit mode.

7. **AI Summary on Record Detail**
   Below the record detail header and above the Quick Action Bar, an AI-generated contextual briefing card is displayed for supported object types (Account, Contact, Lead, Opportunity, Ticket, Quotation, SalesOrder, Invoice). The briefing is NOT generated automatically on page load — instead, the card shows a "Generate Briefing" button that the user clicks to request the AI summary on demand. The card has an orange (#F7941D) sparkle-icon avatar on the left, "AI Briefing" as the title, and the "Generate Briefing" button (outlined, small, with sparkle icon) in the initial state. Once generated, the summary text replaces the button, and a refresh icon button appears to allow regeneration. A collapse/expand toggle lets the user hide or show the summary content. While the AI generates the briefing, a circular loading spinner with "Generating briefing..." text is shown. If no AI provider is configured, the card is not rendered at all. The briefing provides type-specific contextual intelligence: for accounts it covers relationship health and pipeline value; for contacts it covers interactions and associated items; for opportunities it covers deal stage assessment and risks; for leads it covers qualification and conversion readiness; for tickets it covers severity and SLA status. The summary is 3-5 sentences and focuses on actionable insights.

8. **Quick Action Bar**
   Below the record detail header and above the Details card, a horizontal bar of small outlined action buttons provides contextual quick actions relevant to the current record type. Each button has an icon and label. Actions are accessible with a single click. For objects that support activities (Account, Contact, Lead, Opportunity, Ticket), the bar shows: Log Call (phone icon), Log Email (email icon), Log Meeting (calendar icon), New Task (task icon). These create an Activity record of the corresponding type, pre-linked to the current record. Additional type-specific conversion actions are shown after the activity buttons: Opportunity shows "New Quote" (document icon) and "New Sales Order" (cart icon) which open the document conversion dialog; Quotation shows "New Sales Order" (cart icon); SalesOrder shows "New Invoice" (receipt icon); Lead shows "Convert" (transform icon), disabled if status is already "Converted". The bar renders for any object type that has at least one applicable action (activity or conversion). It renders as a horizontal row of compact outlined buttons with 8px gaps, wrapping on smaller screens. Conversion actions also remain in the record header for redundant access.

9. **Object Details Card**
   Below the AI summary and quick action bar, the first card displays the object's own field data. This card is labeled "Details". Field labels are bold and use the primary text color. Field values also use the primary text color for readability. In read mode, fields without a value are hidden to reduce clutter. In edit mode, all fields are shown so the user can fill them in.

10. **Linked Records Section**
    Below the Object Details card, a "Linked Records" section displays related records as individual cards. Each card takes the full width of the page (stacked vertically, not side by side). Each card uses the same data grid control as the main list pages, with sorting, row click navigation, and compact density. The cards shown depend on the object type and the linked record relationships defined in the specifications. For many-to-many relationships (e.g., Contact↔Account via ContactAccount, Opportunity↔Contact via OpportunityContact), the card queries the junction table to find linked records and resolves their display names. Junction-specific fields (such as "role") are shown as additional columns. A "Link" button allows the user to search for and link an existing record without navigating away. An "Unlink" icon on each row removes the junction record (not the target record itself).

## List View

11. **Table-Based List View**
    List views display records in a table format. Clicking a navigation item in the Ribbon opens the corresponding list view in the main content area. Dual-mode pagination: by default, server-side pagination fetches only the current page (25/50/100) with prev/next navigation and server-side sorting. When the user activates the global search or column filters, all records are fetched and the data grid handles filtering, sorting, and pagination client-side — ensuring search always covers all records. When filters are cleared, the view returns to server-side mode. Inline editing of field values is supported directly in the table. CSV export fetches all records on demand.

34. **Export Button on List View**
    The list view toolbar displays an "Export" button (download icon) next to the "New" button. Export immediately downloads a CSV of all records with human-readable column headers and auto-numbers without leading zeros. The button is available on all navigable object types.

35. **Data Import Section in Settings (Admin Only)**
    The Settings page includes a "Data Import" section below Data Replication, visible only to admin users. The section contains: an object type dropdown to select the target, a file drop zone to select a CSV file, a data preview table showing the first 5 rows, and a field mapping panel. The field mapping is CRM-field-centric: it lists all fields of the selected object type, one per row, with required fields shown first (marked with a red asterisk). Each row has a source selector (CSV Column, Fixed Value, or Skip) and a value input. When source is "CSV Column", a dropdown shows available CSV headers. When source is "Fixed Value", an enum field shows a dropdown of allowed values and other fields show a text input. Fields with data model defaults are pre-filled as Fixed Value. Auto-mapped CSV columns are pre-matched by field name or description. The Import button is disabled if any required field is unmapped. During import a progress bar is shown. After import completes, a results summary displays created/skipped/error counts with row-level error details.

## Record Creation

12. **Full-Page Record Creation**
    Creating a new record opens a full page with a form for the new record. The form follows the progressive disclosure pattern defined in the specifications (minimal key fields by default, additional fields revealed on demand).

## Home Screen

13. **AI Priority Summary**
    The home screen displays a full-width AI Priority Summary card at the top. If no AI provider is configured, it shows a placeholder message ("Your personalized AI-powered priority summary will appear here in a future update."). When an AI provider is configured, the card shows an orange sparkle-icon avatar, a "Generate Briefing" button, and on click generates a personalized priority briefing using the user's current dashboard metrics (pipeline value, open opportunities, open tickets, open leads, activities this week, invoices, quotations) as context. The AI response is displayed in a collapsible section with refresh and collapse/expand controls. Loading state shows a circular loading spinner. The card follows the same visual pattern as the record-level AI Briefing.

14. **Dashboard & Trend Analytics**
    Below the AI placeholder, the home screen displays a dashboard with a personalized welcome header ("Welcome back, {first_name}") and a settings gear icon. The dashboard uses a 12-column grid layout:
    - **Row 1**: KPI number cards (3 columns each): Pipeline Value, Open Opportunities, Open Tickets, Open Leads, Activities This Week, Inactive Assets, Leaderboard. Each card shows a title, a large formatted number, and a colored icon.
    - **Row 2**: Two charts (6 columns each): Opportunities by Stage (horizontal bar chart, Recharts) and Tickets by Priority (donut/pie chart, Recharts).
    - **Row 3**: Two charts (6 columns each): Activity Trend over the last 7 days (line chart, Recharts) and Revenue by Invoice Status (bar chart, Recharts).
    Charts use the application's theme colors (primary blue, success green, warning orange, error red). Clicking the settings gear opens a dialog with checkboxes to toggle individual widgets on/off. Visibility preferences persist across sessions via DashboardConfig. While data loads, skeleton placeholders are shown. All dashboard elements are clickable and navigate to the corresponding object list view: KPI cards navigate on click, and chart segments (bars, pie slices, line points) navigate to the relevant object type's list view. Clickable elements show a pointer cursor on hover.

## Ribbon Behavior

15. **Role-Based Ribbon Items**
    The Ribbon only displays navigation items that the admin has assigned to the user's role. Different roles see different sets of navigation items.

## Mobile Behavior

16. **Ribbon on Mobile**
    On mobile devices, the Ribbon is fully hidden by default. Only the hamburger button is visible. Selecting the hamburger button opens the Ribbon as an overlay. The Ribbon closes after a navigation item is selected.

## Gamification in the Top Bar

17. **Gamification Status Display**
    The Top Bar displays the user's current points, latest badge, and current streak to the left of the user profile icon (and to the left of the notification bell). Selecting the visible badge navigates to a dedicated page showing all of the user's badges, trophies, and achievements.

## Notifications

18. **Notification Bell**
    A bell icon is displayed in the Top Bar to the left of the user profile icon. A badge on the bell shows the number of unread notifications in red; the badge is hidden when the count is zero. Clicking the bell opens a popover notification panel anchored to the bell icon. The panel header shows "Notifications" and a "Mark all as read" text button (disabled when no unread). Below the header is a scrollable list (max-height 400px) of notification items. Each item shows: an 8px blue dot on the left if unread, the notification title (bold if unread, normal if read), the notification message (truncated to one line), and a relative time-ago label (e.g., "5m ago", "2h ago", "3d ago"). Each item has a small delete (X) icon button on the right. Clicking an item marks it as read and navigates to the linked record (using link_type and link_id). If no notifications exist, the panel shows an empty state with a bell icon and "No notifications" text. The panel closes when clicking outside or pressing Escape. Desktop browser notifications appear as native OS notifications when new unread notifications arrive (if the user has granted permission via the browser Notification API).

36. **Notification Preferences in Settings**
    The Settings page includes a "Notification Preferences" section below the Appearance section, visible to all users (not admin-only). The section shows a list of notification types with toggle switches: Ticket Assigned, SLA Breach, Deal Stage Change, Mentioned in Comment, Lead Assigned, Challenge Assigned, Badge Earned, Level Up, Personal Best, System. A separate "Desktop Notifications" toggle controls whether browser notifications are shown. Changes are saved immediately when toggling. All types default to enabled if the user has not configured preferences.

## AI/Search Results

19. **Search Results Drop-Up**
    When the user types a query in the AI/Search bar, results are displayed in a drop-up panel that opens upward above the input bar. The panel shows search results grouped by object type, with each group showing the object type name as a header, the navigation icon, and up to 5 matching records. Each result row shows the record's display name and auto-number (if available). Clicking a result navigates to that record's detail page and closes the panel. The panel closes when the user selects a result, presses Escape, or clicks outside. A loading indicator shows while search is in progress. If no results are found, a "No results" message is displayed.

## Celebrations

20. **Confetti Celebration Animations**
    When a user hits a milestone, breaks a personal best, closes a deal, or levels up, a confetti rain animation is displayed across the screen. The animation is non-blocking and does not interrupt the user's workflow.

## List View Columns

21. **Default Column Selection**
    List views show only the 5 most relevant columns per object type by default instead of all fields. The first column is always the object's auto-number (e.g., Account Number, Contact Number), and the second column is the object's name or description. Users can toggle additional columns on or off using the column visibility menu in the table toolbar.

## Dropdown Behavior

22. **Dropdowns Show Options on Click**
    All dropdown fields (enum selects and reference autocompletes) show their available options immediately when the user clicks into the field, without requiring the user to start typing first. Reference field dropdowns load their options on focus/open. Enum fields in inline table editing use a proper select dropdown instead of a plain text input.

## Enum Chip Colors

23. **Colored Status and Enum Chips**
    Enum fields are displayed as filled colored chips with white text for clear visual distinction. Green for positive states (Active, Completed, Won, Paid, Low priority), red for negative states (Inactive, Lost, Rejected, Overdue, High/Critical priority), orange for in-progress states (In Progress, In Review, Sent, Medium priority), blue for initial states (New, Draft, Open, Planned), and default gray for neutral values (company sizes, activity types, sources).

## Auto-Number Display

24. **Auto-Number Display Without Leading Zeros**
    Auto-number fields (e.g., Account Number, Contact Number) are stored with leading zeros in the database (e.g., `0000000001`) for SAP compatibility, but displayed without leading zeros in the UI (e.g., `1`). This applies to all views: list view columns, detail view headers, and detail cards.

## Settings Page

25. **Theme Selection on Profile Page**
    The theme is configured from the Profile page alongside the language selector, not the top bar or Settings page. A dropdown offers three options: Light, Dark, and System (follows the operating system preference). The selection is persisted to localStorage so it survives page reloads and sessions. Further themes and the theme swatches in the user menu are defined in UX 71.

37. **Ticket Status Configuration in Settings (Admin Only)**
    The Settings page includes a "Ticket Statuses" section visible only to admin users. It displays a table of configured statuses with columns: Name, Sort Order, Resolved, Closed, Active, and Actions (Edit, Delete). An "Add Status" button opens an inline row or dialog to create a new status. Each status has: a name (string), sort order (integer for display ordering), is_resolved flag, is_closed flag, and active flag. The admin can edit or delete existing statuses. Statuses are used as the options in the "Current Ticket Status" dropdown on Ticket records.

28. **Access Control in Settings (Admin Only)**
    The Settings page includes an "Access Control" section visible only to admin users. It allows the admin to manage an email/domain whitelist that restricts who can access the application. The section displays: a description explaining that an empty list means all authenticated users can access; a row with a type dropdown (Email/Domain), a text input for the value, and an Add button; and a list of current whitelist entries showing a type chip, the value, and a delete button. When no entries exist, an italic message indicates no restrictions are configured.

42. **Role Management in Settings (Admin Only)**
    The Settings page includes a "Role Management" section visible only to admin users. It displays all roles as a list. Each role shows its name, description, and a chip indicating whether it is a system role. Clicking a role expands an inline editor with: a read-only name and description for system roles (editable for custom roles), and a checkbox grid of all available navigation items (derived from the navigation config). Each checkbox corresponds to one ribbon navigation entry (e.g., Accounts, Contacts, Deal Rooms). Checked items appear in the ribbon for users with that role; unchecked items are hidden. Changes are saved with a "Save" button per role. The section description explains that ribbon items control which navigation entries are visible for each role.

## Login Page

26. **Login Page**
    The login page is displayed when the user is not authenticated. It shows a centered card on the theme-appropriate background with the official CRMTHREE by 66IDEAS lockup, email/password fields, a "Sign In" button, a divider, and a "Sign in with Google" button. Error messages are displayed inline. The login page respects the current light/dark theme.

## Navigation History

27. **Navigation History Breadcrumbs**
    A navigation history trail is displayed above the main content area. It shows the last 5 visited pages as simple text links separated by " / ". Each link shows the record's display name (e.g., "Acme Corp", "John Smith"), also for a record opened from a link or with the browser's back button. The current page is shown as plain text (not a link). Clicking a breadcrumb navigates to that page. Browser back and forward move through the same pages (UX 60); a back step to the previous page shortens the trail instead of adding to it. The trail is session-based and does not persist across page reloads (the address of the current page does).

## Lead Conversion

31. **Lead Conversion Dialog**
    The lead detail page header includes a "Convert" button (with a transform icon) alongside Edit and Delete. Clicking it opens a dialog titled "Convert Lead". The dialog shows three sections: Contact (pre-filled first_name, last_name, email, phone, mobile, position — read-only preview), Account (pre-filled from the lead's company field into the account name — editable), and Opportunity (an opt-in checkbox with an editable opportunity name, defaulting to the lead's full name). A "Convert" button executes the conversion and navigates away. The button is disabled if the lead is already converted (status = "Converted"). The dialog also shows a summary of what will be created.

## Form Validation & Field Defaults

30. **Human-Readable Validation Messages and Date Defaults**
    All validation error messages on forms use the field's human-readable label (description), never the raw field name. For example, "Date the order was placed is required" instead of "order_date is required". Required date fields on create forms auto-initialize with today's date so the user does not need to manually open the date picker just to confirm the pre-filled value.

## Document Conversion

32. **Document Conversion Buttons and Dialog**
    Opportunity, Quotation, and Sales Order detail pages include conversion action buttons in the header alongside Edit and Delete. Opportunity shows "Create Quotation" (document icon) and "Create Sales Order" (cart icon). Quotation shows "Create Sales Order" (cart icon). Sales Order shows "Create Invoice" (receipt icon). Clicking a conversion button opens a confirmation dialog titled "Create {Target} from {Source}". The dialog shows a summary: the account name, number of line items being copied, and any key fields being set. A "Create" button executes the conversion: creates the target record with mapped fields, copies all line items from the source document, and navigates to the newly created record. The dialog shows a loading state during conversion and error messages on failure.

## Linked Record Creation

33. **Data Replication Section in Settings (Admin Only)**
    The Settings page includes a "Data Replication" section below the Access Control section, visible only to admin users. The section displays a table of configured replication sources with columns: Object Type, Web Service URL, Last Run, and Actions (Run, Edit, Delete). An "Add Replication" button opens a dialog where the admin configures: the target object type (dropdown of all navigable types), the web service URL, the request body (JSON editor), and field mappings (source field → CRM field pairs, with an add/remove interface). A key field dropdown selects which CRM field is used for matching existing records. Clicking "Run" triggers the replication and shows a progress indicator. After completion, a results summary is displayed showing created, updated, skipped, and error counts.

34. **Data Sources Section in Settings (Admin Only)**
    The Settings page includes a "Data Sources" section visible only to admin users. The section displays a table of configured data source overrides with columns: Object Type, Source Type (Local/External as a chip), Endpoint URL, Auth Type, Active (Yes/No), and Actions (Edit, Delete). An "Add Data Source" button opens a dialog. The dialog includes: Object Type dropdown (all 14 navigable object types), Source Type dropdown (Local/External), Endpoint URL text field (visible only when External is selected), Auth Type dropdown (None/BasicAuth/OAuth2/APIKey, visible only when External), dynamic authentication fields based on auth type (BasicAuth: Username + Password; OAuth2: Access Token; APIKey: API Key + Header Name), a Field Mapping section with add/remove pairs (External Field free-text input → CRM Field dropdown populated from the data model fields for the selected object type), and an Active toggle. By default all object types use the local database as their data source. Only object types that need to read from an external system require a configuration entry. Saving a configuration clears the client-side data source cache so changes take effect immediately.

35. **Language Management Section in Settings (Admin Only)**
    The Settings page includes a "Language Management" section visible only to admin users. The section displays a table of configured languages with columns: Language, Code, Labels Translated (e.g., "342 / 487"), and Actions (Manage, Delete). An "Add Language" button opens a dialog with an autocomplete dropdown of ~30 common ISO languages (filtered to exclude already-configured ones). Clicking "Manage" opens a full-width label editor dialog showing all translatable UI labels in a table: Label Key | English (read-only) | Target Language (editable TextField). The dialog includes a search/filter field, category filter tabs (All, Navigation, Fields, Enums, UI, Other), and a progress indicator showing how many labels are translated. An "AI Translate All" button (with AutoAwesome icon) batch-translates all untranslated labels using the configured AI provider, showing progress per batch.

36. **Language and Appearance on Profile Page**
    The Profile page includes a "Preferences" section with two dropdowns side by side: a "Language" dropdown that shows English plus all languages configured by the admin, and a "Theme" dropdown (Light/Dark/System). Selecting a language immediately switches all UI labels to that language. The language preference persists across sessions (stored on UserProfile). The theme preference persists via localStorage.

38. **Translatable Page Component Strings**
    All hardcoded English strings in page components (HomePage, LoginPage, SettingsPage, ObjectListPage, ObjectDetailPage, ObjectCreatePage, App.jsx) are wrapped with `t()` translation calls. This includes visible text, button labels, tooltips, section headers, placeholder text, and error messages. Brand names (CRM, THREE) and CSS/structural values are excluded from translation.

39. **Collapsible Settings Sections**
    All sections on the Settings page use accordion components instead of flat cards. Each section is collapsed by default, showing only the section title in the AccordionSummary. Users click to expand and see the full content. This reduces visual clutter and makes it easier to find the desired section.

40. **Responsive Adaptations**
    The application adapts to mobile screens (below 900px) using conditional rendering and responsive CSS values. On mobile: list view tables show only 2-3 essential columns (auto-number + name/subject) instead of 5, eliminating horizontal scroll; the TopBar hides the gamification section but always shows a compact official CRMTHREE wordmark, along with the notification bell and avatar; the AISearchBar drop-up panel is shorter (320px vs 480px), uses tighter padding, a shorter placeholder ("Search or ask AI..."), and hides the "Ask" label; the main content area reduces horizontal padding from 24px to 12px; the record detail header uses icon-only Edit/Delete buttons and a smaller title font; complex dialogs (Lead Convert, Document Convert, CSV Import) go fullScreen below 600px; the Profile page preferences dropdowns stack vertically on narrow screens. All changes are conditional — desktop rendering is unaffected.

41. **Deal Room**
    Deal Rooms are optional, purpose-built workspaces for important Opportunities. They are NOT auto-created — a user explicitly creates one via a "Create Deal Room" button on the Opportunity detail page. Once created, the button changes to "Open Deal Room". Deal Room is its own object type with a name (pre-filled from the Opportunity name, overridable), description, status (Active/Closed), and a required reference to the linked Opportunity. Deal Rooms appear in the left ribbon navigation (after Opportunities) with their own list view showing columns: deal_room_number, name, opportunity, amount, stage, status. The Deal Room detail page is a custom workspace layout (not the generic detail page). It has a sticky header with: back button, Deal Room name (h5), auto-number chip, status chip (Active=success, Closed=default), "Close Deal Room" button, and "View Opportunity" link. Below the header (top to bottom): (1) AI Deal Summary - reuses the record-level AI briefing card with Opportunity data; (2) Quick Actions bar — Update Stage (dropdown of pipeline stages, updates Opportunity), Add Note (dialog creating a Comment), Schedule Follow-up (navigates to activity creation pre-filled); (3) Deal Stage Progress — horizontal stepper showing all pipeline stages with current highlighted, completed steps checked, Won=all green, Lost=error on current step, vertical on mobile; (4) Two-column layout (stacked on mobile) — Left column (8/12): Activity Timeline (chronological feed of activities linked to the Opportunity, with type icons, subject, status chip, relative time, click navigates to activity) + Comment Thread (team discussion with avatar, author, time, content, text input with Post button); Right column (4/12): Deal Info card (amount, probability, expected close date, result, stage, owner, account), Contacts with Roles card (M2M via OpportunityContact), Documents card. Closing a Deal Room is manual only — it does not auto-close when the Opportunity is won or lost.

42. **Role Management in Settings (Admin Only)**
    The Settings page includes a "Role Management" section visible only to admin users. It displays all roles as a list. Each role shows its name, description, and a chip indicating whether it is a system role. Clicking a role expands an inline editor with: a read-only name and description for system roles (editable for custom roles), and a checkbox grid of all available navigation items (derived from the navigation config). Each checkbox corresponds to one ribbon navigation entry (e.g., Accounts, Contacts, Deal Rooms). Checked items appear in the ribbon for users with that role; unchecked items are hidden. Changes are saved with a "Save" button per role. The section description explains that ribbon items control which navigation entries are visible for each role.

43. **Gamification Status Display in TopBar**
    The TopBar displays the user's current XP total, level name (as a small chip), and current streak (fire icon + day count, only shown when streak > 0) to the left of the notification bell. On mobile, this section is hidden. The trophy icon navigates to the leaderboard page.

44. **Confetti Celebration Animations**
    When a user levels up, earns a badge, breaks a personal best, or closes a deal as Won, a non-blocking confetti animation plays across the screen accompanied by a brief snackbar toast describing the achievement. The animation does not block workflow — all UI elements remain clickable underneath.

45. **Gamification Settings (Admin Only)**
    The Settings page includes a "Gamification" section visible only to admin users. It contains three sub-sections: (1) XP Events — a table of event types with descriptions and XP values that admins can edit; (2) Level Definitions — a table of levels with names and XP thresholds; (3) Badges — a table of badges with names, descriptions, categories, and criteria. An "Initialize Defaults" button seeds standard XP events, levels, and badges if none exist.

46. **Profile Page Gamification Stats and Trophy Case**
    The Profile page displays the user's gamification stats below the Preferences section: a stats row showing Level (name + progress bar to next level), XP Total, Current Streak, and Longest Streak. Below that, a Trophy Case grid shows earned badges as cards with category chip, name, description, and earned date. Unearned badges are shown grayed out with a lock icon.

47. **Leaderboard Page**
    A dedicated leaderboard page shows user rankings across dimensions (XP Total, Deals Closed, Activities Logged, Tickets Resolved) with time period tabs (Week, Month, Quarter). Each entry shows rank, avatar, name, and metric value. Top 3 get gold/silver/bronze styling. The current user is highlighted.

48. **Active Challenge Card on Profile**
    When a user has an active monthly AI-assigned challenge, the Profile page shows a challenge card with: title, description, progress bar (current vs target), reward description, and time remaining. If no AI provider is configured, the "Generate Challenge" button does not appear.

49. **Performance Portfolio (Manager View)**
    Managers can view any team member's Profile page at `/profile/:userId`, showing the full gamification history in read-only mode: level progression, badge timeline, challenge history, streak records, and personal bests. An "Export to CSV" button allows the data to be exported.

50. **Case Room Workspace View**
    Every Ticket has a Case Room view accessible via an "Open Case Room" button on the Ticket detail page. The Case Room is NOT a separate object — it is a rich workspace view of the existing Ticket. Route: `/case-rooms/:ticketId`. Layout mirrors the Deal Room pattern: a sticky header with back button, ticket subject (h5), auto-number chip, status chip (colored by resolved/closed state), priority chip, and "View Ticket" link. Below the header (top to bottom): (1) AI Case Summary - reuses the record-level AI briefing card with Ticket data; (2) Quick Actions bar — Update Status (dropdown of TicketStatuses, updates ticket and auto-sets first_response_at/resolved_at/closed_at timestamps), Add Note (dialog creating a Comment with parent_type='Ticket'), Link KB Article (autocomplete search creating TicketKnowledgeArticle junction record); (3) Two-column layout (stacked on mobile) — Left column (8/12): Activity Timeline (activities linked to the ticket via ticket_id) + Comment Thread (team discussion with parent_type='Ticket'); Right column (4/12): Ticket Info card (status, priority, category, account, contact, SLA deadlines, timestamps, owner, assigned_to), Asset card (if linked), Service Contract card (if linked), Knowledge Articles card (M2M via TicketKnowledgeArticle).

51. **User Timeline (Standalone Page)**
    A dedicated "My Timeline" page at `/my-timeline` shows a chronological feed of the current user's activities AND CRM events across all objects. The page is accessible from the profile dropdown menu in the top bar — a "My Timeline" item with a Timeline icon appears between "Profile" and "Sign Out". The timeline merges two data sources: Activity records (calls, emails, meetings, tasks) and AuditLog records (record creations, status changes, field updates). Filter controls at the top: date range picker (from/to, default last 30 days) and event type dropdown (All, Activities Only, Events Only). Activity entries show the type icon (phone/email/calendar/task), subject, status chip, XP points awarded (small orange "+15 XP" chip, value read from XPEvent config for `log_activity`), relative time, and parent record context chips. CRM event entries show a green AddCircle icon for creations or blue EditNote icon for field changes, the event summary text (e.g., "Created Account Acme Corp", "Changed status to Qualified on Lead John Doe"), relative time, and an object type chip. All entries are sorted chronologically (newest first).

52. **Team Timeline Page (Manager Only)**
    A dedicated page at `/team-timeline` accessible only to team managers and admins. Shows a chronological feed of all team member activities AND CRM events, using the same combined timeline as the user timeline. Filter controls: team member selector (All or specific member), date range picker (from/to, default last 30 days), and event type dropdown (All, Activities Only, Events Only). Each entry shows the owner's name, appropriate icon, summary/subject, relative time, and context. The page header shows "Team Timeline" with the team name. Non-managers who navigate to this page see an access denied message. A "View Team Timeline" button appears on the Profile page for users who are team managers.

53. **Leaderboard Card on Home Screen**
    The home screen KPI card row includes a "Leaderboard" card at the same grid size as Pipeline Value or Open Opportunities (`xs: 12, sm: 6, md: 3`). The card displays the top 3 users ranked by XP Total (all time). Each row shows a rank medal indicator (gold/silver/bronze), a small avatar, the user's name (truncated if needed), and their XP value right-aligned. The card header shows "Leaderboard" with a trophy icon. Clicking the card navigates to the full Leaderboard page (`/leaderboard`). The card is configurable — it can be toggled on/off via the home screen settings popover. It is visible to all roles by default.

54. **Record Lock Indicator**
    When another user is editing a record, the record detail header shows a lock indicator: a lock icon with "{user name} is editing" caption text. The Edit button is disabled and shows a tooltip explaining the record is locked. When the editing user saves or cancels, the lock indicator disappears in real-time and the Edit button becomes enabled again. If the lock expires (15-minute TTL), the indicator also disappears.

29. **Inline Line Item Editing**
    Line items on Opportunity, Quotation, Sales Order, and Invoice detail pages are managed inline in a table — no navigation to a separate page. The line items table appears as the first linked record card, directly below the details card. The table shows columns: Item # | Product | Quantity | Net Price | Discount % | Net Value. Rows are sorted ascending by Item #. Clicking "+ Add New" inserts an inline creation row. Item number auto-populates (10, 20, 30...). Net value auto-calculates live as the user types (quantity × net price × (1 − discount / 100)). Each row has a delete icon. Parent context fields (parent_id, parent_type) are never shown. Below the line items table, a totals row displays the sum of all Net Value entries, right-aligned under the Net Value column. For non-line-item linked records, clicking "Add New" opens the create form with parent context pre-filled and hidden, returning to the parent page after creation.

55. **User Management (Settings Section, Admin Only)**
    The Settings page includes a "User Management" section, visible to admins only, placed directly above "Role Management". It is the single place to see who has access and to grant it, replacing manual database edits.

    The section header shows the user count and, when any invitations are outstanding, a warning-coloured chip reading "{n} pending". The body opens with a one-line explanation of how access works: a person must sign in once with Google before they appear, unless they are invited by email first.

    **User list.** A table of all UserProfile records sorted by last name, with columns: Name (avatar + first/last name, the current user marked with a "You" chip), Email, Role (inline dropdown of all Role records), Status, Level (level name + XP), and a row action menu. Status is a chip with three states — "Active" (green), "Inactive" (grey), and "Pending" (amber, shown when `auth_uid` is empty, meaning the person was invited but has not signed in yet). Changing the role dropdown saves immediately and shows a transient confirmation; an admin cannot change their own role or deactivate themselves, and those controls are disabled with an explanatory tooltip.

    **Invite a user.** An "Invite User" button opens a dialog with fields: Email (required, validated, checked for duplicates against existing profiles), First Name (required), Last Name (required), and Role (required, defaults to the "User" role). On save a UserProfile is created with an empty `auth_uid` and the gamification defaults (0 XP, level 1 Rookie, streaks 0, active true). The person can then sign in with Google using that email address and the profile is claimed automatically.

    **Whitelist awareness.** If the email whitelist is non-empty and the invited address matches no entry, the dialog shows an inline warning before saving — "This address is not on the access whitelist and will be rejected at sign-in" — with an "Add to whitelist" checkbox, ticked by default, that creates the matching whitelist entry alongside the profile.

    **Row actions.** The row menu offers "Deactivate" / "Reactivate" (toggles `active`; inactive users keep their data but are refused at sign-in), "Resend instructions" (copies a ready-made sign-in instruction text to the clipboard), and "Delete user" (confirmation dialog naming the person; removes the UserProfile but not their authentication account or the records they own).

56. **Pending Access Message Names the Fix**
    The "Your account has not been provisioned yet" screen shown to a signed-in user without a profile also states the email address they signed in with, so they can pass the right address to an administrator.

57. **Default List Sort Order (Settings Section, Admin Only)**
    Lists open in a defined, configurable order instead of the database's own document order, which is a UUID sequence and reads as random.

    The Settings page includes a "List Sorting" section, visible to admins only, placed directly below "User Management". The body opens with a one-line explanation that the setting controls the order a list opens in, and that clicking any column header still re-sorts that list for the current visit only.

    **The table.** One row per object that has a list page, with columns: Object (the nav label), Sort By, Direction, and Sorted Field. Sort By is a dropdown with exactly two options, "Number" and "Name". Direction is a dropdown with "Ascending" and "Descending". Both save immediately on change and show a transient confirmation. Sorted Field is read-only grey text naming the database field the choice resolves to, so the effect is never opaque.

    **How the two options resolve.** "Number" resolves to the object's auto-number field (`account_number`, `ticket_number`, …); for an object that has none, it resolves to the creation timestamp, shown as "Created". "Name" resolves to the object's primary display field — `name`, `name1`, `title`, `subject` or `label`; for people-shaped objects (Contact, Lead) it resolves to `last_name`, since a list is sorted by one field and surname order is the useful one; for document objects that have no name at all (Quotation, Sales Order, Invoice) it resolves to the same number field, and the Sorted Field column says so.

    **Default.** An object with nothing configured sorts by Number, ascending. This applies to a fresh instance with no settings saved at all.

    **Incomplete-data warning.** Records that do not have the sorted field are not returned by a sorted query at all, so they would silently disappear from the list. When a chosen combination would hide records, the row shows an amber warning chip reading "{n} hidden" with a tooltip naming the cause, and a "Fix" button that assigns the missing auto-numbers from the object's counter. The check runs when the section is expanded and after every change.

58. **Opportunity Kanban Board**
    The Opportunities list page shows a two-button toggle to the right of the page title: a table icon ("Table") and a board icon ("Kanban"). The selected display is remembered in the browser. Kanban replaces the table with a toolbar (search field filtering by opportunity and account name, "New" button) and a board below it.

    **Board.** One column per active pipeline stage in stage order, closed stages included. The board scrolls horizontally; columns share the available width (at least 240 px, at most 340 px each, so all stages fit side by side on large screens) and are as tall as the viewport allows, and its card list scrolls vertically on its own. Columns sit on a light surface with rounded corners and a 3 px top border: primary colour for open stages, success colour for the won stage, grey for the lost stage. The header shows the stage name in bold with the card count in muted text, and below it the total amount per currency in caption style ("€302,363.90 + SEK 50,658.20"). An empty column says "No opportunities" in muted text and still accepts drops.

    **Cards.** An outlined card per opportunity: the name as a link (bold, wraps), then the account as a link, the amount with its currency and the expected close date, and the owner in muted text. Alerts sit next to the name on open opportunities only: a red error icon (tooltip "Overdue activity") or an amber warning icon (tooltip "No open activity"). A menu button on the card offers "Open" and "Move to" with every other stage.

    **Moving.** Cards show a grab cursor. While dragging, the card fades and the column under the pointer is highlighted with a dashed primary outline and a light tint; holding the card near the board's left or right edge scrolls the board. Dropping on the lost stage opens a small "Close as Lost" dialog with a loss reason (common reasons plus free text) and Cancel / Save; Cancel leaves the card where it was. After a move a snackbar confirms "Moved to <stage>"; a won deal also shows the existing celebration. A move refused because another user holds the edit lock shows an error snackbar naming that user. On phones the columns are 85% of the screen wide and the card menu is the way to move a card.

## Retrofit from a customer project (2026-10-16)

Generic improvements first built in a customer project and adopted by the standard. Functional stories 65 to 74 in `specifications.md`.

59. **Reference Fields Are Links, With the Record Number**
    Every reference field on a record page shows the referenced record's name as a link that opens that record. Next to the name, in muted text, comes the record's number when its object has one ("Acme expansion #2741"), because names are not unique. Reference columns in list views and in the related lists of a record page are links as well: a click on the link opens the referenced record, a click elsewhere on the row opens the row's record; the tooltip shows object and number. Links are real addresses (UX 60), so Ctrl/Cmd-click or the middle mouse button opens the record in a new browser tab. A reference to a record the user cannot see shows the name without a link.

60. **Addresses, Browser Back and Deep Links**
    Every page has its own address, and the browser's back and forward buttons, reload and bookmarks work: `/` home; `/<Object>` the list of an object, with its state in the query (`q` search, `page`, `size`, `sort` and `dir` when they differ from the default, `fav=1` favorites only, `filter` the filter of a "View all" or dashboard list); `/<Object>/<id>` a record page; `/<Object>/new` a new record (`prefill` in the query); workspace, settings, profile and timeline pages have their own. Paging, sorting and searching replace the current address (back returns to the previous page, not to every keystroke); opening another page adds one, and back from a record returns to the same page of the list. A link opened while signed out shows the sign-in page and then the linked page; signing out on purpose starts at home again. Edit mode is not part of the address: a reload or a link opens the record read-only. Leaving a record in edit mode with unsaved changes by the browser's back button asks first (UX 68); "Stay" keeps page and address together. The browser tab shows the page's name ("Acme Corp - CRMTHREE").

61. **Favorites**
    Any record can be marked as a favorite. Favorites are personal (stored per user on the server, so they follow the user to every device) and have no fixed limit.
    - **Record page:** a star next to the record name and number in the page title: an outline star (tooltip "Add to favorites"), filled amber when the record is a favorite (tooltip "Remove from favorites"). One click toggles it.
    - **List views:** every list of the main navigation has a narrow first column with a star per row; clicking the star toggles the favorite without opening the record. "★ Favorites (n)" is a built-in list view next to "All" and the saved views (UX 78), shown as a tab by default; search, sort, paging and export work as usual. Address `view=fav`.
    - **Top bar:** a star button next to the notifications opens "Favorites": the 50 most recently marked favorites the user can still see, grouped by object, each with name and number; a click opens the record, "Show all" next to an object opens its list filtered to favorites. Deleted or no longer visible records drop out.
    Users who share one login share its favorites.

62. **Favorites on the Home Page**
    A section "★ My favorites" at the top of the home page: per object a link with its count to the list filtered to favorites ("Quotes 3 · Opportunities 2"), and the 12 newest favorites as quick links, each with its star (removes it without leaving the page), name, object and number. Without favorites the section is one line explaining the star. The section reloads after a star changes.

63. **Related Lists Show Number, Title and Status**
    The related lists on a record page show, in this order: the record number, the record's title or description (name, subject, title or description field), then the object's other list columns, at most five. The column that only points back to the record on screen (the opportunity on the opportunity's own quote list) is left out. Where an object has a more specific status than its generic one, the related list shows that status with its colour. Reference columns are links (UX 59).

64. **Related Lists Load a Limited Number of Rows**
    A record page loads the newest 100 related records per object. When there are more, the card header reads "Quotations (100 of 1,234)" and offers "View all", which opens the object's list filtered to the record with a readable filter chip ("Opportunity: Acme expansion ✕"); removing the chip shows the whole list. Documents (quote, order, invoice, contract) load their lines complete. Related lists of server-written logs (status history, call logs) have no "+ Add" button.

65. **Unavailable Actions Are Disabled and Say Why**
    An action button is disabled when the record's state or the user's rights rule it out, and its tooltip lists the reasons ("The opportunity is closed."). Reasons known from the record show at once; reasons only the server can check arrive a moment after the page opened. Reasons that depend on what the user enters still appear in the action's dialog; a dialog whose action cannot run shows only the reasons and a Close button, not a form that cannot be submitted. Applies to document conversion, lead conversion, deal room creation and every other action with preconditions.

66. **Busy Overlay**
    While an action that changes data waits for the server, the screen is covered by a transparent overlay that blocks further clicks, also over open dialogs. After 300 ms the overlay shows a spinner and the action ("Saving...", "Creating the quote..."). Typing, field edits and background calls (lock heartbeats, favorites, search) are never blocked.

67. **Dialog Layout and Pinned Dialog Messages**
    Dialogs with more than four fields use the width of the screen: up to 900 px wide, two columns of fields (one column below 700 px). Header and footer with the action buttons stay visible; only the fields scroll. Messages in a dialog (why an action is not possible, errors returned by the server) appear in a message area directly below the dialog title, outside the scrolling fields, so they stay visible while the user scrolls. A new message replaces the old one; the area takes no space when there is no message. Short confirmations and errors triggered from inside a dialog appear above the dialog, never behind it.

68. **Edit Mode Under a Server Lock and Unsaved Changes**
    A record opens read-only. "Edit" asks the server for the lock and switches to edit mode only after the server confirmed it. Everyone else sees "Being edited by <name> since <time>"; the editor sees a small "You are editing; others see it read-only" note with the idle timeout as tooltip. Administrators see "Release lock" on a record someone else edits. Leaving a record in edit mode with unsaved changes (header form or editable grids), by navigation or with the browser's back button, opens the in-app dialog "Unsaved changes" with "Stay and keep editing" and "Discard changes and leave"; browser popups are not used because users can silence them. Reload and closing the tab show the browser's own leave warning. Extends UX 54.

69. **Tables Scroll Only Their Rows**
    On every page, lists and tables scroll only their content; the page header, the search and filter bar, the table header and the paging stay visible. List views fill the screen and scroll their rows inside the list card. Tables on record pages (line items, related lists) and in Settings scroll inside their card, limited to about two thirds of the screen, with the card title, its search and buttons above and the column headers fixed on top. In dialogs the table header stays visible while the dialog scrolls. Implemented once for every table, not per screen.

70. **Code List Fields**
    A field bound to a code list shows "CODE label" in forms, record pages and lists ("YA14 Payable within 14 days"). Lists with more than 60 values are a searchable field that shows the label while typing; lists stored as arrays are multi-selects. A stored value that is not in the list stays selectable as "CODE (not in list)", so the record can still be saved. A model default that is not in the list (currency "USD" where the list has CHF and EUR) is not preselected; the user chooses.

71. **Themes and Theme Swatches**
    Themes are sets of design tokens plus a few rules each: Light, Dark, Lightning (the Salesforce Lightning look, for users coming from Salesforce) and a customer theme (colours, shapes, fallback fonts and the company name as a text wordmark) that a deployment fills. The user menu shows all themes as swatches side by side; one click applies the theme and the menu stays open. The choice is kept per browser, in addition to the Profile setting of UX 25. The navigation stays the left Ribbon in every theme. Selections and unsaved changes have their own colours, independent of the brand colour, so they never look like errors in any theme (a red brand colour included).

72. **Speed Tiles on the Home Page**
    A row of tiles shows how fast the CRM answers, measured, not estimated: the home figures' server time ("all figures, counted by the database"), the time the last record page needed from click to drawn page in this browser, and further screens a deployment measures. A tile without a measurement shows "-".

73. **Opportunity Team Card**
    The opportunity page has an "Opportunity team" card: the owner and the members with their access (Edit or Read) and team role, a short note who sees the deal ("The owner, the team and the managers above the owner see this deal and its quotes. Members with access Read cannot edit."), and for the owner, the managers above and administrators a user picker with access and "Add", and "Remove" per member. A record the user may not see answers "You do not have access to this record (it belongs to another team)." (spec 71).

74. **Approvals Card and "Approvals for Me"**
    A record under an approval workflow (spec 72) shows an "Approvals" card: "Approval check" lists which rules apply and why; "Submit for approval" and "Recall" act on them; each request shows level, approver (or delegate), state, decision, comment and time. Approvers decide with "Approve" or "Reject" and a comment in a dialog. The home page shows a tile "Approvals for me" with the number of waiting requests and the oldest ones, each opening its record.

75. **E-mail Outbox in Settings**
    Settings shows the e-mail outbox (spec 73): recipient, language, subject, state (waiting, sent, failed), attempts, last error and time, newest first, with "Retry" on failed mails. A note shows whether sending is configured and which recipients the allow-list lets through.

76. **Code List Maintenance in Settings**
    Settings lists the code lists (spec 70) with their fields; an administrator opens a list, edits codes, labels per language, order and active flag, and adds values. Changes reach open browsers at once.

77. **Integration Connections, Call Log and Job Queue in Settings**
    Settings shows every connection to an external system (spec 74) with address, login, mode (Live or Off), timeout and the last test; "Test" and "Test all" report reachability and login; the login's password is entered once and never shown again. A call log lists every call with connection, operation, record, duration, HTTP status, outcome and message, filterable and linked from the record. A job queue lists background work with state, attempts and "Retry" or "Cancel".

78. **User-Defined List Views**
    All, Favorites and saved views are one concept. "All" (the object's default columns and sort) and "★ Favorites (n)" are built-in views; users add their own. Up to five views appear as tabs in the list toolbar (All and Favorites by default; a new view becomes a tab while there is room); the open view always shows as a tab, unpinned ones in italics. A "Views" menu next to the tabs lists "Built in", "My views" and "Shared with me" (with the owner's name); each row offers "Tab" (pin or unpin), "Default" (the navigation opens the list in this view; built-in views can be the default too) and, for own views, "Edit"; "+ New view" at the bottom. "Edit view" is a dialog: name, sharing (only me, my team, everyone; everyone needs the admin right), my default and, for administrators, the default for everyone; all fields with a search, chosen columns reordered with up and down buttons (column headers can also be dragged in the table); sort (field and direction) and filters (field, a fitting operator, and the value entered like the field itself: a record picker for references, dropdowns for code lists, enums and yes/no, date fields for dates; favorites only). Only fields with a database index are offered for sort and filters, and column headers sort only on such fields. "Save" updates an own view, "Save as new view" creates one. The view is part of the address (`view=<id>`, `view=fav`, nothing for All). Changing columns or sort without saving shows "View changed · Save · Reset".

