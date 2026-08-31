import { BrowserRouter, Routes, Route } from 'react-router';
import AppLayout from './layout/AppLayout';
import LoginPage from './pages/LoginPage';
import LoadingSpinner from './components/common/LoadingSpinner';
import { useAuth } from './contexts/AuthContext';
import routes from './config/routes';
import Box from '@mui/material/Box';
import Alert from '@mui/material/Alert';
import Button from '@mui/material/Button';
import Typography from '@mui/material/Typography';
import NavigationHistoryProvider from './contexts/NavigationHistoryContext';
import NotificationProvider from './contexts/NotificationContext';
import GamificationProvider from './contexts/GamificationContext';
import { t } from './services/TranslationService';
import usePermissions from './hooks/usePermissions';
import { seedBundledTranslations } from './services/TranslationSeeder';
import { useEffect } from 'react';

function AuthGate({ children }) {
  const { user, userProfile, loading, profileLoading, rejectedReason, handleSignOut } = useAuth();
  const { isAdmin } = usePermissions();

  // First-run seeding of bundled language packs runs once an administrator is signed in.
  useEffect(() => {
    if (user && userProfile && isAdmin) seedBundledTranslations();
  }, [user, userProfile, isAdmin]);

  if (loading) {
    return (
      <Box sx={{ height: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <LoadingSpinner />
      </Box>
    );
  }

  if (!user) {
    return <LoginPage />;
  }

  if (profileLoading) {
    return (
      <Box sx={{ height: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap: 2 }}>
        <LoadingSpinner />
        <Typography variant="body2" color="text.secondary">
          {t('app.loading_profile', 'Loading your profile...')}
        </Typography>
      </Box>
    );
  }

  if (rejectedReason === 'deactivated') {
    return (
      <Box sx={{ height: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', p: 3 }}>
        <Alert
          severity="warning"
          sx={{ maxWidth: 420 }}
          action={
            <Button color="inherit" size="small" onClick={handleSignOut}>
              {t('ui.sign_out', 'Sign Out')}
            </Button>
          }
        >
          {t('app.deactivated', 'Your account has been deactivated. Please contact an administrator.')}
        </Alert>
      </Box>
    );
  }

  if (rejectedReason === 'not_whitelisted') {
    return (
      <Box sx={{ height: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', p: 3 }}>
        <Alert
          severity="warning"
          sx={{ maxWidth: 400 }}
          action={
            <Button color="inherit" size="small" onClick={handleSignOut}>
              {t('ui.sign_out', 'Sign Out')}
            </Button>
          }
        >
          {t('app.not_authorized', 'Your email address is not authorized to access this application. Please contact an administrator.')}
        </Alert>
      </Box>
    );
  }

  if (!userProfile) {
    return (
      <Box sx={{ height: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', p: 3 }}>
        <Alert
          severity="info"
          sx={{ maxWidth: 420 }}
          action={
            <Button color="inherit" size="small" onClick={handleSignOut}>
              {t('ui.sign_out', 'Sign Out')}
            </Button>
          }
        >
          {t('app.not_provisioned', 'Your account has not been provisioned yet. Please contact an administrator to set up your user profile.')}
          {user?.email && (
            <Typography variant="body2" sx={{ mt: 1, fontWeight: 600 }}>
              {user.email}
            </Typography>
          )}
        </Alert>
      </Box>
    );
  }

  return children;
}

export default function App() {
  return (
    <BrowserRouter>
      <NavigationHistoryProvider>
        <AuthGate>
          <NotificationProvider>
            <GamificationProvider>
              <Routes>
                <Route element={<AppLayout />}>
                  {routes.map(({ path, element: Element }) => (
                    <Route key={path} path={path} element={<Element />} />
                  ))}
                </Route>
              </Routes>
            </GamificationProvider>
          </NotificationProvider>
        </AuthGate>
      </NavigationHistoryProvider>
    </BrowserRouter>
  );
}
