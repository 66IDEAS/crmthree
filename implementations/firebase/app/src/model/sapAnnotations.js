import ModelRegistry from './ModelRegistry';

/**
 * Returns the SAP equivalent label for an object type (e.g., "Business Partner — Organization (BU type)")
 * Returns null if no SAP equivalent is defined.
 */
export function getSAPEquivalent(objectType) {
  const obj = ModelRegistry._model.objects[objectType];
  return obj?.sap_equivalent || null;
}

/**
 * Returns true if the object type has SAP annotations.
 */
export function hasSAPAnnotations(objectType) {
  return getSAPEquivalent(objectType) !== null;
}

/**
 * Returns only the fields that have SAP field annotations (sap_field property).
 * Returns an empty array if none exist.
 */
export function getSAPFields(objectType) {
  const obj = ModelRegistry._model.objects[objectType];
  if (!obj) return [];
  return obj.fields.filter((f) => f.sap_field);
}

/**
 * Returns the SAP type for a specific field (e.g., "CHAR 10"), or null.
 */
export function getSAPType(objectType, fieldName) {
  const obj = ModelRegistry._model.objects[objectType];
  if (!obj) return null;
  const field = obj.fields.find((f) => f.name === fieldName);
  return field?.sap_type || null;
}

/**
 * Returns the SAP field name mapping for a specific field (e.g., "PARTNER"), or null.
 */
export function getSAPFieldName(objectType, fieldName) {
  const obj = ModelRegistry._model.objects[objectType];
  if (!obj) return null;
  const field = obj.fields.find((f) => f.name === fieldName);
  return field?.sap_field || null;
}
