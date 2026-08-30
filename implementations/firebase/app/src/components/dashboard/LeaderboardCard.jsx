import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Avatar from '@mui/material/Avatar';
import Skeleton from '@mui/material/Skeleton';
import EmojiEventsIcon from '@mui/icons-material/EmojiEvents';
import { t } from '../../services/TranslationService';

const MEDALS = [
  { emoji: '\u{1F947}', color: '#FFD700' },
  { emoji: '\u{1F948}', color: '#C0C0C0' },
  { emoji: '\u{1F949}', color: '#CD7F32' },
];

export default function LeaderboardCard({ rankings = [], loading, onClick }) {
  return (
    <Paper
      onClick={onClick}
      sx={{
        p: 2.5,
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        cursor: onClick ? 'pointer' : 'default',
        transition: 'box-shadow 0.2s',
        '&:hover': onClick ? { boxShadow: 4 } : {},
      }}
    >
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 1.5 }}>
        <Typography variant="body2" color="text.secondary">
          {t('dashboard.leaderboard', 'Leaderboard')}
        </Typography>
        <Box sx={{ p: 1, borderRadius: 2, bgcolor: '#F7941D15' }}>
          <EmojiEventsIcon sx={{ color: '#F7941D', fontSize: 28 }} />
        </Box>
      </Box>

      {loading ? (
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
          {[0, 1, 2].map((i) => (
            <Skeleton key={i} height={24} />
          ))}
        </Box>
      ) : rankings.length === 0 ? (
        <Typography variant="caption" color="text.secondary">
          {t('dashboard.no_data', 'No data')}
        </Typography>
      ) : (
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.75 }}>
          {rankings.map((entry, i) => (
            <Box
              key={entry.userId}
              sx={{ display: 'flex', alignItems: 'center', gap: 1 }}
            >
              <Typography sx={{ fontSize: '1rem', width: 20, textAlign: 'center', flexShrink: 0 }}>
                {MEDALS[i].emoji}
              </Typography>
              <Avatar
                src={entry.avatarUrl || undefined}
                sx={{
                  width: 24,
                  height: 24,
                  fontSize: '0.65rem',
                  bgcolor: MEDALS[i].color,
                  flexShrink: 0,
                }}
              >
                {(entry.name || '?')[0]}
              </Avatar>
              <Typography
                variant="body2"
                noWrap
                sx={{ flex: 1, minWidth: 0, fontWeight: 500 }}
              >
                {entry.name}
              </Typography>
              <Typography
                variant="caption"
                sx={{ fontWeight: 600, flexShrink: 0, color: 'text.secondary' }}
              >
                {(entry.value || 0).toLocaleString()}
              </Typography>
            </Box>
          ))}
        </Box>
      )}
    </Paper>
  );
}
