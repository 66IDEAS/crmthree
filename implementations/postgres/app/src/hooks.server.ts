import type { Handle, ServerInit } from '@sveltejs/kit';
import { building } from '$app/environment';
import { svelteKitHandler } from 'better-auth/svelte-kit';
import { auth } from '$lib/server/auth';
import { withUser } from '$lib/server/db';
import { seedTranslations } from '$lib/server/seed-translations';

/**
 * Resolves the session once per request and attaches the CRM profile to locals.
 *
 * The authenticated account and the CRM UserProfile are separate things: an account proves
 * who signed in, a profile grants access and carries the role. A valid account with no
 * active profile is authenticated but not provisioned, which is what the reference
 * implementation calls the "not provisioned" state.
 */
/** Server start: seed the bundled language packs (once per language, ever). */
export const init: ServerInit = async () => {
	await seedTranslations();
};

export const handle: Handle = async ({ event, resolve }) => {
	const session = await auth.api.getSession({ headers: event.request.headers });
	event.locals.account = session?.user ?? null;
	event.locals.profile = null;

	if (session?.user?.id) {
		// Looked up with no identity set, so this query must not depend on RLS. The profile
		// tables are readable to the application role for exactly this bootstrap step.
		// Resolved through a SECURITY DEFINER function: this runs before an identity exists,
		// so an ordinary query would be filtered to nothing by the very policies it is trying
		// to establish the identity for.
		const rows = await withUser(null, async (client) => {
			const result = await client.query('select * from app.profile_for_auth_uid($1)', [
				session.user.id
			]);
			return result.rows;
		});
		event.locals.profile = rows[0] ?? null;

		// The whitelist is evaluated on every sign-in, not only the first, and applies to
		// users who already hold a profile (story 18b). An empty whitelist allows everyone.
		if (event.locals.profile) {
			const allowed = await withUser(null, (client) =>
				client
					.query('select app.email_allowed($1) as allowed', [event.locals.profile!.email])
					.then((r) => r.rows[0]?.allowed === true)
			).catch(() => true);
			if (!allowed) event.locals.profile = null;
		}
	}

	return svelteKitHandler({ auth, event, resolve, building });
};
