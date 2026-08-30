import { db } from '../config/firebase';
import {
  collection,
  doc,
  getDocs,
  setDoc,
  deleteDoc,
} from 'firebase/firestore';
import { v4 as uuidv4 } from 'uuid';

const COLLECTION = 'emailWhitelist';

/**
 * Fetch all whitelist entries.
 */
export async function fetchWhitelistEntries() {
  if (!db) return [];
  const snapshot = await getDocs(collection(db, COLLECTION));
  return snapshot.docs.map((d) => ({ id: d.id, ...d.data() }));
}

/**
 * Add a whitelist entry. Normalizes value to lowercase and strips leading '@' from domains.
 */
export async function addWhitelistEntry(type, value, createdBy) {
  if (!db) throw new Error('Firestore is not configured');
  let normalized = value.trim().toLowerCase();
  if (type === 'domain') {
    normalized = normalized.replace(/^@/, '');
  }
  const id = uuidv4();
  const entry = {
    id,
    type,
    value: normalized,
    created_at: new Date().toISOString(),
    created_by: createdBy,
  };
  await setDoc(doc(db, COLLECTION, id), entry);
  return entry;
}

/**
 * Remove a whitelist entry by ID.
 */
export async function removeWhitelistEntry(id) {
  if (!db) throw new Error('Firestore is not configured');
  await deleteDoc(doc(db, COLLECTION, id));
}

/**
 * Check if an email is allowed by the whitelist.
 * Returns true if the collection is empty (no restrictions)
 * or if the email/domain matches an entry.
 */
export async function isEmailWhitelisted(email) {
  if (!db) return true;
  const snapshot = await getDocs(collection(db, COLLECTION));
  if (snapshot.empty) return true;

  const normalized = email.toLowerCase();
  const domain = normalized.split('@')[1];

  return snapshot.docs.some((d) => {
    const entry = d.data();
    if (entry.type === 'email' && entry.value === normalized) return true;
    if (entry.type === 'domain' && entry.value === domain) return true;
    return false;
  });
}
