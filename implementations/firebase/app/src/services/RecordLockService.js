import { db } from '../config/firebase';
import { doc, getDoc, setDoc, deleteDoc, updateDoc } from 'firebase/firestore';

const COLLECTION = 'recordLocks';
const LOCK_TTL_MS = 15 * 60 * 1000; // 15 minutes

function lockId(objectType, recordId) {
  return `${objectType}_${recordId}`;
}

/**
 * Attempt to acquire a lock on a record.
 * Returns { success: true } or { success: false, lockedBy: 'Name' }.
 */
export async function acquireLock(objectType, recordId, userId, userName) {
  try {
    const id = lockId(objectType, recordId);
    const ref = doc(db, COLLECTION, id);
    const existing = await getDoc(ref);

    if (existing.exists()) {
      const data = existing.data();
      const expiresAt = data.expires_at ? new Date(data.expires_at).getTime() : 0;

      // If locked by another user and not expired, deny
      if (data.locked_by !== userId && expiresAt > Date.now()) {
        return { success: false, lockedBy: data.locked_by_name || 'Another user' };
      }
    }

    const now = new Date().toISOString();
    const expiresAt = new Date(Date.now() + LOCK_TTL_MS).toISOString();

    await setDoc(ref, {
      object_type: objectType,
      record_id: recordId,
      locked_by: userId,
      locked_by_name: userName,
      locked_at: now,
      expires_at: expiresAt,
    });

    return { success: true };
  } catch {
    // If lock acquisition fails, allow editing anyway (graceful degradation)
    return { success: true };
  }
}

/**
 * Release a lock. Only deletes if the current user holds it.
 */
export async function releaseLock(objectType, recordId, userId) {
  try {
    const id = lockId(objectType, recordId);
    const ref = doc(db, COLLECTION, id);
    const existing = await getDoc(ref);

    if (existing.exists() && existing.data().locked_by === userId) {
      await deleteDoc(ref);
    }
  } catch {
    // Silent — lock release should never block the user
  }
}

/**
 * Extend the lock TTL. Called periodically while editing.
 */
export async function heartbeat(objectType, recordId, userId) {
  try {
    const id = lockId(objectType, recordId);
    const ref = doc(db, COLLECTION, id);
    const existing = await getDoc(ref);

    if (existing.exists() && existing.data().locked_by === userId) {
      await updateDoc(ref, {
        expires_at: new Date(Date.now() + LOCK_TTL_MS).toISOString(),
      });
    }
  } catch {
    // Silent
  }
}
