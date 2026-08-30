import ModelRegistry from '../model/ModelRegistry';
import { formatFieldLabel, formatAutoNumber, getAutoNumberField } from './fieldUtils';

/**
 * F19: CSV Import/Export utilities.
 */

/**
 * Returns the exportable fields for an object type.
 * Excludes: primary_key, common audit fields (created_by, updated_by).
 * Includes auto-number (read-only in export) and all user-editable fields.
 */
export function getExportFields(objectType) {
  const fields = ModelRegistry.getSpecificFields(objectType);
  return fields.filter(
    (f) => !f.primary_key && f.name !== 'created_by' && f.name !== 'updated_by'
  );
}

/**
 * Returns the importable fields for an object type.
 * Includes auto_generated fields (e.g. product_number) so external values
 * (such as SAP material numbers) can be imported via CSV.
 * Excludes: primary_key, common audit fields.
 */
export function getImportFields(objectType) {
  const fields = ModelRegistry.getSpecificFields(objectType);
  return fields.filter(
    (f) =>
      !f.primary_key &&
      f.name !== 'created_by' &&
      f.name !== 'updated_by' &&
      f.name !== 'created_at' &&
      f.name !== 'updated_at'
  );
}

/**
 * Exports records to a CSV string.
 * Uses field descriptions as column headers.
 * Formats auto-numbers without leading zeros.
 */
export function exportToCsv(objectType, records) {
  const fields = getExportFields(objectType);
  const headers = fields.map((f) => formatFieldLabel(f, objectType));

  const rows = records.map((record) =>
    fields.map((field) => {
      let val = record[field.name];
      if (val === null || val === undefined) return '';
      // Format auto-numbers
      if (field.auto_generated && field.name.endsWith('_number')) {
        val = formatAutoNumber(String(val));
      }
      // Escape CSV values
      val = String(val);
      if (val.includes(',') || val.includes('"') || val.includes('\n')) {
        val = '"' + val.replace(/"/g, '""') + '"';
      }
      return val;
    })
  );

  const csvContent = [headers.map(escapeCell).join(','), ...rows.map((r) => r.join(','))].join(
    '\n'
  );
  return csvContent;
}

function escapeCell(val) {
  const s = String(val);
  if (s.includes(',') || s.includes('"') || s.includes('\n')) {
    return '"' + s.replace(/"/g, '""') + '"';
  }
  return s;
}

/**
 * Triggers a CSV file download in the browser.
 */
export function downloadCsv(csvContent, filename) {
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
}

/**
 * Parses a CSV string into an array of objects.
 * First row is treated as headers.
 */
export function parseCsv(csvText) {
  const lines = [];
  let current = '';
  let inQuotes = false;

  for (let i = 0; i < csvText.length; i++) {
    const ch = csvText[i];
    if (ch === '"') {
      if (inQuotes && csvText[i + 1] === '"') {
        current += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (ch === '\n' && !inQuotes) {
      lines.push(current);
      current = '';
    } else if (ch === '\r' && !inQuotes) {
      // skip \r
    } else {
      current += ch;
    }
  }
  if (current.trim()) lines.push(current);

  if (lines.length === 0) return { headers: [], rows: [] };

  const splitLine = (line) => {
    const cells = [];
    let cell = '';
    let q = false;
    for (let i = 0; i < line.length; i++) {
      const ch = line[i];
      if (ch === '"') {
        if (q && line[i + 1] === '"') {
          cell += '"';
          i++;
        } else {
          q = !q;
        }
      } else if (ch === ',' && !q) {
        cells.push(cell);
        cell = '';
      } else {
        cell += ch;
      }
    }
    cells.push(cell);
    return cells;
  };

  const headers = splitLine(lines[0]);
  const rows = lines.slice(1).map((line) => {
    const cells = splitLine(line);
    const obj = {};
    headers.forEach((h, i) => {
      obj[h] = cells[i] !== undefined ? cells[i].trim() : '';
    });
    return obj;
  });

  return { headers, rows };
}

/**
 * Auto-maps CSV column headers to CRM field definitions.
 * Matches by field name (exact or normalized) or description.
 * Returns a map: { csvHeader: fieldName | null }
 */
export function autoMapFields(csvHeaders, objectType) {
  const fields = getImportFields(objectType);
  const mapping = {};

  for (const header of csvHeaders) {
    const h = header.trim();
    const hLower = h.toLowerCase();
    const hNormalized = hLower.replace(/[\s_-]+/g, '_');

    // Exact field name match
    let match = fields.find((f) => f.name === h);

    // Case-insensitive field name match
    if (!match) match = fields.find((f) => f.name.toLowerCase() === hLower);

    // Normalized match (spaces/hyphens → underscores)
    if (!match) match = fields.find((f) => f.name.toLowerCase() === hNormalized);

    // Description match (case-insensitive)
    if (!match) match = fields.find((f) => f.description && f.description.toLowerCase() === hLower);

    // Partial description match
    if (!match)
      match = fields.find(
        (f) =>
          f.description &&
          (f.description.toLowerCase().includes(hLower) ||
            hLower.includes(f.description.toLowerCase()))
      );

    mapping[h] = match ? match.name : null;
  }

  return mapping;
}
