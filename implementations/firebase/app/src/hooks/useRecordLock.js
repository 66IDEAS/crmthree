import { useState, useEffect } from 'react';
import { db } from '../config/firebase';
import { doc, onSnapshot } from 'firebase/firestore';

const COLLECTION = 'recordLocks';

/**
 * Real-time hook that watches a lock document for a given record.
 * Returns { lock, loading } where lock is null (unlocked) or the lock data.
 * Expired locks are treated as null.
 */
export default function useRecordLock(objectType, recordId) {
  const [lock, setLock] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!objectType || !recordId) {
      setLock(null);
      setLoading(false);
      return;
    }

    const lockDocId = `${objectType}_${recordId}`;
    const ref = doc(db, COLLECTION, lockDocId);

    const unsubscribe = onSnapshot(
      ref,
      (snapshot) => {
        if (snapshot.exists()) {
          const data = snapshot.data();
          const expiresAt = data.expires_at ? new Date(data.expires_at).getTime() : 0;

          if (expiresAt > Date.now()) {
            setLock(data);
          } else {
            // Expired lock — treat as unlocked
            setLock(null);
          }
        } else {
          setLock(null);
        }
        setLoading(false);
      },
      () => {
        // On error, treat as unlocked (graceful degradation)
        setLock(null);
        setLoading(false);
      }
    );

    return unsubscribe;
  }, [objectType, recordId]);

  return { lock, loading };
}
