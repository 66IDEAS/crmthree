/**
 * Regenerates the embedded data blocks of index.html from the shared blueprint (PL6):
 *  - #c3m: the model registry derived from specs/data-model.json plus navigation and
 *    curated list columns, with labels matching the shared catalog English.
 *  - #c3p: the English label catalog, gzip+base64 - the source text for the label editor
 *    and for AI translation. Other languages are added inside the app (D8).
 * Regeneration is deliberate and reviewed: run, diff, commit.
 *   node scripts/generate-model.mjs
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { gzipSync } from 'node:zlib';
import path from 'node:path';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(here, '../../..');
const model = JSON.parse(readFileSync(path.join(root, 'specs/data-model.json'), 'utf8'));

const humanize = (n) => n.split('_').map(w => w[0].toUpperCase() + w.slice(1)).join(' ');
const label = (f) => f.description || humanize(f.name);
const snake = (t) => t.replace(/([a-z0-9])([A-Z])/g, '$1_$2').toLowerCase();

// The reference navigation set defines the ribbon and the object.* catalog keys.
const NAV = [
  ['Account', 'Accounts'], ['Contact', 'Contacts'], ['Lead', 'Leads'],
  ['Opportunity', 'Opportunities'], ['DealRoom', 'Deal Rooms'], ['Quotation', 'Quotes'],
  ['SalesOrder', 'Sales Orders'], ['Invoice', 'Invoices'], ['Product', 'Products'],
  ['Activity', 'Activities'], ['Ticket', 'Tickets'], ['CaseRoom', 'Case Rooms'],
  ['KnowledgeArticle', 'Knowledge'], ['Asset', 'Assets'], ['SLA', 'SLAs'],
  ['ServiceContract', 'Contracts']
];

// Curated list columns where the model-order heuristic picks badly (shared product habit).
const COLS = {
  Account: ['account_number', 'name1', 'city', 'country', 'industry_description', 'status'],
  Contact: ['contact_number', 'first_name', 'last_name', 'email', 'phone', 'status'],
  Lead: ['lead_number', 'first_name', 'last_name', 'company', 'email', 'status'],
  Opportunity: ['opportunity_number', 'name', 'account_id', 'amount', 'expected_close_date', 'result'],
  Quotation: ['quotation_number', 'account_id', 'status', 'valid_to', 'total_amount'],
  SalesOrder: ['order_number', 'account_id', 'status', 'order_date', 'total_amount'],
  Invoice: ['invoice_number', 'account_id', 'status', 'due_date', 'total_amount'],
  Product: ['product_number', 'name', 'product_group', 'unit_of_measure', 'base_price', 'status'],
  Activity: ['activity_number', 'type', 'subject', 'status', 'due_date'],
  Ticket: ['ticket_number', 'subject', 'account_id', 'priority', 'status_id'],
  DealRoom: ['deal_room_number', 'name', 'opportunity_id', 'status'],
  KnowledgeArticle: ['article_number', 'title', 'category', 'status'],
  Asset: ['asset_number', 'name', 'account_id', 'serial_number', 'status'],
  SLA: ['sla_number', 'name', 'priority_level', 'response_time_hours', 'active'],
  ServiceContract: ['contract_number', 'name', 'account_id', 'start_date', 'end_date', 'status']
};

const objects = {};
for (const [type, def] of Object.entries(model.objects)) {
  const fields = def.fields.map(f => {
    const e = { k: f.name, l: label(f) };
    if (f.type !== 'string') e.t = f.type;
    if (f.required) e.q = 1;
    if (f.auto_generated) e.a = 1;
    if (f.length) e.len = f.length;
    if (f.values) e.o = f.values;
    if (f.target) e.r = f.target;
    if (f.default !== undefined) e.d = f.default;
    return e;
  });
  const numField = def.fields.find(f => f.auto_generated && f.name.endsWith('_number'));
  const byName = new Set(def.fields.map(f => f.name));
  let cols = COLS[type];
  if (!cols) {
    cols = [];
    if (numField) cols.push(numField.name);
    for (const f of def.fields) {
      if (cols.length >= 6) break;
      if (cols.includes(f.name)) continue;
      if (['text', 'json'].includes(f.type)) continue;
      if (f.name.endsWith('_id') && !['account_id'].includes(f.name)) continue;
      cols.push(f.name);
    }
  }
  cols = cols.filter(c => byName.has(c) || c.endsWith('_id'));
  const linked = [];
  for (const rel of def.relationships || []) {
    if (rel.type === 'one-to-many' && rel.foreign_key) {
      const entry = { t: rel.target, k: rel.foreign_key, l: humanize(rel.name), n: rel.name };
      if (rel.condition) {
        const m = rel.condition.match(/^(\w+)\s*=\s*'([^']+)'$/);
        if (m) entry.w = { f: m[1], v: m[2] };
      }
      linked.push(entry);
    } else if (rel.type === 'many-to-many' && rel.through && model.objects[rel.through]) {
      const jf = new Set(model.objects[rel.through].fields.map(f => f.name));
      const a = snake(type) + '_id', b = snake(rel.target) + '_id';
      if (jf.has(a) && jf.has(b)) {
        linked.push({ t: rel.target, m: rel.through, a, b, l: humanize(rel.name), n: rel.name });
      }
    }
  }
  objects[type] = { f: fields, c: cols, x: linked, ...(numField ? { n: numField.name, nl: numField.length || 10 } : {}) };
}

const registry = { o: objects, nav: NAV };

// Only the English catalog is embedded (divergence D8): it is the source text the label
// editor shows and the AI translates from. The eight product language packs are NOT bundled -
// they would be ~127 kB of the file, and a language is added in the app in one step, either by
// AI-translating this catalog or by importing a pack from specs/translations/.
const railsCatalog = JSON.parse(readFileSync(path.join(root, 'implementations/rails/config/crm/catalog.en.json'), 'utf8'));
const packs = { en: { n: 'English', l: railsCatalog } };
const packBlob = gzipSync(Buffer.from(JSON.stringify(packs)), { level: 9 }).toString('base64');

const html = readFileSync(path.join(here, '../index.html'), 'utf8');
const modelTag = `<!--C3MODEL--><script id="c3m" type="application/json">${JSON.stringify(registry)}</script>\n  <script id="c3p" type="application/base64">${packBlob}</script><!--/C3MODEL-->`;
let out;
if (html.includes('<!--C3MODEL-->')) {
  out = html.replace(/<!--C3MODEL-->[\s\S]*?<!--\/C3MODEL-->/, modelTag);
} else {
  out = html.replace('  <script>\n  (function()', `  ${modelTag}\n  <script>\n  (function()`);
  if (!out.includes('<!--C3MODEL-->')) throw new Error('insertion anchor not found');
}
writeFileSync(path.join(here, '../index.html'), out);
console.log(`model: ${Object.keys(objects).length} objects, catalog: ${Object.keys(railsCatalog).length} keys (${(packBlob.length / 1000).toFixed(0)} kB base64)`);
