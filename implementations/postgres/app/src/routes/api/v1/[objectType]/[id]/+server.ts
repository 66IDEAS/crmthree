import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import PostgresMapper from '$lib/server/PostgresMapper';

function requireProfile(locals: App.Locals) {
	if (!locals.profile) throw error(401, 'Not provisioned');
	return locals.profile.id;
}

export const GET: RequestHandler = async ({ params, locals }) => {
	const profileId = requireProfile(locals);
	const record = await PostgresMapper.getById(profileId, params.objectType as string, params.id as string);
	// Indistinguishable from a record the policies hide, which is deliberate: a 404 must not
	// reveal that a record exists but is out of reach.
	if (!record) throw error(404, 'Not found');
	return json(record);
};

export const PUT: RequestHandler = async ({ params, request, locals }) => {
	const profileId = requireProfile(locals);
	const updated = await PostgresMapper.update(
		profileId,
		params.objectType as string,
		params.id as string,
		await request.json()
	);
	if (!updated) throw error(404, 'Not found');
	return json(updated);
};

export const DELETE: RequestHandler = async ({ params, locals }) => {
	const profileId = requireProfile(locals);
	const removed = await PostgresMapper.remove(profileId, params.objectType as string, params.id as string);
	if (!removed) throw error(404, 'Not found');
	return new Response(null, { status: 204 });
};
