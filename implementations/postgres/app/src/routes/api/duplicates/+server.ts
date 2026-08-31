import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import ModelRegistry from '$lib/model/ModelRegistry';
import { tableName } from '$lib/server/PostgresMapper';
import { withUser } from '$lib/server/db';
import { displayName } from '$lib/display';

/**
 * Duplicate detection (story 53): trigram similarity over the type's display-name columns,
 * run under the caller's identity. The create form asks before saving; the threshold is
 * deliberately forgiving, because a false "possible duplicate" costs a glance and a false
 * negative costs a duplicate record.
 */
const NAME_COLUMNS = ['name', 'name1', 'first_name', 'last_name', 'subject', 'title'];
const THRESHOLD = 0.35;

export const GET: RequestHandler = async ({ url, locals }) => {
	if (!locals.profile) throw error(401, 'Not provisioned');
	const objectType = url.searchParams.get('type') ?? '';
	const candidate = url.searchParams.get('name')?.trim() ?? '';
	if (!ModelRegistry.hasObject(objectType)) throw error(400, 'Unknown object type');
	if (candidate.length < 3) return json({ matches: [] });

	const columns = ModelRegistry.getObjectSchema(objectType)
		.fields.filter((f) => f.type === 'string' && NAME_COLUMNS.includes(f.name))
		.map((f) => f.name);
	if (!columns.length) return json({ matches: [] });

	const expr = columns.length === 1 ? `"${columns[0]}"` : `concat_ws(' ', ${columns.map((c) => `"${c}"`).join(', ')})`;
	const rows = await withUser(locals.profile.id, (client) =>
		client
			.query(
				`select *, similarity(${expr}, $1) as _score from ${tableName(objectType)}
				  where similarity(${expr}, $1) > ${THRESHOLD}
				  order by _score desc limit 5`,
				[candidate]
			)
			.then((r) => r.rows)
	);
	return json({
		matches: rows.map((row: Record<string, unknown>) => ({
			id: row.id,
			display: displayName(row),
			score: Math.round(Number(row._score) * 100)
		}))
	});
};
