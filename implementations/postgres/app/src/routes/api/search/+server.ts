import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import ModelRegistry from '$lib/model/ModelRegistry';
import { tableName } from '$lib/server/PostgresMapper';
import { withUser } from '$lib/server/db';
import { displayName, NAV_OBJECTS, objectLabel } from '$lib/display';

/**
 * Global search (story 16). One ILIKE query per navigable object type over its name-like,
 * email and auto-number columns, run under the caller's identity so row level security
 * scopes every result. Unlike the reference implementation, which fetches all records and
 * filters in the browser, nothing leaves the database but the matches.
 */
const SEARCHABLE = new Set(['name', 'name1', 'name2', 'first_name', 'last_name', 'subject', 'title', 'label', 'email', 'company']);
const PER_TYPE = 5;

function searchColumns(objectType: string): string[] {
	return ModelRegistry.getObjectSchema(objectType)
		.fields.filter((f) => f.type === 'string' && (SEARCHABLE.has(f.name) || f.auto_generated))
		.map((f) => f.name);
}

export const GET: RequestHandler = async ({ url, locals }) => {
	if (!locals.profile) throw error(401, 'Not provisioned');
	const query = url.searchParams.get('q')?.trim() ?? '';
	if (query.length < 2) return json({ results: [] });

	const pattern = `%${query}%`;
	const profileId = locals.profile.id;

	const groups = await Promise.all(
		NAV_OBJECTS.map(async (objectType) => {
			const columns = searchColumns(objectType);
			if (columns.length === 0) return null;
			const where = columns.map((c) => `"${c}" ilike $1`).join(' or ');
			const rows = await withUser(profileId, (client) =>
				client
					.query(`select * from ${tableName(objectType)} where ${where} limit ${PER_TYPE}`, [pattern])
					.then((r) => r.rows)
			).catch(() => []);
			if (rows.length === 0) return null;
			return {
				objectType,
				label: objectLabel(objectType, true),
				matches: rows.map((row: Record<string, unknown>) => ({
					id: row.id,
					display: displayName(row),
					sub: columns.map((c) => row[c]).filter((v) => v && String(v) !== displayName(row)).slice(0, 2).join(' · ')
				}))
			};
		})
	);
	return json({ results: groups.filter(Boolean) });
};
