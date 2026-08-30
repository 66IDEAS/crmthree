-- Generated from the installed better-auth by db/generate-auth-ddl.mjs. Do not edit.
-- Regenerate after upgrading better-auth.

create table "auth_user" (
  "id" text primary key,
  "name" text not null,
  "email" text not null unique,
  "emailVerified" boolean not null,
  "image" text,
  "createdAt" timestamptz not null,
  "updatedAt" timestamptz not null
);

create table "auth_session" (
  "id" text primary key,
  "expiresAt" timestamptz not null,
  "token" text not null unique,
  "createdAt" timestamptz not null,
  "updatedAt" timestamptz not null,
  "ipAddress" text,
  "userAgent" text,
  "userId" text not null references "auth_user" ("id") on delete cascade
);

create table "auth_account" (
  "id" text primary key,
  "issuer" text not null,
  "accountId" text not null,
  "providerId" text not null,
  "userId" text not null references "auth_user" ("id") on delete cascade,
  "accessToken" text,
  "refreshToken" text,
  "idToken" text,
  "accessTokenExpiresAt" timestamptz,
  "refreshTokenExpiresAt" timestamptz,
  "scope" text,
  "password" text,
  "createdAt" timestamptz not null,
  "updatedAt" timestamptz not null
);

create table "auth_verification" (
  "id" text primary key,
  "identifier" text not null,
  "value" text not null,
  "expiresAt" timestamptz not null,
  "createdAt" timestamptz not null,
  "updatedAt" timestamptz not null
);

create unique index "auth_account_idx_0" on "auth_account" ("issuer", "accountId");

-- Reached only by the server, never by a browser, so no row level security here: the
-- session lookup runs before any identity exists to filter on.
grant select, insert, update, delete on "auth_user", "auth_session", "auth_account", "auth_verification" to crm_app;
