import { betterAuth } from 'better-auth';
import { sveltekitCookies } from 'better-auth/svelte-kit';
import { getRequestEvent } from '$app/server';
import pg from 'pg';
import { env } from '$env/dynamic/private';

const googleConfigured = Boolean(env.GOOGLE_CLIENT_ID && env.GOOGLE_CLIENT_SECRET);

/**
 * Authentication for the Postgres implementation (R2).
 *
 * Better Auth keeps its own tables in the same database, so identity is a set of ordinary
 * tables rather than a managed service. That removes the constraint the Firebase
 * implementation works around: there, the auth user list is readable only through a
 * privileged SDK, so user management needs a backend of its own.
 *
 * Self-service registration is closed on both paths, matching the reference implementation:
 * administrators create accounts, nobody signs themselves up.
 */
export const auth = betterAuth({
	database: new pg.Pool({ connectionString: env.MIGRATION_DATABASE_URL || env.DATABASE_URL }),
	// Auth tables are namespaced auth_*. Without this they collide with the CRM domain:
	// data-model.json defines an Account object, so better-auth's own "account" table would
	// target the customer accounts table. Left at its default, the schema generator emits
	// `alter table "account" add column "password"` against 27 columns of CRM data.
	// Renaming also avoids "user", which is a reserved word in SQL.
	user: { modelName: 'auth_user' },
	session: { modelName: 'auth_session' },
	account: { modelName: 'auth_account' },
	verification: { modelName: 'auth_verification' },
	secret: env.BETTER_AUTH_SECRET,
	baseURL: env.BETTER_AUTH_URL,
	emailAndPassword: {
		enabled: true,
		// Rejected in better-auth's sign-up route; an admin must create the account.
		disableSignUp: true
	},
	socialProviders: googleConfigured
		? {
				google: {
					clientId: env.GOOGLE_CLIENT_ID as string,
					clientSecret: env.GOOGLE_CLIENT_SECRET as string,
					// A Google account with no pre-created profile is refused rather than
					// silently provisioned.
					disableSignUp: true
				}
			}
		: {},
	plugins: [sveltekitCookies(getRequestEvent)]
});
