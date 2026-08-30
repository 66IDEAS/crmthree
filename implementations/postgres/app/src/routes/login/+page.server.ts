import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	if (locals.profile) throw redirect(303, '/');
	// Authenticated but no profile: surface the not-provisioned state on the login page.
	return { unprovisioned: Boolean(locals.account && !locals.profile) };
};
