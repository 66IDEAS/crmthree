import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { saveFile } from '$lib/server/storage';

/**
 * Upload (R6). Multipart with a single "file" field. Returns the stored file's metadata;
 * the caller then creates a Document record whose file_path is /api/files/<id>, which keeps
 * domain data in the database and bytes on disk.
 */
export const POST: RequestHandler = async ({ request, locals }) => {
	if (!locals.profile) throw error(401, 'Not provisioned');
	const form = await request.formData().catch(() => null);
	const file = form?.get('file');
	if (!(file instanceof File)) throw error(400, 'Multipart field "file" is required');
	try {
		const stored = await saveFile(file);
		return json({ ...stored, url: `/api/files/${stored.id}` }, { status: 201 });
	} catch (e) {
		throw error(400, (e as Error).message);
	}
};
