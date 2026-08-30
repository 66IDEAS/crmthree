import FirestoreMapper from './FirestoreMapper';
import ExternalSourceAdapter from './ExternalSourceAdapter';
import { db } from '../config/firebase';
import { collection, getDocs } from 'firebase/firestore';

let configCache = null;

/**
 * Loads all DataSourceConfig entries from Firestore and caches them.
 * Returns an array of config objects, or empty array if Firestore isn't available.
 */
async function loadConfigs() {
  if (configCache !== null) return configCache;
  if (!db) {
    configCache = [];
    return configCache;
  }
  try {
    const snapshot = await getDocs(collection(db, 'dataSourceConfigs'));
    configCache = snapshot.docs.map((d) => ({ id: d.id, ...d.data() }));
  } catch {
    configCache = [];
  }
  return configCache;
}

/**
 * Returns the DataSourceConfig for a given object type.
 * Defaults to { source_type: 'Local' } if no config exists.
 */
async function getSourceConfig(objectType) {
  const configs = await loadConfigs();
  const config = configs.find((c) => c.object_type === objectType);
  return config || { source_type: 'Local' };
}

/** Resets the config cache (call after updating DataSourceConfig) */
export function clearConfigCache() {
  configCache = null;
}

/**
 * Routes a data operation to the correct adapter based on DataSourceConfig.
 * @param {string} objectType - The object type (e.g., 'Account')
 * @param {string} operation - The operation name (e.g., 'getById', 'list', 'create', 'update', 'remove')
 * @param {...any} args - Arguments to pass to the adapter
 */
export async function routeOperation(objectType, operation, ...args) {
  const config = await getSourceConfig(objectType);

  if (config.source_type === 'External' && config.active !== false) {
    return ExternalSourceAdapter[operation](objectType, config, ...args);
  }

  return FirestoreMapper[operation](objectType, ...args);
}
