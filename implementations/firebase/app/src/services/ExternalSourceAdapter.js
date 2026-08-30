import { functions } from '../config/firebase';
import { httpsCallable } from 'firebase/functions';

const callProxy = functions ? httpsCallable(functions, 'externalDataProxy') : null;

/**
 * Internal: call the externalDataProxy Cloud Function.
 * Credentials stay server-side; we only send objectType, operation, and args.
 */
async function proxyCall(objectType, operation, args) {
  if (!callProxy) throw new Error('Firebase is not configured');
  const result = await callProxy({ objectType, operation, args });
  return result.data;
}

/**
 * A16/F30: Adapter for external data sources (e.g., SAP via web services).
 * Proxies all operations through the externalDataProxy Cloud Function
 * so that API credentials never reach the browser.
 */
const ExternalSourceAdapter = {
  async getById(objectType, config, id) {
    return proxyCall(objectType, 'getById', { id });
  },

  async list(objectType, config, options) {
    return proxyCall(objectType, 'list', { options });
  },

  async create(objectType, config, data) {
    return proxyCall(objectType, 'create', { data });
  },

  async update(objectType, config, id, data) {
    return proxyCall(objectType, 'update', { id, data });
  },

  async remove(objectType, config, id) {
    return proxyCall(objectType, 'remove', { id });
  },

  async count(objectType, config, options) {
    const result = await proxyCall(objectType, 'count', { options });
    return typeof result === 'number' ? result : (result?.count || 0);
  },

  async listPage(objectType, config, options) {
    const result = await proxyCall(objectType, 'listPage', { options });
    return { data: result.data || result, lastDoc: null };
  },
};

export default ExternalSourceAdapter;
