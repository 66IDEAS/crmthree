import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import ModelRegistry from '$lib/model/ModelRegistry';
import { referenceOptions } from '$lib/server/references';

export const load: PageServerLoad = async ({ params, locals }) => {
	const { objectType } = params;
	if (!ModelRegistry.hasObject(objectType)) throw error(404, `No such object type: ${objectType}`);
	const fields = ModelRegistry.getSpecificFields(objectType).filter((f) => !f.auto_generated);
	return {
		objectType,
		fields,
		options: await referenceOptions(locals.profile!.id, objectType)
	};
};
