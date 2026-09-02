# CRMTHREE — Rails implementation

This is the Ruby on Rails implementation of the shared CRMTHREE specifications. It runs
self-contained on a single machine, and deploys the same way to any host that runs Ruby -
SQLite and attachments travel with the app. The
authoritative domain model remains [`../../specs/data-model.json`](../../specs/data-model.json);
Rails migrations, models, and `config/crm/model_manifest.json` are deterministic generated outputs.

## Requirements

- macOS on Apple Silicon
- Ruby 3.4.10 (the exact version is recorded in `.ruby-version`)
- SQLite 3 and standard macOS command-line tools

One convenient Ruby installation is `brew install ruby@3.4`. Ensure that Homebrew Ruby and its gem
executables are ahead of `/usr/bin` in `PATH`; `ruby --version` must report 3.4.10 or newer.

## Setup and development

```sh
bin/setup --skip-server
bin/dev
```

`bin/setup` is idempotent: it installs gems, verifies generated blueprint artifacts, prepares all
four SQLite databases, and seeds missing defaults. `bin/dev` starts Puma, Tailwind watch mode, and
Solid Queue together. No web console, hosted database, container, or deployment step is required.

Before the first sign-in, create the only initial account from the command line. A password file
keeps the password out of shell history:

```sh
umask 077
printf '%s' 'choose-a-password-of-at-least-12-characters' > tmp/admin-password
EMAIL=you@example.com FIRST_NAME=Your LAST_NAME=Name PASSWORD_FILE=tmp/admin-password bin/rails crm:auth:bootstrap
rm tmp/admin-password
bin/dev
```

Open `http://localhost:3000` and sign in. Registration does not exist. To create a local reset URL:

```sh
EMAIL=you@example.com bin/rails crm:auth:reset_link
```

The command writes a private, short-lived instruction file under `tmp/local_password_resets/`.

## AI and integrations

Administrators configure AI providers, local/external data sources, replication jobs, and
reviewable configuration proposals under **Settings**. Only one AI provider can be active. If none
is configured, AI actions stay hidden and the rest of CRMTHREE continues to work normally.

Review-first intake and replication run through Solid Queue, so use `bin/dev` rather than starting
Puma alone. Provider and external-system calls use bounded timeouts and reject private-network
destinations by default. To integrate an explicitly trusted service running on this Mac, start the
development processes with `CRM_ALLOW_PRIVATE_NETWORKS=true bin/dev`; never use that override with
untrusted URLs.

The versioned REST contract is available while the app is running at
`http://localhost:3000/api/v1/openapi` and in [`docs/openapi.yml`](docs/openapi.yml). API bearer
tokens are stored as SHA-256 digests and can be scoped, expired, or revoked; their raw value is
returned only when issued.

## Verification

```sh
bin/ci
bin/rails crm:blueprint:validate
bin/rails crm:blueprint:check
```

After changing the shared blueprint, deliberately regenerate and review its outputs:

```sh
bin/rails crm:blueprint:generate
```

## Local backups

```sh
bin/rails crm:backup:create
bin/rails crm:backup:verify ARCHIVE=storage/backups/<archive>.tar.gz
bin/rails crm:backup:restore ARCHIVE=storage/backups/<archive>.tar.gz CONFIRM=replace-development-data
```

Stop `bin/dev` before restoring. Restore first validates paths and SHA-256 checksums, creates a
pre-restore safety backup, replaces local data, and runs SQLite integrity checks.
