import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import ModelRegistry from '$lib/model/ModelRegistry';
import PostgresMapper from '$lib/server/PostgresMapper';
import { fieldLabel } from '$lib/display';
import { validateObject } from '$lib/model/validators';

/**
 * CSV export and import (story 19).
 *
 * Export streams every readable record with human-readable headers, auto-numbers rendered
 * without padding per the product convention. Import parses server-side, maps headers by
 * field name or label, validates every row against the model and reports per-line errors;
 * valid rows are created through the same path as every other write, so RLS and defaults
 * apply unchanged.
 */
function requireProfile(locals: App.Locals) {
	if (!locals.profile) throw error(401, 'Not provisioned');
	return locals.profile.id;
}

function csvEscape(value: unknown): string {
	if (value === null || value === undefined) return '';
	const text = value instanceof Date ? value.toISOString() : String(value);
	return /[",\n\r]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

export const GET: RequestHandler = async ({ params, locals }) => {
	const profileId = requireProfile(locals);
	const objectType = params.objectType as string;
	if (!ModelRegistry.hasObject(objectType)) throw error(404, 'Unknown object type');

	const fields = ModelRegistry.getObjectSchema(objectType).fields;
	const header = fields.map((f) => csvEscape(fieldLabel(f.name))).join(',');

	const lines: string[] = [header];
	let cursor: { sort: unknown; id: string } | null = null;
	// Keyset pages until exhausted; RLS bounds what "all records" means for this caller.
	for (;;) {
		const page = await PostgresMapper.listPage(profileId, objectType, { pageSize: 1000, cursor });
		for (const row of page.data as Record<string, unknown>[]) {
			lines.push(
				fields
					.map((f) => {
						let value = row[f.name];
						if (f.auto_generated && typeof value === 'string' && /^0*\d+$/.test(value)) value = String(Number(value));
						return csvEscape(value);
					})
					.join(',')
			);
		}
		if (!page.cursor || page.data.length < 1000) break;
		cursor = page.cursor;
	}

	return new Response(lines.join('\r\n'), {
		headers: {
			'content-type': 'text/csv; charset=utf-8',
			'content-disposition': `attachment; filename="${objectType}.csv"`
		}
	});
};

/** Minimal RFC-4180 parser: quoted fields, embedded commas, quotes and newlines. */
function parseCsv(text: string): string[][] {
	const rows: string[][] = [];
	let row: string[] = [], field = '', quoted = false;
	for (let i = 0; i < text.length; i++) {
		const char = text[i];
		if (quoted) {
			if (char === '"' && text[i + 1] === '"') { field += '"'; i++; }
			else if (char === '"') quoted = false;
			else field += char;
		} else if (char === '"') quoted = true;
		else if (char === ',') { row.push(field); field = ''; }
		else if (char === '\n' || char === '\r') {
			if (char === '\r' && text[i + 1] === '\n') i++;
			row.push(field); field = '';
			if (row.some((cell) => cell !== '')) rows.push(row);
			row = [];
		} else field += char;
	}
	row.push(field);
	if (row.some((cell) => cell !== '')) rows.push(row);
	return rows;
}

export const POST: RequestHandler = async ({ params, request, locals }) => {
	const profileId = requireProfile(locals);
	const objectType = params.objectType as string;
	if (!ModelRegistry.hasObject(objectType)) throw error(404, 'Unknown object type');

	const rows = parseCsv(await request.text());
	if (rows.length < 2) throw error(400, 'CSV needs a header row and at least one data row');

	// Header cells map by exact field name or by its human label, case-insensitively.
	const fields = ModelRegistry.getObjectSchema(objectType).fields;
	const byKey = new Map<string, string>();
	for (const field of fields) {
		byKey.set(field.name.toLowerCase(), field.name);
		byKey.set(fieldLabel(field.name).toLowerCase(), field.name);
	}
	const skip = new Set(['id', 'created_at', 'updated_at', 'created_by', 'updated_by']);
	const mapping = rows[0].map((cell) => {
		const name = byKey.get(cell.trim().toLowerCase());
		return name && !skip.has(name) ? name : null;
	});
	if (!mapping.some(Boolean)) throw error(400, 'No CSV column matches any field of ' + objectType);

	let created = 0;
	const problems: { line: number; error: string }[] = [];
	for (let i = 1; i < rows.length; i++) {
		const data: Record<string, unknown> = {};
		rows[i].forEach((cell, col) => {
			const name = mapping[col];
			if (name && cell !== '') data[name] = cell;
		});
		for (const field of ModelRegistry.getSpecificFields(objectType)) {
			if (field.default !== undefined && data[field.name] === undefined) data[field.name] = field.default;
		}
		const failures = validateObject(objectType, data) as { error: string }[];
		if (failures.length) {
			problems.push({ line: i + 1, error: failures.map((f) => f.error).join('; ') });
			continue;
		}
		try {
			await PostgresMapper.create(profileId, objectType, data);
			created += 1;
		} catch (e) {
			problems.push({ line: i + 1, error: (e as Error).message });
		}
	}
	return json({ created, failed: problems.length, problems: problems.slice(0, 20) });
};
