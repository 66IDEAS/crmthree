import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { callProvider } from '$lib/server/ai';
import { detectRelevantTypes, buildDataContext, buildRecordContext } from '$lib/server/ai-context';
import PostgresMapper from '$lib/server/PostgresMapper';

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
