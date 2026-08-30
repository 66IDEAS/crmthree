import { db } from '../config/firebase';
import { collection, doc, getDocs, setDoc } from 'firebase/firestore';
import ModelRegistry from '../model/ModelRegistry';
import { getSortFieldForMode, getAutoNumberField } from '../utils/fieldUtils';
import FirestoreMapper, { getNextAutoNumber } from './FirestoreMapper';
import DataService from './DataService';

const COLLECTION = 'listViewSettings';

/** The two sort bases offered per object. */
export const SORT_MODES = ['number', 'name'];

/** Applied to any object with nothing saved, including a fresh instance. */
export const DEFAULT_SORT = { sort_by: 'number', sort_direction: 'asc' };

// Every list page open reads this, so the whole (tiny) collection is cached
// for the session and refreshed in place whenever a setting is saved.
let cache = null;
let inflight = null;

/**
 * Loads and caches all list sort settings. Safe to call on every list open —
 * only the first call hits Firestore. Never rejects: a settings collection that
 * cannot be read falls back to the defaults rather than breaking every list.
 */
export async function loadListSortSettings(force = false) {
  if (!db) {
    cache = cache || {};
    return cache;
  }
  if (cache && !force) return cache;
  if (inflight && !force) return inflight;

  inflight = getDocs(collection(db, COLLECTION))
    .then((snapshot) => {
      const map = {};
      snapshot.docs.forEach((d) => { map[d.id] = { id: d.id, ...d.data() }; });
      cache = map;
      return map;
    })
    .catch((err) => {
      console.warn('Failed to load list sort settings, using defaults:', err);
      cache = cache || {};
      return cache;
    })
    .finally(() => { inflight = null; });

  return inflight;
}

/** The saved setting for an object, or the default. Reads the cache only. */
export function getListSortSetting(objectType) {
  const stored = cache?.[objectType];
  return {
    sort_by: stored?.sort_by === 'name' ? 'name' : DEFAULT_SORT.sort_by,
    sort_direction: stored?.sort_direction === 'desc' ? 'desc' : DEFAULT_SORT.sort_direction,
  };
}

/** The field a given object+mode resolves to, e.g. 'account_number', 'name1'. */
export function getSortFieldFor(objectType, mode) {
  if (!ModelRegistry.hasObject(objectType)) return null;
  return getSortFieldForMode(ModelRegistry.getSpecificFields(objectType), mode);
}

/**
 * The configured default as Material React Table sorting state.
 * Returns [] for anything not in the model, which leaves the list unsorted.
 */
export function getDefaultSorting(objectType) {
  if (!ModelRegistry.hasObject(objectType)) return [];
  const { sort_by, sort_direction } = getListSortSetting(objectType);
  const field = getSortFieldFor(objectType, sort_by);
  if (!field) return [];
  return [{ id: field, desc: sort_direction === 'desc' }];
}

/** Saves one object's setting and updates the cache so open lists pick it up. */
export async function saveListSortSetting(objectType, { sort_by, sort_direction }, updatedBy) {
  if (!db) throw new Error('Firestore is not configured');
  const record = {
    object_type: objectType,
    sort_by: sort_by === 'name' ? 'name' : 'number',
    sort_direction: sort_direction === 'desc' ? 'desc' : 'asc',
    updated_at: new Date().toISOString(),
    updated_by: updatedBy || null,
  };
  await setDoc(doc(db, COLLECTION, objectType), record);
  cache = { ...(cache || {}), [objectType]: { id: objectType, ...record } };
  return record;
}

/**
 * How many records a sorted list would hide, because they carry no value for
 * the sorted field. Returns 0 when the check cannot be run (for example when
 * the object is served by an external data source rather than Firestore).
 */
export async function countHiddenBySort(objectType, sortField) {
  try {
    const [total, sorted] = await Promise.all([
      DataService.count(objectType),
      FirestoreMapper.countSorted(objectType, sortField),
    ]);
    return Math.max(0, total - sorted);
  } catch (err) {
    console.warn(`Hidden-record check failed for ${objectType}:`, err);
    return 0;
  }
}

/**
 * Assigns auto-numbers to records that have none, so they stop being hidden by
 * a number-sorted list. Only ever fills a missing value — existing numbers are
 * left alone — and draws from the same counter as normal record creation.
 * Returns the number of records fixed.
 */
export async function assignMissingAutoNumbers(objectType) {
  const fields = ModelRegistry.getSpecificFields(objectType);
  const autoField = getAutoNumberField(fields);
  if (!autoField) return 0;

  const all = await DataService.list(objectType, { pageSize: 0 });
  const missing = all.filter((r) => !r[autoField.name]);
  const padLength = autoField.length || 10;

  for (const record of missing) {
    const next = await getNextAutoNumber(objectType);
    await DataService.update(objectType, record.id, {
      [autoField.name]: String(next).padStart(padLength, '0'),
    });
  }
  return missing.length;
}
