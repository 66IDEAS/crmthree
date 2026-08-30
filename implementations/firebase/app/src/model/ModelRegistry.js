import dataModel from './dataModel.json';

const ModelRegistry = {
  _model: dataModel,

  /** Returns all object type names (e.g., 'Account', 'Contact', ...) */
  getObjectTypes() {
    return Object.keys(this._model.objects);
  },

  /** Returns true if the given object type exists */
  hasObject(objectType) {
    return objectType in this._model.objects;
  },

  /** Returns the full schema for an object type, with common fields merged in */
  getObjectSchema(objectType) {
    const obj = this._model.objects[objectType];
    if (!obj) throw new Error(`Unknown object type: ${objectType}`);
    return {
      ...obj,
      fields: [...this._model.common_fields, ...obj.fields],
    };
  },

  /** Returns a single field definition, or undefined if not found */
  getFieldDefinition(objectType, fieldName) {
    const schema = this.getObjectSchema(objectType);
    return schema.fields.find((f) => f.name === fieldName);
  },

  /** Returns the object-specific fields only (without common fields) */
  getSpecificFields(objectType) {
    const obj = this._model.objects[objectType];
    if (!obj) throw new Error(`Unknown object type: ${objectType}`);
    return obj.fields;
  },

  /** Returns the relationships array for an object type */
  getRelationships(objectType) {
    return this._model.objects[objectType]?.relationships || [];
  },

  /** Returns the 5 common fields (id, created_at, updated_at, created_by, updated_by) */
  getCommonFields() {
    return this._model.common_fields;
  },

  /** Returns the field_types definitions */
  getFieldTypes() {
    return this._model.field_types;
  },

  /** Returns the object description */
  getDescription(objectType) {
    return this._model.objects[objectType]?.description || '';
  },

  /** Returns required fields for an object type (excluding auto-generated and common) */
  getRequiredFields(objectType) {
    const obj = this._model.objects[objectType];
    if (!obj) throw new Error(`Unknown object type: ${objectType}`);
    return obj.fields.filter(
      (f) => f.required && !f.auto_generated && !f.primary_key
    );
  },
};

export default ModelRegistry;
