import type { PageServerLoad } from './$types';
import { withUser } from '$lib/server/db';
import ModelRegistry from '$lib/model/ModelRegistry';

export const load: PageServerLoad = async ({ locals }) => {
	const me = await withUser(locals.profile!.id, (client) =>
		client
			.query(
				`select p.*, r.name as role_name from user_profile p join role r on r.id = p.role_id
				  where p.id = $1`,
				[locals.profile!.id]
			)
			.then((r) => r.rows[0])
	);
	return {
		me,
		notificationTypes: ModelRegistry.getFieldDefinition('Notification', 'type')?.values ?? []
	};
};
