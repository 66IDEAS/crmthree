import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';

export default function NotFoundPage() {
  return (
    <Box sx={{ textAlign: 'center', mt: 8 }}>
      <Typography variant="h3" sx={{ fontWeight: 700, mb: 1 }}>
        404
      </Typography>
      <Typography variant="body1" color="text.secondary">
        Page not found.
      </Typography>
    </Box>
  );
}
