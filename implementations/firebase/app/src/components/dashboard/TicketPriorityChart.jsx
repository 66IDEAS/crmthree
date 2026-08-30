import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import { useTheme } from '@mui/material/styles';

const PRIORITY_COLORS = {
  Low: '#4caf50',
  Medium: '#ff9800',
  High: '#f44336',
  Critical: '#9c27b0',
};

export default function TicketPriorityChart({ data, onClick }) {
  const theme = useTheme();

  if (!data || data.length === 0) {
    return (
      <Paper sx={{ p: 2.5, height: '100%' }}>
        <Typography variant="subtitle2" sx={{ mb: 2 }}>Tickets by Priority</Typography>
        <Typography variant="body2" color="text.secondary">No ticket data available.</Typography>
      </Paper>
    );
  }

  return (
    <Paper sx={{ p: 2.5, height: '100%' }}>
      <Typography variant="subtitle2" sx={{ mb: 2 }}>Tickets by Priority</Typography>
      <ResponsiveContainer width="100%" height={250}>
        <PieChart>
          <Pie
            data={data}
            dataKey="value"
            nameKey="name"
            cx="50%"
            cy="50%"
            innerRadius={50}
            outerRadius={80}
            paddingAngle={3}
            label={({ name, value }) => `${name}: ${value}`}
            onClick={onClick}
            style={{ cursor: onClick ? 'pointer' : 'default' }}
          >
            {data.map((entry) => (
              <Cell key={entry.name} fill={PRIORITY_COLORS[entry.name] || theme.palette.grey[400]} />
            ))}
          </Pie>
          <Tooltip />
          <Legend />
        </PieChart>
      </ResponsiveContainer>
    </Paper>
  );
}
