import type { PageServerLoad } from './$types';
import { withUser } from '$lib/server/db';

export const load: PageServerLoad = async ({ locals }) => {
	const isAdmin = locals.profile!.role_name === 'Admin';
	if (!isAdmin) return { isAdmin, users: [], roles: [] };

	const [users, roles] = await withUser(locals.profile!.id, async (client) => {
		const usersResult = await client.query(
			`select p.id, p.email, p.first_name, p.last_name, p.active, p.auth_uid is not null as claimed,
			        r.id as role_id, r.name as role_name
			   from user_profile p join role r on r.id = p.role_id
			  order by p.created_at`
		);
		const rolesResult = await client.query(
			`select id, name, description, is_system_role, permissions from role order by created_at`
		);
		return [usersResult.rows, rolesResult.rows];
	});
	return { isAdmin, users, roles };
};
