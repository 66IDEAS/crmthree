import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from 'recharts';
import { useTheme } from '@mui/material/styles';

const STATUS_COLORS = {
  Paid: '#4caf50',
  Sent: '#2196f3',
  Draft: '#9e9e9e',
  Overdue: '#f44336',
  'Partially Paid': '#ff9800',
  Cancelled: '#757575',
};

function formatCurrency(value) {
  if (value >= 1000000) return `${(value / 1000000).toFixed(1)}M`;
  if (value >= 1000) return `${(value / 1000).toFixed(1)}K`;
  return value.toString();
}

export default function RevenueChart({ data, onClick }) {
  const theme = useTheme();

  if (!data || data.length === 0) {
    return (
      <Paper sx={{ p: 2.5, height: '100%' }}>
        <Typography variant="subtitle2" sx={{ mb: 2 }}>Revenue by Invoice Status</Typography>
        <Typography variant="body2" color="text.secondary">No invoice data available.</Typography>
      </Paper>
    );
  }

  const coloredData = data.map((d) => ({
    ...d,
    fill: STATUS_COLORS[d.name] || theme.palette.grey[400],
  }));

  return (
    <Paper sx={{ p: 2.5, height: '100%' }}>
      <Typography variant="subtitle2" sx={{ mb: 2 }}>Revenue by Invoice Status</Typography>
      <ResponsiveContainer width="100%" height={250}>
        <BarChart data={coloredData} margin={{ left: 10, right: 20, top: 5, bottom: 5 }}>
          <CartesianGrid strokeDasharray="3 3" stroke={theme.palette.divider} />
          <XAxis dataKey="name" tick={{ fontSize: 12 }} />
          <YAxis tickFormatter={formatCurrency} tick={{ fontSize: 12 }} />
          <Tooltip formatter={(value) => [`$${value.toLocaleString()}`, 'Amount']} />
          <Bar
            dataKey="value"
            radius={[4, 4, 0, 0]}
            name="Amount"
            onClick={onClick}
            style={{ cursor: onClick ? 'pointer' : 'default' }}
          >
            {coloredData.map((entry, index) => (
              <Cell key={index} fill={entry.fill} />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </Paper>
  );
}
