import type { PageServerLoad } from './$types';
import { withUser } from '$lib/server/db';
import ModelRegistry from '$lib/model/ModelRegistry';

export const load: PageServerLoad = async ({ locals }) => {
	const [me, badges, activity, languages] = await withUser(locals.profile!.id, async (client) => {
		const [m, b, a, l] = await Promise.all([
			client.query(
				`select p.*, r.name as role_name from user_profile p join role r on r.id = p.role_id
				  where p.id = $1`,
				[locals.profile!.id]
			),
			client.query(
				`select b.name, b.description, b.category, ub.earned_at
				   from user_badge ub join badge b on b.id = ub.badge_id
				  where ub.user_id = $1 order by ub.earned_at desc`,
				[locals.profile!.id]
			),
			// One's own audit rows, via the own-rows policy: the user timeline (story 35).
			client.query(
				`select action, object_type, object_name, summary, "timestamp"
				   from audit_log where user_id = $1 order by "timestamp" desc limit 20`,
				[locals.profile!.id]
			),
			client.query('select code, language_name from translation order by code')
		]);
		return [m.rows[0], b.rows, a.rows, l.rows];
	});
	return {
		me,
		badges,
		activity,
		languages,
		notificationTypes: ModelRegistry.getFieldDefinition('Notification', 'type')?.values ?? []
	};
};
