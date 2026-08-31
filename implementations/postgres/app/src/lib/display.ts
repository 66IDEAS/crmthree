import ModelRegistry from '$lib/model/ModelRegistry';
import { t } from '$lib/i18n';

/**
 * Display helpers shared by list, detail and form pages. The name resolution order matches
 * the reference implementation: name/name1, then a first+last composite, then
 * title/subject/label, then an auto-number, then the id.
 */
export function displayName(record: Record<string, unknown> | null | undefined): string {
	if (!record) return '';
	for (const key of ['name', 'name1']) {
		if (record[key]) return String(record[key]);
	}
	const composite = [record.first_name, record.last_name].filter(Boolean).join(' ');
	if (composite) return composite;
	for (const key of ['subject', 'title', 'label']) {
		if (record[key]) return String(record[key]);
	}
	const numberField = Object.keys(record).find((k) => k.endsWith('_number'));
	if (numberField && record[numberField] != null) return `#${record[numberField]}`;
	return String(record.id ?? '');
}

/** The reference navigation labels; they define the object.* keys of the shared catalog. */
export const NAV_LABELS: Record<string, string> = {
	Account: 'Accounts', Contact: 'Contacts', Lead: 'Leads', Opportunity: 'Opportunities',
	DealRoom: 'Deal Rooms', Quotation: 'Quotes', SalesOrder: 'Sales Orders', Invoice: 'Invoices',
	Product: 'Products', Activity: 'Activities', Ticket: 'Tickets', CaseRoom: 'Case Rooms',
	KnowledgeArticle: 'Knowledge', Asset: 'Assets', SLA: 'SLAs', ServiceContract: 'Contracts'
};

const capWords = (name: string) =>
	name.split('_').map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');

/** English default for a field, the reference rule: model description, else the capitalised name. */
export function fieldEnglish(field: { name: string; description?: string }): string {
	return field.description || capWords(field.name);
}

const COMMON_FIELDS = new Set(['id', 'created_at', 'updated_at', 'created_by', 'updated_by']);

/**
 * Human label for a field, keyed to the shared catalog: `field.<ObjectType>.<name>` for
 * object fields, `field._common.<name>` for the five common fields. Mirrors the reference
 * implementation's formatFieldLabel, including its English defaults.
 */
export function fieldLabel(
	field: string | { name: string; description?: string },
	objectType?: string
): string {
	let def = typeof field === 'string' ? undefined : field;
	const name = typeof field === 'string' ? field : field.name;
	if (!def && objectType && ModelRegistry.hasObject(objectType)) {
		def = ModelRegistry.getObjectSchema(objectType).fields.find((f) => f.name === name);
	}
	const english = fieldEnglish(def ?? { name });
	if (COMMON_FIELDS.has(name)) return t(`field._common.${name}`, english);
	if (objectType) return t(`field.${objectType}.${name}`, english);
	return t(`field._.${name}`, english);
}

/** Translated enum value for display; the stored value stays English (story 60). */
export function enumLabel(value: string): string {
	return t(`enum.${value}`, value);
}

/** Translated relationship name: `child_accounts` -> "Child Accounts". */
export function relLabel(name: string): string {
	return t(`rel.${name}`, capWords(name));
}

const GOOD = new Set(['Active', 'Won', 'Paid', 'Completed', 'Published', 'Accepted', 'Confirmed', 'Qualified', 'Converted']);
const BAD = new Set(['Lost', 'Cancelled', 'Overdue', 'Inactive', 'Rejected', 'Expired', 'Critical', 'Terminated', 'Retired', 'Unqualified']);
const WARN = new Set(['High', 'In Progress', 'In Review', 'Sent', 'Contacted', 'In Repair', 'Partially Paid', 'Shipped']);

/** Tailwind classes for an enum chip; filled tints of the brand's semantic colours. */
export function enumChipClass(value: string): string {
	if (GOOD.has(value)) return 'bg-success/10 text-success';
	if (BAD.has(value)) return 'bg-error/10 text-error';
	if (WARN.has(value)) return 'bg-warning/10 text-warning';
	return 'bg-rule/40 text-ink/70';
}

/** Monogram for the collapsed navigation rail: initials of the words in the type name. */
export function monogram(objectType: string): string {
	const words = objectType.replace(/([a-z])([A-Z])/g, '$1 $2').split(' ');
	return (words.length > 1 ? words[0][0] + words[1][0] : objectType.slice(0, 2)).toUpperCase();
}

/** A date-ish value as ISO YYYY-MM-DD, whether it arrives as Date or string. */
export function isoDate(value: unknown): string {
	if (value instanceof Date) return value.toISOString().slice(0, 10);
	return String(value).slice(0, 10);
}

/** A datetime-ish value as an ISO minute string for datetime-local inputs. */
export function isoDateTime(value: unknown): string {
	const date = value instanceof Date ? value : new Date(String(value));
	return isNaN(date.getTime()) ? String(value).slice(0, 16) : date.toISOString().slice(0, 16);
}

export function formatValue(field: { type: string; auto_generated?: boolean }, value: unknown): string {
	if (value == null || value === '') return '—';
	// Auto-numbers are stored in their SAP-compatible zero-padded form; purely numeric ones
	// display without the padding, alphanumeric replicated identifiers display as they are.
	if (field.auto_generated && /^0*\d+$/.test(String(value))) {
		return String(Number(value));
	}
	switch (field.type) {
		case 'currency':
			return new Intl.NumberFormat(undefined, { minimumFractionDigits: 2 }).format(Number(value));
		case 'date':
			return isoDate(value);
		case 'datetime':
			return new Date(String(value)).toLocaleString();
		case 'boolean':
			return value ? t('ui.yes', 'Yes') : t('ui.no', 'No');
		case 'enum':
			return enumLabel(String(value));
		default:
			return String(value);
	}
}

/**
 * Curated default columns where the model-order heuristic picks badly: Account would burn
 * four slots on empty address fragments, Contact would lead with the salutation, Product
 * would duplicate its group twice. Types not listed keep the heuristic.
 */
const LIST_COLUMN_DEFAULTS: Record<string, string[]> = {
	Account: ['account_number', 'name1', 'city', 'country', 'industry_description', 'status'],
	Contact: ['contact_number', 'first_name', 'last_name', 'email', 'phone', 'status'],
	Lead: ['lead_number', 'first_name', 'last_name', 'company', 'email', 'status'],
	Product: ['product_number', 'name', 'product_group', 'unit_of_measure', 'base_price', 'status'],
	Ticket: ['ticket_number', 'subject', 'priority', 'category', 'sla_response_deadline']
};

/** Columns worth showing in a list: curated where needed, else scalar fields in model order. */
export function listColumns(objectType: string) {
	const curated = LIST_COLUMN_DEFAULTS[objectType];
	const fields = ModelRegistry.getObjectSchema(objectType).fields;
	if (curated) {
		return curated
			.map((name) => fields.find((f) => f.name === name))
			.filter(Boolean) as typeof fields;
	}
	const skip = new Set(['id', 'created_at', 'updated_at', 'created_by', 'updated_by']);
	return fields
		.filter((f) => !skip.has(f.name) && !['reference', 'json', 'text'].includes(f.type))
		.slice(0, 6);
}

/** The object types shown in the navigation rail. */
export const NAV_OBJECTS = [
	'Account', 'Contact', 'Lead', 'Opportunity', 'DealRoom', 'CaseRoom', 'Quotation', 'SalesOrder',
	'Invoice', 'Product', 'Activity', 'Ticket', 'KnowledgeArticle', 'Asset',
	'ServiceContract', 'SLA', 'Timeline'
] as const;

/** Nav entries that are workspaces over another type rather than model objects. */
export const NAV_VIRTUAL = new Set(['CaseRoom', 'Timeline']);

/**
 * Object type label. Plural uses the shared catalog's `object.<Type>` key, whose values are
 * the reference navigation labels. The singular form is not in the shared catalog - the
 * reference never translates it - so it stays English.
 */
export function objectLabel(objectType: string, plural = false): string {
	const spaced = objectType.replace(/([a-z])([A-Z])/g, '$1 $2');
	if (!plural) return spaced;
	let fallback = NAV_LABELS[objectType];
	if (!fallback) {
		if (objectType === 'Timeline') fallback = 'Team Timeline';
		else if (spaced.endsWith('y')) fallback = spaced.slice(0, -1) + 'ies';
		else if (spaced.endsWith('s')) fallback = spaced;
		else fallback = spaced + 's';
	}
	return t(`object.${objectType}`, fallback);
}
