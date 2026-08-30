import { useState, useEffect, useMemo } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Paper from '@mui/material/Paper';
import TextField from '@mui/material/TextField';
import MenuItem from '@mui/material/MenuItem';
import Alert from '@mui/material/Alert';
import Skeleton from '@mui/material/Skeleton';
import GroupsIcon from '@mui/icons-material/Groups';
import { useAuth } from '../contexts/AuthContext';
import usePermissions from '../hooks/usePermissions';
import DataService from '../services/DataService';
import CombinedTimeline from '../components/timeline/CombinedTimeline';
import { t } from '../services/TranslationService';

const EVENT_TYPES = [
  { key: 'all', label: 'All' },
  { key: 'activities', label: 'Activities Only' },
  { key: 'events', label: 'Events Only' },
];

export default function TeamTimelinePage() {
  const { userProfile } = useAuth();
  const { isAdmin } = usePermissions();
  const [team, setTeam] = useState(null);
  const [members, setMembers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [authorized, setAuthorized] = useState(false);

  const today = new Date();
  const thirtyDaysAgo = new Date(today);
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  const [selectedMember, setSelectedMember] = useState('all');
  const [dateFrom, setDateFrom] = useState(thirtyDaysAgo.toISOString().split('T')[0]);
  const [dateTo, setDateTo] = useState(today.toISOString().split('T')[0]);
  const [eventType, setEventType] = useState('all');

  // Load team and verify authorization
  useEffect(() => {
    if (!userProfile?.id) return;

    const loadTeamData = async () => {
      setLoading(true);
      try {
        // Find the team where this user is the manager
        let teams = await DataService.list('Team', {
          filters: [{ field: 'manager_id', op: '==', value: userProfile.id }],
          pageSize: 1,
        });

        // If admin but not a team manager, try to load any team they belong to
        if (teams.length === 0 && isAdmin && userProfile.team_id) {
          const t = await DataService.getById('Team', userProfile.team_id);
          if (t) teams = [t];
        }

        if (teams.length === 0 && !isAdmin) {
          setAuthorized(false);
          setLoading(false);
          return;
        }

        // Admins without a team can still be authorized
        if (teams.length === 0 && isAdmin) {
          setAuthorized(true);
          setLoading(false);
          return;
        }

        const foundTeam = teams[0];
        setTeam(foundTeam);

        // Verify authorization: must be the manager or admin
        if (foundTeam.manager_id !== userProfile.id && !isAdmin) {
          setAuthorized(false);
          setLoading(false);
          return;
        }

        setAuthorized(true);

        // Load team members
        const teamMembers = await DataService.list('UserProfile', {
          filters: [{ field: 'team_id', op: '==', value: foundTeam.id }],
          pageSize: 50,
        });
        setMembers(teamMembers);
      } catch {
        setAuthorized(false);
      } finally {
        setLoading(false);
      }
    };

    loadTeamData();
  }, [userProfile?.id, userProfile?.team_id, isAdmin]);

  // Build member name map for showOwner
  const ownerNames = useMemo(() => {
    const map = {};
    for (const m of members) {
      const name = [m.first_name, m.last_name].filter(Boolean).join(' ') || m.email || 'User';
      map[m.id] = name;
    }
    return map;
  }, [members]);

  // Build separate filters for Activity and AuditLog
  const activityFilters = useMemo(() => {
    if (members.length === 0) return null;
    const f = [];
    if (selectedMember === 'all') {
      const memberIds = members.map((m) => m.id).slice(0, 30);
      if (memberIds.length > 0) {
        f.push({ field: 'owner_id', op: 'in', value: memberIds });
      }
    } else {
      f.push({ field: 'owner_id', op: '==', value: selectedMember });
    }
    return f;
  }, [members, selectedMember]);

  const auditFilters = useMemo(() => {
    if (members.length === 0) return null;
    const f = [];
    if (selectedMember === 'all') {
      const memberIds = members.map((m) => m.id).slice(0, 30);
      if (memberIds.length > 0) {
        f.push({ field: 'user_id', op: 'in', value: memberIds });
      }
    } else {
      f.push({ field: 'user_id', op: '==', value: selectedMember });
    }
    return f;
  }, [members, selectedMember]);

  if (loading) {
    return (
      <Box>
        <Skeleton width={250} height={36} sx={{ mb: 2 }} />
        {[1, 2, 3].map((i) => (
          <Skeleton key={i} height={80} sx={{ mb: 1, borderRadius: 1 }} />
        ))}
      </Box>
    );
  }

  if (!authorized) {
    return (
      <Box sx={{ p: 2 }}>
        <Alert severity="warning">
          {t('team_timeline.access_denied', 'You do not have access to the Team Timeline. This page is available to team managers and administrators.')}
        </Alert>
      </Box>
    );
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
        <GroupsIcon sx={{ color: '#F7941D', fontSize: 28 }} />
        <Typography variant="h5" sx={{ fontWeight: 700 }}>
          {t('team_timeline.title', 'Team Timeline')}
        </Typography>
        {team && (
          <Typography variant="body2" color="text.secondary" sx={{ ml: 1 }}>
            {team.name}
          </Typography>
        )}
      </Box>

      {members.length === 0 ? (
        <Alert severity="info">
          {t('team_timeline.no_members', 'No team members found. Members need to be assigned to your team.')}
        </Alert>
      ) : (
        <>
          {/* Filter controls */}
          <Paper sx={{ p: 2, mb: 2 }}>
            <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
              <TextField
                select
                label={t('filter.team_member', 'Team Member')}
                value={selectedMember}
                onChange={(e) => setSelectedMember(e.target.value)}
                size="small"
                sx={{ minWidth: 200 }}
              >
                <MenuItem value="all">{t('filter.all_members', 'All Members')}</MenuItem>
                {members.map((m) => (
                  <MenuItem key={m.id} value={m.id}>
                    {ownerNames[m.id]}
                  </MenuItem>
                ))}
              </TextField>
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
                sx={{ minWidth: 150 }}
              >
                {EVENT_TYPES.map(({ key, label }) => (
                  <MenuItem key={key} value={key}>{label}</MenuItem>
                ))}
              </TextField>
            </Box>
          </Paper>

          {/* Combined timeline with owner names and context */}
          {activityFilters && (
            <CombinedTimeline
              activityFilters={activityFilters}
              auditFilters={auditFilters}
              eventType={eventType}
              showContext
              showOwner
              ownerNames={ownerNames}
              title={t('team_timeline.activities', 'Team Activities')}
              emptyMessage={t('team_timeline.no_entries', 'No timeline entries found for the selected filters.')}
            />
          )}
        </>
      )}
    </Box>
  );
}
