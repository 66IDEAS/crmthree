import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import ModelRegistry from '$lib/model/ModelRegistry';
import { withUser } from '$lib/server/db';

/** Lock TTL and heartbeat behaviour follow the reference implementation: 15 minutes. */
const TTL_MINUTES = 15;

/**
 * Acquire or extend a lock (story 61, P9). Acquiring twice is the heartbeat: the same user
 * re-acquiring their own lock pushes expires_at forward. A lock someone else holds is a 409
 * unless it has expired, in which case it is taken over.
 */
export const POST: RequestHandler = async ({ request, locals }) => {
	if (!locals.profile) throw error(401, 'Not provisioned');
	const profile = locals.profile;
	const body = await request.json().catch(() => null);
	if (!body?.objectType || !body?.recordId) throw error(400, 'objectType and recordId are required');
	if (!ModelRegistry.hasObject(body.objectType)) throw error(400, `Unknown object type: ${body.objectType}`);

	const lock = await withUser(profile.id, async (client) => {
		// Clear an expired lock first; the delete policy allows removing expired locks held
		// by anyone, which is how takeover works.
		await client.query(
			`delete from record_lock where object_type = $1 and record_id = $2 and expires_at < now()`,
			[body.objectType, body.recordId]
		);
		const result = await client.query(
			`insert into record_lock (object_type, record_id, locked_by, locked_by_name, expires_at)
			 values ($1, $2, $3, $4, now() + interval '${TTL_MINUTES} minutes')
			 on conflict (object_type, record_id) do update
			   set expires_at = excluded.expires_at, locked_at = now()
			   where record_lock.locked_by = excluded.locked_by
			 returning *`,
			[body.objectType, body.recordId, profile.id, `${profile.first_name} ${profile.last_name}`.trim()]
		);
		return result.rows[0] ?? null;
	});

	if (!lock) throw error(409, 'Record is locked by another user');
	return json(lock, { status: 201 });
};
