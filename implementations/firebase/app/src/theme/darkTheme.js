import { createTheme } from '@mui/material/styles';
import { darkTokens, fontStack } from './tokens';

const darkTheme = createTheme({
  palette: {
    mode: 'dark',
    primary: { main: darkTokens.accentBlue },
    success: { main: darkTokens.accentGreen },
    error: { main: darkTokens.accentRed },
    warning: { main: darkTokens.accentOrange },
    info: { main: darkTokens.accentPurple },
    background: {
      default: darkTokens.bgPrimary,
      paper: darkTokens.bgSecondary,
    },
    text: {
      primary: darkTokens.textPrimary,
      secondary: darkTokens.textSecondary,
    },
    divider: darkTokens.border,
  },
  typography: {
    fontFamily: fontStack,
    fontSize: 14,
    h1: { fontSize: '1.75rem', fontWeight: 700 },
    h2: { fontSize: '1.5rem', fontWeight: 700 },
    h3: { fontSize: '1rem', fontWeight: 600, color: darkTokens.accentBlue },
    body1: { fontSize: '0.875rem', lineHeight: 1.6 },
    body2: { fontSize: '0.8rem', lineHeight: 1.7, color: darkTokens.textSecondary },
  },
  shape: {
    borderRadius: darkTokens.radiusLg,
  },
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        body: {
          lineHeight: 1.6,
          margin: 0,
          padding: 0,
        },
      },
    },
    MuiPaper: {
      defaultProps: { elevation: 0 },
      styleOverrides: {
        root: {
          backgroundImage: 'none',
          border: `1px solid ${darkTokens.border}`,
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: { textTransform: 'none', fontWeight: 600 },
      },
    },
    MuiDrawer: {
      styleOverrides: {
        paper: {
          backgroundColor: darkTokens.bgSecondary,
          borderRight: `1px solid ${darkTokens.border}`,
        },
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          backgroundColor: darkTokens.bgSecondary,
          borderBottom: `1px solid ${darkTokens.border}`,
        },
      },
    },
  },
});

export default darkTheme;
