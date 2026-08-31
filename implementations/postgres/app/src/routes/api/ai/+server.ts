import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { callProvider } from '$lib/server/ai';
import { detectRelevantTypes, buildDataContext, buildRecordContext } from '$lib/server/ai-context';
import { NAV_OBJECTS, NAV_VIRTUAL } from '$lib/display';
import PostgresMapper, { createInTx } from '$lib/server/PostgresMapper';
import { withUser } from '$lib/server/db';

/**
 * The AI operations of the reference implementation's callAIProvider, as a server route.
 * chat gets data-aware context injection; briefing builds record-level context from the
 * record and its relationships. All context is read under the caller's identity, so the
 * AI can only ever see what the asking user could see.
 */
export const POST: RequestHandler = async ({ request, locals }) => {
	if (!locals.profile) throw error(401, 'Not provisioned');
	const profileId = locals.profile.id;
	const body = await request.json().catch(() => null);
	if (!body?.operation) throw error(400, 'operation is required');

	let messages;
	switch (body.operation) {
		case 'chat': {
			if (!Array.isArray(body.params?.messages)) throw error(400, 'params.messages required');
			const types = detectRelevantTypes(body.params.messages);
			const context = await buildDataContext(profileId, types);
			messages = [
				{
					role: 'system',
					content: `You are the CRM assistant. Relevant CRM data follows; reference records by name and keep answers concise.\n\n${context}`
				},
				...body.params.messages
			];
			break;
		}
		case 'briefing': {
			if (!body.params?.objectType || !body.params?.recordId) {
				throw error(400, 'params.objectType and params.recordId required');
			}
			const record = (await PostgresMapper.getById(profileId, body.params.objectType, body.params.recordId)) as
				| Record<string, unknown>
				| null;
			if (!record) throw error(404, 'Record not found');
			const context = await buildRecordContext(profileId, body.params.objectType, record);
			messages = [
				{
					role: 'system',
					content:
						'You produce a 3-5 sentence contextual briefing for a CRM user about the record below. Focus on actionable insights: relationship health, open items, risks, next steps. No preamble.'
				},
				{ role: 'user', content: context }
			];
			break;
		}
		case 'semanticSearch': {
			// Story 23: intent search across every type. All context is read under the
			// caller's identity, so the AI cannot surface a record the asker could not.
			const searchTypes = NAV_OBJECTS.filter((t) => !NAV_VIRTUAL.has(t));
			const context = await buildDataContext(profileId, [...searchTypes], 100);
			messages = [
				{
					role: 'system' as const,
					content:
						'You match CRM records to a natural-language query by intent, not just keywords. ' +
						'Return ONLY JSON: {"results":[{"type":"...","id":"...","name":"...","reason":"..."}]} ' +
						'with at most 10 results, using ids from the data below.\n\n' + context
				},
				{ role: 'user' as const, content: String(body.params?.query ?? '') }
			];
			try {
				const raw = await callProvider(messages);
				const parsed = JSON.parse(raw.content.replace(/^```(json)?|```$/g, '').trim());
				return json({ results: Array.isArray(parsed.results) ? parsed.results : [] });
			} catch (e) {
				if ((e as Error).message.includes('provider')) throw error(502, (e as Error).message);
				return json({ results: [] });   // graceful fallback on unparseable output
			}
		}
		case 'caseToArticle': {
			// Stories 25 and 51: a resolved case becomes a draft knowledge article, written by
			// the AI from the ticket and its discussion, linked back to the case.
			if (!body.params?.ticketId) throw error(400, 'params.ticketId required');
			const article = await withUser(profileId, async (client) => {
				const ticket = (
					await client.query('select * from ticket where id = $1', [body.params.ticketId])
				).rows[0];
				if (!ticket) throw new Error('Ticket not found');
				const comments = (
					await client.query(
						`select content from comment where parent_type = 'Ticket' and parent_id = $1 order by created_at`,
						[ticket.id]
					)
				).rows;
				const material = [
					`Subject: ${ticket.subject}`,
					ticket.description ? `Description: ${ticket.description}` : '',
					ticket.resolution ? `Resolution: ${ticket.resolution}` : '',
					...comments.map((c: { content: string }) => `Comment: ${c.content}`)
				].filter(Boolean).join('\n');
				const generated = await callProvider([
					{
						role: 'system',
						content:
							'Write a knowledge base article from this support case: a clear problem statement, cause if known, and the resolution steps. Plain text, no preamble.'
					},
					{ role: 'user', content: material }
				]);
				const created = await createInTx(client, profileId, 'KnowledgeArticle', {
					title: String(ticket.subject).slice(0, 255),
					content: generated.content,
					category: ticket.category ?? undefined,
					status: 'Draft',
					source: 'Case Conversion',
					author_id: profileId
				});
				await createInTx(client, profileId, 'TicketKnowledgeArticle', {
					ticket_id: ticket.id,
					article_id: created.id,
					linked_at: new Date().toISOString(),
					linked_by: profileId
				});
				return created;
			});
			return json({ id: article.id, objectType: 'KnowledgeArticle' }, { status: 201 });
		}
		case 'parseEmail': {
			// Story 27: paste an email, get lead fields.
			const parsed = await callProvider([
				{
					role: 'system',
					content:
						'Extract lead fields from this email. Return ONLY JSON: {"first_name":"","last_name":"","email":"","phone":"","company":"","position":""} with empty strings for unknowns.'
				},
				{ role: 'user', content: String(body.params?.text ?? '') }
			]);
			try {
				return json({ fields: JSON.parse(parsed.content.replace(/^```(json)?|```$/g, '').trim()) });
			} catch {
				return json({ fields: {} });
			}
		}
		case 'performance': {
			// Story 28: a personal performance narrative from the caller's own numbers.
			const stats = await withUser(profileId, (client) =>
				client
					.query(
						`select
							(select count(*) from opportunity where owner_id = $1 and result = 'Won') as deals_won,
							(select coalesce(sum(amount),0) from opportunity where owner_id = $1 and result = 'Won') as won_value,
							(select count(*) from activity where owner_id = $1) as activities,
							(select count(*) from ticket where assigned_to = $1 and resolved_at is not null) as tickets_resolved,
							(select xp_total from user_profile where id = $1) as xp,
							(select current_streak_days from user_profile where id = $1) as streak`,
						[profileId]
					)
					.then((r) => r.rows[0])
			);
			messages = [
				{
					role: 'system',
					content:
						'Write a short, encouraging first-person-addressed performance summary for a CRM user from their numbers. 3-4 sentences, concrete, no flattery padding.'
				},
				{ role: 'user', content: JSON.stringify(stats) }
			];
			break;
		}
		case 'summarize':
			messages = [
				{ role: 'system', content: 'Summarize the following concisely for a CRM user.' },
				{ role: 'user', content: String(body.params?.text ?? '') }
			];
			break;
		case 'generate':
			messages = [{ role: 'user', content: String(body.params?.prompt ?? '') }];
			break;
		default:
			throw error(400, `Unknown operation: ${body.operation}`);
	}

	try {
		return json(await callProvider(messages));
	} catch (e) {
		throw error(502, (e as Error).message);
	}
};
