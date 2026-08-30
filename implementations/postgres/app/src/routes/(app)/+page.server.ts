import type { PageServerLoad } from './$types';
import PostgresMapper from '$lib/server/PostgresMapper';
import { NAV_OBJECTS } from '$lib/display';

/** Dashboard: one count per navigable object, gathered in parallel, rendered on the server. */
export const load: PageServerLoad = async ({ locals }) => {
	const profileId = locals.profile!.id;
	const counts = await Promise.all(
		NAV_OBJECTS.map(async (objectType) => ({
			objectType,
			total: await PostgresMapper.count(profileId, objectType).catch(() => 0)
		}))
	);
	return { counts };
};
