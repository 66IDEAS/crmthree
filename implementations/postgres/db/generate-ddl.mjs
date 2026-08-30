#!/usr/bin/env node
/**
 * Generates Postgres DDL from specs/data-model.json.
 *
 * Implements P3 of specs/postgres.architecture.md: the data model stays the single source
 * of truth and each architecture template supplies its own mapper into the target database.
 *
 * Usage: node db/generate-ddl.mjs > db/schema.sql
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const model = JSON.parse(readFileSync(resolve(here, '../../../specs/data-model.json'), 'utf8'));

/** PascalCase object name -> snake_case table name. Acronyms stay together (SLA -> sla). */
const tableName = (name) =>
	name
		.replace(/([a-z0-9])([A-Z])/g, '$1_$2')
		.replace(/([A-Z]+)([A-Z][a-z])/g, '$1_$2')
		.toLowerCase();

const enumTypeName = (obj, field) => `${tableName(obj)}_${field.name}`;
const seqName = (obj, field) => `${tableName(obj)}_${field.name}_seq`;

/** Maps a data-model field type onto a Postgres column type. */
function columnType(obj, field) {
	switch (field.type) {
		case 'uuid':
			return 'uuid';
		case 'string':
			// Auto-numbers stay strings: replicated SAP data carries alphanumeric identifiers
			// (DE10002345), which sank the integer-column design. Locally created rows get a
			// sequence-backed, zero-padded default below, so the database still assigns them.
			return `varchar(${field.length ?? 255})`;
		case 'text':
			return 'text';
		case 'integer':
			return 'integer';
		case 'decimal':
		case 'currency':
			return `numeric(${field.precision ?? 15},${field.scale ?? 2})`;
		case 'boolean':
			return 'boolean';
		case 'date':
			return 'date';
		case 'datetime':
			return 'timestamptz';
		case 'json':
			return 'jsonb';
		case 'enum':
			return enumTypeName(obj, field);
		case 'reference':
			return 'uuid';
		default:
			throw new Error(`Unmapped field type "${field.type}" on ${obj}.${field.name}`);
	}
}

function defaultClause(obj, field) {
	if (field.type === 'string' && field.auto_generated)
		return ` default lpad(nextval('${seqName(obj, field)}')::text, ${field.length ?? 10}, '0')`;
	if (field.default === undefined) return '';
	if (typeof field.default === 'string' && field.type !== 'enum') return ` default '${field.default}'`;
	if (field.type === 'enum') return ` default '${field.default}'::${enumTypeName(obj, field)}`;
	return ` default ${field.default}`;
}

const out = [];
const p = (s = '') => out.push(s);

p('-- Generated from specs/data-model.json by db/generate-ddl.mjs. Do not edit by hand.');
p(`-- Model version: ${model.version ?? 'unspecified'}`);
p(`-- ${Object.keys(model.objects).length} objects`);
p();
p('create extension if not exists "pgcrypto";');
p();

// 1. Enum types. Declared before the tables that use them.
p('-- Enumerations. Invalid values are rejected by the database, not by convention.');
for (const [obj, def] of Object.entries(model.objects)) {
	for (const f of def.fields) {
		if (f.type !== 'enum') continue;
		const values = f.values.map((v) => `'${v.replace(/'/g, "''")}'`).join(', ');
		p(`create type ${enumTypeName(obj, f)} as enum (${values});`);
	}
}
p();

// 2. Sequences backing auto-generated numbers.
p('-- Auto-number sequences. See P3: sequences replace zero-padded strings.');
for (const [obj, def] of Object.entries(model.objects)) {
	for (const f of def.fields) {
		if (f.type === 'string' && f.auto_generated) p(`create sequence ${seqName(obj, f)} start 1;`);
	}
}
p();

// 3. Tables, without foreign keys. Constraints are added afterwards so that circular and
//    self-referencing relationships (Account.parent_account_id, created_by -> UserProfile)
//    need no topological ordering.
const fks = [];
const indexes = [];
for (const [obj, def] of Object.entries(model.objects)) {
	const table = tableName(obj);
	const cols = [];
	for (const f of [...model.common_fields, ...def.fields]) {
		let line = `  ${f.name} ${columnType(obj, f)}`;
		if (f.primary_key) line += ' primary key';
		if (f.name === 'id') line += ' default gen_random_uuid()';
		if (f.required && !f.primary_key) line += ' not null';
		if (f.unique && !f.primary_key) line += ' unique';
		line += defaultClause(obj, f);
		cols.push(line);
		if (f.type === 'reference' && f.target) {
			// Deferrable, because the object graph contains cycles: every row carries
			// created_by -> UserProfile, and UserProfile.role_id -> Role whose own
			// created_by points back at UserProfile. Seeding the first user and the
			// default roles is therefore a single transaction. See db/README.md.
			fks.push(
				`alter table ${table} add constraint ${table}_${f.name}_fk ` +
					`foreign key (${f.name}) references ${tableName(f.target)}(id) ` +
					`deferrable initially deferred;`
			);
			indexes.push(`create index ${table}_${f.name}_idx on ${table} (${f.name});`);
		}
	}
	p(`-- ${def.description ?? obj}`);
	p(`create table ${table} (`);
	p(cols.join(',\n'));
	p(');');
	p();
}

p('-- Foreign keys, added after all tables exist.');
fks.forEach(p);
p();
p('-- Indexes on foreign keys, which list views filter and join on.');
indexes.forEach(p);
p();
p('-- Row Level Security (P7). Policies are defined per table in db/policies.sql;');
p('-- enabling RLS with no policy denies all access, which is the correct default.');
for (const obj of Object.keys(model.objects)) {
	p(`alter table ${tableName(obj)} enable row level security;`);
}

console.log(out.join('\n'));
