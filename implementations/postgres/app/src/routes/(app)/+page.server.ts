import type { PageServerLoad } from './$types';
import { withUser } from '$lib/server/db';

/**
 * Dashboard (story 15). Aggregation happens in SQL under the caller's identity, so every
 * number respects row level security; the reference implementation fetches up to 1000
 * records per type and aggregates in the browser.
 */
export const load: PageServerLoad = async ({ locals }) => {
	const profileId = locals.profile!.id;
	return withUser(profileId, async (client) => {
		const [kpis, pipeline, priorities] = await Promise.all([
			client.query(`
				select
					(select coalesce(sum(amount), 0) from opportunity where result = 'Open') as pipeline_value,
					(select count(*) from opportunity where result = 'Open') as open_opportunities,
					(select count(*) from ticket t left join ticket_status s on s.id = t.status_id
					  where coalesce(s.is_closed, false) = false) as open_tickets,
					(select count(*) from lead where status in ('New', 'Contacted', 'Qualified')) as open_leads,
					(select count(*) from activity
					  where coalesce(due_date, start_date::date) >= date_trunc('week', now())::date
					    and coalesce(due_date, start_date::date) < (date_trunc('week', now()) + interval '7 days')::date) as activities_this_week
			`),
			client.query(`
				select s.name, coalesce(sum(o.amount), 0)::numeric as value, count(o.id)::int as deals
				  from pipeline_stage s
				  left join opportunity o on o.stage_id = s.id and o.result = 'Open'
				 group by s.name, s.sort_order
				 order by s.sort_order
			`),
			client.query(`
				select priority::text, count(*)::int as tickets
				  from ticket group by priority
				 order by case priority when 'Low' then 1 when 'Medium' then 2 when 'High' then 3 else 4 end
			`)
		]);
		return {
			kpis: kpis.rows[0],
			pipeline: pipeline.rows as { name: string; value: string; deals: number }[],
			priorities: priorities.rows as { priority: string; tickets: number }[]
		};
	});
};
