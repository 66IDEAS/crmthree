import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';

export default function KpiCard({ title, value, subtitle, icon: Icon, color = 'primary.main', onClick }) {
  return (
    <Paper
      onClick={onClick}
      sx={{
        p: 2.5,
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        cursor: onClick ? 'pointer' : 'default',
        transition: 'box-shadow 0.2s',
        '&:hover': onClick ? { boxShadow: 4 } : {},
      }}
    >
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <Box>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 0.5 }}>
            {title}
          </Typography>
          <Typography variant="h4" sx={{ fontWeight: 700 }}>
            {value}
          </Typography>
        </Box>
        {Icon && (
          <Box sx={{ p: 1, borderRadius: 2, bgcolor: `${color}15` }}>
            <Icon sx={{ color, fontSize: 28 }} />
          </Box>
        )}
      </Box>
      {subtitle && (
        <Typography variant="caption" color="text.secondary" sx={{ mt: 1 }}>
          {subtitle}
        </Typography>
      )}
    </Paper>
  );
}
