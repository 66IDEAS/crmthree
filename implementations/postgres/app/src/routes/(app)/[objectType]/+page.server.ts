import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import ModelRegistry from '$lib/model/ModelRegistry';
import PostgresMapper from '$lib/server/PostgresMapper';
import { listColumns } from '$lib/display';

/**
 * Generic list page (P13). Sort, page size, visible columns and per-column filters all live
 * in the URL, so any adjusted view is shareable and the back button retraces real states.
 * Filtering runs server-side through the same validated filter path as the API - the
 * reference implementation instead switches to fetching all records and filtering in the
 * browser, which 2878 products would not enjoy.
 */
const PAGE_SIZES = [25, 50, 100];

export const load: PageServerLoad = async ({ params, url, locals }) => {
	const { objectType } = params;
	if (!ModelRegistry.hasObject(objectType)) throw error(404, `No such object type: ${objectType}`);

	const profileId = locals.profile!.id;

	// Everything scalar is offerable; the default set stays the compact heuristic.
	const skip = new Set(['id', 'created_at', 'updated_at', 'created_by', 'updated_by']);
	const offerable = ModelRegistry.getObjectSchema(objectType).fields.filter(
		(f) => !skip.has(f.name) && !['json', 'text', 'reference'].includes(f.type)
	);
	const defaults = listColumns(objectType).map((f) => f.name);
	const requested = url.searchParams.get('cols')?.split(',').filter(Boolean);
	const visible = requested?.length
		? offerable.filter((f) => requested.includes(f.name))
		: offerable.filter((f) => defaults.includes(f.name));
	const columns = visible.length ? visible : offerable.slice(0, 6);

	// Per-column filters: f_<field>=value. Strings match contains, enums and booleans exact.
	const filters: { field: string; op: string; value: unknown }[] = [];
	for (const [key, raw] of url.searchParams) {
		if (!key.startsWith('f_') || raw === '') continue;
		const field = ModelRegistry.getFieldDefinition(objectType, key.slice(2));
		if (!field) continue;
		if (field.type === 'enum') filters.push({ field: field.name, op: 'eq', value: raw });
		else if (field.type === 'boolean') filters.push({ field: field.name, op: 'eq', value: raw === 'true' });
		else if (field.type === 'string') filters.push({ field: field.name, op: 'contains', value: raw });
		else filters.push({ field: field.name, op: 'eq', value: raw });
	}

	const sortField = url.searchParams.get('sort') ?? columns[0]?.name ?? 'created_at';
	const direction = url.searchParams.get('dir') === 'desc' ? 'desc' : 'asc';
	const pageSize = PAGE_SIZES.includes(Number(url.searchParams.get('pageSize')))
		? Number(url.searchParams.get('pageSize'))
		: 25;
	const cursorId = url.searchParams.get('cursorId');

	const [page, total] = await Promise.all([
		PostgresMapper.listPage(profileId, objectType, {
			filters,
			sort: { field: sortField, direction },
			pageSize,
			cursor: cursorId ? { sort: url.searchParams.get('cursorSort'), id: cursorId } : null
		}),
		PostgresMapper.count(profileId, objectType, { filters })
	]);

	return {
		objectType,
		columns,
		offerable: offerable.map((f) => ({ name: f.name, type: f.type, values: f.values ?? null })),
		defaultColumns: defaults,
		rows: page.data as Record<string, unknown>[],
		cursor: page.cursor,
		total,
		sortField,
		direction,
		pageSize,
		filtered: filters.length > 0,
		pageStart: cursorId !== null
	};
};
