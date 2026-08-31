import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import PostgresMapper from '$lib/server/PostgresMapper';
import { withUser } from '$lib/server/db';
import { displayName } from '$lib/display';
import { activeConfig } from '$lib/server/ai';

/**
 * Deal Room workspace (story 33): a purpose-built layout over the Opportunity, replacing
 * the generic detail page for this one type, exactly as the shared UX prescribes.
 */
export const load: PageServerLoad = async ({ params, locals }) => {
	const profileId = locals.profile!.id;
	const room = (await PostgresMapper.getById(profileId, 'DealRoom', params.id)) as Record<string, unknown> | null;
	if (!room) throw error(404, 'Not found');

	const opportunity = (await PostgresMapper.getById(profileId, 'Opportunity', String(room.opportunity_id))) as
		| Record<string, unknown>
		| null;

	const extras = await withUser(profileId, async (client) => {
		const [stages, activities, contacts, account, owner] = await Promise.all([
			client.query('select id, name, sort_order, default_probability as probability from pipeline_stage order by sort_order'),
			opportunity
				? client.query(
						`select * from activity where opportunity_id = $1 order by coalesce(start_date, created_at) desc limit 20`,
						[opportunity.id]
					)
				: Promise.resolve({ rows: [] }),
			opportunity
				? client.query(
						`select c.id, c.first_name, c.last_name, c.email, oc.role
						   from opportunity_contact oc join contact c on c.id = oc.contact_id
						  where oc.opportunity_id = $1`,
						[opportunity.id]
					)
				: Promise.resolve({ rows: [] }),
			opportunity?.account_id
				? client.query('select id, name1 from account where id = $1', [opportunity.account_id])
				: Promise.resolve({ rows: [] }),
			opportunity?.owner_id
				? client.query('select first_name, last_name from user_profile where id = $1', [opportunity.owner_id])
				: Promise.resolve({ rows: [] })
		]);
		return {
			stages: stages.rows,
			activities: activities.rows,
			contacts: contacts.rows,
			account: account.rows[0] ?? null,
			owner: owner.rows[0] ?? null
		};
	});

	return {
		aiConfigured: await activeConfig().then(Boolean).catch(() => false),
		room,
		opportunity,
		opportunityName: displayName(opportunity ?? {}),
		...extras,
		profileId
	};
};
