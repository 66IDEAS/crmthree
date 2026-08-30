import { createContext, useContext, useCallback, useRef, useSyncExternalStore } from 'react';
import { useLocation } from 'react-router';
import { useEffect } from 'react';
import { resolveObjectType } from '../config/navigation';
import { getObjectLabel } from '../utils/fieldUtils';

const MAX_HISTORY = 15;

const NavigationHistoryContext = createContext({
  history: [],
  updateCurrentLabel: () => {},
});

export function useNavigationHistory() {
  return useContext(NavigationHistoryContext);
}

/**
 * Returns a label only for detail pages (/:slug/:id and /:slug/new).
 * Returns null for everything else so the caller can skip non-detail pages.
 */
function resolveDetailLabel(pathname) {
  const parts = pathname.split('/').filter(Boolean);
  if (parts.length < 2) return null; // home, list pages, settings, profile

  const slug = parts[0];
  const objectType = resolveObjectType(slug);
  if (!objectType) return null;

  const label = getObjectLabel(objectType);

  if (parts[1] === 'new') return `New ${label.replace(/s$/, '')}`;
  // Detail page — use singular label as placeholder until page updates it
  return label.replace(/s$/, '');
}

export default function NavigationHistoryProvider({ children }) {
  const location = useLocation();
  const historyRef = useRef([]);
  const listenersRef = useRef(new Set());

  const subscribe = useCallback((listener) => {
    listenersRef.current.add(listener);
    return () => listenersRef.current.delete(listener);
  }, []);

  const getSnapshot = useCallback(() => historyRef.current, []);

  const history = useSyncExternalStore(subscribe, getSnapshot);

  const notify = useCallback(() => {
    listenersRef.current.forEach((l) => l());
  }, []);

  useEffect(() => {
    const path = location.pathname;
    const label = resolveDetailLabel(path);
    // Only track detail pages
    if (!label) return;

    const current = historyRef.current;
    // Remove any existing entry for this path so each page appears only once
    const filtered = current.filter((entry) => entry.path !== path);
    const next = [...filtered, { path, label }];
    if (next.length > MAX_HISTORY) next.splice(0, next.length - MAX_HISTORY);
    historyRef.current = next;
    notify();
  }, [location.pathname, notify]);

  const updateCurrentLabel = useCallback((label) => {
    const current = historyRef.current;
    if (current.length === 0) return;
    const last = current[current.length - 1];
    if (last.label === label) return;
    historyRef.current = [...current.slice(0, -1), { ...last, label }];
    notify();
  }, [notify]);

  return (
    <NavigationHistoryContext.Provider value={{ history, updateCurrentLabel }}>
      {children}
    </NavigationHistoryContext.Provider>
  );
}
