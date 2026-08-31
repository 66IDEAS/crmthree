/**
 * First-run seeding of the bundled language packs (shared architecture, section 13).
 * Bundled packs are served from hosting (public/translations/, copied at build time).
 * Seeding is per language and at most once per code, tracked in the seed registry
 * document translations_meta/seed: a registered code is never touched again, a code
 * with an existing translation document is adopted into the registry untouched, and a
 * code with neither gets its pack fetched and written. Deleting a language therefore
 * sticks, while a pack added to the product later appears on the next admin session.
 */
import { db } from '../config/firebase';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { loadTranslationDoc, saveTranslationDoc } from './TranslationStore';

let ran = false;

export async function seedBundledTranslations() {
  if (ran || !db) return;
  ran = true;
  try {
    const index = await fetch('/translations/index.json').then((r) => (r.ok ? r.json() : null));
    if (!index?.codes?.length) return;

    const registryRef = doc(db, 'translations_meta', 'seed');
    const registrySnap = await getDoc(registryRef);
    const registered = new Set(registrySnap.exists() ? registrySnap.data().codes ?? [] : []);

    const newlyRegistered = [];
    for (const code of index.codes) {
      if (registered.has(code)) continue;
      const existing = await loadTranslationDoc(code);
      if (!existing) {
        const pack = await fetch(`/translations/${code}.json`).then((r) => (r.ok ? r.json() : null));
        if (!pack?.labels) continue;
        await saveTranslationDoc(code, { language_name: pack.language_name, labels: pack.labels });
      }
      newlyRegistered.push(code);
    }
    if (newlyRegistered.length) {
      await setDoc(registryRef, {
        codes: [...registered, ...newlyRegistered],
        updated_at: new Date().toISOString(),
      });
    }
  } catch (err) {
    // Seeding must never break the app; the next admin session simply retries.
    console.warn('Bundled translation seeding skipped:', err);
    ran = false;
  }
}
