import { createContext, useCallback, useContext, useMemo, useState } from 'react';
import { ThemeProvider as MuiThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import lightTheme from './lightTheme';
import darkTheme from './darkTheme';

function resolveMode(preference) {
  if (preference === 'light' || preference === 'dark') return preference;
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

const ThemeContext = createContext({
  mode: 'light',
  preference: 'system',
  setPreference: () => {},
});

export function useThemeMode() {
  return useContext(ThemeContext);
}

export default function ThemeProvider({ children }) {
  const [preference, setPreferenceState] = useState(() => {
    return localStorage.getItem('crmthree-theme') || 'system';
  });

  const mode = resolveMode(preference);

  const setPreference = useCallback((pref) => {
    localStorage.setItem('crmthree-theme', pref);
    setPreferenceState(pref);
  }, []);

  const theme = useMemo(() => (mode === 'dark' ? darkTheme : lightTheme), [mode]);

  const contextValue = useMemo(() => ({ mode, preference, setPreference }), [mode, preference, setPreference]);

  return (
    <ThemeContext.Provider value={contextValue}>
      <MuiThemeProvider theme={theme}>
        <CssBaseline />
        {children}
      </MuiThemeProvider>
    </ThemeContext.Provider>
  );
}
