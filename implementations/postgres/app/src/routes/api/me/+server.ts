import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

/** Echoes what the request hooks resolved, so the auth wiring can be verified end to end. */
export const GET: RequestHandler = async ({ locals }) =>
	json({ account: locals.account, profile: locals.profile });
