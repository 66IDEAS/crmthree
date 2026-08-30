import ModelRegistry from '$lib/model/ModelRegistry';
import PostgresMapper from './PostgresMapper';
import { displayName } from '$lib/display';

/**
 * Related records for a detail page (story 58, UX21), derived entirely from the model's
 * relationship definitions: one-to-many via foreign key, polymorphic one-to-many via the
 * declared condition (line items, documents), many-to-many via the junction object. No
 * per-object code; a new relationship in the model appears as a card by itself.
 */
export type RelatedRow = Record<string, unknown> & { _display: string; _junctionId?: string };
export type RelatedCard = {
	name: string;
	target: string;
	kind: 'one-to-many' | 'many-to-many';
	rows: RelatedRow[];
	total: number;
	/** many-to-many only: what a link dialog needs to create a junction row. */
	junction?: { objectType: string; thisField: string; otherField: string };
	/** one-to-many only: prefill for the New button. */
	prefill?: Record<string, string>;
};

const CARD_ROWS = 8;

function parseCondition(condition?: string): { field: string; value: string } | null {
	const match = condition?.match(/^(\w+)\s*=\s*'([^']+)'$/);
	return match ? { field: match[1], value: match[2] } : null;
}

export async function relatedCards(
	profileId: string,
	objectType: string,
	record: Record<string, unknown>
): Promise<RelatedCard[]> {
	const relationships = ModelRegistry.getRelationships(objectType);
	const id = String(record.id);

	const cards = await Promise.all(
		relationships.map(async (rel): Promise<RelatedCard | null> => {
			try {
				if (rel.type === 'one-to-many' && rel.foreign_key) {
					const filters = [{ field: rel.foreign_key, op: 'eq', value: id }];
					const condition = parseCondition((rel as { condition?: string }).condition);
					if (condition) filters.push({ field: condition.field, op: 'eq', value: condition.value });
					const [page, total] = await Promise.all([
						PostgresMapper.listPage(profileId, rel.target, { filters, pageSize: CARD_ROWS }),
						PostgresMapper.count(profileId, rel.target, { filters })
					]);
					const prefill: Record<string, string> = { [rel.foreign_key]: id };
					if (condition) prefill[condition.field] = condition.value;
					return {
						name: rel.name,
						target: rel.target,
						kind: 'one-to-many',
						rows: page.data.map((row: Record<string, unknown>) => ({ ...row, _display: displayName(row) })),
						total,
						prefill
					};
				}

				if (rel.type === 'many-to-many' && rel.through) {
					const junctionRefs = ModelRegistry.getSpecificFields(rel.through).filter(
						(f) => f.type === 'reference'
					);
					// The side pointing back at us and the side pointing at the target. A
					// self-referencing junction would need role hints; none exists in the model.
					const thisField = junctionRefs.find((f) => f.target === objectType)?.name;
					const otherField = junctionRefs.find((f) => f.target === rel.target && f.name !== thisField)?.name;
					if (!thisField || !otherField) return null;

					const filters = [{ field: thisField, op: 'eq', value: id }];
					const [page, total] = await Promise.all([
						PostgresMapper.listPage(profileId, rel.through, { filters, pageSize: CARD_ROWS }),
						PostgresMapper.count(profileId, rel.through, { filters })
					]);
					const rows = (
						await Promise.all(
							page.data.map(async (junction: Record<string, unknown>) => {
								const target = await PostgresMapper.getById(
									profileId,
									rel.target,
									String(junction[otherField])
								);
								if (!target) return null;
								return { ...target, _display: displayName(target), _junctionId: String(junction.id) };
							})
						)
					).filter(Boolean) as RelatedRow[];
					return {
						name: rel.name,
						target: rel.target,
						kind: 'many-to-many',
						rows,
						total,
						junction: { objectType: rel.through, thisField, otherField }
					};
				}
			} catch {
				// A card that cannot load (say, the caller lacks read on the target) is simply
				// absent, matching how RLS treats the data itself.
				return null;
			}
			return null;
		})
	);
	return cards.filter(Boolean) as RelatedCard[];
}
