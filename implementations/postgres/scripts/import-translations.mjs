/**
 * Imports the language packs from specs/translations/*.json into the `translation`
 * table, replacing the stored label map wholesale (shared architecture, section 13).
 * Connects over the migration connection: MIGRATION_DATABASE_URL from the
 * environment, falling back to the app's .env.
 *
 *   node scripts/import-translations.mjs [codes...]   # default: every pack file
 */
import { createRequire } from 'node:module';
import { readFileSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const here = path.dirname(fileURLToPath(import.meta.url));
const packsDir = path.join(here, '../../../specs/translations');
const require = createRequire(path.join(here, '../app/package.json'));
const { Client } = require('pg');

let dsn = process.env.MIGRATION_DATABASE_URL;
if (!dsn) {
  try {
    const env = readFileSync(path.join(here, '../app/.env'), 'utf8');
    dsn = env.match(/^MIGRATION_DATABASE_URL=(.+)$/m)?.[1]?.trim();
  } catch { /* fall through to the error below */ }
}
if (!dsn) throw new Error('Set MIGRATION_DATABASE_URL (or put it in app/.env).');

const wanted = process.argv.slice(2);
const files = readdirSync(packsDir).filter((f) => f.endsWith('.json'))
  .filter((f) => wanted.length === 0 || wanted.includes(path.basename(f, '.json')));
if (files.length === 0) throw new Error('No pack files matched.');

const client = new Client({ connectionString: dsn });
await client.connect();
try {
  for (const file of files.sort()) {
    const pack = JSON.parse(readFileSync(path.join(packsDir, file), 'utf8'));
    await client.query(
      `insert into translation (code, language_name, labels)
       values ($1, $2, $3)
       on conflict (code) do update set language_name = excluded.language_name,
         labels = excluded.labels, updated_at = now()`,
      [pack.code, pack.language_name, JSON.stringify(pack.labels)]
    );
    console.log(`${pack.code}  ${pack.language_name}  ${Object.keys(pack.labels).length} labels`);
  }
} finally {
  await client.end();
}
