import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import ModelRegistry from '$lib/model/ModelRegistry';
import PostgresMapper from '$lib/server/PostgresMapper';
import { referenceOptions, resolveReferences } from '$lib/server/references';
import { relatedCards } from '$lib/server/related';
import { DOCUMENT_CONVERSIONS } from '$lib/server/conversions';
import { activeConfig } from '$lib/server/ai';
import { listColumns, displayName } from '$lib/display';

export const load: PageServerLoad = async ({ params, locals }) => {
	const { objectType, id } = params;
	if (!ModelRegistry.hasObject(objectType)) throw error(404, `No such object type: ${objectType}`);

	const profileId = locals.profile!.id;
	const record = (await PostgresMapper.getById(profileId, objectType, id)) as Record<string, unknown> | null;
	// Hidden-by-policy and nonexistent are indistinguishable on purpose.
	if (!record) throw error(404, 'Not found');

	const [referenceNames, options, related] = await Promise.all([
		resolveReferences(profileId, objectType, record),
		referenceOptions(profileId, objectType),
		relatedCards(profileId, objectType, record)
	]);

	// Each card needs its target's columns; many-to-many cards also need candidates for the
	// link dialog, loaded under the caller's identity like every picker.
	const NAMEISH = new Set(['name', 'name1', 'first_name', 'last_name', 'subject', 'title', 'label']);
	const cardColumns = Object.fromEntries(
		related.map((card) => [
			card.name,
			// The first cell already shows the display name, so its source columns would
			// only repeat it.
			listColumns(card.target).filter((f) => !NAMEISH.has(f.name)).slice(0, 3)
		])
	);
	const linkOptions: Record<string, { id: string; label: string }[]> = {};
	for (const card of related) {
		if (card.kind !== 'many-to-many') continue;
		const rows = (await PostgresMapper.list(profileId, card.target, { pageSize: 200 }).catch(() => [])) as Record<string, unknown>[];
		linkOptions[card.name] = rows.map((row) => ({ id: String(row.id), label: displayName(row) }));
	}

	return {
		objectType,
		record,
		referenceNames,
		options,
		related,
		conversions: (DOCUMENT_CONVERSIONS[objectType] ?? []).map(({ targetType, label }) => ({ targetType, label })),
		// Comment threads belong to the rooms (stories 33/34): the Deal Room and the Case
		// Room each render their own. The ticket detail links to its Case Room instead.
		caseRoom: objectType === 'Ticket',
		// The briefing card exists only for supported types AND a configured provider.
		aiBriefing:
			['Account', 'Contact', 'Lead', 'Opportunity', 'Ticket', 'Quotation', 'SalesOrder', 'Invoice', 'Activity'].includes(objectType) &&
			(await activeConfig().then(Boolean).catch(() => false)),
		isLead: objectType === 'Lead',
		cardColumns,
		linkOptions,
		fields: ModelRegistry.getSpecificFields(objectType),
		profileId
	};
};
