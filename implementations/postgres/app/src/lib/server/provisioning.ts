import { randomUUID } from 'node:crypto';
import type pg from 'pg';
import { createLocalAccountIssuer } from '@better-auth/core/db';
import { auth } from './auth';
import { withUser, withOwner } from './db';

const DEFAULT_ROLES = [
	{ name: 'Admin', description: 'Full access', permissions: {} },
	{ name: 'Manager', description: 'Team oversight', permissions: {} },
	{ name: 'User', description: 'Standard access', permissions: {} }
];

/**
 * Creates an authentication account and the CRM profile that grants access to it.
 *
 * Self-service registration is closed, so this is the only way an account comes into
 * existence. The two halves are deliberately separate: the account proves who signed in, the
 * profile grants access and carries the role. `user_profile.auth_uid` links them.
 *
 * `createdBy` is null only for the very first user, who references themselves. Foreign keys
 * are deferrable precisely so that this is possible; see db/README.md.
 */
export async function provisionUser(input: {
	email: string;
	password: string;
	firstName: string;
	lastName: string;
	roleName: string;
	createdBy: string | null;
}) {
	const ctx = await auth.$context;
	const account = await ctx.internalAdapter.createUser(
		{
			email: input.email,
			name: `${input.firstName} ${input.lastName}`.trim(),
			emailVerified: false
		},
		{ method: 'email-password' }
	);
	await ctx.internalAdapter.linkAccount({
		userId: account.id,
		providerId: 'credential',
		// Providers with no issuer of their own get a synthetic one; this matches what
		// better-auth's own sign-up route writes, so the row is indistinguishable from a
		// normally registered credential account.
		issuer: createLocalAccountIssuer('credential'),
		accountId: account.id,
		password: await ctx.password.hash(input.password)
	});

	const profileId = randomUUID();
	const actor = input.createdBy ?? profileId;

	try {
		return await createProfile();
	} catch (error) {
		// Roll back the account so a failed provision leaves nothing behind and the same
		// email can be retried. Better Auth writes the account outside our transaction, so
		// this cannot be handled by the database alone.
		await ctx.internalAdapter.deleteUser(account.id).catch(() => {});
		throw error;
	}

	function createProfile() {
	// Bootstrap is exempt from RLS by necessity; every later creation runs as the admin who
	// requested it and is checked by the ordinary policies.
	const run = <T>(fn: (client: pg.PoolClient) => Promise<T>): Promise<T> =>
		input.createdBy === null ? withOwner(fn) : withUser(input.createdBy, fn);
	return run(async (client) => {
		// Seed the default roles on first use. Idempotent: existing names are left alone.
		for (const role of DEFAULT_ROLES) {
			// Parameters are cast explicitly: $3 appears both as an inserted value and in the
			// existence check, and Postgres refuses to deduce one type for both positions.
			await client.query(
				`insert into role (id, created_at, updated_at, created_by, updated_by, name, description, permissions, ribbon_items, is_system_role, active)
				 select $1::uuid, now(), now(), $2::uuid, $2::uuid, $3::text, $4::text, $5::jsonb, '[]'::jsonb, true, true
				 where not exists (select 1 from role where name = $3::text)`,
				[randomUUID(), actor, role.name, role.description, JSON.stringify(role.permissions)]
			);
		}
		const role = await client.query('select id from role where name = $1 limit 1', [input.roleName]);
		if (role.rowCount === 0) throw new Error(`Unknown role: ${input.roleName}`);

		await client.query(
			`insert into user_profile
			   (id, created_at, updated_at, created_by, updated_by, auth_uid, email, first_name, last_name, role_id, active)
			 values ($1, now(), now(), $2, $2, $3, $4, $5, $6, $7, true)`,
			[profileId, actor, account.id, input.email, input.firstName, input.lastName, role.rows[0].id]
		);
		return { profileId, accountId: account.id };
	});
	}
}

/** True when no profile exists yet, so the next created user bootstraps as Admin. */
export async function isUnprovisioned(): Promise<boolean> {
	// Asked through a SECURITY DEFINER function. Counting user_profile directly would be
	// filtered to nothing for an unauthenticated caller, reporting every instance as empty and
	// handing the bootstrap path to anyone who asked for it.
	return withUser(null, async (client) => {
		const result = await client.query('select app.is_unprovisioned() as empty');
		return result.rows[0].empty === true;
	});
}
