import { useState, useEffect, useCallback } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Grid from '@mui/material/Grid';
import Skeleton from '@mui/material/Skeleton';
import Paper from '@mui/material/Paper';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import Popover from '@mui/material/Popover';
import FormGroup from '@mui/material/FormGroup';
import FormControlLabel from '@mui/material/FormControlLabel';
import Checkbox from '@mui/material/Checkbox';
import SettingsIcon from '@mui/icons-material/Settings';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import ConfirmationNumberIcon from '@mui/icons-material/ConfirmationNumber';
import PeopleIcon from '@mui/icons-material/People';
import EventNoteIcon from '@mui/icons-material/EventNote';
import AttachMoneyIcon from '@mui/icons-material/AttachMoney';
import BuildIcon from '@mui/icons-material/Build';
import { useNavigate } from 'react-router';
import { useAuth } from '../contexts/AuthContext';
import useDashboardData from '../hooks/useDashboardData';
import DashboardService from '../services/DashboardService';
import KpiCard from '../components/dashboard/KpiCard';
import OpportunityStageChart from '../components/dashboard/OpportunityStageChart';
import TicketPriorityChart from '../components/dashboard/TicketPriorityChart';
import ActivityTrendChart from '../components/dashboard/ActivityTrendChart';
import RevenueChart from '../components/dashboard/RevenueChart';
import AiSummaryPlaceholder from '../components/dashboard/AiSummaryPlaceholder';
import LeaderboardCard from '../components/dashboard/LeaderboardCard';
import useLeaderboardData from '../hooks/useLeaderboardData';
import { t } from '../services/TranslationService';

const ALL_WIDGETS = [
  { id: 'ai-summary', labelKey: 'dashboard.ai_priority_summary', labelFallback: 'AI Priority Summary', category: 'all' },
  { id: 'pipeline-value', labelKey: 'dashboard.pipeline_value', labelFallback: 'Pipeline Value', category: 'sales' },
  { id: 'open-opportunities', labelKey: 'dashboard.open_opportunities', labelFallback: 'Open Opportunities', category: 'sales' },
  { id: 'open-tickets', labelKey: 'dashboard.open_tickets', labelFallback: 'Open Tickets', category: 'service' },
  { id: 'open-leads', labelKey: 'dashboard.open_leads', labelFallback: 'Open Leads', category: 'sales' },
  { id: 'activities-week', labelKey: 'dashboard.activities_this_week', labelFallback: 'Activities This Week', category: 'all' },
  { id: 'opp-by-stage', labelKey: 'dashboard.opp_by_stage', labelFallback: 'Opportunities by Stage', category: 'sales' },
  { id: 'tickets-by-priority', labelKey: 'dashboard.tickets_by_priority', labelFallback: 'Tickets by Priority', category: 'service' },
  { id: 'activity-trend', labelKey: 'dashboard.activity_trend', labelFallback: 'Activity Trend', category: 'all' },
  { id: 'revenue-by-status', labelKey: 'dashboard.revenue_by_status', labelFallback: 'Revenue by Status', category: 'sales' },
  { id: 'inactive-assets', labelKey: 'dashboard.inactive_assets', labelFallback: 'Inactive Assets', category: 'service' },
  { id: 'leaderboard', labelKey: 'dashboard.leaderboard', labelFallback: 'Leaderboard', category: 'all' },
];

function getDefaultVisibility(roleName) {
  const rn = (roleName || '').toLowerCase();
  const isService = rn.includes('service') || rn.includes('support');
  const isSales = rn.includes('sales') || rn.includes('rep');
  const defaults = {};
  for (const w of ALL_WIDGETS) {
    if (w.category === 'all') {
      defaults[w.id] = true;
    } else if (w.category === 'sales') {
      defaults[w.id] = !isService;
    } else if (w.category === 'service') {
      defaults[w.id] = !isSales;
    }
  }
  return defaults;
}

function formatCurrency(value) {
  if (value >= 1000000) return `$${(value / 1000000).toFixed(1)}M`;
  if (value >= 1000) return `$${(value / 1000).toFixed(1)}K`;
  return `$${value.toLocaleString()}`;
}

export default function HomePage() {
  const { userProfile, role } = useAuth();
  const { data, loading } = useDashboardData();
  const { rankings: lbRankings, loading: lbLoading } = useLeaderboardData('xp_total', 'all');
  const navigate = useNavigate();
  const [visibility, setVisibility] = useState(null);
  const [configLoaded, setConfigLoaded] = useState(false);
  const [settingsAnchor, setSettingsAnchor] = useState(null);

  const goTo = useCallback((path) => () => navigate(path), [navigate]);

  const userId = userProfile?.id;
  const roleName = role?.name || '';
  const firstName = userProfile?.first_name || 'there';

  // Load user's widget visibility config
  useEffect(() => {
    if (!userId) return;
    let cancelled = false;
    DashboardService.loadConfig(userId).then((config) => {
      if (cancelled) return;
      if (config?.widgets) {
        setVisibility(config.widgets);
      } else {
        setVisibility(getDefaultVisibility(roleName));
      }
      setConfigLoaded(true);
    }).catch(() => {
      if (!cancelled) {
        setVisibility(getDefaultVisibility(roleName));
        setConfigLoaded(true);
      }
    });
    return () => { cancelled = true; };
  }, [userId, roleName]);

  const toggleWidget = useCallback((widgetId) => {
    setVisibility((prev) => {
      const next = { ...prev, [widgetId]: !prev[widgetId] };
      if (userId) {
        DashboardService.saveConfig(userId, next).catch(() => {});
      }
      return next;
    });
  }, [userId]);

  const isVisible = (id) => visibility?.[id] !== false;

  if (!configLoaded) {
    return (
      <Box>
        <Skeleton variant="text" width={300} height={40} sx={{ mb: 2 }} />
        <Skeleton variant="rectangular" height={80} sx={{ mb: 3, borderRadius: 1 }} />
        <Grid container spacing={2}>
          {[1, 2, 3, 4].map((i) => (
            <Grid key={i} size={{ xs: 12, sm: 6, md: 3 }}>
              <Skeleton variant="rectangular" height={120} sx={{ borderRadius: 1 }} />
            </Grid>
          ))}
        </Grid>
      </Box>
    );
  }

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
        <Typography variant="h5" sx={{ fontWeight: 700 }}>
          {t('dashboard.welcome_back', 'Welcome back')}, {firstName}
        </Typography>
        <Tooltip title={t('dashboard.configure_widgets', 'Configure widgets')}>
          <IconButton onClick={(e) => setSettingsAnchor(e.currentTarget)}>
            <SettingsIcon />
          </IconButton>
        </Tooltip>
      </Box>

      {/* Widget settings popover */}
      <Popover
        open={Boolean(settingsAnchor)}
        anchorEl={settingsAnchor}
        onClose={() => setSettingsAnchor(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
        transformOrigin={{ vertical: 'top', horizontal: 'right' }}
      >
        <Box sx={{ p: 2, minWidth: 240 }}>
          <Typography variant="subtitle2" sx={{ mb: 1 }}>{t('dashboard.show_hide_widgets', 'Show / Hide Widgets')}</Typography>
          <FormGroup>
            {ALL_WIDGETS.map((w) => (
              <FormControlLabel
                key={w.id}
                control={<Checkbox checked={isVisible(w.id)} onChange={() => toggleWidget(w.id)} size="small" />}
                label={<Typography variant="body2">{t(w.labelKey, w.labelFallback)}</Typography>}
              />
            ))}
          </FormGroup>
        </Box>
      </Popover>

      {/* AI Summary Placeholder */}
      {isVisible('ai-summary') && (
        <Box sx={{ mb: 3 }}>
          <AiSummaryPlaceholder dashboardData={data} userName={firstName} />
        </Box>
      )}

      {/* KPI Cards */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        {isVisible('pipeline-value') && (
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            {loading ? (
              <Skeleton variant="rectangular" height={120} sx={{ borderRadius: 1 }} />
            ) : (
              <KpiCard
                title={t('dashboard.pipeline_value', 'Pipeline Value')}
                value={formatCurrency(data?.opportunities?.pipelineValue || 0)}
                subtitle={`${data?.opportunities?.open || 0} ${t('dashboard.open_opportunities_subtitle', 'open opportunities')}`}
                icon={AttachMoneyIcon}
                color="success.main"
                onClick={goTo('/opportunities')}
              />
            )}
          </Grid>
        )}
        {isVisible('open-opportunities') && (
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            {loading ? (
              <Skeleton variant="rectangular" height={120} sx={{ borderRadius: 1 }} />
            ) : (
              <KpiCard
                title={t('dashboard.open_opportunities', 'Open Opportunities')}
                value={data?.opportunities?.open || 0}
                subtitle={`${data?.opportunities?.total || 0} ${t('dashboard.total', 'total')}`}
                icon={TrendingUpIcon}
                color="primary.main"
                onClick={goTo('/opportunities')}
              />
            )}
          </Grid>
        )}
        {isVisible('open-tickets') && (
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            {loading ? (
              <Skeleton variant="rectangular" height={120} sx={{ borderRadius: 1 }} />
            ) : (
              <KpiCard
                title={t('dashboard.open_tickets', 'Open Tickets')}
                value={data?.tickets?.open || 0}
                subtitle={`${data?.tickets?.total || 0} ${t('dashboard.total', 'total')}`}
                icon={ConfirmationNumberIcon}
                color="warning.main"
                onClick={goTo('/tickets')}
              />
            )}
          </Grid>
        )}
        {isVisible('open-leads') && (
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            {loading ? (
              <Skeleton variant="rectangular" height={120} sx={{ borderRadius: 1 }} />
            ) : (
              <KpiCard
                title={t('dashboard.open_leads', 'Open Leads')}
                value={data?.leads?.open || 0}
                subtitle={`${data?.leads?.conversionRate || 0}% ${t('dashboard.conversion_rate', 'conversion rate')}`}
                icon={PeopleIcon}
                color="info.main"
                onClick={goTo('/leads')}
              />
            )}
          </Grid>
        )}
        {isVisible('activities-week') && (
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            {loading ? (
              <Skeleton variant="rectangular" height={120} sx={{ borderRadius: 1 }} />
            ) : (
              <KpiCard
                title={t('dashboard.activities_this_week', 'Activities This Week')}
                value={data?.activities?.thisWeek || 0}
                subtitle={`${data?.activities?.total || 0} ${t('dashboard.total', 'total')}`}
                icon={EventNoteIcon}
                color="secondary.main"
                onClick={goTo('/activities')}
              />
            )}
          </Grid>
        )}
        {isVisible('inactive-assets') && (
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            {loading ? (
              <Skeleton variant="rectangular" height={120} sx={{ borderRadius: 1 }} />
            ) : (
              <KpiCard
                title={t('dashboard.inactive_assets', 'Inactive Assets')}
                value={data?.assets?.inactive || 0}
                subtitle={`${data?.assets?.total || 0} ${t('dashboard.total', 'total')}`}
                icon={BuildIcon}
                color="error.main"
                onClick={goTo('/assets')}
              />
            )}
          </Grid>
        )}
        {isVisible('leaderboard') && (
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <LeaderboardCard
              rankings={lbRankings.slice(0, 3)}
              loading={lbLoading}
              onClick={goTo('/leaderboard')}
            />
          </Grid>
        )}
      </Grid>

      {/* Charts */}
      <Grid container spacing={2}>
        {isVisible('opp-by-stage') && (
          <Grid size={{ xs: 12, md: 6 }}>
            {loading ? (
              <Paper sx={{ p: 2.5 }}><Skeleton variant="rectangular" height={280} /></Paper>
            ) : (
              <OpportunityStageChart data={data?.opportunities?.byStage || []} onClick={goTo('/opportunities')} />
            )}
          </Grid>
        )}
        {isVisible('tickets-by-priority') && (
          <Grid size={{ xs: 12, md: 6 }}>
            {loading ? (
              <Paper sx={{ p: 2.5 }}><Skeleton variant="rectangular" height={280} /></Paper>
            ) : (
              <TicketPriorityChart data={data?.tickets?.byPriority || []} onClick={goTo('/tickets')} />
            )}
          </Grid>
        )}
        {isVisible('activity-trend') && (
          <Grid size={{ xs: 12, md: 6 }}>
            {loading ? (
              <Paper sx={{ p: 2.5 }}><Skeleton variant="rectangular" height={280} /></Paper>
            ) : (
              <ActivityTrendChart data={data?.activities?.trend || []} onClick={goTo('/activities')} />
            )}
          </Grid>
        )}
        {isVisible('revenue-by-status') && (
          <Grid size={{ xs: 12, md: 6 }}>
            {loading ? (
              <Paper sx={{ p: 2.5 }}><Skeleton variant="rectangular" height={280} /></Paper>
            ) : (
              <RevenueChart data={data?.invoices?.revenueByStatus || []} onClick={goTo('/invoices')} />
            )}
          </Grid>
        )}
      </Grid>
    </Box>
  );
}
