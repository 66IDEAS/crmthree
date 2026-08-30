import { useState } from 'react';
import Box from '@mui/material/Box';
import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import TextField from '@mui/material/TextField';
import Button from '@mui/material/Button';
import Divider from '@mui/material/Divider';
import Alert from '@mui/material/Alert';
import CircularProgress from '@mui/material/CircularProgress';
import GoogleIcon from '@mui/icons-material/Google';
import Logo from '../components/common/Logo';
import { useAuth } from '../contexts/AuthContext';
import { t } from '../services/TranslationService';

export default function LoginPage() {
  const { signInEmail, signInGoogle, error: authError, profileLoading } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleEmailSignIn = async (e) => {
    e.preventDefault();
    if (!email || !password) return;
    setLoading(true);
    setError(null);
    try {
      await signInEmail(email, password);
    } catch (err) {
      setError(formatAuthError(err));
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleSignIn = async () => {
    setLoading(true);
    setError(null);
    try {
      await signInGoogle();
    } catch (err) {
      setError(formatAuthError(err));
    } finally {
      setLoading(false);
    }
  };

  const isLoading = loading || profileLoading;
  const displayError = error || authError;

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        bgcolor: 'background.default',
        p: 2,
      }}
    >
      <Paper sx={{ p: 4, maxWidth: 400, width: '100%' }}>
        <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', mb: 3 }}>
          <Logo size={64} by />
          <Typography variant="body2" color="text.secondary" sx={{ mt: 1.5 }}>
            {t('login.subtitle', 'Sign in to continue')}
          </Typography>
        </Box>

        {displayError && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {displayError}
          </Alert>
        )}

        <Box component="form" onSubmit={handleEmailSignIn} noValidate>
          <TextField
            fullWidth
            size="small"
            label={t('login.email', 'Email')}
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            disabled={isLoading}
            sx={{ mb: 2 }}
            autoComplete="email"
          />
          <TextField
            fullWidth
            size="small"
            label={t('login.password', 'Password')}
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            disabled={isLoading}
            sx={{ mb: 2 }}
            autoComplete="current-password"
          />
          <Button
            fullWidth
            variant="contained"
            type="submit"
            disabled={isLoading || !email || !password}
            sx={{ mb: 2 }}
          >
            {isLoading ? <CircularProgress size={22} /> : t('ui.sign_in', 'Sign In')}
          </Button>
        </Box>

        <Divider sx={{ my: 2 }}>{t('ui.or', 'or')}</Divider>

        <Button
          fullWidth
          variant="outlined"
          startIcon={<GoogleIcon />}
          onClick={handleGoogleSignIn}
          disabled={isLoading}
        >
          {t('ui.sign_in_google', 'Sign in with Google')}
        </Button>
      </Paper>
    </Box>
  );
}

function formatAuthError(err) {
  const code = err?.code;
  switch (code) {
    case 'auth/invalid-email':
      return t('login.error.invalid_email', 'Invalid email address.');
    case 'auth/user-disabled':
      return t('login.error.disabled', 'This account has been disabled.');
    case 'auth/user-not-found':
    case 'auth/wrong-password':
    case 'auth/invalid-credential':
      return t('login.error.invalid_credentials', 'Invalid email or password.');
    case 'auth/too-many-requests':
      return t('login.error.too_many_attempts', 'Too many sign-in attempts. Please try again later.');
    case 'auth/popup-closed-by-user':
      return t('login.error.popup_closed', 'Sign-in cancelled.');
    default:
      return err?.message || t('login.error.generic', 'An error occurred during sign-in.');
  }
}
