import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { withUser } from '$lib/server/db';

/** Current lock on a record, if any. Expired locks read as unlocked. */
export const GET: RequestHandler = async ({ params, locals }) => {
	if (!locals.profile) throw error(401, 'Not provisioned');
	const lock = await withUser(locals.profile.id, async (client) => {
		const result = await client.query(
			`select * from record_lock where object_type = $1 and record_id = $2 and expires_at > now()`,
			[params.objectType, params.id]
		);
		return result.rows[0] ?? null;
	});
	return json({ lock });
};

/** Release. The delete policy restricts this to the holder, or to anyone once expired. */
export const DELETE: RequestHandler = async ({ params, locals }) => {
	if (!locals.profile) throw error(401, 'Not provisioned');
	await withUser(locals.profile.id, (client) =>
		client.query(`delete from record_lock where object_type = $1 and record_id = $2`, [
			params.objectType,
			params.id
		])
	);
	return new Response(null, { status: 204 });
};
