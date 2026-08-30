import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import ModelRegistry from '$lib/model/ModelRegistry';
import { referenceOptions } from '$lib/server/references';

export const load: PageServerLoad = async ({ params, url, locals }) => {
	const { objectType } = params;
	if (!ModelRegistry.hasObject(objectType)) throw error(404, `No such object type: ${objectType}`);
	const fields = ModelRegistry.getSpecificFields(objectType).filter((f) => !f.auto_generated);
	// A "New X" button on a related card prefills the linking fields through the URL. Only
	// names the model knows are accepted.
	const prefill: Record<string, string> = {};
	for (const [key, value] of url.searchParams) {
		if (ModelRegistry.getFieldDefinition(objectType, key)) prefill[key] = value;
	}
	return {
		objectType,
		fields,
		prefill,
		options: await referenceOptions(locals.profile!.id, objectType)
	};
};
