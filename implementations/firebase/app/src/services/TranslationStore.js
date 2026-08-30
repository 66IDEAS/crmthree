/**
 * A21: Direct Firestore access for the translations collection.
 * Not routed through DataService since translations are a system concern,
 * not a CRM business object.
 */
import { db } from '../config/firebase';
import { collection, doc, getDoc, setDoc, getDocs, deleteDoc } from 'firebase/firestore';

const COLLECTION = 'translations';

export async function loadTranslationDoc(langCode) {
  if (!db) return null;
  const snap = await getDoc(doc(db, COLLECTION, langCode));
  return snap.exists() ? snap.data() : null;
}

export async function saveTranslationDoc(langCode, data) {
  if (!db) throw new Error('Firestore not configured');
  await setDoc(doc(db, COLLECTION, langCode), {
    ...data,
    updated_at: new Date().toISOString(),
  });
}

export async function deleteTranslationDoc(langCode) {
  if (!db) throw new Error('Firestore not configured');
  await deleteDoc(doc(db, COLLECTION, langCode));
}

export async function listTranslationDocs() {
  if (!db) return [];
  const snap = await getDocs(collection(db, COLLECTION));
  return snap.docs.map((d) => ({ language_code: d.id, ...d.data() }));
}
