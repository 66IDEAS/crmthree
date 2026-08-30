import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import ModelRegistry from '$lib/model/ModelRegistry';
import PostgresMapper from '$lib/server/PostgresMapper';
import { listColumns } from '$lib/display';

/**
 * Generic list page (P13): one route serves every object type, driven entirely by the model.
 * Data is fetched during server render, so the page arrives with rows instead of a spinner.
 * Sort and cursor live in the URL, which makes pagination shareable and the back button an
 * honest "previous page".
 */
export const load: PageServerLoad = async ({ params, url, locals }) => {
	const { objectType } = params;
	if (!ModelRegistry.hasObject(objectType)) throw error(404, `No such object type: ${objectType}`);

	const profileId = locals.profile!.id;
	const columns = listColumns(objectType);
	const sortField = url.searchParams.get('sort') ?? columns[0]?.name ?? 'created_at';
	const direction = url.searchParams.get('dir') === 'desc' ? 'desc' : 'asc';
	const cursorId = url.searchParams.get('cursorId');

	const [page, total] = await Promise.all([
		PostgresMapper.listPage(profileId, objectType, {
			sort: { field: sortField, direction },
			pageSize: 25,
			cursor: cursorId ? { sort: url.searchParams.get('cursorSort'), id: cursorId } : null
		}),
		PostgresMapper.count(profileId, objectType)
	]);

	return {
		objectType,
		columns,
		rows: page.data as Record<string, unknown>[],
		cursor: page.cursor,
		total,
		sortField,
		direction,
		pageStart: cursorId !== null
	};
};
