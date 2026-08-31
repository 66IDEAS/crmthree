import { redirect } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';
import { withUser } from '$lib/server/db';

/**
 * Everything in the (app) group needs a provisioned profile. An authenticated account with
 * no profile lands back on the login page, which explains the not-provisioned state.
 */
export const load: LayoutServerLoad = async ({ locals }) => {
	if (!locals.profile) throw redirect(303, '/login');
	const [prefs, labels] = await withUser(locals.profile.id, async (client) => {
		const p = await client
			.query(
				`select u.theme_preference, u.language_preference, r.ribbon_items
				   from user_profile u join role r on r.id = u.role_id where u.id = $1`,
				[locals.profile!.id]
			)
			.then((r) => r.rows[0] ?? {});
		const lang = p.language_preference ?? 'en';
		const l =
			lang === 'en'
				? {}
				: await client
						.query('select labels from translation where code = $1', [lang])
						.then((r) => r.rows[0]?.labels ?? {});
		return [p, l];
	});
	return { profile: locals.profile, prefs, labels };
};
