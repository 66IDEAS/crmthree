import { createContext, useContext, useEffect, useState, useMemo, useCallback } from 'react';
import { useAuth } from './AuthContext';
import TranslationService from '../services/TranslationService';
import { loadTranslationDoc } from '../services/TranslationStore';
import DataService from '../services/DataService';

const TranslationContext = createContext({
  language: 'en',
  setLanguage: () => {},
  t: (key, fallback) => fallback || key,
});

export function useTranslation() {
  return useContext(TranslationContext);
}

export default function TranslationProvider({ children }) {
  const { userProfile } = useAuth();
  const [language, setLanguageState] = useState('en');
  const [, forceUpdate] = useState(0);

  const loadTranslations = useCallback(async (lang) => {
    if (!lang || lang === 'en') {
      TranslationService.setTranslations('en', {});
      setLanguageState('en');
      return;
    }
    try {
      const docData = await loadTranslationDoc(lang);
      TranslationService.setTranslations(lang, docData?.labels || {});
      setLanguageState(lang);
    } catch {
      TranslationService.setTranslations('en', {});
      setLanguageState('en');
    }
  }, []);

  // On auth, read user's language preference
  useEffect(() => {
    const lang = userProfile?.language_preference || 'en';
    loadTranslations(lang);
  }, [userProfile?.language_preference, loadTranslations]);

  // Subscribe to TranslationService changes for re-render
  useEffect(() => {
    return TranslationService.subscribe(() => forceUpdate((n) => n + 1));
  }, []);

  const setLanguage = useCallback(async (lang) => {
    await loadTranslations(lang);
    if (userProfile?.id) {
      DataService.update('UserProfile', userProfile.id, {
        language_preference: lang,
      }).catch(() => {});
    }
  }, [userProfile, loadTranslations]);

  const tFn = useCallback((key, fallback) => {
    return TranslationService.t(key, fallback);
  }, [language]); // eslint-disable-line react-hooks/exhaustive-deps

  const value = useMemo(
    () => ({ language, setLanguage, t: tFn }),
    [language, setLanguage, tFn]
  );

  return (
    <TranslationContext.Provider value={value}>
      {children}
    </TranslationContext.Provider>
  );
}
