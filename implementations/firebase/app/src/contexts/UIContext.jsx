import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';

const UIContext = createContext({
  ribbonExpanded: false,
  isMobile: false,
  mobileDrawerOpen: false,
  toggleRibbon: () => {},
  setMobileDrawerOpen: () => {},
});

export function useUI() {
  return useContext(UIContext);
}

const MOBILE_BREAKPOINT = 900;

export default function UIProvider({ children }) {
  const [ribbonExpanded, setRibbonExpanded] = useState(false);
  const [isMobile, setIsMobile] = useState(() => window.innerWidth <= MOBILE_BREAKPOINT);
  const [mobileDrawerOpen, setMobileDrawerOpen] = useState(false);

  useEffect(() => {
    const mql = window.matchMedia(`(max-width: ${MOBILE_BREAKPOINT}px)`);
    const handler = (e) => {
      setIsMobile(e.matches);
      if (!e.matches) setMobileDrawerOpen(false);
    };
    mql.addEventListener('change', handler);
    return () => mql.removeEventListener('change', handler);
  }, []);

  const toggleRibbon = useCallback(() => {
    if (isMobile) {
      setMobileDrawerOpen((prev) => !prev);
    } else {
      setRibbonExpanded((prev) => !prev);
    }
  }, [isMobile]);

  const value = useMemo(
    () => ({ ribbonExpanded, isMobile, mobileDrawerOpen, toggleRibbon, setMobileDrawerOpen }),
    [ribbonExpanded, isMobile, mobileDrawerOpen, toggleRibbon]
  );

  return <UIContext.Provider value={value}>{children}</UIContext.Provider>;
}
