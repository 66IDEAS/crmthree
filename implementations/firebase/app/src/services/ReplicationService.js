import { db, functions } from '../config/firebase';
import { httpsCallable } from 'firebase/functions';
import {
  collection,
  doc,
  getDocs,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
} from 'firebase/firestore';
import { v4 as uuidv4 } from 'uuid';
import { getCollectionName } from './collectionNames';

const CONFIGS_COLLECTION = 'replicationConfigs';

/**
 * F59: Data Replication Service.
 * Manages replication configs and executes replication runs.
 */
const ReplicationService = {
  /** List all replication configs */
  async listConfigs() {
    if (!db) return [];
    const snapshot = await getDocs(collection(db, CONFIGS_COLLECTION));
    return snapshot.docs.map((d) => ({ id: d.id, ...d.data() }));
  },

  /** Get a single config by ID */
  async getConfig(id) {
    if (!db) return null;
    const snap = await getDoc(doc(db, CONFIGS_COLLECTION, id));
    return snap.exists() ? { id: snap.id, ...snap.data() } : null;
  },

  /** Create or update a replication config */
  async saveConfig(config) {
    if (!db) throw new Error('Firestore not configured');
    const id = config.id || uuidv4();
    const now = new Date().toISOString();
    const data = {
      ...config,
      id,
      updated_at: now,
      created_at: config.created_at || now,
    };
    await setDoc(doc(db, CONFIGS_COLLECTION, id), data);
    return data;
  },

  /** Delete a replication config */
  async deleteConfig(id) {
    if (!db) return;
    await deleteDoc(doc(db, CONFIGS_COLLECTION, id));
  },

  /**
   * Execute a replication run.
   * Calls the external web service via the Cloud Function proxy,
   * maps fields, and upserts records into Firestore.
   */
  async runReplication(config, onProgress) {
    if (!db || !functions) throw new Error('Firebase not configured');

    const result = { created: 0, updated: 0, skipped: 0, errors: [] };
    const progress = (msg) => onProgress?.(msg);

    // 1. Call the external web service via the Cloud Function proxy
    progress('Calling external web service...');
    const proxy = httpsCallable(functions, 'replicationProxy');
    let records;
    try {
      const response = await proxy({ url: config.url, body: config.requestBody });
      records = response.data?.records;
      if (!Array.isArray(records)) {
        throw new Error('Response does not contain a records array');
      }
    } catch (err) {
      throw new Error(`Web service call failed: ${err.message}`);
    }

    progress(`Received ${records.length} records. Processing...`);

    // 2. Build a lookup of existing records by key field
    const collName = getCollectionName(config.objectType);
    const crmKeyField = config.keyField; // e.g., 'account_number'
    const sourceKeyField = config.sourceKeyField; // e.g., 'Customer'

    // Load existing records to build key→id map
    const existingSnapshot = await getDocs(collection(db, collName));
    const existingByKey = {};
    existingSnapshot.docs.forEach((d) => {
      const data = d.data();
      if (data[crmKeyField]) {
        existingByKey[data[crmKeyField]] = { id: d.id, ...data };
      }
    });

    // 3. Process each incoming record
    const now = new Date().toISOString();
    for (let i = 0; i < records.length; i++) {
      const sourceRecord = records[i];
      try {
        // Check delete flag
        if (config.deleteField && sourceRecord[config.deleteField]) {
          result.skipped++;
          continue;
        }

        // Map fields
        const mapped = {};
        for (const [sourceField, crmField] of Object.entries(config.fieldMapping)) {
          if (sourceRecord[sourceField] !== undefined && sourceRecord[sourceField] !== null) {
            mapped[crmField] = String(sourceRecord[sourceField]);
          }
        }

        if (!mapped[crmKeyField]) {
          result.skipped++;
          continue;
        }

        // Check if record exists
        const existing = existingByKey[mapped[crmKeyField]];

        if (existing) {
          // Update existing record
          mapped.updated_at = now;
          await updateDoc(doc(db, collName, existing.id), mapped);
          result.updated++;
        } else {
          // Create new record
          const id = uuidv4();
          mapped.id = id;
          mapped.created_at = now;
          mapped.updated_at = now;
          mapped.status = mapped.status || 'Active';
          await setDoc(doc(db, collName, id), mapped);
          existingByKey[mapped[crmKeyField]] = { id, ...mapped };
          result.created++;
        }

        if ((i + 1) % 10 === 0) {
          progress(`Processed ${i + 1} of ${records.length} records...`);
        }
      } catch (err) {
        result.errors.push(`Record ${i + 1}: ${err.message}`);
      }
    }

    // 4. Update config with last run info
    await updateDoc(doc(db, CONFIGS_COLLECTION, config.id), {
      last_run: now,
      last_run_result: {
        created: result.created,
        updated: result.updated,
        skipped: result.skipped,
        errorCount: result.errors.length,
        totalRecords: records.length,
      },
    });

    return result;
  },
};

export default ReplicationService;
