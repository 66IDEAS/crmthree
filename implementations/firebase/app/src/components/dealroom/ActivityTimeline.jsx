import { useMemo, useState, useEffect } from 'react';
import Box from '@mui/material/Box';
import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import Avatar from '@mui/material/Avatar';
import Chip from '@mui/material/Chip';
import CircularProgress from '@mui/material/CircularProgress';
import PhoneIcon from '@mui/icons-material/Phone';
import EmailIcon from '@mui/icons-material/Email';
import EventIcon from '@mui/icons-material/Event';
import TaskIcon from '@mui/icons-material/Task';
import { useNavigate } from 'react-router';
import { useList } from '../../hooks/useDataService';
import { t } from '../../services/TranslationService';
import { timeAgo } from '../../utils/timeUtils';
import { getXPEventConfigs } from '../../services/GamificationService';

const ICON_MAP = {
  Call: { icon: PhoneIcon, color: 'info.main' },
  Email: { icon: EmailIcon, color: 'warning.main' },
  Meeting: { icon: EventIcon, color: 'primary.main' },
  Task: { icon: TaskIcon, color: 'success.main' },
};

const STATUS_COLORS = {
  Planned: 'info',
  'In Progress': 'warning',
  Completed: 'success',
  Cancelled: 'default',
};

const CONTEXT_FIELDS = [
  { field: 'account_id', label: 'Account' },
  { field: 'opportunity_id', label: 'Opportunity' },
  { field: 'ticket_id', label: 'Ticket' },
  { field: 'lead_id', label: 'Lead' },
  { field: 'contact_id', label: 'Contact' },
];

export default function ActivityTimeline({
  opportunityId,
  ticketId,
  filters: filtersProp,
  title,
  emptyMessage,
  showContext = false,
  showOwner = false,
  ownerNames,
  showXP = false,
}) {
  const resolvedFilters = useMemo(() => {
    if (filtersProp) return filtersProp;
    if (opportunityId) return [{ field: 'opportunity_id', op: '==', value: opportunityId }];
    if (ticketId) return [{ field: 'ticket_id', op: '==', value: ticketId }];
    return [];
  }, [filtersProp, opportunityId, ticketId]);

  const filterOpts = useMemo(() => ({
    filters: resolvedFilters,
    pageSize: 200,
  }), [resolvedFilters]);

  const { data: activities, loading } = useList('Activity', filterOpts);
  const navigate = useNavigate();

  // Fetch XP value for log_activity when showXP is enabled
  const [activityXP, setActivityXP] = useState(null);
  useEffect(() => {
    if (!showXP) return;
    getXPEventConfigs().then((events) => {
      const evt = events.find((e) => e.event_type === 'log_activity');
      setActivityXP(evt?.xp_value || 0);
    });
  }, [showXP]);

  const sorted = useMemo(
    () => [...(activities || [])].sort((a, b) => (b.created_at || '').localeCompare(a.created_at || '')),
    [activities]
  );

  return (
    <Paper variant="outlined" sx={{ p: 2 }}>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
        <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
          {title || t('section.activity_timeline', 'Activity Timeline')}
        </Typography>
        {!loading && (
          <Chip label={sorted.length} size="small" variant="outlined" />
        )}
      </Box>

      {loading && (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 3 }}>
          <CircularProgress size={24} />
        </Box>
      )}

      {!loading && sorted.length === 0 && (
        <Typography variant="body2" color="text.secondary" sx={{ py: 2, textAlign: 'center' }}>
          {emptyMessage || t('dealroom.no_activities', 'No activities recorded yet.')}
        </Typography>
      )}

      {!loading && sorted.map((activity, index) => {
        const config = ICON_MAP[activity.type] || ICON_MAP.Task;
        const Icon = config.icon;
        const isLast = index === sorted.length - 1;

        return (
          <Box
            key={activity.id}
            onClick={() => navigate(`/activities/${activity.id}`)}
            sx={{
              display: 'flex',
              gap: 1.5,
              cursor: 'pointer',
              position: 'relative',
              pb: isLast ? 0 : 2,
              '&:hover': { bgcolor: 'action.hover', borderRadius: 1 },
            }}
          >
            {/* Connector line */}
            {!isLast && (
              <Box
                sx={{
                  position: 'absolute',
                  left: 15,
                  top: 32,
                  bottom: 0,
                  width: 2,
                  bgcolor: 'divider',
                }}
              />
            )}

            {/* Icon */}
            <Avatar sx={{ width: 32, height: 32, bgcolor: config.color, flexShrink: 0 }}>
              <Icon sx={{ fontSize: 16 }} />
            </Avatar>

            {/* Content */}
            <Box sx={{ flex: 1, minWidth: 0 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexWrap: 'wrap' }}>
                <Typography variant="body2" sx={{ fontWeight: 600 }} noWrap>
                  {activity.subject || activity.type}
                </Typography>
                {activity.status && (
                  <Chip
                    label={activity.status}
                    size="small"
                    color={STATUS_COLORS[activity.status] || 'default'}
                  />
                )}
                {showXP && activityXP > 0 && (
                  <Chip
                    label={`+${activityXP} XP`}
                    size="small"
                    sx={{ bgcolor: '#F7941D', color: '#fff', fontWeight: 600, fontSize: '0.65rem', height: 20 }}
                  />
                )}
              </Box>
              {activity.description && (
                <Typography
                  variant="body2"
                  color="text.secondary"
                  sx={{
                    mt: 0.25,
                    overflow: 'hidden',
                    display: '-webkit-box',
                    WebkitLineClamp: 2,
                    WebkitBoxOrient: 'vertical',
                  }}
                >
                  {activity.description}
                </Typography>
              )}
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexWrap: 'wrap' }}>
                {showOwner && ownerNames?.[activity.owner_id] && (
                  <Typography variant="caption" sx={{ fontWeight: 600 }}>
                    {ownerNames[activity.owner_id]}
                  </Typography>
                )}
                <Typography variant="caption" color="text.secondary">
                  {timeAgo(activity.created_at)}
                </Typography>
                {showContext && CONTEXT_FIELDS.map(({ field, label }) =>
                  activity[field] ? (
                    <Chip
                      key={field}
                      label={label}
                      size="small"
                      variant="outlined"
                      sx={{ fontSize: '0.6rem', height: 16 }}
                    />
                  ) : null
                )}
              </Box>
            </Box>
          </Box>
        );
      })}
    </Paper>
  );
}
