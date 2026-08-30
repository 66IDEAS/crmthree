import { redirect } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';

/**
 * Everything in the (app) group needs a provisioned profile. An authenticated account with
 * no profile lands back on the login page, which explains the not-provisioned state.
 */
export const load: LayoutServerLoad = async ({ locals }) => {
	if (!locals.profile) throw redirect(303, '/login');
	return { profile: locals.profile };
};
