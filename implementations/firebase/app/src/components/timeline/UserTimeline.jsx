import { useState, useMemo } from 'react';
import Box from '@mui/material/Box';
import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import Chip from '@mui/material/Chip';
import TextField from '@mui/material/TextField';
import MenuItem from '@mui/material/MenuItem';
import TimelineIcon from '@mui/icons-material/Timeline';
import { useList } from '../../hooks/useDataService';
import ActivityTimeline from '../dealroom/ActivityTimeline';
import { t } from '../../services/TranslationService';

const ACTIVITY_TYPES = ['Call', 'Email', 'Meeting', 'Task'];

export default function UserTimeline({ userId }) {
  const today = new Date();
  const thirtyDaysAgo = new Date(today);
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  const [dateFrom, setDateFrom] = useState(thirtyDaysAgo.toISOString().split('T')[0]);
  const [dateTo, setDateTo] = useState(today.toISOString().split('T')[0]);
  const [typeFilter, setTypeFilter] = useState('All');

  // Build filters for ActivityTimeline
  const filters = useMemo(() => {
    const f = [{ field: 'owner_id', op: '==', value: userId }];
    if (typeFilter !== 'All') {
      f.push({ field: 'type', op: '==', value: typeFilter });
    }
    return f;
  }, [userId, typeFilter]);

  // Load all activities via filters prop on ActivityTimeline
  // Client-side date filtering via the activities returned
  // We pass the filters directly to ActivityTimeline which handles the Firestore query

  return (
    <Paper sx={{ p: 3, mb: 3 }}>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
        <TimelineIcon sx={{ color: '#F7941D' }} />
        <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
          {t('profile.my_timeline', 'My Timeline')}
        </Typography>
      </Box>

      {/* Filter controls */}
      <Box sx={{ display: 'flex', gap: 2, mb: 2, flexWrap: 'wrap' }}>
        <TextField
          type="date"
          label={t('filter.from', 'From')}
          value={dateFrom}
          onChange={(e) => setDateFrom(e.target.value)}
          size="small"
          slotProps={{ inputLabel: { shrink: true } }}
          sx={{ minWidth: 150 }}
        />
        <TextField
          type="date"
          label={t('filter.to', 'To')}
          value={dateTo}
          onChange={(e) => setDateTo(e.target.value)}
          size="small"
          slotProps={{ inputLabel: { shrink: true } }}
          sx={{ minWidth: 150 }}
        />
        <TextField
          select
          label={t('filter.activity_type', 'Activity Type')}
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          size="small"
          sx={{ minWidth: 150 }}
        >
          <MenuItem value="All">{t('filter.all', 'All')}</MenuItem>
          {ACTIVITY_TYPES.map((type) => (
            <MenuItem key={type} value={type}>{type}</MenuItem>
          ))}
        </TextField>
      </Box>

      {/* Activity timeline with context */}
      <ActivityTimeline
        filters={filters}
        showContext
        showXP
        title={t('profile.recent_activities', 'Recent Activities')}
        emptyMessage={t('profile.no_activities', 'No activities found for the selected filters.')}
      />
    </Paper>
  );
}
