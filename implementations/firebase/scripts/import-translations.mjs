/**
 * Imports the language packs from specs/translations/*.json into a Firestore instance
 * as `translations/<code>` documents, replacing each document wholesale (shared
 * architecture, section 13). Works against any instance of this implementation:
 *
 *   FIREBASE_TOKEN=$(gcloud auth print-access-token) \
 *     node scripts/import-translations.mjs --project <project-id> [codes...]
 *
 * The token needs Firestore access on the target project; any OAuth bearer token
 * for an authorized user or service account works.
 */
import { readFileSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const here = path.dirname(fileURLToPath(import.meta.url));
const packsDir = path.join(here, '../../../specs/translations');

const args = process.argv.slice(2);
const projectIdx = args.indexOf('--project');
if (projectIdx === -1 || !args[projectIdx + 1]) throw new Error('Usage: --project <project-id> [codes...]');
const project = args[projectIdx + 1];
const wanted = args.filter((a, i) => i !== projectIdx && i !== projectIdx + 1);

const token = process.env.FIREBASE_TOKEN;
if (!token) throw new Error('Set FIREBASE_TOKEN to an OAuth bearer token for the target project.');

const files = readdirSync(packsDir).filter((f) => f.endsWith('.json'))
  .filter((f) => wanted.length === 0 || wanted.includes(path.basename(f, '.json')));
if (files.length === 0) throw new Error('No pack files matched.');

for (const file of files.sort()) {
  const pack = JSON.parse(readFileSync(path.join(packsDir, file), 'utf8'));
  const labelFields = Object.fromEntries(
    Object.entries(pack.labels).map(([k, v]) => [k, { stringValue: v }])
  );
  const doc = {
    fields: {
      language_name: { stringValue: pack.language_name },
      labels: { mapValue: { fields: labelFields } },
      updated_at: { stringValue: new Date().toISOString() },
    },
  };
  const url = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/translations/${pack.code}`;
  const res = await fetch(url, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(doc),
  });
  if (!res.ok) throw new Error(`${pack.code}: HTTP ${res.status} ${await res.text()}`);
  console.log(`${pack.code}  ${pack.language_name}  ${Object.keys(pack.labels).length} labels -> ${project}`);
}
