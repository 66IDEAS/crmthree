import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import PostgresMapper from '$lib/server/PostgresMapper';
import { withUser } from '$lib/server/db';
import { activeConfig } from '$lib/server/ai';

/** Case Room workspace (story 34): the service twin of the Deal Room, a view over the Ticket. */
export const load: PageServerLoad = async ({ params, locals }) => {
	const profileId = locals.profile!.id;
	const ticket = (await PostgresMapper.getById(profileId, 'Ticket', params.id)) as Record<string, unknown> | null;
	if (!ticket) throw error(404, 'Not found');

	const extras = await withUser(profileId, async (client) => {
		const [statuses, activities, articles, account, contact, assignee] = await Promise.all([
			client.query('select id, name, is_closed, is_resolved from ticket_status where active order by sort_order'),
			client.query(
				`select * from activity where ticket_id = $1 order by coalesce(start_date, created_at) desc limit 20`,
				[ticket.id]
			),
			client.query(
				`select k.id, k.title, k.status, j.id as junction_id
				   from ticket_knowledge_article j join knowledge_article k on k.id = j.article_id
				  where j.ticket_id = $1`,
				[ticket.id]
			),
			ticket.account_id
				? client.query('select id, name1 from account where id = $1', [ticket.account_id])
				: Promise.resolve({ rows: [] }),
			ticket.contact_id
				? client.query('select id, first_name, last_name from contact where id = $1', [ticket.contact_id])
				: Promise.resolve({ rows: [] }),
			ticket.assigned_to
				? client.query('select first_name, last_name from user_profile where id = $1', [ticket.assigned_to])
				: Promise.resolve({ rows: [] })
		]);
		return {
			statuses: statuses.rows,
			activities: activities.rows,
			articles: articles.rows,
			account: account.rows[0] ?? null,
			contact: contact.rows[0] ?? null,
			assignee: assignee.rows[0] ?? null
		};
	});

	return { ticket, ...extras, profileId, aiConfigured: await activeConfig().then(Boolean).catch(() => false) };
};
