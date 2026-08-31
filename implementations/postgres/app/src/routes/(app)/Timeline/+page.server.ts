import type { PageServerLoad } from './$types';
import { withUser } from '$lib/server/db';

/**
 * Team timeline (story 36): the team's activity stream from the activity table - which
 * everyone can already read - beside the XP standings. RLS scopes both.
 */
export const load: PageServerLoad = async ({ locals }) => {
	return withUser(locals.profile!.id, async (client) => {
		const [feed, members] = await Promise.all([
			client.query(
				`select a.id, a.subject, a.type, a.status, coalesce(a.start_date, a.created_at) as at,
				        p.first_name, p.last_name
				   from activity a left join user_profile p on p.id = a.owner_id
				  order by coalesce(a.start_date, a.created_at) desc limit 50`
			),
			client.query(
				`select id, first_name, last_name, level, level_name, xp_total, current_streak_days
				   from user_profile where active order by xp_total desc`
			)
		]);
		return { feed: feed.rows, members: members.rows };
	});
};
