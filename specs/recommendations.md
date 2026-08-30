# Technology Recommendations: Second Implementation

Status: **stack decided; deployment target under discussion.**

Decisions: the second implementation is an **architecture proof**. Data layer is
**Postgres** (Option A below), hosted on **Supabase**, which also supplies auth, realtime
and storage. Frontend is **Svelte 5 + SvelteKit**, and it should look deliberately
different from the Firebase implementation so the contrast is visible. Named
`postgres`, not `supabase`, because the architecture is the technology and Supabase is
the deployment target.

The Firebase implementation in `implementations/firebase/` is the reference. This
document proposes stacks for a second, parallel implementation.

**Hard constraint:** every technology and hosting platform must be free of charge, at
least for the demo deployment.

## 1. What the stack must provide

Derived from `specifications.md` and from what the Firebase implementation actually uses:

| # | Capability | Driven by | Notes |
|---|---|---|---|
| 1 | Static SPA hosting | whole app | Easy everywhere |
| 2 | Auth: email/password + Google OAuth | 18, 18b | No self-service signup; admin provisions users |
| 3 | Database: paginated, sorted, server-side count | 1-14, A25 | 35 objects, `data-model.json` |
| 4 | **Real-time subscriptions** | 17 notifications, 61 record locking, 33/34 rooms | The hardest thing to replace outside Firestore |
| 5 | Server-side compute holding secrets | 20-28 AI proxy, 59 replication, 30 external sources, 32 REST API | AI keys must never reach the browser |
| 6 | File storage | documents, business card photos | |
| 7 | Declarative authorization | 18 RBAC | Firestore rules today |

Capability 4 is the real discriminator. Everything else is commodity.

## 2. A scoping question that changes everything

`DataService` -> `DataSourceRouter` -> `FirestoreMapper` / `ExternalSourceAdapter` is
already a persistence seam (story 30). So "second implementation" can mean two very
different things:

- **(a) Backend swap.** Reuse the React app unchanged, write a new mapper behind
  `DataService`, and replace auth/storage/functions. Small, and it proves the data model
  is portable.
- **(b) Full second stack.** Regenerate frontend and backend from `specs/` on a different
  framework. Large, and it proves the *blueprint thesis*: the specification is the
  product and any stack can realise it.

(b) is the honest test of what CRMTHREE claims to be. (a) is a fraction of the work.

## 3. Options

### Option A: Supabase + React SPA
Postgres, Supabase Auth (email/password + Google), Supabase Realtime, Supabase Storage,
Edge Functions (Deno), Row Level Security. Deployed on Cloudflare Pages or Netlify.

- **Maps 1:1 onto every Firebase primitive**, including capability 4. Lowest-risk path.
- Swaps document NoSQL for relational SQL, which validates the "database-agnostic,
  SAP-compatible" claim of `data-model.json` far better than another document store.
- RLS is a stronger fit for RBAC (18) than the current blanket Firestore rules.
- Also satisfies the "Next.js: Node.js, PostgreSQL" template already named in
  `architecture.md` section 9.
- **Caveat:** free projects pause after a period of inactivity and need manual restore.
  Mitigable with a weekly keep-alive query from a scheduled job.

### Option B: Cloudflare full stack
Pages + Workers + D1 (SQLite) + R2 (storage) + Durable Objects (WebSockets for
capability 4). Auth is not included: add Better Auth, Lucia, or similar.

- Genuinely always-on, no pausing, no cold origin, commercial use permitted on free tier.
- Lowest running cost of any option, effectively zero at demo scale.
- **Most assembly required**, because auth and realtime are hand-built.
- Proves CRMTHREE runs edge-native with no origin server at all.

### Option C: PocketBase, self-hosted
One Go binary providing SQLite, auth with OAuth, realtime over SSE, file storage, rules
and an admin UI. Hosted on an always-free VM (e.g. Oracle Cloud Always Free) or a free
container host.

- Batteries-included backend: covers capabilities 2-7 out of the box, very little code.
- Proves a **self-hosted / on-premise** story: no vendor, no data leaving the customer.
  That is a real enterprise selling point (data residency, procurement).
- **You own the ops**: VM, TLS, backups, updates. Free-VM signup has friction.

### Option D: Conventional portable stack
React SPA + Node/NestJS API + Postgres (Neon free tier, scale-to-zero with automatic
resume) + Auth.js. Realtime via SSE or WebSocket on the API. Hosted on Netlify or
Cloudflare.

- No proprietary platform anywhere; the most "enterprise-recognisable" shape.
- Neon resumes automatically on connect, so no manual unpause like Option A.
- **Most total work**: the API layer, auth and realtime are all hand-written.

## 4. Free-tier traps to verify before committing

Free tiers change often. Confirm at signup rather than trusting this table.

- **Vercel Hobby is non-commercial.** For a commercial product demo, prefer Cloudflare
  Pages or Netlify.
- **Supabase free projects pause** after inactivity.
- **Render free Postgres expires**; free web services sleep.
- **Railway and Fly.io** no longer offer a meaningful always-free allowance.
- **Oracle Cloud Always Free** is genuinely free and long-lived, but signup requires a
  card and capacity for free ARM instances is often unavailable.
- Cloudflare Workers/Pages, Netlify, Neon, Turso and MongoDB Atlas M0 all permit
  commercial use on their free tiers.

## 5. Recommendation

**Option A (Supabase)** if the goal is to prove portability with the best effort-to-proof
ratio. It is the natural SQL twin of the Firebase implementation, every capability has a
direct counterpart, and it ticks the Postgres template already promised in section 9.

**Option B (Cloudflare)** if an always-on, never-paused public demo link matters more than
implementation speed.

**Option C (PocketBase)** if the more valuable story is "runs entirely on your own
infrastructure".

## 6. Open questions

1. Scope: backend swap (2a) or full second stack (2b)?
2. Must the demo be permanently reachable, or is on-demand acceptable?
3. Is the second implementation primarily a **sales proof**, an **architecture proof**, or
   an **enterprise self-hosting** story?
4. Reuse the React frontend, or deliberately choose a different frontend to prove UX
   portability too?

## 7. Frontend selection for the Supabase implementation

The Firebase implementation is React 19 + MUI 7 + Material React Table 3 + Recharts.

### Port cost is the component library, not the grid

| Dependency | Files touched (of 118) | Implication |
|---|---|---|
| Material React Table | 3 | Contained. Swappable behind `RecordListView`, `LineItemsCard`, `LinkedRecordCard` |
| MUI | 72 | Pervasive. This is the real cost of a frontend swap |
| Recharts | 4 | Contained |

### Prerequisite: the specs are not as technology-agnostic as they claim

A second stack cannot be built from `specs/` as written, because the specs name the
reference implementation's technology:

- `ux.md`: "Material React Table" x2, "MUI" x4 (Grid, Badge, Accordion, Stepper),
  "React" x3, and ~22 MUI icon identifiers such as `NotificationsNoneIcon`.
- `specifications.md`: "Firestore" x8, "Firebase" x1.

Neutralising these is spec-first work and must happen **before** the second
implementation starts. Restate them as intent ("a badge showing unread count", "a data
grid with server-side pagination", "the database") rather than as named components.
This leakage being found is the architecture proof already paying for itself.

### Candidate frontends

| Option | Paradigm distance from React | Design language | Data grid | Note |
|---|---|---|---|---|
| **Angular 20** + Angular Material + AG Grid | Highest of the mainstream options: TypeScript-mandatory, DI, RxJS/signals, opinionated framework | Material, so `ux.md` visual intent survives | AG Grid Angular, server-side row model | Enterprise and SAP-credible |
| **Svelte 5** + SvelteKit | Highest overall: compiler, runes, no virtual DOM | Not Material by default, implies visual redesign | AG Grid or hand-rolled | Smallest bundles |
| **Vue 3** + Vuetify | Lowest: closest to React | Material via Vuetify | PrimeVue / Vuetify table | Safest, weakest proof |

### Recommendation

**Angular 20 + Angular Material + AG Grid.** It maximises paradigm distance from React
while keeping the Material design language, so the UX specification stays satisfiable on
intent even as component names change. That isolates the variable being tested: this
proves the *architecture* is portable without simultaneously redesigning the UX. RxJS also
wraps Supabase realtime channels cleanly, and TypeScript is a deliberate, visible contrast
with the reference implementation's "JSX only, no TypeScript" rule.

Choose **Svelte 5** instead if the goal is to showcase a lean, modern runtime and a
redesign is acceptable. A measurable side-benefit either way: the current build is a single
2.5 MB chunk with no code splitting, so route-level lazy loading in the second
implementation gives a concrete comparison metric.

## 8. Hosting the SvelteKit application

Supabase does not host web applications, so the frontend needs a separate home. SvelteKit's
adapter model means the choice also decides the architecture, not just the address.

| Host | Adapter | Free tier | Verdict |
|---|---|---|---|
| **Cloudflare Pages / Workers** | `adapter-cloudflare` | Always on, commercial use allowed | **Recommended** |
| Netlify | `adapter-netlify` | Commercial use allowed, build minutes capped | Solid fallback |
| Vercel | `adapter-vercel` | **Hobby tier is non-commercial** | Rules it out here |
| GitHub Pages | `adapter-static` | Static only, no server routes | Only if R5 moves to Supabase |

**Recommendation: Cloudflare Pages with `adapter-cloudflare`, using SvelteKit server routes.**

The architectural reason matters more than the price. The Firebase implementation is a static
SPA that calls separate Cloud Functions. If the Postgres implementation uses SvelteKit server
routes for requirement R5, the AI proxy and the REST API move *into* the web framework
instead of living beside it. That is a genuinely different architecture rather than the same
shape with different logos, which is the point of an architecture proof. Session auth then
runs through cookies via `@supabase/ssr` rather than a client-side SDK holding the token,
which is a second real difference.

Choosing `adapter-static` instead would mirror the Firebase shape: a static bundle plus
Supabase Edge Functions for R5. Cheaper to reason about, weaker as a proof.

## 9. Making it look different

Deliberate goal: a visitor should see at a glance that this is not the same application.

- **Design system:** avoid Material. `shadcn-svelte` or Skeleton (both Tailwind-based) give a
  distinctly non-Material look. This is the main lever.
- **Data grid:** TanStack Table has a Svelte adapter and is headless, so the skin is entirely
  ours. Worth knowing that Material React Table is itself built on TanStack Table, so the
  table *engine* would be shared while the appearance diverges completely.
- Because `ux.md` is now neutral, a different visual language no longer contradicts the
  specification. Only genuine behavioural divergence would need a `postgres.ux.md`.
