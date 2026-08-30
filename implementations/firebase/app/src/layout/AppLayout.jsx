import Box from '@mui/material/Box';
import TopBar from './TopBar';
import LeftRibbon from './LeftRibbon';
import MainContent from './MainContent';
import AISearchBar from './AISearchBar';
import CelebrationOverlay from '../components/gamification/CelebrationOverlay';
import { useUI } from '../contexts/UIContext';

export default function AppLayout() {
  const { isMobile } = useUI();

  return (
    <Box
      sx={{
        display: 'grid',
        gridTemplateAreas: isMobile
          ? `"topbar" "content" "aibar"`
          : `"topbar topbar" "ribbon content" "aibar aibar"`,
        gridTemplateColumns: isMobile ? '1fr' : 'auto 1fr',
        gridTemplateRows: '56px 1fr 48px',
        height: '100vh',
        bgcolor: 'background.default',
      }}
    >
      <TopBar />
      {!isMobile && <LeftRibbon />}
      {isMobile && <LeftRibbon />}
      <MainContent />
      <AISearchBar />
      <CelebrationOverlay />
    </Box>
  );
}
