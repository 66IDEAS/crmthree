import { useState } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Paper from '@mui/material/Paper';
import Tabs from '@mui/material/Tabs';
import Tab from '@mui/material/Tab';
import ToggleButton from '@mui/material/ToggleButton';
import ToggleButtonGroup from '@mui/material/ToggleButtonGroup';
import Avatar from '@mui/material/Avatar';
import Chip from '@mui/material/Chip';
import Skeleton from '@mui/material/Skeleton';
import EmojiEventsIcon from '@mui/icons-material/EmojiEvents';
import PersonIcon from '@mui/icons-material/Person';
import { useNavigate } from 'react-router';
import { useAuth } from '../contexts/AuthContext';
import useLeaderboardData from '../hooks/useLeaderboardData';
import { t } from '../services/TranslationService';

const DIMENSIONS = [
  { key: 'xp_total', label: 'XP Total' },
  { key: 'deals_closed', label: 'Deals Closed' },
  { key: 'activities_logged', label: 'Activities' },
  { key: 'tickets_resolved', label: 'Tickets Resolved' },
];

const PERIODS = [
  { key: 'all', label: 'All Time' },
  { key: 'quarter', label: 'Quarter' },
  { key: 'month', label: 'Month' },
  { key: 'week', label: 'Week' },
];

const MEDAL_COLORS = ['#FFD700', '#C0C0C0', '#CD7F32'];

export default function LeaderboardPage() {
  const { userProfile } = useAuth();
  const navigate = useNavigate();
  const [dimensionIdx, setDimensionIdx] = useState(0);
  const [period, setPeriod] = useState('all');
  const dimension = DIMENSIONS[dimensionIdx].key;
  const { rankings, loading } = useLeaderboardData(dimension, period);

  return (
    <Box>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
        <EmojiEventsIcon sx={{ color: '#F7941D', fontSize: 28 }} />
        <Typography variant="h5" sx={{ fontWeight: 700 }}>
          {t('leaderboard.title', 'Leaderboard')}
        </Typography>
      </Box>

      <Paper sx={{ mb: 2 }}>
        <Tabs
          value={dimensionIdx}
          onChange={(_, v) => setDimensionIdx(v)}
          variant="scrollable"
          scrollButtons="auto"
        >
          {DIMENSIONS.map((d) => (
            <Tab key={d.key} label={t(`leaderboard.${d.key}`, d.label)} />
          ))}
        </Tabs>
      </Paper>

      <Box sx={{ display: 'flex', justifyContent: 'flex-end', mb: 2 }}>
        <ToggleButtonGroup
          value={period}
          exclusive
          onChange={(_, v) => v && setPeriod(v)}
          size="small"
        >
          {PERIODS.map((p) => (
            <ToggleButton key={p.key} value={p.key}>
              {t(`leaderboard.${p.key}`, p.label)}
            </ToggleButton>
          ))}
        </ToggleButtonGroup>
      </Box>

      <Paper sx={{ p: 0, overflow: 'hidden' }}>
        {loading ? (
          <Box sx={{ p: 2 }}>
            {[1, 2, 3, 4, 5].map((i) => (
              <Skeleton key={i} height={56} sx={{ mb: 0.5 }} />
            ))}
          </Box>
        ) : rankings.length === 0 ? (
          <Box sx={{ p: 3, textAlign: 'center' }}>
            <Typography variant="body2" color="text.secondary">
              {t('leaderboard.no_data', 'No data available yet.')}
            </Typography>
          </Box>
        ) : (
          rankings.map((entry, idx) => {
            const isCurrentUser = entry.userId === userProfile?.id;
            const isTop3 = idx < 3;
            return (
              <Box
                key={entry.userId}
                onClick={() => navigate(isCurrentUser ? '/profile' : `/profile/${entry.userId}`)}
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 2,
                  px: 2,
                  py: 1.5,
                  borderBottom: '1px solid',
                  borderColor: 'divider',
                  bgcolor: isCurrentUser ? 'action.selected' : 'transparent',
                  cursor: 'pointer',
                  '&:hover': { bgcolor: 'action.hover' },
                  '&:last-child': { borderBottom: 'none' },
                }}
              >
                {/* Rank */}
                <Box sx={{ width: 36, textAlign: 'center', flexShrink: 0 }}>
                  {isTop3 ? (
                    <EmojiEventsIcon sx={{ color: MEDAL_COLORS[idx], fontSize: 24 }} />
                  ) : (
                    <Typography variant="body2" sx={{ fontWeight: 600, color: 'text.secondary' }}>
                      {idx + 1}
                    </Typography>
                  )}
                </Box>

                {/* Avatar */}
                <Avatar
                  src={entry.avatarUrl || undefined}
                  sx={{
                    width: 36,
                    height: 36,
                    bgcolor: isTop3 ? MEDAL_COLORS[idx] : 'primary.main',
                    fontSize: '0.85rem',
                  }}
                >
                  {entry.name?.charAt(0) || <PersonIcon fontSize="small" />}
                </Avatar>

                {/* Name + level */}
                <Box sx={{ flex: 1, minWidth: 0 }}>
                  <Typography
                    variant="body2"
                    sx={{ fontWeight: isCurrentUser ? 700 : 500 }}
                    noWrap
                  >
                    {entry.name}
                    {isCurrentUser && (
                      <Typography component="span" variant="caption" color="primary" sx={{ ml: 1 }}>
                        ({t('leaderboard.you', 'You')})
                      </Typography>
                    )}
                  </Typography>
                  <Chip
                    label={entry.levelName}
                    size="small"
                    sx={{ fontSize: '0.65rem', height: 18 }}
                  />
                </Box>

                {/* Value */}
                <Typography
                  variant="h6"
                  sx={{
                    fontWeight: 700,
                    color: isTop3 ? MEDAL_COLORS[idx] : 'text.primary',
                    minWidth: 60,
                    textAlign: 'right',
                  }}
                >
                  {entry.value.toLocaleString()}
                </Typography>
              </Box>
            );
          })
        )}
      </Paper>
    </Box>
  );
}
