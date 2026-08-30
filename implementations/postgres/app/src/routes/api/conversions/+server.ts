import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { convertLead, convertDocument } from '$lib/server/conversions';

export const POST: RequestHandler = async ({ request, locals }) => {
	if (!locals.profile) throw error(401, 'Not provisioned');
	const body = await request.json().catch(() => null);
	try {
		if (body?.kind === 'lead') {
			if (!body.leadId) throw new Error('leadId is required');
			return json(await convertLead(locals.profile.id, body.leadId, body), { status: 201 });
		}
		if (body?.kind === 'document') {
			if (!body.sourceType || !body.sourceId || !body.targetType) {
				throw new Error('sourceType, sourceId and targetType are required');
			}
			return json(
				await convertDocument(locals.profile.id, body.sourceType, body.sourceId, body.targetType),
				{ status: 201 }
			);
		}
		throw new Error('kind must be "lead" or "document"');
	} catch (e) {
		throw error(400, (e as Error).message);
	}
};
