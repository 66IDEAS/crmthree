import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { withOwner } from '$lib/server/db';
import { encryptSecret } from '$lib/server/crypto';

function requireAdmin(locals: App.Locals) {
	if (locals.profile?.role_name !== 'Admin') throw error(403, 'Administrators only');
	return locals.profile;
}

/** Config without the key. The api_key column never travels to a client, even encrypted. */
export const GET: RequestHandler = async ({ locals }) => {
	requireAdmin(locals);
	const rows = await withOwner((client) =>
		client
			.query(
				`select id, provider, model, endpoint_url, is_active, (api_key is not null) as has_key
				   from ai_provider_config order by created_at`
			)
			.then((r) => r.rows)
	);
	return json({ configs: rows });
};

/**
 * Upsert the provider configuration. The key is encrypted here, server-side, before it is
 * stored; activating a provider deactivates the others, matching the reference behaviour.
 */
export const PUT: RequestHandler = async ({ request, locals }) => {
	const admin = requireAdmin(locals);
	const body = await request.json().catch(() => null);
	if (!body?.provider || !body?.model) throw error(400, 'provider and model are required');

	await withOwner(async (client) => {
		if (body.is_active !== false) {
			await client.query('update ai_provider_config set is_active = false, updated_at = now()');
		}
		const encrypted = body.api_key ? encryptSecret(body.api_key) : null;
		await client.query(
			`insert into ai_provider_config
			   (created_at, updated_at, created_by, updated_by, provider, model, api_key, endpoint_url, is_active)
			 values (now(), now(), $1, $1, $2, $3, coalesce($4, ''), $5, $6)`,
			[admin.id, body.provider, body.model, encrypted, body.endpoint_url ?? null, body.is_active !== false]
		);
	});
	return json({ ok: true }, { status: 201 });
};
