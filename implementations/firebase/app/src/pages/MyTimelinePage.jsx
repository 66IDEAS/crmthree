import { useState, useMemo } from 'react';
import Box from '@mui/material/Box';
import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import TextField from '@mui/material/TextField';
import MenuItem from '@mui/material/MenuItem';
import TimelineIcon from '@mui/icons-material/Timeline';
import { useAuth } from '../contexts/AuthContext';
import CombinedTimeline from '../components/timeline/CombinedTimeline';
import { t } from '../services/TranslationService';

const EVENT_TYPES = [
  { key: 'all', label: 'All' },
  { key: 'activities', label: 'Activities Only' },
  { key: 'events', label: 'Events Only' },
];

export default function MyTimelinePage() {
  const { userProfile } = useAuth();

  const today = new Date();
  const thirtyDaysAgo = new Date(today);
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  const [dateFrom, setDateFrom] = useState(thirtyDaysAgo.toISOString().split('T')[0]);
  const [dateTo, setDateTo] = useState(today.toISOString().split('T')[0]);
  const [eventType, setEventType] = useState('all');

  // Activity filters: owner_id == userId
  const activityFilters = useMemo(() => {
    if (!userProfile?.id) return null;
    return [{ field: 'owner_id', op: '==', value: userProfile.id }];
  }, [userProfile?.id]);

  // AuditLog filters: user_id == userId
  const auditFilters = useMemo(() => {
    if (!userProfile?.id) return null;
    return [{ field: 'user_id', op: '==', value: userProfile.id }];
  }, [userProfile?.id]);

  return (
    <Box>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
        <TimelineIcon sx={{ color: '#F7941D', fontSize: 28 }} />
        <Typography variant="h5" sx={{ fontWeight: 700 }}>
          {t('profile.my_timeline', 'My Timeline')}
        </Typography>
      </Box>

      {/* Filter controls */}
      <Paper sx={{ p: 2, mb: 2 }}>
        <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
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
            label={t('filter.event_type', 'Event Type')}
            value={eventType}
            onChange={(e) => setEventType(e.target.value)}
            size="small"
            sx={{ minWidth: 170 }}
          >
            {EVENT_TYPES.map((et) => (
              <MenuItem key={et.key} value={et.key}>
                {t(`filter.${et.key}`, et.label)}
              </MenuItem>
            ))}
          </TextField>
        </Box>
      </Paper>

      {/* Combined timeline */}
      {activityFilters && (
        <CombinedTimeline
          activityFilters={activityFilters}
          auditFilters={auditFilters}
          eventType={eventType}
          showContext
          showXP
          title={t('profile.recent_activities', 'Recent Activities')}
          emptyMessage={t('profile.no_activities', 'No timeline entries found for the selected filters.')}
        />
      )}
    </Box>
  );
}
