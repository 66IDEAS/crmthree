import Box from '@mui/material/Box';
import { Outlet } from 'react-router';
import HistoryBreadcrumbs from './HistoryBreadcrumbs';

export default function MainContent() {
  return (
    <Box
      component="main"
      sx={{
        gridArea: 'content',
        display: 'flex',
        flexDirection: 'column',
        overflow: 'hidden',
      }}
    >
      <Box sx={{ px: { xs: 1.5, md: 3 }, pt: 1.5, flexShrink: 0 }}>
        <HistoryBreadcrumbs />
      </Box>
      <Box sx={{ flex: 1, overflow: 'auto', px: { xs: 1.5, md: 3 }, pb: 3 }}>
        <Outlet />
      </Box>
    </Box>
  );
}
