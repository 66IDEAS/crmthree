import DataService from './DataService';
import ModelRegistry from '../model/ModelRegistry';
import { getDisplayName } from '../utils/fieldUtils';

/**
 * Audit Log Service — captures CRM events (record creations and field changes)
 * for display in the User Timeline and Team Timeline.
 * Follows the same silent-failure pattern as NotificationTrigger and GamificationTrigger.
 */

/** Fields worth tracking per object type. Only these field changes get logged. */
const TRACKED_FIELDS = {
  Opportunity: ['stage_id', 'result', 'owner_id'],
  Lead: ['status', 'owner_id'],
  Ticket: ['status_id', 'priority', 'assigned_to', 'owner_id'],
  Account: ['owner_id'],
  Contact: ['owner_id'],
  SalesOrder: ['status', 'owner_id'],
  Quotation: ['status', 'owner_id'],
  Invoice: ['status', 'owner_id'],
};

/** Human-readable field labels for summary text */
const FIELD_LABELS = {
  stage_id: 'stage',
  status_id: 'status',
  status: 'status',
  result: 'result',
  priority: 'priority',
  owner_id: 'owner',
  assigned_to: 'assignee',
};

function resolveDisplayName(data, objectType) {
  try {
    const fields = ModelRegistry.getSpecificFields(objectType);
    return getDisplayName(data, fields) || '';
  } catch {
    return '';
  }
}

function formatObjectLabel(objectType) {
  // "SalesOrder" → "Sales Order", "KnowledgeArticle" → "Knowledge Article"
  return objectType.replace(/([a-z])([A-Z])/g, '$1 $2');
}

/** Maps reference ID fields to their lookup object types and display fields. */
const REFERENCE_LOOKUPS = {
  stage_id: { type: 'PipelineStage', display: ['name', 'stage_name'] },
  status_id: { type: 'TicketStatus', display: ['name', 'status_name'] },
  owner_id: { type: 'UserProfile', display: ['first_name', 'last_name'] },
  assigned_to: { type: 'UserProfile', display: ['first_name', 'last_name'] },
};

/**
 * Resolve a reference ID to a human-readable name.
 * Returns the original value if lookup fails.
 */
async function resolveReferenceValue(fieldName, value) {
  if (!value) return value;
  const lookup = REFERENCE_LOOKUPS[fieldName];
  if (!lookup) return value;

  try {
    const record = await DataService.getById(lookup.type, value);
    if (!record) return value;

    // For user profiles, combine first + last name
    if (lookup.display.includes('first_name')) {
      const name = [record.first_name, record.last_name].filter(Boolean).join(' ');
      return name || value;
    }

    // For other references, try each display field
    for (const field of lookup.display) {
      if (record[field]) return record[field];
    }
    return value;
  } catch {
    return value;
  }
}

/**
 * Log a record creation event.
 * @param {string} objectType
 * @param {string} recordId
 * @param {object} data - The created record data
 * @param {string} userId
 */
export async function logCreate(objectType, recordId, data, userId) {
  if (!userId || !objectType) return;
  try {
    const objectName = resolveDisplayName(data, objectType);
    const label = formatObjectLabel(objectType);
    const summary = objectName
      ? `Created ${label} "${objectName}"`
      : `Created ${label}`;

    await DataService.create('AuditLog', {
      object_type: objectType,
      object_id: recordId,
      action: 'Create',
      user_id: userId,
      timestamp: new Date().toISOString(),
      object_name: objectName,
      summary,
    });
  } catch {
    // Silent — audit logging should never block workflow
  }
}

/**
 * Log field change events for tracked fields.
 * @param {string} objectType
 * @param {string} recordId
 * @param {object} changes - The changed fields (delta)
 * @param {object} previousRecord - The record state before the save
 * @param {string} userId
 */
export async function logFieldChanges(objectType, recordId, changes, previousRecord, userId) {
  if (!userId || !objectType || !changes) return;

  const trackedFields = TRACKED_FIELDS[objectType];
  if (!trackedFields) return;

  const objectName = resolveDisplayName({ ...previousRecord, ...changes }, objectType);
  const label = formatObjectLabel(objectType);

  for (const fieldName of trackedFields) {
    if (!(fieldName in changes)) continue;

    const oldValue = previousRecord?.[fieldName];
    const newValue = changes[fieldName];

    // Skip if value didn't actually change
    if (oldValue === newValue) continue;

    const fieldLabel = FIELD_LABELS[fieldName] || fieldName.replace(/_/g, ' ');

    // Resolve reference IDs to human-readable names
    const [resolvedOld, resolvedNew] = await Promise.all([
      oldValue != null ? resolveReferenceValue(fieldName, String(oldValue)) : Promise.resolve(''),
      newValue != null ? resolveReferenceValue(fieldName, String(newValue)) : Promise.resolve(''),
    ]);
    const oldStr = resolvedOld || '';
    const newStr = resolvedNew || '';

    let summary;
    if (oldStr && newStr) {
      summary = `Changed ${fieldLabel} from "${oldStr}" to "${newStr}" on ${label} "${objectName}"`;
    } else if (newStr) {
      summary = `Set ${fieldLabel} to "${newStr}" on ${label} "${objectName}"`;
    } else {
      summary = `Cleared ${fieldLabel} on ${label} "${objectName}"`;
    }

    try {
      await DataService.create('AuditLog', {
        object_type: objectType,
        object_id: recordId,
        action: 'Update',
        field_name: fieldName,
        old_value: oldStr,
        new_value: newStr,
        user_id: userId,
        timestamp: new Date().toISOString(),
        object_name: objectName,
        summary,
      });
    } catch {
      // Silent
    }
  }
}
