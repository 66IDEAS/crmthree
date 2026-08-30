import ModelRegistry from './ModelRegistry';

/**
 * Validates a single field value against the schema definition.
 * Returns { valid: boolean, error: string | null }
 */
export function validateField(objectType, fieldName, value) {
  const field = ModelRegistry.getFieldDefinition(objectType, fieldName);
  if (!field) {
    return { valid: false, error: `Unknown field: ${fieldName}` };
  }

  // Use human-readable label (description) instead of raw field name
  const label = field.description || fieldName;

  // Required check
  if (field.required && (value === null || value === undefined || value === '')) {
    // Skip required check for auto-generated, primary key, and common system fields
    if (!field.auto_generated && !field.primary_key) {
      return { valid: false, error: `${label} is required` };
    }
  }

  // If value is empty and not required, it's valid
  if (value === null || value === undefined || value === '') {
    return { valid: true, error: null };
  }

  // String length check (covers SAP-compatible lengths)
  if (field.type === 'string' && field.length) {
    if (typeof value === 'string' && value.length > field.length) {
      return {
        valid: false,
        error: `${label} exceeds maximum length of ${field.length} characters`,
      };
    }
  }

  // Enum values check
  if (field.type === 'enum' && field.values) {
    if (!field.values.includes(value)) {
      return {
        valid: false,
        error: `${label} must be one of: ${field.values.join(', ')}`,
      };
    }
  }

  // Decimal/currency precision check
  if ((field.type === 'decimal' || field.type === 'currency') && field.scale !== undefined) {
    if (typeof value === 'number') {
      const parts = String(value).split('.');
      if (parts[1] && parts[1].length > field.scale) {
        return {
          valid: false,
          error: `${label} exceeds ${field.scale} decimal places`,
        };
      }
    }
  }

  // Integer type check
  if (field.type === 'integer' && typeof value === 'number') {
    if (!Number.isInteger(value)) {
      return { valid: false, error: `${label} must be a whole number` };
    }
  }

  // Boolean type check
  if (field.type === 'boolean' && typeof value !== 'boolean') {
    return { valid: false, error: `${label} must be true or false` };
  }

  return { valid: true, error: null };
}

/**
 * Validates all fields of an object.
 * Returns an array of { field: string, error: string } for invalid fields.
 * An empty array means the object is valid.
 */
export function validateObject(objectType, data) {
  const schema = ModelRegistry.getObjectSchema(objectType);
  const errors = [];

  const skipFields = new Set(['id', 'created_at', 'updated_at', 'created_by', 'updated_by']);

  for (const field of schema.fields) {
    // Skip common system fields and auto-generated fields
    if (skipFields.has(field.name) || field.auto_generated || field.primary_key) {
      continue;
    }

    const result = validateField(objectType, field.name, data[field.name]);
    if (!result.valid) {
      errors.push({ field: field.name, error: result.error });
    }
  }

  return errors;
}
