import { error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { openFile } from '$lib/server/storage';

/** Download. Authorised like every other route; anonymous requests never reach the disk. */
export const GET: RequestHandler = async ({ params, locals }) => {
	if (!locals.profile) throw error(401, 'Not provisioned');
	const found = await openFile(params.id as string).catch(() => null);
	if (!found) throw error(404, 'Not found');
	return new Response(found.body, {
		headers: {
			'content-type': found.meta.type,
			'content-length': String(found.meta.size),
			'content-disposition': `attachment; filename="${found.meta.name.replace(/"/g, '')}"`
		}
	});
};
