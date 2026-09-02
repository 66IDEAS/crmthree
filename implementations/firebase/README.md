# CRMTHREE - Firebase reference implementation

The canonical reference implementation of the [CRMTHREE specification](../../specs/):
React 19 + Vite + MUI on Firebase (Hosting, Authentication, Firestore, Cloud Functions).

**Implemented by Claude**, working from the specification.

## Prerequisites

- Node.js 20+
- A Firebase project (Blaze plan if you want the AI proxy Cloud Function)
- `npm install -g firebase-tools`

## Setup

```bash
# 1. Firebase project config
cp .firebaserc.example .firebaserc          # put your project id in
cp app/.env.example app/.env                # paste your Firebase web app config

# 2. Install
npm install
npm --prefix app install
npm --prefix functions install

# 3. Enable in the Firebase console:
#    Authentication (Email/Password + Google), Firestore

# 4. Deploy rules, indexes, functions, hosting
firebase deploy
```

## Local development

```bash
cd app && npm run dev        # Vite dev server on http://localhost:5173
```

## Structure

| Path | Contents |
|---|---|
| `app/` | The single-page application (React + Vite + MUI) |
| `functions/` | Cloud Functions: AI provider proxy, external data source proxy |
| `firestore.rules` / `firestore.indexes.json` | Firestore security rules and indexes |

## Notes

- The first user to sign in becomes admin (bootstrap); manage further users in
  Settings → User Management.
- AI features are optional: configure a provider (OpenAI, Google, Anthropic, Moonshot)
  in Settings → AI Providers. API keys stay server-side.
- This implementation follows the spec. If it disagrees with `specs/`, that is a bug -
  please open an issue. Per [CONTRIBUTING.md](../../CONTRIBUTING.md), code PRs are not
  accepted here; spec PRs are.
