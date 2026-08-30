import navigationItems from '../config/navigation';
import { t } from '../services/TranslationService';

/**
 * Converts a snake_case field name to a human-readable label.
 * Uses field.description if available, otherwise formats the name.
 * If objectType is provided, looks up a translated label first.
 */
export function formatFieldLabel(field, objectType) {
  const english = field.description ||
    field.name.split('_').map((word) => word.charAt(0).toUpperCase() + word.slice(1)).join(' ');
  if (objectType) return t(`field.${objectType}.${field.name}`, english);
  return t(`field._.${field.name}`, english);
}

/**
 * Returns a suggested column width (px) based on field type and length.
 */
export function getColumnWidth(field) {
  if (field.type === 'boolean') return 80;
  if (field.type === 'enum') return 140;
  if (field.type === 'currency' || field.type === 'decimal') return 130;
  if (field.type === 'date') return 120;
  if (field.type === 'datetime') return 180;
  if (field.type === 'reference') return 200;
  if (field.type === 'text') return 250;
  if (field.length) return Math.min(Math.max(field.length * 8, 100), 300);
  return 150;
}

/**
 * Determines the primary display field name for an object type.
 * Returns the field name whose value best represents the record (e.g., "name1" for Account).
 */
export function getPrimaryDisplayField(fields) {
  // Check name/name1 first
  for (const p of ['name', 'name1']) {
    if (fields.find((f) => f.name === p)) return p;
  }
  // Composite first_name + last_name takes priority over title/subject
  if (fields.find((f) => f.name === 'first_name') && fields.find((f) => f.name === 'last_name')) {
    return 'first_name+last_name';
  }
  // Then try title, subject, label
  for (const p of ['title', 'subject', 'label']) {
    if (fields.find((f) => f.name === p)) return p;
  }
  // Auto-number for document objects without a name (e.g., Quotation, SalesOrder, Invoice)
  const autoNum = fields.find((f) => f.auto_generated && f.name.endsWith('_number'));
  if (autoNum) return autoNum.name;
  // Fallback: first required non-auto string field
  const fallback = fields.find(
    (f) => f.required && !f.auto_generated && !f.primary_key && (f.type === 'string' || f.type === 'text')
  );
  return fallback?.name || fields[0]?.name || 'id';
}

/**
 * Extracts the display name from a record using the primary display field.
 */
export function getDisplayName(record, fields) {
  if (!record) return '';
  const primary = getPrimaryDisplayField(fields);
  if (primary === 'first_name+last_name') {
    return [record.first_name, record.last_name].filter(Boolean).join(' ');
  }
  const value = record[primary] || '';
  // Format auto-number values (strip leading zeros)
  const field = fields.find((f) => f.name === primary);
  if (field?.auto_generated && primary.endsWith('_number') && typeof value === 'string') {
    return formatAutoNumber(value);
  }
  return value;
}

/**
 * Returns the auto-number field for an object type (e.g., account_number, contact_number).
 * Returns undefined if the object has no auto-generated number field.
 */
export function getAutoNumberField(fields) {
  return fields.find((f) => f.auto_generated && f.type === 'string' && f.name.endsWith('_number'));
}

/**
 * Maps a user-facing sort choice onto the single field a query can order by.
 *
 * A sorted query orders by one field, so the first_name + last_name composite
 * used for display resolves to last_name here. Objects with no auto-number fall
 * back to created_at, and document objects with no name at all (Quotation,
 * SalesOrder, Invoice) fall back to their number.
 *
 * @param {Array} fields - the object's specific field definitions
 * @param {'number'|'name'} mode
 * @returns {string} the field name to order by
 */
export function getSortFieldForMode(fields, mode) {
  const numberField = getAutoNumberField(fields)?.name || 'created_at';
  if (mode !== 'name') return numberField;

  const names = new Set(fields.map((f) => f.name));
  for (const p of ['name', 'name1']) {
    if (names.has(p)) return p;
  }
  if (names.has('first_name') && names.has('last_name')) return 'last_name';
  for (const p of ['title', 'subject', 'label']) {
    if (names.has(p)) return p;
  }
  return numberField;
}

/**
 * Formats an auto-number value for display by stripping leading zeros.
 * Stored as '0000000001' in DB, displayed as '1'.
 */
export function formatAutoNumber(value) {
  if (!value || typeof value !== 'string') return value;
  const stripped = value.replace(/^0+/, '');
  return stripped || '0';
}

/**
 * Formats a relationship name for display (e.g., "child_accounts" → "Child Accounts").
 */
export function formatRelationshipName(name) {
  const english = name
    .split('_')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
  return t(`rel.${name}`, english);
}

/**
 * Returns the nav label for an object type (e.g., "Account" → "Accounts").
 */
export function getObjectLabel(objectType) {
  const item = navigationItems.find((n) => n.objectType === objectType);
  const english = item
    ? item.label
    : (() => {
        const spaced = objectType.replace(/([a-z])([A-Z])/g, '$1 $2');
        return spaced.endsWith('s') ? spaced : spaced + 's';
      })();
  return t(`object.${objectType}`, english);
}
