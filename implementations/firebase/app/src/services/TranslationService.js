/**
 * A21: Module-level singleton for translations.
 * Initialized by TranslationProvider, callable from anywhere —
 * both React components and pure utility functions like formatFieldLabel.
 */
let currentLanguage = 'en';
let translations = {};
let listeners = [];

const TranslationService = {
  setTranslations(lang, labels) {
    currentLanguage = lang;
    translations = labels || {};
    listeners.forEach((cb) => cb(lang));
  },

  getLanguage() {
    return currentLanguage;
  },

  t(key, fallback) {
    if (currentLanguage === 'en') return fallback || key;
    return translations[key] || fallback || key;
  },

  subscribe(callback) {
    listeners.push(callback);
    return () => {
      listeners = listeners.filter((cb) => cb !== callback);
    };
  },

  getTranslations() {
    return { ...translations };
  },
};

export default TranslationService;

/** Shorthand importable t() function */
export function t(key, fallback) {
  return TranslationService.t(key, fallback);
}
