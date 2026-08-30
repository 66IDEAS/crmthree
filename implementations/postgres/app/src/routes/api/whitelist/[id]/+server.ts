import { error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { withUser } from '$lib/server/db';

export const DELETE: RequestHandler = async ({ params, locals }) => {
	if (locals.profile?.role_name !== 'Admin') throw error(403, 'Administrators only');
	await withUser(locals.profile.id, (client) =>
		client.query('delete from email_whitelist where id = $1', [params.id])
	);
	return new Response(null, { status: 204 });
};
