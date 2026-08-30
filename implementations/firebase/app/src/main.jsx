import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import ThemeProvider from './theme/ThemeProvider';
import UIProvider from './contexts/UIContext';
import AuthProvider from './contexts/AuthContext';
import TranslationProvider from './contexts/TranslationContext';
import App from './App';

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <ThemeProvider>
      <UIProvider>
        <AuthProvider>
          <TranslationProvider>
            <App />
          </TranslationProvider>
        </AuthProvider>
      </UIProvider>
    </ThemeProvider>
  </StrictMode>
);
