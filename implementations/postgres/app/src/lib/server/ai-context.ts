import ModelRegistry from '$lib/model/ModelRegistry';
import { tableName } from './PostgresMapper';
import { withUser } from './db';
import { displayName } from '$lib/display';

/**
 * Data-aware context injection (stories 20-23), ported from the reference Cloud Function.
 * User messages are scanned for object-type keywords, matching types are queried under the
 * caller's identity - so the AI can only ever see what the asking user could see - and the
 * records are prepended as compact pipe-separated context with ids, enabling record-level
 * references in answers.
 */
const OBJECT_TYPE_KEYWORDS: Record<string, string[]> = {
	Account: ['account', 'customer', 'company', 'client', 'partner', 'vendor'],
	Contact: ['contact', 'person', 'people'],
	Lead: ['lead'],
	Opportunity: ['opportunity', 'deal', 'pipeline', 'forecast'],
	Quotation: ['quote', 'quotation', 'proposal'],
	SalesOrder: ['sales order', 'order'],
	Invoice: ['invoice', 'billing', 'payment'],
	Product: ['product', 'material', 'item', 'catalog'],
	Activity: ['activity', 'call', 'meeting', 'task', 'email', 'event'],
	Ticket: ['ticket', 'case', 'issue', 'support', 'service request'],
	KnowledgeArticle: ['knowledge', 'article', 'faq'],
	Asset: ['asset', 'equipment', 'device', 'hardware'],
	SLA: ['sla', 'service level'],
	ServiceContract: ['contract', 'service contract', 'agreement']
};

const KEY_FIELDS: Record<string, string[]> = {
	Account: ['name1', 'name2', 'industry_description', 'annual_revenue', 'company_size', 'city', 'country'],
	Contact: ['first_name', 'last_name', 'email', 'phone', 'position'],
	Lead: ['first_name', 'last_name', 'company', 'status', 'source', 'email'],
	Opportunity: ['name', 'amount', 'expected_close_date', 'probability', 'result'],
	Quotation: ['quotation_number', 'status', 'total_amount', 'valid_until'],
	SalesOrder: ['order_number', 'status', 'total_amount', 'order_date'],
	Invoice: ['invoice_number', 'status', 'total_amount', 'due_date'],
	Product: ['name', 'product_number', 'base_price', 'product_group', 'status'],
	Activity: ['subject', 'type', 'status', 'due_date', 'priority'],
	Ticket: ['subject', 'priority', 'category', 'created_at'],
	KnowledgeArticle: ['title', 'category', 'status'],
	Asset: ['name', 'serial_number', 'status', 'installation_date'],
	SLA: ['name', 'response_time_hours', 'resolution_time_hours'],
	ServiceContract: ['name', 'status', 'start_date', 'end_date']
};

type Message = { role: string; content: string };

export function detectRelevantTypes(messages: Message[]): string[] {
	const text = messages.filter((m) => m.role !== 'system').map((m) => m.content).join(' ').toLowerCase();
	const matched: string[] = [];
	for (const [objectType, keywords] of Object.entries(OBJECT_TYPE_KEYWORDS)) {
		if (keywords.some((keyword) => text.includes(keyword))) {
			matched.push(objectType);
			if (matched.length >= 3) break;
		}
	}
	return matched.length ? matched : ['Account', 'Opportunity'];
}

function columnsFor(objectType: string): string[] {
	return (KEY_FIELDS[objectType] ?? []).filter((name) =>
		ModelRegistry.getFieldDefinition(objectType, name)
	);
}

export async function buildDataContext(profileId: string, types: string[], perType = 100): Promise<string> {
	const sections = await Promise.all(
		types.map(async (objectType) => {
			const columns = columnsFor(objectType);
			if (!columns.length) return '';
			const rows = await withUser(profileId, (client) =>
				client
					.query(
						`select id, ${columns.map((c) => `"${c}"`).join(', ')} from ${tableName(objectType)}
						 order by updated_at desc limit ${perType}`
					)
					.then((r) => r.rows)
			).catch(() => []);
			if (!rows.length) return '';
			const lines = rows.map((row: Record<string, unknown>) =>
				[row.id, ...columns.map((c) => row[c] ?? '')].join(' | ')
			);
			return `## ${objectType} (id | ${columns.join(' | ')})\n${lines.join('\n')}`;
		})
	);
	return sections.filter(Boolean).join('\n\n');
}

/** Context for a record-level briefing: the record itself plus its related records. */
export async function buildRecordContext(
	profileId: string,
	objectType: string,
	record: Record<string, unknown>
): Promise<string> {
	const parts = [`# ${objectType}: ${displayName(record)}`];
	for (const [key, value] of Object.entries(record)) {
		if (value !== null && value !== undefined && value !== '') parts.push(`${key}: ${value}`);
	}
	const { relatedCards } = await import('./related');
	const cards = await relatedCards(profileId, objectType, record);
	for (const card of cards) {
		if (!card.rows.length) continue;
		parts.push(`\n## ${card.name} (${card.total})`);
		for (const row of card.rows) parts.push(`- ${row._display}`);
	}
	return parts.join('\n');
}
