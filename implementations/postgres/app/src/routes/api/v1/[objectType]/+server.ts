import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import PostgresMapper from '$lib/server/PostgresMapper';
import { validateObject } from '$lib/model/validators';

/**
 * Collection endpoint (R9, P6). The browser reaches data only through here; there is no
 * client-side database driver, which is the structural difference from the reference
 * implementation where the SPA talks to Firestore directly.
 *
 * Every call runs under the caller's identity, so row level security decides what comes
 * back. The API therefore cannot return more than the same user would see in the UI.
 */
function requireProfile(locals: App.Locals) {
	if (!locals.profile) throw error(401, 'Not provisioned');
	return locals.profile.id;
}

export const GET: RequestHandler = async ({ params, url, locals }) => {
	const profileId = requireProfile(locals);
	const objectType = params.objectType as string;

	const sortField = url.searchParams.get('sort');
	// Optional filters, JSON-encoded: [{"field":"status","op":"eq","value":"Active"}].
	// Field names are validated against the model inside the mapper; RLS still applies on
	// top, so a filter can only narrow what the caller could see anyway.
	let filters;
	try {
		filters = JSON.parse(url.searchParams.get('filters') ?? '[]');
	} catch {
		throw error(400, 'filters must be valid JSON');
	}
	const options = {
		filters,
		pageSize: Number(url.searchParams.get('pageSize') ?? 25),
		sort: sortField
			? { field: sortField, direction: (url.searchParams.get('direction') ?? 'asc') as 'asc' | 'desc' }
			: undefined,
		cursor: url.searchParams.get('cursorId')
			? { sort: url.searchParams.get('cursorSort'), id: url.searchParams.get('cursorId') as string }
			: null
	};

	try {
		if (url.searchParams.get('count') === 'true') {
			return json({ total: await PostgresMapper.count(profileId, objectType, options) });
		}
		return json(await PostgresMapper.listPage(profileId, objectType, options));
	} catch (e) {
		throw error(400, (e as Error).message);
	}
};

export const POST: RequestHandler = async ({ params, request, locals }) => {
	const profileId = requireProfile(locals);
	const body = await request.json().catch(() => ({}));
	// Model validation runs on the server, where it cannot be skipped; the reference
	// implementation validates in the browser only.
	const problems = validateObject(params.objectType as string, body) as { field: string; error: string }[];
	if (problems.length > 0) {
		throw error(400, problems.map((p) => p.error).join('; '));
	}
	try {
		const created = await PostgresMapper.create(profileId, params.objectType as string, body);
		return json(created, { status: 201 });
	} catch (e) {
		throw error(400, (e as Error).message);
	}
};
