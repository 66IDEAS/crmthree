# Plain UX Requirements

This document defines the user interface and interaction design for the **Plain** implementation, mapping the requirements in `ux.md` into a zero-dependency, ultra-compact single-file web application.

---

## 1. Visual Styling & Design Tokens

### UX-P1. Modern & Clean Visual Style
The application adheres strictly to the official CRMTHREE color palette and typography using pure CSS custom properties defined in a single root stylesheet. No external CSS frameworks, web fonts, or icon libraries are loaded.

```css
:root {
  --bg: #F8F9FA;
  --surface: #FFFFFF;
  --border: #E5E7EB;
  --text: #111827;
  --text-muted: #6B7280;
  --primary: #2E62E8;
  --primary-hover: #1E4FC2;
  --accent: #F7941D; /* C3 Orange */
  --success: #10B981;
  --warning: #F59E0B;
  --danger: #EF4444;
  --font: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
}

[data-theme="dark"] {
  --bg: #121418;
  --surface: #1E2229;
  --border: #2D333F;
  --text: #F3F4F6;
  --text-muted: #9CA3AF;
  --primary: #487DF8;
  --primary-hover: #2E62E8;
  --accent: #F7941D;
}
```

- **Theme Switching:** Configured on the Profile page (Light / Dark / System). The preference is persisted in `localStorage` (`c3.cfg.theme`) and applied immediately via `document.documentElement.setAttribute('data-theme', ...)`.
- **Branding:** The official CRMTHREE wordmark is inlined as SVG in the file itself. It carries no fixed colours: the word mark paints in `currentColor` and the accent word in `var(--primary)`, so one copy serves both themes. The browser tab icon is the 66 mark, inlined as an SVG data URI. The bold orange rule under the top bar remains the accent element.
- **No emoji:** all interface affordances use inline SVG icons. Emoji appear only in gamification surfaces (streak flame, leaderboard medals, badge glyphs), where they are content rather than iconography.

---

## 2. Application Shell

### UX-P2. Top Bar
Fixed at the top of the viewport with a bold **3px orange line (`#F7941D`)** along the bottom edge:
- **Left:** Clickable CRMTHREE wordmark linking to the Home Dashboard.
- **Right (from left to right):**
  1. **Gamification Status:** XP Total counter, Level name chip (e.g. `Rookie`), and Streak indicator with fire icon (`🔥 3d`). On mobile devices, this group is hidden to conserve space. Clicking the trophy icon navigates to `/leaderboard`.
  2. **Notification Bell:** Bell icon with a red badge displaying the unread notification count. Clicking toggles the notification popover.
  3. **User Profile Avatar:** Displays user initials. Clicking toggles a dropdown menu with links to "Profile", "My Timeline", and "Sign Out" (profile switcher).

### UX-P3. Left Ribbon Navigation
The rail itself never scrolls: only its navigation list does, with its scrollbar suppressed so that platform scrollbar settings (macOS "always show scrollbars") cannot cover the icons. The Settings item stays pinned and visible above the bottom bar at every viewport height.
A vertical navigation rail on the left side:
- **Top Toggle:** Hamburger button with an orange icon (`#F7941D`). Clicking toggles between collapsed (icons-only, 56px wide) and expanded (icons + labels, 200px wide). The default initial state is **collapsed**.
- **Navigation Items:** Accounts, Contacts, Leads, Opportunities, Deal Rooms, Quotes, Sales Orders, Invoices, Products, Activities, Tickets, Case Rooms, Knowledge, Assets, SLAs, and Contracts - the reference implementation's ribbon set.
- **Settings:** Pinned to the bottom of the rail, separated by a thin horizontal border.
- **Mobile Behavior:** On viewports under 768px, the ribbon is hidden off-canvas. Tapping the top hamburger opens the ribbon as a sliding overlay; selecting an item navigates and auto-closes the overlay.

### UX-P4. Persistent Bottom AI / Search Bar
Fixed at the bottom of every screen:
- Left label: **"Ask"** (hidden on mobile).
- Centered input field: `placeholder="Ask AI or search across all records... (Ctrl+K)"`.
- **Smart Query Heuristics:**
  - Short keywords or numbers trigger an immediate debounced multi-collection search. Results display in a scrollable drop-up panel grouped by entity type (up to 5 records per group).
  - Queries containing question words (`who`, `what`, `where`, `why`, `how`), question marks (`?`), or 4+ words are routed to the AI Assistant drop-up chat upon pressing Enter.
- **AI Chat Thread:** Displays a scrollable conversation bubble thread (user queries right-aligned in primary blue; AI answers left-aligned with an orange sparkle icon). Follow-up questions maintain multi-turn context.
- Focused instantly with `Ctrl+K` / `Cmd+K`; dismissed with `Escape`.

### UX-P5. Main Content Area & Sticky Headers
Occupies the viewport space between the Top Bar, Ribbon, and Bottom AI Bar:
- Scrollable content area with subtle custom scrollbars.
- **Breadcrumb Navigation:** Displays the last 5 visited detail pages as clickable links above the content.
- **Sticky Page Headers:** List titles, filter toolbars, and record detail action headers remain pinned at the top of the content area while cards and tables scroll smoothly beneath them.

---

## 3. Record Detail View

### UX-P6. Record Detail Header
Single compact row at the top of the page:
- **Back Button:** Navigates to the previous view.
- **Headline Title:** Primary record name (`name`, `name1`, or `first_name + last_name`). For document-type objects lacking a name (Quotation, Sales Order, Invoice), displays `Auto-Number (Account Name)` — e.g. `10 (Acme Corp)`.
- **Auto-Number Chip:** Formatted without leading zeros (`10` instead of `0000000010`).
- **Lock Indicator:** When another browser tab is editing this record, shows a lock icon with `"{User} is editing"` and disables the Edit button.
- **Action Buttons:** Outlined `Edit` and `Delete` buttons.

### UX-P7. AI Briefing Card
Positioned directly beneath the detail header:
- Header displays an orange sparkle icon, "AI Briefing" title, and an outlined **"Generate Briefing"** button.
- Clicking sends the current record data to the configured AI provider. While waiting, an inline CSS spinner shows *"Generating briefing..."*.
- The briefing displays 3–5 actionable insights (pipeline stage risks, relationship summary, or SLA urgency). An expand/collapse arrow and a refresh icon allow toggling and re-generation.
- If no AI key is configured, the card shows a subtle prompt directing the user to Settings.

### UX-P8. Quick Action Bar
Horizontal row of compact outlined icon buttons placed above the Details card:
- **Activities:** `Log Call`, `Log Email`, `Log Meeting`, `New Task` (pre-links parent record).
- **Conversions:**
  - Opportunity: `+ New Quote`, `+ New Order`.
  - Quotation: `+ New Order`.
  - Sales Order: `+ New Invoice`.
  - Lead: `Convert Lead` (disabled if status is already "Converted").

### UX-P9. Details Card with Progressive Disclosure
- Clean two-column grid showing bold field labels and formatted values.
- **Read Mode:** Empty/null fields are hidden to minimize clutter. Long-text fields (knowledge article content, descriptions, notes) render their Markdown - headings, emphasis, lists, quotes, code and links - rather than showing the raw source.
- **Edit Mode:** the read-only card is **replaced** by the form in place; the record is never shown twice. All fields display native input elements (`<input>`, `<select>`, `<textarea>`), except references (see UX-P18). Form validation messages display human-readable labels (e.g. *"Account Name is required"*).
- Fields identifying the assigned user default to the signed-in user on creation.
- Primary actions switch to `Save` (primary blue) and `Cancel` (subtle gray).

### UX-P18. Reference Pickers
**Every lookup into business data uses one picker** - accounts, contacts, opportunities, leads, assets, products, tickets and any other referenced object, on forms, inside the line-item grid, and in the link dialog. A plain dropdown over a list of every account or product is unusable at hundreds or thousands of records.

The picker is a text input that filters candidates as the user types, shows the first 50 matches with a "keep typing" hint beyond that, supports arrow-key and Enter selection, and offers a clear control. The selected id is submitted through a hidden field.

**What it matches:** the display name, the auto-number, and every plain-text column the target object's own list view shows - so a contact is found by email, an account by city, a product by its group. That column is also shown beside each candidate as a disambiguating hint, which keeps lookup and list views consistent: what you can see in a list is what you can search by in a lookup.

**Dependent pickers:** on documents that carry both, the contact picker is filtered to contacts of the currently selected account, re-evaluated each time it opens. In the line-item grid, choosing a product adopts that product's list price; a price typed afterwards stands until the product is changed again.

**Placement:** the candidate list is rendered in a top-level layer rather than inside the field's card, so no panel, table or scrolling region can clip it. It opens below the field, flips above when there is more room there, shrinks to fit rather than being cut off, and tracks scrolling while open.

**Empty by default:** a newly added line item has no product and no price; its picker is marked until one is chosen, and a document whose line items still lack a product cannot be saved.

Plain dropdowns remain correct for **enums** (short, fixed, defined by the model) and for small administrator-curated configuration lists - ticket status, role, pipeline stage, language, page size. Those are state choices, not lookups into business data.

### UX-P10. Inline Line-Item Editing
Opportunity, Quotation, Sales Order, and Invoice **creation forms and** detail pages display an inline line-item grid directly below the Details card, **in read and edit mode alike** - a document is its header and its items together. While items exist the document total is read-only in the header form, mirrors the grid as rows change, and is recomputed from the items on save, since it is derived from them. On the creation form the grid edits draft rows held in memory and writes them - with their item numbers and the document total - in the same step that creates the document, so a quote is entered header-and-items in one pass:
- **Columns:** `Item #` | `Product` | `Quantity` | `Net Price` | `Discount %` | `Net Value` | `Action`.
- Item numbers auto-sequence in SAP style (`10`, `20`, `30...`).
- Net value auto-calculates live as user edits quantity or discount: `qty * price * (1 - discount/100)`.
- Table footer displays the bold, right-aligned **Total Net Amount**.
- Each row includes a small trash icon to remove the item.

### UX-P11. Linked Record Cards
- One-to-many cards (e.g. an account's **Contacts**, the contacts whose primary account this is) offer "+ Add" to create a pre-linked record.
- Many-to-many cards (e.g. an account's **Additional Contacts** through the `ContactAccount` junction - contacts associated with the account without belonging to it) additionally offer **Link**, which opens a picker of records not yet linked, and an unlink control per row.
Stacked vertically below the Details card:
- Displays associated entities (e.g. Contacts for an Account, Activities for a Deal, Tickets for an Asset).
- Compact table with column sorting and row click navigation.
- Header includes `+ Add New` (opens creation form pre-linked to parent) and `Link Existing` (opens lookup dialog for many-to-many relationships).

---

## 4. List Views & Data Grids

### UX-P12. Table-Based List View
- Clean HTML `<table>` rendering with striped hover states.
- **Default Columns:** Shows the 5 most critical columns (First column: Auto-number without leading zeros; Second column: Name/Subject; Status chip; Owner; Updated date).
- **Default Sorting:** Governed by admin configuration in Settings (Story 63 / UX 57): default sort resolves to either `Number` or `Name`, ascending or descending. Clicking column headers toggles ad hoc sorting.
- **Pagination Toolbar:** Compact footer showing `Showing 1–25 of 142 records`, `Previous` / `Next` buttons, and a page-size selector (`25 / 50 / 100`).
- **Export Action:** "Export CSV" button immediately triggers a client-side Blob download.

### UX-P13. Semantic Status Chips
Enumerated fields are rendered as filled, rounded badges with white text:
- **Green (`--success`):** `Active`, `Won`, `Completed`, `Paid`, `Low` priority.
- **Orange (`--warning`):** `In Progress`, `In Review`, `Contacted`, `Medium` priority.
- **Red (`--danger`):** `Inactive`, `Lost`, `Rejected`, `Overdue`, `High` / `Critical` priority.
- **Blue (`--primary`):** `New`, `Draft`, `Open`, `Planned`.
- **Gray (`--text-muted`):** Neutral enums (company size, lead source, activity type).

---

## 5. Workspaces & Gamification

### UX-P14. Deal Room & Case Room Workspaces
Dedicated split-pane layout:
- **Header:** Workspace title, auto-number, status badge, and close button.
- **Stage Stepper:** Visual horizontal milestone stepper highlighting current pipeline/ticket stage.
- **Left Pane (65% width):** Activity timeline feed (calls/emails/meetings) + Team comment thread with avatar, timestamp, and message input.
- **Right Pane (35% width):** Deal/Case summary card, linked key contacts with roles, and attached documents.

### UX-P15. Home Dashboard & Micro-Charts
Rendered with pure inline SVG and CSS bars (zero third-party chart libraries):
- **Row 1 (KPIs):** Pipeline Value, Open Opportunities, Open Tickets, Open Leads, Activities This Week, Leaderboard Preview.
- **Row 2 (Charts):**
  - *Opportunities by Stage:* Horizontal SVG bar chart with color-coded stages and value labels.
  - *Tickets by Priority:* Circular SVG donut chart with center total.
- **Row 3 (Charts):**
  - *Activity Trend:* SVG polyline line chart showing 7-day activity volume.
  - *Revenue by Status:* Vertical bar chart comparing paid vs open invoices.

### UX-P16. Gamification Displays & Confetti
- **Trophy Case:** Profile page displays earned badges in vibrant color; unearned badges are muted with a lock icon.
- **Leaderboard Page:** Table of users ranked by XP, deals won, and tickets resolved with Gold/Silver/Bronze crown medals for the top 3.
- **Celebration Confetti:** Triggered when closing a deal as "Won", leveling up, or earning a badge. Injected as a 15-particle CSS keyframe animation overlay that flutters across the screen for 2.5 seconds without blocking user clicks.

---

## 6. Dialogs & Conversion Flows

### UX-P17. Native `<dialog>` Modals
All dialogs use the HTML5 `<dialog>` element with backdrop blur:
- **Lead Conversion:** Modal displaying Contact preview (read-only), Account name (editable), and optional Opportunity checkbox + name. Clicking "Convert" runs the transaction and navigates to the new record.
- **Document Conversion:** Modal summarizing source document line items, target document type, and mapped totals.
- **CSV Data Import:** Admin modal with file dropzone, 5-row preview table, CRM field-to-column mapper, and import progress bar.
- **User Management Invite:** Admin modal for email, first/last name, and role assignment.

---

## 7. Responsive Mobile Adaptations

On viewports below 768px:
1. Ribbon navigation collapses into a slide-over mobile drawer toggled by the hamburger button.
2. List views hide secondary columns, displaying only Auto-Number, Display Name, and Status chip.
3. Two-column detail cards and workspace layouts stack vertically into a single column.
4. Top Bar gamification elements collapse to conserve space, keeping only the wordmark, bell, and avatar.
5. Bottom AI search bar shortens placeholder text and hides the "Ask" label.
6. Dialogs expand to full screen (`width: 100vw; height: 100vh; border-radius: 0;`).

