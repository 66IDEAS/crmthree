import { createTheme } from '@mui/material/styles';
import { lightTokens, fontStack } from './tokens';

const lightTheme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: lightTokens.primary,
      dark: lightTokens.primaryDark,
      light: lightTokens.primaryLight,
    },
    success: { main: lightTokens.green },
    error: { main: lightTokens.red },
    warning: { main: lightTokens.amber },
    background: {
      default: lightTokens.gray50,
      paper: '#ffffff',
    },
    text: {
      primary: lightTokens.gray900,
      secondary: lightTokens.gray500,
    },
    divider: lightTokens.gray200,
  },
  typography: {
    fontFamily: fontStack,
    fontSize: 14,
    h1: { fontSize: '1.75rem', fontWeight: 600 },
    h2: { fontSize: '1.3rem', fontWeight: 600, color: lightTokens.gray900 },
    h3: { fontSize: '1.05rem', fontWeight: 600, color: lightTokens.gray700 },
    body1: { fontSize: '0.9rem', lineHeight: 1.6 },
    body2: { fontSize: '0.85rem', lineHeight: 1.6, color: lightTokens.gray500 },
  },
  shape: {
    borderRadius: lightTokens.radius,
  },
  shadows: [
    'none',
    lightTokens.shadow,
    lightTokens.shadow,
    lightTokens.shadowLg,
    lightTokens.shadowLg,
    ...Array(20).fill(lightTokens.shadowLg),
  ],
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
      defaultProps: { elevation: 1 },
    },
    MuiButton: {
      styleOverrides: {
        root: { textTransform: 'none', fontWeight: 500 },
      },
    },
  },
});

export default lightTheme;
