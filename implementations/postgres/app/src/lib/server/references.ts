import ModelRegistry from '$lib/model/ModelRegistry';
import PostgresMapper from './PostgresMapper';
import { displayName } from '$lib/display';

export type ReferenceOption = { id: string; label: string };

/**
 * Options for every reference field of an object type, for edit and create forms. Loaded
 * under the caller's identity, so a picker only ever offers records the user could read.
 * Capped per target; a searching combobox replaces this when datasets outgrow it.
 */
export async function referenceOptions(
	profileId: string,
	objectType: string
): Promise<Record<string, ReferenceOption[]>> {
	const fields = ModelRegistry.getObjectSchema(objectType).fields.filter(
		(f) => f.type === 'reference' && !['created_by', 'updated_by'].includes(f.name)
	);
	const entries = await Promise.all(
		fields.map(async (field) => {
			const rows = await PostgresMapper.list(profileId, field.target as string, { pageSize: 200 }).catch(
				() => []
			);
			return [
				field.name,
				rows.map((row: Record<string, unknown>) => ({ id: String(row.id), label: displayName(row) }))
			] as const;
		})
	);
	return Object.fromEntries(entries);
}

/** Resolves each populated reference field of one record to a display name. */
export async function resolveReferences(
	profileId: string,
	objectType: string,
	record: Record<string, unknown>
): Promise<Record<string, string>> {
	const fields = ModelRegistry.getObjectSchema(objectType).fields.filter(
		(f) => f.type === 'reference' && record[f.name]
	);
	const entries = await Promise.all(
		fields.map(async (field) => {
			const target = field.name === 'created_by' || field.name === 'updated_by' ? 'UserProfile' : (field.target as string);
			const row = await PostgresMapper.getById(profileId, target, String(record[field.name])).catch(() => null);
			return [field.name, row ? displayName(row) : String(record[field.name])] as const;
		})
	);
	return Object.fromEntries(entries);
}
