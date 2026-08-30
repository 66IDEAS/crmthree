import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import ModelRegistry from '$lib/model/ModelRegistry';
import PostgresMapper from '$lib/server/PostgresMapper';
import { referenceOptions, resolveReferences } from '$lib/server/references';

export const load: PageServerLoad = async ({ params, locals }) => {
	const { objectType, id } = params;
	if (!ModelRegistry.hasObject(objectType)) throw error(404, `No such object type: ${objectType}`);

	const profileId = locals.profile!.id;
	const record = (await PostgresMapper.getById(profileId, objectType, id)) as Record<string, unknown> | null;
	// Hidden-by-policy and nonexistent are indistinguishable on purpose.
	if (!record) throw error(404, 'Not found');

	const [referenceNames, options] = await Promise.all([
		resolveReferences(profileId, objectType, record),
		referenceOptions(profileId, objectType)
	]);

	return {
		objectType,
		record,
		referenceNames,
		options,
		fields: ModelRegistry.getSpecificFields(objectType),
		profileId
	};
};
