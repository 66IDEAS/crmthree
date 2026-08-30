# Technical Architecture — CRM System

## Delivery Model

### 1. Blueprint-Based Delivery
The product is not shipped as source code or compiled software. It is shipped as a structured set of blueprints (specifications, data model, UX templates, architecture templates, deployment templates, and test templates) that an AI coding agent uses to generate the complete application for each customer.

### 2. Customer Workflow
The customer imports a Claude Code skill that guides them through the full process: select or customize specifications, select or customize a UX template, select or customize an architecture template, select or customize a deployment template, then run the build to generate a working CRM application.

### 3. Customization Before Build
Customers can modify any blueprint before building: add or remove user stories from the specifications, adjust the data model, change UX templates, select a different architecture, or create their own architecture template from scratch.

### 4. Rebuild and Evolution
The system supports rebuild at any time. Customers can change specifications (add features), switch architectures (move from Firebase to Azure), change UX templates, or modify deployment targets — then regenerate the application.

### 5. Update Mechanism
The skill checks a central Git repository for updates to specifications, data model, architecture templates, UX templates, and deployment templates. When updates are available, the skill downloads and merges them into the customer's customized version.

## Product Package

### 6. Specifications
Functional requirements defined as numbered user stories with acceptance criteria. Technology-agnostic. Customizable by the customer before build.

### 7. Data Model
Database-agnostic data model defined in JSON. Describes all objects, fields, types, lengths, relationships, and constraints. SAP-compatible field types and lengths for shared objects (Business Partners, Materials, Notifications). Each architecture template maps this model to its specific database technology.

**Reference:** `specs/data-model.json` (35 objects, all field definitions, SAP annotations, relationships)

### 8. UX Templates
Multiple templates that define both the visual look-and-feel and the structural layout of the generated application. Customers can select, modify, or create their own UX templates. Templates control styling, theming, visual design, and structural layout choices (e.g., sidebar navigation vs. top navigation, card-based vs. table-based views, dashboard arrangements).

### 9. Architecture Templates
Each architecture template defines the full technical stack: frontend framework, backend runtime, database, authentication, storage, and AI integration. Templates are self-contained and include all technology-specific implementation patterns. Shipped templates include:
- Google Cloud: Firebase Hosting, Cloud Functions, Firestore, Firebase Auth, Firebase Storage
- Microsoft Azure: .NET, Azure SQL / MS SQL, Azure AD
- Next.js: Node.js, PostgreSQL
- Customers can create their own architecture templates

### 10. Deployment Templates
Each architecture template includes one or more deployment configurations. These define how the generated application is deployed to its target environment (e.g., Firebase deploy, Azure App Service, Docker, Vercel).

### 11. Test Templates
Each architecture template includes test protocols and test templates. Tests are generated alongside the application code and are specific to the architecture's technology stack (e.g., Jest for Node.js, xUnit for .NET).

### 12. The Skill
A single Claude Code skill that orchestrates the entire customer journey: blueprint selection, customization, build, deployment, and updates. The skill is trained to generate correct implementations for each architecture template.

## Data Architecture

### 14. Database-Agnostic Data Model
The data model is defined in a JSON schema that is independent of any database technology. Each architecture template includes a mapper that translates the JSON data model into the target database structure (e.g., Firestore collections, SQL tables, PostgreSQL schemas).

**Reference:** `specs/data-model.json`

### 15. SAP-Compatible Field Definitions
Fields on shared objects (Accounts/Business Partners, Products/Materials, Tickets/Notifications) use SAP-compatible types and lengths in the JSON data model. This ensures data exchanged between the CRM and SAP requires no truncation or type conversion.

**Reference:** SAP annotations (sap_field, sap_type, sap_equivalent) on Account, Contact, Product, Quotation, SalesOrder, Invoice, LineItem, Asset, PricebookEntry → `specs/data-model.json`

## Implementation Requirements

Every implementation, whatever its stack, must provide the capabilities below. How each one
is realised is documented in that implementation's own architecture file
(`firebase.architecture.md`, `postgres.architecture.md`, and so on).

| # | Capability | Driven by |
|---|---|---|
| R1 | Hosting for the web application. Whether it is a static bundle or server-rendered is an implementation choice | whole product |
| R2 | Authentication with email/password and Google sign-in. No self-service registration; accounts are provisioned by an administrator | 18, 18b, 62 |
| R3 | A database supporting server-side pagination, sorting and record counts across the objects in `data-model.json` | 1-14, 63 |
| R4 | Real-time subscriptions that push changes to connected clients | 17, 61, 33, 34 |
| R5 | Server-side execution able to hold secrets, so provider API keys never reach the browser | 20-28 |
| R6 | File storage for documents, attachments and business card photos | 19, 50 |
| R7 | Declarative, server-enforced authorization tied to the signed-in user's role | 18 |
| R8 | Outbound HTTP for reading from and writing to external systems of record | 30, 31, 59 |
| R9 | A public REST interface over the same data | 32 |

Requirement R4 is the discriminating one: it is the capability most likely to have no direct
equivalent outside the reference stack. Where any capability has no direct equivalent, the
implementation's own architecture document must state how it is substituted.

**Naming.** Stack-specific architecture documents are named for the **technology**, not for
the hosting platform, because section 10 already treats deployment as a separate concern: a
Postgres implementation can be hosted on Supabase, on Neon, or self-hosted without its
architecture changing. `firebase.architecture.md` is the deliberate exception, because
Firestore exists only on Google's platform, so there technology and platform are genuinely
inseparable. Each implementation's folder under `implementations/` uses the same name as its
architecture document.
