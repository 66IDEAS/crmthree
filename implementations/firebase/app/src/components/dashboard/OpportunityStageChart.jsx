import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { useTheme } from '@mui/material/styles';

export default function OpportunityStageChart({ data, onClick }) {
  const theme = useTheme();

  if (!data || data.length === 0) {
    return (
      <Paper sx={{ p: 2.5, height: '100%' }}>
        <Typography variant="subtitle2" sx={{ mb: 2 }}>Opportunities by Stage</Typography>
        <Typography variant="body2" color="text.secondary">No opportunity data available.</Typography>
      </Paper>
    );
  }

  return (
    <Paper sx={{ p: 2.5, height: '100%' }}>
      <Typography variant="subtitle2" sx={{ mb: 2 }}>Opportunities by Stage</Typography>
      <ResponsiveContainer width="100%" height={250}>
        <BarChart data={data} layout="vertical" margin={{ left: 20, right: 20, top: 5, bottom: 5 }}>
          <CartesianGrid strokeDasharray="3 3" stroke={theme.palette.divider} />
          <XAxis type="number" allowDecimals={false} tick={{ fontSize: 12 }} />
          <YAxis dataKey="name" type="category" width={100} tick={{ fontSize: 12 }} />
          <Tooltip />
          <Bar
            dataKey="value"
            fill={theme.palette.primary.main}
            radius={[0, 4, 4, 0]}
            name="Count"
            onClick={onClick}
            style={{ cursor: onClick ? 'pointer' : 'default' }}
          />
        </BarChart>
      </ResponsiveContainer>
    </Paper>
  );
}
