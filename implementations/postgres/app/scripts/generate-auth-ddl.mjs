#!/usr/bin/env node
/**
 * Generates DDL for the authentication tables from the installed better-auth library.
 *
 * Deliberately not using @better-auth/cli. The CLI's latest release lags the library (1.4.21
 * against 1.7.2 at the time of writing) and omits fields the runtime writes, notably
 * account.issuer, which produces a schema that type-checks and then fails at insert time.
 * Reading getAuthTables() from the installed package keeps schema and runtime in lockstep by
 * construction.
 *
 * Lives in app/ because it imports the installed better-auth; ESM resolves packages from the
 * script's own location, not the working directory.
 *
 *   cd app && node scripts/generate-auth-ddl.mjs > ../db/20-auth.sql
 */
import { getAuthTables } from 'better-auth/db';

// Namespaced because the CRM domain already defines an Account object; see
// app/src/lib/server/auth.ts. Must match the model names configured there.
const MODEL_NAMES = {
	user: { modelName: 'auth_user' },
	session: { modelName: 'auth_session' },
	account: { modelName: 'auth_account' },
	verification: { modelName: 'auth_verification' }
};

const tables = getAuthTables(MODEL_NAMES);
const tableFor = (model) => MODEL_NAMES[model]?.modelName ?? model;

const columnType = (field) => {
	switch (field.type) {
		case 'string': return 'text';
		case 'boolean': return 'boolean';
		case 'date': return 'timestamptz';
		case 'number': return 'integer';
		default: throw new Error(`Unmapped auth field type: ${field.type}`);
	}
};

const out = [];
const p = (s = '') => out.push(s);

p('-- Generated from the installed better-auth by db/generate-auth-ddl.mjs. Do not edit.');
p('-- Regenerate after upgrading better-auth.');
p();

const ordered = Object.values(tables).sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
for (const table of ordered) {
	const cols = ['  "id" text primary key'];
	for (const [name, field] of Object.entries(table.fields)) {
		const column = field.fieldName || name;
		let line = `  "${column}" ${columnType(field)}`;
		if (field.required) line += ' not null';
		if (field.unique) line += ' unique';
		if (field.references) {
			line += ` references "${tableFor(field.references.model)}" ("${field.references.field}") on delete cascade`;
		}
		cols.push(line);
	}
	p(`create table "${table.modelName}" (`);
	p(cols.join(',\n'));
	p(');');
	p();
}

for (const table of ordered) {
	for (const [i, index] of (table.indexes ?? []).entries()) {
		const cols = index.fields.map((f) => `"${table.fields[f]?.fieldName || f}"`).join(', ');
		p(`create ${index.unique ? 'unique ' : ''}index "${table.modelName}_idx_${i}" on "${table.modelName}" (${cols});`);
	}
}
p();
p('-- Reached only by the server, never by a browser, so no row level security here: the');
p('-- session lookup runs before any identity exists to filter on.');
p(`grant select, insert, update, delete on ${ordered.map((t) => `"${t.modelName}"`).join(', ')} to crm_app;`);

console.log(out.join('\n'));
