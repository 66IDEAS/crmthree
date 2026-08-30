import { db } from '../config/firebase';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  limit,
  startAfter,
  runTransaction,
  getCountFromServer,
} from 'firebase/firestore';
import { getCollectionName } from './collectionNames';

function ensureDb() {
  if (!db) throw new Error('Firestore is not configured. Add Firebase credentials to .env');
}

/**
 * Atomically increments and returns the next auto-number for a given object type.
 * Uses a Firestore counter document in the `counters` collection.
 * @param {string} objectType - e.g. 'Account'
 * @returns {Promise<number>} The next sequential number
 */
async function getNextAutoNumber(objectType) {
  ensureDb();
  const counterRef = doc(db, 'counters', objectType);
  const nextVal = await runTransaction(db, async (transaction) => {
    const counterDoc = await transaction.get(counterRef);
    const current = counterDoc.exists() ? counterDoc.data().next : 0;
    const next = current + 1;
    transaction.set(counterRef, { next });
    return next;
  });
  return nextVal;
}

const FirestoreMapper = {
  /** Read a single document by ID */
  async getById(objectType, id) {
    ensureDb();
    const collName = getCollectionName(objectType);
    const docRef = doc(db, collName, id);
    const snapshot = await getDoc(docRef);
    if (!snapshot.exists()) return null;
    return { id: snapshot.id, ...snapshot.data() };
  },

  /** List documents with optional filters, sorting, and pagination */
  async list(objectType, { filters = [], sort, pageSize = 25, cursor } = {}) {
    ensureDb();
    const collName = getCollectionName(objectType);
    const collRef = collection(db, collName);

    const constraints = [];
    for (const f of filters) {
      constraints.push(where(f.field, f.op, f.value));
    }
    if (sort) {
      constraints.push(orderBy(sort.field, sort.direction || 'asc'));
    }
    if (pageSize) constraints.push(limit(pageSize));
    if (cursor) {
      constraints.push(startAfter(cursor));
    }

    const q = query(collRef, ...constraints);
    const snapshot = await getDocs(q);
    return snapshot.docs.map((d) => ({ id: d.id, ...d.data() }));
  },

  /** Count documents matching optional filters */
  async count(objectType, { filters = [] } = {}) {
    ensureDb();
    const collName = getCollectionName(objectType);
    const collRef = collection(db, collName);
    const constraints = [];
    for (const f of filters) {
      constraints.push(where(f.field, f.op, f.value));
    }
    const q = query(collRef, ...constraints);
    const snapshot = await getCountFromServer(q);
    return snapshot.data().count;
  },

  /**
   * Counts the documents a sorted query would actually return.
   *
   * Firestore omits documents that lack the orderBy field entirely — they are
   * not sorted last, they are absent — while count() still includes them. The
   * difference between the two is the number of records a sorted list hides.
   */
  async countSorted(objectType, sortField, { filters = [] } = {}) {
    ensureDb();
    const collName = getCollectionName(objectType);
    const collRef = collection(db, collName);
    const constraints = [];
    for (const f of filters) {
      constraints.push(where(f.field, f.op, f.value));
    }
    constraints.push(orderBy(sortField, 'asc'));
    const q = query(collRef, ...constraints);
    const snapshot = await getCountFromServer(q);
    return snapshot.data().count;
  },

  /**
   * List a single page of documents, returning data and the last DocumentSnapshot
   * for cursor-based pagination.
   * @returns {{ data: Array, lastDoc: DocumentSnapshot|null }}
   */
  async listPage(objectType, { filters = [], sort, pageSize = 25, cursor } = {}) {
    ensureDb();
    const collName = getCollectionName(objectType);
    const collRef = collection(db, collName);

    const constraints = [];
    for (const f of filters) {
      constraints.push(where(f.field, f.op, f.value));
    }
    if (sort) {
      constraints.push(orderBy(sort.field, sort.direction || 'asc'));
    }
    constraints.push(limit(pageSize));
    if (cursor) {
      constraints.push(startAfter(cursor));
    }

    const q = query(collRef, ...constraints);
    const snapshot = await getDocs(q);
    const data = snapshot.docs.map((d) => ({ id: d.id, ...d.data() }));
    const lastDoc = snapshot.docs.length > 0
      ? snapshot.docs[snapshot.docs.length - 1]
      : null;

    return { data, lastDoc };
  },

  /** Create a new document */
  async create(objectType, data) {
    ensureDb();
    const collName = getCollectionName(objectType);
    const docRef = doc(db, collName, data.id);
    await setDoc(docRef, data);
    return data;
  },

  /** Update an existing document (partial update) */
  async update(objectType, id, data) {
    ensureDb();
    const collName = getCollectionName(objectType);
    const docRef = doc(db, collName, id);
    await updateDoc(docRef, data);
    return { id, ...data };
  },

  /** Delete a document */
  async remove(objectType, id) {
    ensureDb();
    const collName = getCollectionName(objectType);
    const docRef = doc(db, collName, id);
    await deleteDoc(docRef);
  },
};

export { getNextAutoNumber };
export default FirestoreMapper;
