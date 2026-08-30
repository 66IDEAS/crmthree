import pg from 'pg';
import { env } from '$env/dynamic/private';

/**
 * Application connection pool. Connects as a restricted role so that row level security
 * applies; see specs/postgres.architecture.md P7. Connecting as the database owner would
 * silently bypass every policy.
 */
export const pool = new pg.Pool({ connectionString: env.DATABASE_URL });

/**
 * Runs `fn` inside a transaction carrying the caller's identity.
 *
 * Identity reaches Postgres as a transaction-scoped setting rather than a platform function.
 * The third argument to set_config marks it local to the transaction, so it cannot leak to
 * the next borrower of a pooled connection.
 *
 * Passing null runs with no identity, which every policy treats as seeing nothing.
 */
export async function withUser<T>(
	profileId: string | null,
	fn: (client: pg.PoolClient) => Promise<T>
): Promise<T> {
	const client = await pool.connect();
	try {
		await client.query('begin');
		await client.query("select set_config('app.user_id', $1, true)", [profileId ?? '']);
		const result = await fn(client);
		await client.query('commit');
		return result;
	} catch (error) {
		await client.query('rollback');
		throw error;
	} finally {
		client.release();
	}
}

/**
 * Privileged pool, connecting as the database owner and therefore exempt from row level
 * security. Reserved for one situation: bootstrapping an empty instance.
 *
 * The first user cannot be created through the ordinary path, because every insert policy
 * asks what the caller may do and on an empty instance there is no caller yet. Rather than
 * carve a permanent hole in the policies for a state that exists once in an instance's
 * lifetime, the bootstrap is an explicitly administrative operation.
 *
 * Nothing else may use this pool.
 */
const ownerPool = new pg.Pool({ connectionString: env.MIGRATION_DATABASE_URL });

export async function withOwner<T>(fn: (client: pg.PoolClient) => Promise<T>): Promise<T> {
	const client = await ownerPool.connect();
	try {
		await client.query('begin');
		const result = await fn(client);
		await client.query('commit');
		return result;
	} catch (error) {
		await client.query('rollback');
		throw error;
	} finally {
		client.release();
	}
}
