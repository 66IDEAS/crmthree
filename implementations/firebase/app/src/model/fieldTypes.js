/**
 * Maps data model field types to JavaScript types and Firestore types.
 */
const fieldTypeMap = {
  string:    { jsType: 'string',  firestoreType: 'string' },
  text:      { jsType: 'string',  firestoreType: 'string' },
  integer:   { jsType: 'number',  firestoreType: 'number' },
  decimal:   { jsType: 'number',  firestoreType: 'number' },
  currency:  { jsType: 'number',  firestoreType: 'number' },
  boolean:   { jsType: 'boolean', firestoreType: 'boolean' },
  date:      { jsType: 'string',  firestoreType: 'string' },      // YYYY-MM-DD
  datetime:  { jsType: 'string',  firestoreType: 'timestamp' },   // ISO 8601 <-> Firestore Timestamp
  enum:      { jsType: 'string',  firestoreType: 'string' },
  reference: { jsType: 'string',  firestoreType: 'string' },      // stores the ID
  json:      { jsType: 'object',  firestoreType: 'map' },
  uuid:      { jsType: 'string',  firestoreType: 'string' },
};

/** Returns the JavaScript type for a model field type */
export function getJSType(modelType) {
  return fieldTypeMap[modelType]?.jsType || 'string';
}

/** Returns the Firestore type for a model field type */
export function getFirestoreType(modelType) {
  return fieldTypeMap[modelType]?.firestoreType || 'string';
}

/** Returns the full mapping for a model field type */
export function getTypeMapping(modelType) {
  return fieldTypeMap[modelType] || fieldTypeMap.string;
}

export default fieldTypeMap;
