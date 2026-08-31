import type { PageServerLoad } from './$types';
import { withUser } from '$lib/server/db';

/** Case Rooms list every ticket but navigate to workspaces, per the shared UX. */
export const load: PageServerLoad = async ({ locals }) => {
	const rows = await withUser(locals.profile!.id, (client) =>
		client
			.query(
				`select t.id, t.ticket_number, t.subject, t.priority, s.name as status, a.name1 as account
				   from ticket t
				   left join ticket_status s on s.id = t.status_id
				   left join account a on a.id = t.account_id
				  order by t.created_at desc limit 100`
			)
			.then((r) => r.rows)
	);
	return { rows };
};
