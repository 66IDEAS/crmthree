import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { withUser } from '$lib/server/db';

function requireAdmin(locals: App.Locals) {
	if (locals.profile?.role_name !== 'Admin') throw error(403, 'Administrators only');
	return locals.profile;
}

export const GET: RequestHandler = async ({ locals }) => {
	const admin = requireAdmin(locals);
	const rows = await withUser(admin.id, (client) =>
		client.query('select * from email_whitelist order by created_at').then((r) => r.rows)
	);
	return json({ entries: rows });
};

export const POST: RequestHandler = async ({ request, locals }) => {
	const admin = requireAdmin(locals);
	const body = await request.json().catch(() => null);
	if (!['email', 'domain'].includes(body?.kind) || !body?.value?.trim()) {
		throw error(400, 'kind (email|domain) and value are required');
	}
	// Normalized like the reference: lowercase, domains without a leading @.
	const value = String(body.value).trim().toLowerCase().replace(/^@/, '');
	const row = await withUser(admin.id, (client) =>
		client
			.query(
				`insert into email_whitelist (kind, value, created_by) values ($1, $2, $3) returning *`,
				[body.kind, value, admin.id]
			)
			.then((r) => r.rows[0])
	).catch((e: Error) => {
		throw error(400, e.message.includes('unique') ? 'Already whitelisted' : e.message);
	});
	return json(row, { status: 201 });
};
