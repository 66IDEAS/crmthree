import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { provisionUser, isUnprovisioned } from '$lib/server/provisioning';

/**
 * Creates a user. Administrators only, except on an empty instance, where the first caller
 * becomes the Admin. This mirrors the first-user bootstrap of the reference implementation.
 */
export const POST: RequestHandler = async ({ request, locals }) => {
	const bootstrap = await isUnprovisioned();
	if (!bootstrap && locals.profile?.role_name !== 'Admin') {
		throw error(403, 'Administrators only');
	}

	const body = await request.json().catch(() => null);
	if (!body?.email || !body?.password || !body?.firstName || !body?.lastName) {
		throw error(400, 'email, password, firstName and lastName are required');
	}

	const created = await provisionUser({
		email: body.email,
		password: body.password,
		firstName: body.firstName,
		lastName: body.lastName,
		roleName: bootstrap ? 'Admin' : (body.roleName ?? 'User'),
		createdBy: locals.profile?.id ?? null
	});
	return json({ ...created, bootstrap }, { status: 201 });
};
