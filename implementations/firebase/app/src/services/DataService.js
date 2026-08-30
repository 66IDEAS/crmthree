import { routeOperation } from './DataSourceRouter';
import { validateObject } from '../model/validators';
import { v4 as uuidv4 } from 'uuid';
import ModelRegistry from '../model/ModelRegistry';
import { getAutoNumberField } from '../utils/fieldUtils';
import { getNextAutoNumber } from './FirestoreMapper';

class ValidationError extends Error {
  constructor(objectType, errors) {
    super(`Validation failed for ${objectType}: ${errors.map((e) => e.error).join('; ')}`);
    this.name = 'ValidationError';
    this.objectType = objectType;
    this.errors = errors;
  }
}

const DataService = {
  /** Read a single record by ID */
  async getById(objectType, id) {
    return routeOperation(objectType, 'getById', id);
  },

  /**
   * List records with optional filters, sorting, and pagination.
   * @param {string} objectType
   * @param {Object} options - { filters: [{ field, op, value }], sort: { field, direction }, pageSize, cursor }
   */
  async list(objectType, options = {}) {
    return routeOperation(objectType, 'list', options);
  },

  /**
   * Create a new record. Validates data against the schema.
   * Automatically sets id, created_at, and updated_at.
   * @throws {ValidationError} if validation fails
   */
  async create(objectType, data) {
    const errors = validateObject(objectType, data);
    if (errors.length > 0) {
      throw new ValidationError(objectType, errors);
    }

    const now = new Date().toISOString();
    const enriched = {
      ...data,
      id: data.id || uuidv4(),
      created_at: now,
      updated_at: now,
    };

    // Generate auto-number if the object type has one
    const fields = ModelRegistry.getSpecificFields(objectType);
    const autoField = getAutoNumberField(fields);
    if (autoField && !enriched[autoField.name]) {
      const nextNum = await getNextAutoNumber(objectType);
      const padLength = autoField.length || 10;
      enriched[autoField.name] = String(nextNum).padStart(padLength, '0');
    }

    return routeOperation(objectType, 'create', enriched);
  },

  /**
   * Update an existing record. Automatically sets updated_at.
   */
  async update(objectType, id, data) {
    const enriched = {
      ...data,
      updated_at: new Date().toISOString(),
    };

    return routeOperation(objectType, 'update', id, enriched);
  },

  /** Delete a record */
  async remove(objectType, id) {
    return routeOperation(objectType, 'remove', id);
  },

  /**
   * Fetch a single page with cursor info for server-side pagination.
   * @returns {{ data: Array, lastDoc: DocumentSnapshot|null }}
   */
  async listPage(objectType, options = {}) {
    return routeOperation(objectType, 'listPage', options);
  },

  /**
   * Count records matching optional filters (server-side).
   * @returns {Promise<number>}
   */
  async count(objectType, options = {}) {
    return routeOperation(objectType, 'count', options);
  },
};

export { ValidationError };
export default DataService;
