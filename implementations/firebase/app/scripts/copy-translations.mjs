/**
 * Build step: copies the product language packs (shared architecture, section 13) into
 * public/translations/ together with an index.json listing the bundled codes, so every
 * hosting deploy physically ships the packs and the in-app seeder can discover them.
 * The specs/ folder is located by walking upward, so the script works in any checkout
 * layout that keeps specs/translations at the repository root.
 */
import { cpSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const appDir = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
let dir = appDir;
let packsDir = null;
while (dir !== path.dirname(dir)) {
  const candidate = path.join(dir, 'specs', 'translations');
  if (existsSync(candidate)) { packsDir = candidate; break; }
  dir = path.dirname(dir);
}
if (!packsDir) {
  console.warn('copy-translations: no specs/translations found above', appDir, '- skipping');
  process.exit(0);
}

const outDir = path.join(appDir, 'public', 'translations');
rmSync(outDir, { recursive: true, force: true });
mkdirSync(outDir, { recursive: true });

const languages = [];
for (const file of readdirSync(packsDir).filter((f) => f.endsWith('.json')).sort()) {
  const pack = JSON.parse(readFileSync(path.join(packsDir, file), 'utf8'));
  cpSync(path.join(packsDir, file), path.join(outDir, file));
  languages.push({ code: pack.code, language_name: pack.language_name });
}
writeFileSync(
  path.join(outDir, 'index.json'),
  JSON.stringify({ codes: languages.map((l) => l.code), languages }, null, 1) + '\n'
);
console.log(`copy-translations: ${languages.length} packs -> public/translations/`);
