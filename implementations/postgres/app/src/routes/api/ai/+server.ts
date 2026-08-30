import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { callProvider } from '$lib/server/ai';

/**
 * The AI operations of the reference implementation's callAIProvider, as a server route.
 * chat takes messages; summarize and generate wrap a prompt in the appropriate framing.
 */
export const POST: RequestHandler = async ({ request, locals }) => {
	if (!locals.profile) throw error(401, 'Not provisioned');
	const body = await request.json().catch(() => null);
	if (!body?.operation) throw error(400, 'operation is required');

	let messages;
	switch (body.operation) {
		case 'chat':
			if (!Array.isArray(body.params?.messages)) throw error(400, 'params.messages required');
			messages = body.params.messages;
			break;
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
