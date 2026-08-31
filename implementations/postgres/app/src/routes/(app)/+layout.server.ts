import { redirect } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';
import { withUser } from '$lib/server/db';

/**
 * Everything in the (app) group needs a provisioned profile. An authenticated account with
 * no profile lands back on the login page, which explains the not-provisioned state.
 */
export const load: LayoutServerLoad = async ({ locals }) => {
	if (!locals.profile) throw redirect(303, '/login');
	const prefs = await withUser(locals.profile.id, (client) =>
		client
			.query('select theme_preference, language_preference from user_profile where id = $1', [
				locals.profile!.id
			])
			.then((r) => r.rows[0] ?? {})
	);
	return { profile: locals.profile, prefs };
};
