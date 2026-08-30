import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { useTheme } from '@mui/material/styles';

export default function ActivityTrendChart({ data, onClick }) {
  const theme = useTheme();

  if (!data || data.length === 0) {
    return (
      <Paper sx={{ p: 2.5, height: '100%' }}>
        <Typography variant="subtitle2" sx={{ mb: 2 }}>Activity Trend (Last 7 Days)</Typography>
        <Typography variant="body2" color="text.secondary">No activity data available.</Typography>
      </Paper>
    );
  }

  return (
    <Paper sx={{ p: 2.5, height: '100%' }}>
      <Typography variant="subtitle2" sx={{ mb: 2 }}>Activity Trend (Last 7 Days)</Typography>
      <ResponsiveContainer width="100%" height={250}>
        <LineChart data={data} margin={{ left: 0, right: 20, top: 5, bottom: 5 }}>
          <CartesianGrid strokeDasharray="3 3" stroke={theme.palette.divider} />
          <XAxis dataKey="day" tick={{ fontSize: 12 }} />
          <YAxis allowDecimals={false} tick={{ fontSize: 12 }} />
          <Tooltip />
          <Line
            type="monotone"
            dataKey="count"
            stroke={theme.palette.secondary.main}
            strokeWidth={2}
            dot={{ r: 4 }}
            activeDot={{ r: 6, onClick, style: { cursor: onClick ? 'pointer' : 'default' } }}
            name="Activities"
          />
        </LineChart>
      </ResponsiveContainer>
    </Paper>
  );
}
