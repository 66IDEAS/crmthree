// Imported from specs/, not a copy. The reference implementation keeps its own fork of the
// data model under src/model/dataModel.json, and that fork has drifted from the
// specification. Reading the spec directly is the only way the claim "the specification is
// the product" survives contact with a second implementation.
import dataModel from '$model';
import type { FieldDefinition, ObjectDefinition, Relationship } from '$model';

const ModelRegistry = {
  _model: dataModel,

  /** Returns all object type names (e.g., 'Account', 'Contact', ...) */
  getObjectTypes(): string[] {
    return Object.keys(this._model.objects);
  },

  /** Returns true if the given object type exists */
  hasObject(objectType: string): boolean {
    return objectType in this._model.objects;
  },

  /** Returns the full schema for an object type, with common fields merged in */
  getObjectSchema(objectType: string): ObjectDefinition & { fields: FieldDefinition[] } {
    const obj = this._model.objects[objectType];
    if (!obj) throw new Error(`Unknown object type: ${objectType}`);
    return {
      ...obj,
      fields: [...this._model.common_fields, ...obj.fields],
    };
  },

  /** Returns a single field definition, or undefined if not found */
  getFieldDefinition(objectType: string, fieldName: string): FieldDefinition | undefined {
    const schema = this.getObjectSchema(objectType);
    return schema.fields.find((f: FieldDefinition) => f.name === fieldName);
  },

  /** Returns the object-specific fields only (without common fields) */
  getSpecificFields(objectType: string): FieldDefinition[] {
    const obj = this._model.objects[objectType];
    if (!obj) throw new Error(`Unknown object type: ${objectType}`);
    return obj.fields;
  },

  /** Returns the relationships array for an object type */
  getRelationships(objectType: string): Relationship[] {
    return this._model.objects[objectType]?.relationships || [];
  },

  /** Returns the 5 common fields (id, created_at, updated_at, created_by, updated_by) */
  getCommonFields(): FieldDefinition[] {
    return this._model.common_fields;
  },

  /** Returns the field_types definitions */
  getFieldTypes() {
    return this._model.field_types;
  },

  /** Returns the object description */
  getDescription(objectType: string): string {
    return this._model.objects[objectType]?.description || '';
  },

  /** Returns required fields for an object type (excluding auto-generated and common) */
  getRequiredFields(objectType: string): FieldDefinition[] {
    const obj = this._model.objects[objectType];
    if (!obj) throw new Error(`Unknown object type: ${objectType}`);
    return obj.fields.filter(
      (f: FieldDefinition) => f.required && !f.auto_generated && !f.primary_key
    );
  },
};

export default ModelRegistry;
