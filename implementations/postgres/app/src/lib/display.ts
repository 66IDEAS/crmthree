import ModelRegistry from '$lib/model/ModelRegistry';

/**
 * Display helpers shared by list, detail and form pages. The name resolution order matches
 * the reference implementation: name/name1, then a first+last composite, then
 * title/subject/label, then an auto-number, then the id.
 */
export function displayName(record: Record<string, unknown> | null | undefined): string {
	if (!record) return '';
	for (const key of ['name', 'name1', 'title', 'subject', 'label']) {
		if (record[key]) return String(record[key]);
	}
	const composite = [record.first_name, record.last_name].filter(Boolean).join(' ');
	if (composite) return composite;
	const numberField = Object.keys(record).find((k) => k.endsWith('_number'));
	if (numberField && record[numberField] != null) return `#${record[numberField]}`;
	return String(record.id ?? '');
}

/** Human label for a field name: account_id -> Account, first_name -> First Name. */
export function fieldLabel(name: string): string {
	return name
		.replace(/_id$/, '')
		.split('_')
		.map((part) => part.charAt(0).toUpperCase() + part.slice(1))
		.join(' ');
}

const GOOD = new Set(['Active', 'Won', 'Paid', 'Completed', 'Published', 'Accepted', 'Confirmed', 'Qualified', 'Converted']);
const BAD = new Set(['Lost', 'Cancelled', 'Overdue', 'Inactive', 'Rejected', 'Expired', 'Critical', 'Terminated', 'Retired', 'Unqualified']);
const WARN = new Set(['High', 'In Progress', 'In Review', 'Sent', 'Contacted', 'In Repair', 'Partially Paid', 'Shipped']);

/** Tailwind classes for an enum chip; filled, per the product convention. */
export function enumChipClass(value: string): string {
	if (GOOD.has(value)) return 'bg-emerald-100 text-emerald-800';
	if (BAD.has(value)) return 'bg-red-100 text-red-700';
	if (WARN.has(value)) return 'bg-amber-100 text-amber-800';
	return 'bg-zinc-200 text-zinc-700';
}

export function formatValue(field: { type: string }, value: unknown): string {
	if (value == null || value === '') return '—';
	switch (field.type) {
		case 'currency':
			return new Intl.NumberFormat(undefined, { minimumFractionDigits: 2 }).format(Number(value));
		case 'date':
			return String(value).slice(0, 10);
		case 'datetime':
			return new Date(String(value)).toLocaleString();
		case 'boolean':
			return value ? 'Yes' : 'No';
		default:
			return String(value);
	}
}

/** Columns worth showing in a list: scalar, short, not references, model order. */
export function listColumns(objectType: string) {
	const skip = new Set(['id', 'created_at', 'updated_at', 'created_by', 'updated_by']);
	return ModelRegistry.getObjectSchema(objectType)
		.fields.filter(
			(f) => !skip.has(f.name) && !['reference', 'json', 'text'].includes(f.type)
		)
		.slice(0, 6);
}

/** The object types shown in the navigation rail. */
export const NAV_OBJECTS = [
	'Account', 'Contact', 'Lead', 'Opportunity', 'DealRoom', 'Quotation', 'SalesOrder',
	'Invoice', 'Product', 'Activity', 'Ticket', 'KnowledgeArticle', 'Asset',
	'ServiceContract', 'SLA'
] as const;

/** Object -> human plural for nav and headings, only where naive pluralisation fails. */
export function objectLabel(objectType: string, plural = false): string {
	const spaced = objectType.replace(/([a-z])([A-Z])/g, '$1 $2');
	if (!plural) return spaced;
	if (objectType === 'SLA') return 'SLAs';
	if (spaced.endsWith('y')) return spaced.slice(0, -1) + 'ies';
	return spaced + 's';
}
