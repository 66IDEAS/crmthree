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
import AddCircleOutlineIcon from '@mui/icons-material/AddCircleOutline';
import EditNoteIcon from '@mui/icons-material/EditNote';
import { useNavigate } from 'react-router';
import { useList } from '../../hooks/useDataService';
import { t } from '../../services/TranslationService';
import { timeAgo } from '../../utils/timeUtils';
import { getXPEventConfigs } from '../../services/GamificationService';

/** Icons for Activity types */
const ACTIVITY_ICON_MAP = {
  Call: { icon: PhoneIcon, color: 'info.main' },
  Email: { icon: EmailIcon, color: 'warning.main' },
  Meeting: { icon: EventIcon, color: 'primary.main' },
  Task: { icon: TaskIcon, color: 'success.main' },
};

const ACTIVITY_STATUS_COLORS = {
  Planned: 'info',
  'In Progress': 'warning',
  Completed: 'success',
  Cancelled: 'default',
};

/** Icons for AuditLog actions */
const AUDIT_ICON_MAP = {
  Create: { icon: AddCircleOutlineIcon, color: 'success.main' },
  Update: { icon: EditNoteIcon, color: 'info.main' },
  Delete: { icon: EditNoteIcon, color: 'error.main' },
};

/** Colors for object type chips */
const OBJECT_TYPE_COLORS = {
  Account: 'primary',
  Contact: 'primary',
  Lead: 'warning',
  Opportunity: 'success',
  Ticket: 'info',
  Quotation: 'default',
  SalesOrder: 'default',
  Invoice: 'default',
};

const CONTEXT_FIELDS = [
  { field: 'account_id', label: 'Account' },
  { field: 'opportunity_id', label: 'Opportunity' },
  { field: 'ticket_id', label: 'Ticket' },
  { field: 'lead_id', label: 'Lead' },
  { field: 'contact_id', label: 'Contact' },
];

/**
 * CombinedTimeline — merges Activity records and AuditLog events into a single
 * chronological feed. Used by MyTimelinePage and TeamTimelinePage.
 *
 * Props:
 * - activityFilters: Firestore filters for Activity query
 * - auditFilters: Firestore filters for AuditLog query
 * - eventType: 'all' | 'activities' | 'events' — controls which entries to show
 * - title: section title
 * - emptyMessage: message when no entries
 * - showContext: show parent record chips on activities
 * - showOwner: show owner name per entry
 * - ownerNames: { userId: name } map
 */
/** Maps object type + audit action to XP event type */
const CREATE_XP_MAP = {
  Account: 'create_account',
  Contact: 'create_contact',
  Lead: 'create_lead',
  Opportunity: 'create_opportunity',
  Activity: 'log_activity',
  Quotation: 'create_quotation',
  KnowledgeArticle: 'create_knowledge_article',
};

export default function CombinedTimeline({
  activityFilters,
  auditFilters,
  eventType = 'all',
  title,
  emptyMessage,
  showContext = false,
  showOwner = false,
  ownerNames,
  showXP = false,
}) {
  const navigate = useNavigate();

  // Fetch XP event configs when showXP is enabled
  const [xpMap, setXpMap] = useState({});
  useEffect(() => {
    if (!showXP) return;
    getXPEventConfigs().then((events) => {
      const map = {};
      for (const e of events) {
        map[e.event_type] = e.xp_value || 0;
      }
      setXpMap(map);
    });
  }, [showXP]);

  // Query Activities (only if showing all or activities)
  const shouldLoadActivities = eventType === 'all' || eventType === 'activities';
  const activityOpts = useMemo(() => ({
    filters: activityFilters || [],
    pageSize: 200,
  }), [activityFilters]);
  const { data: activities, loading: activitiesLoading } = useList(
    shouldLoadActivities ? 'Activity' : null,
    shouldLoadActivities ? activityOpts : {}
  );

  // Query AuditLog (only if showing all or events)
  const shouldLoadAudit = eventType === 'all' || eventType === 'events';
  const auditOpts = useMemo(() => ({
    filters: auditFilters || [],
    pageSize: 200,
  }), [auditFilters]);
  const { data: auditEntries, loading: auditLoading } = useList(
    shouldLoadAudit ? 'AuditLog' : null,
    shouldLoadAudit ? auditOpts : {}
  );

  const loading = (shouldLoadActivities && activitiesLoading) || (shouldLoadAudit && auditLoading);

  // Normalize and merge entries
  const merged = useMemo(() => {
    const items = [];

    if (shouldLoadActivities && activities) {
      for (const a of activities) {
        items.push({
          _source: 'activity',
          _sortTime: a.created_at || '',
          ...a,
        });
      }
    }

    if (shouldLoadAudit && auditEntries) {
      for (const e of auditEntries) {
        items.push({
          _source: 'audit',
          _sortTime: e.timestamp || e.created_at || '',
          ...e,
        });
      }
    }

    items.sort((a, b) => (b._sortTime || '').localeCompare(a._sortTime || ''));
    return items;
  }, [activities, auditEntries, shouldLoadActivities, shouldLoadAudit]);

  return (
    <Paper variant="outlined" sx={{ p: 2 }}>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
        <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
          {title || t('section.timeline', 'Timeline')}
        </Typography>
        {!loading && (
          <Chip label={merged.length} size="small" variant="outlined" />
        )}
      </Box>

      {loading && (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 3 }}>
          <CircularProgress size={24} />
        </Box>
      )}

      {!loading && merged.length === 0 && (
        <Typography variant="body2" color="text.secondary" sx={{ py: 2, textAlign: 'center' }}>
          {emptyMessage || t('timeline.no_entries', 'No timeline entries found.')}
        </Typography>
      )}

      {!loading && merged.map((entry, index) => {
        const isLast = index === merged.length - 1;

        if (entry._source === 'activity') {
          return (
            <ActivityEntry
              key={`a-${entry.id}`}
              activity={entry}
              isLast={isLast}
              showContext={showContext}
              showOwner={showOwner}
              ownerNames={ownerNames}
              xp={showXP ? xpMap.log_activity : null}
              onClick={() => navigate(`/activities/${entry.id}`)}
            />
          );
        }

        const auditEventType = entry.action === 'Create' ? CREATE_XP_MAP[entry.object_type] : null;
        return (
          <AuditEntry
            key={`e-${entry.id}`}
            entry={entry}
            isLast={isLast}
            showOwner={showOwner}
            ownerNames={ownerNames}
            xp={showXP && auditEventType ? xpMap[auditEventType] : null}
          />
        );
      })}
    </Paper>
  );
}

/** Renders an Activity entry (call, email, meeting, task) */
function ActivityEntry({ activity, isLast, showContext, showOwner, ownerNames, xp, onClick }) {
  const config = ACTIVITY_ICON_MAP[activity.type] || ACTIVITY_ICON_MAP.Task;
  const Icon = config.icon;

  return (
    <Box
      onClick={onClick}
      sx={{
        display: 'flex',
        gap: 1.5,
        cursor: 'pointer',
        position: 'relative',
        pb: isLast ? 0 : 2,
        '&:hover': { bgcolor: 'action.hover', borderRadius: 1 },
      }}
    >
      {!isLast && <ConnectorLine />}
      <Avatar sx={{ width: 32, height: 32, bgcolor: config.color, flexShrink: 0 }}>
        <Icon sx={{ fontSize: 16 }} />
      </Avatar>
      <Box sx={{ flex: 1, minWidth: 0 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexWrap: 'wrap' }}>
          <Typography variant="body2" sx={{ fontWeight: 600 }} noWrap>
            {activity.subject || activity.type}
          </Typography>
          {activity.status && (
            <Chip
              label={activity.status}
              size="small"
              color={ACTIVITY_STATUS_COLORS[activity.status] || 'default'}
            />
          )}
          {xp > 0 && (
            <Chip
              label={`+${xp} XP`}
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
}

/** Renders an AuditLog entry (record created, field changed) */
function AuditEntry({ entry, isLast, showOwner, ownerNames, xp }) {
  const config = AUDIT_ICON_MAP[entry.action] || AUDIT_ICON_MAP.Update;
  const Icon = config.icon;
  const objectLabel = (entry.object_type || '').replace(/([a-z])([A-Z])/g, '$1 $2');

  return (
    <Box
      sx={{
        display: 'flex',
        gap: 1.5,
        position: 'relative',
        pb: isLast ? 0 : 2,
      }}
    >
      {!isLast && <ConnectorLine />}
      <Avatar sx={{ width: 32, height: 32, bgcolor: config.color, flexShrink: 0 }}>
        <Icon sx={{ fontSize: 16 }} />
      </Avatar>
      <Box sx={{ flex: 1, minWidth: 0 }}>
        <Typography variant="body2" sx={{ fontWeight: 500 }}>
          {entry.summary || `${entry.action} ${objectLabel}`}
        </Typography>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexWrap: 'wrap', mt: 0.25 }}>
          {showOwner && ownerNames?.[entry.user_id] && (
            <Typography variant="caption" sx={{ fontWeight: 600 }}>
              {ownerNames[entry.user_id]}
            </Typography>
          )}
          <Typography variant="caption" color="text.secondary">
            {timeAgo(entry.timestamp || entry.created_at)}
          </Typography>
          <Chip
            label={objectLabel}
            size="small"
            color={OBJECT_TYPE_COLORS[entry.object_type] || 'default'}
            sx={{ fontSize: '0.6rem', height: 16 }}
          />
          {xp > 0 && (
            <Chip
              label={`+${xp} XP`}
              size="small"
              sx={{ bgcolor: '#F7941D', color: '#fff', fontWeight: 600, fontSize: '0.65rem', height: 20 }}
            />
          )}
        </Box>
      </Box>
    </Box>
  );
}

/** Vertical connector line between timeline entries */
function ConnectorLine() {
  return (
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
  );
}
