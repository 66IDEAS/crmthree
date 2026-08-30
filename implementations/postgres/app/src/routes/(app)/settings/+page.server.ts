import type { PageServerLoad } from './$types';
import { withUser, withOwner } from '$lib/server/db';

export const load: PageServerLoad = async ({ locals }) => {
	const isAdmin = locals.profile!.role_name === 'Admin';
	if (!isAdmin) return { isAdmin, users: [], roles: [], statuses: [], whitelist: [], aiConfigs: [] };

	// The provider-config query runs on the owner connection: has_key touches the api_key
	// column, which is deliberately unreadable by the application role. The page itself is
	// admin-gated above.
	const aiConfigs = await withOwner((client) =>
		client
			.query(
				`select id, provider, model, endpoint_url, is_active, (api_key <> '') as has_key
				   from ai_provider_config order by created_at`
			)
			.then((r) => r.rows)
	);
	const [users, roles, statuses, whitelist] = await withUser(locals.profile!.id, async (client) => {
		const [u, r, t, w] = await Promise.all([
			client.query(
				`select p.id, p.email, p.first_name, p.last_name, p.active, p.auth_uid is not null as claimed,
				        r.id as role_id, r.name as role_name
				   from user_profile p join role r on r.id = p.role_id
				  order by p.created_at`
			),
			client.query(`select id, name, description, is_system_role, permissions from role order by created_at`),
			client.query(`select id, name, sort_order, is_closed, is_resolved, active from ticket_status order by sort_order`),
			client.query(`select id, kind, value, created_at from email_whitelist order by created_at`)
		]);
		return [u.rows, r.rows, t.rows, w.rows];
	});
	return { isAdmin, users, roles, statuses, whitelist, aiConfigs };
};
