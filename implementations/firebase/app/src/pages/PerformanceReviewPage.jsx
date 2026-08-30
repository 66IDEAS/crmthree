import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Paper from '@mui/material/Paper';
import Grid from '@mui/material/Grid';
import Chip from '@mui/material/Chip';
import Avatar from '@mui/material/Avatar';
import Button from '@mui/material/Button';
import LinearProgress from '@mui/material/LinearProgress';
import Breadcrumbs from '@mui/material/Breadcrumbs';
import Link from '@mui/material/Link';
import Skeleton from '@mui/material/Skeleton';
import StarIcon from '@mui/icons-material/Star';
import EmojiEventsIcon from '@mui/icons-material/EmojiEvents';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import WhatshotIcon from '@mui/icons-material/Whatshot';
import DownloadIcon from '@mui/icons-material/Download';
import { Link as RouterLink, useParams } from 'react-router';
import usePerformancePortfolio, { exportPortfolioCSV } from '../hooks/usePerformancePortfolio';
import { t } from '../services/TranslationService';

const CATEGORY_COLORS = {
  Sales: 'success',
  Service: 'info',
  'Data Quality': 'warning',
  Collaboration: 'primary',
  Milestone: 'secondary',
  Challenge: 'error',
  Special: 'default',
};

export default function PerformanceReviewPage() {
  const { userId } = useParams();
  const { data, loading } = usePerformancePortfolio(userId);

  if (loading) {
    return (
      <Box>
        <Skeleton width={200} height={32} sx={{ mb: 2 }} />
        {[1, 2, 3].map((i) => (
          <Skeleton key={i} height={120} sx={{ mb: 2, borderRadius: 1 }} />
        ))}
      </Box>
    );
  }

  if (!data?.profile) {
    return (
      <Box sx={{ p: 2 }}>
        <Typography color="text.secondary">
          {t('profile.user_not_found', 'User not found.')}
        </Typography>
      </Box>
    );
  }

  const { profile, earnedBadges, allBadges, personalBests, challenges } = data;
  const displayName = [profile.first_name, profile.last_name].filter(Boolean).join(' ') || profile.email || 'User';
  const earnedBadgeIds = new Set(earnedBadges.map((ub) => ub.badge_id));

  return (
    <Box>
      <Breadcrumbs sx={{ mb: 2 }}>
        <Link component={RouterLink} to="/leaderboard" underline="hover" color="inherit">
          {t('leaderboard.title', 'Leaderboard')}
        </Link>
        <Typography color="text.primary">{t('profile.performance_review', 'Performance Review')}</Typography>
      </Breadcrumbs>

      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Avatar
            src={profile.avatar_url || undefined}
            sx={{ width: 56, height: 56, bgcolor: 'primary.main', fontSize: '1.2rem' }}
          >
            {profile.first_name?.[0]}{profile.last_name?.[0]}
          </Avatar>
          <Box>
            <Typography variant="h5" sx={{ fontWeight: 700 }}>
              {displayName}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {profile.email}
            </Typography>
          </Box>
        </Box>
        <Button
          variant="outlined"
          startIcon={<DownloadIcon />}
          onClick={() => exportPortfolioCSV(data)}
          size="small"
        >
          {t('profile.export_csv', 'Export CSV')}
        </Button>
      </Box>

      {/* Stats Overview */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2 }}>
          {t('profile.overview', 'Overview')}
        </Typography>
        <Grid container spacing={2}>
          <Grid size={{ xs: 6, sm: 3 }}>
            <Box sx={{ textAlign: 'center' }}>
              <Avatar sx={{ width: 44, height: 44, bgcolor: 'primary.main', mx: 'auto', mb: 1 }}>
                <StarIcon />
              </Avatar>
              <Typography variant="h6" sx={{ fontWeight: 700 }}>{profile.level_name || 'Rookie'}</Typography>
              <Typography variant="caption" color="text.secondary">
                {t('profile.level', 'Level')} {profile.level || 1}
              </Typography>
            </Box>
          </Grid>
          <Grid size={{ xs: 6, sm: 3 }}>
            <Box sx={{ textAlign: 'center' }}>
              <Avatar sx={{ width: 44, height: 44, bgcolor: '#F7941D', mx: 'auto', mb: 1 }}>
                <TrendingUpIcon />
              </Avatar>
              <Typography variant="h6" sx={{ fontWeight: 700 }}>{(profile.xp_total || 0).toLocaleString()}</Typography>
              <Typography variant="caption" color="text.secondary">{t('profile.total_xp', 'Total XP')}</Typography>
            </Box>
          </Grid>
          <Grid size={{ xs: 6, sm: 3 }}>
            <Box sx={{ textAlign: 'center' }}>
              <Avatar sx={{ width: 44, height: 44, bgcolor: (profile.current_streak_days || 0) > 0 ? 'error.main' : 'action.disabled', mx: 'auto', mb: 1 }}>
                <WhatshotIcon />
              </Avatar>
              <Typography variant="h6" sx={{ fontWeight: 700 }}>{profile.current_streak_days || 0}</Typography>
              <Typography variant="caption" color="text.secondary">{t('profile.current_streak', 'Day Streak')}</Typography>
            </Box>
          </Grid>
          <Grid size={{ xs: 6, sm: 3 }}>
            <Box sx={{ textAlign: 'center' }}>
              <Avatar sx={{ width: 44, height: 44, bgcolor: 'success.main', mx: 'auto', mb: 1 }}>
                <EmojiEventsIcon />
              </Avatar>
              <Typography variant="h6" sx={{ fontWeight: 700 }}>{profile.longest_streak_days || 0}</Typography>
              <Typography variant="caption" color="text.secondary">{t('profile.longest_streak', 'Best Streak')}</Typography>
            </Box>
          </Grid>
        </Grid>
      </Paper>

      {/* Badges */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
          <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
            {t('profile.badges_earned', 'Badges Earned')}
          </Typography>
          <Chip label={`${earnedBadges.length} / ${allBadges.length}`} size="small" variant="outlined" />
        </Box>
        {earnedBadges.length === 0 ? (
          <Typography variant="body2" color="text.secondary" sx={{ fontStyle: 'italic' }}>
            {t('profile.no_badges_earned', 'No badges earned yet.')}
          </Typography>
        ) : (
          <Grid container spacing={2}>
            {allBadges.map((badge) => {
              const earned = earnedBadgeIds.has(badge.id);
              const ub = earnedBadges.find((e) => e.badge_id === badge.id);
              return (
                <Grid key={badge.id} size={{ xs: 6, sm: 4, md: 3 }}>
                  <Paper variant="outlined" sx={{ p: 2, textAlign: 'center', opacity: earned ? 1 : 0.3 }}>
                    <Avatar sx={{ width: 36, height: 36, mx: 'auto', mb: 0.5, bgcolor: earned ? 'primary.main' : 'action.disabled' }}>
                      <EmojiEventsIcon fontSize="small" />
                    </Avatar>
                    <Typography variant="body2" sx={{ fontWeight: 600 }} noWrap>{badge.name}</Typography>
                    <Chip label={badge.category} size="small" color={CATEGORY_COLORS[badge.category] || 'default'} sx={{ mt: 0.5, fontSize: '0.6rem', height: 18 }} />
                    {ub && (
                      <Typography variant="caption" color="success.main" sx={{ display: 'block', mt: 0.5 }}>
                        {new Date(ub.earned_at).toLocaleDateString()}
                      </Typography>
                    )}
                  </Paper>
                </Grid>
              );
            })}
          </Grid>
        )}
      </Paper>

      {/* Personal Bests */}
      {personalBests.length > 0 && (
        <Paper sx={{ p: 3, mb: 3 }}>
          <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2 }}>
            {t('profile.personal_bests', 'Personal Bests')}
          </Typography>
          <Grid container spacing={2}>
            {personalBests.map((pb) => (
              <Grid key={pb.id} size={{ xs: 6, sm: 4, md: 3 }}>
                <Paper variant="outlined" sx={{ p: 2, textAlign: 'center' }}>
                  <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                    {(pb.metric || '').replace(/_/g, ' ')}
                  </Typography>
                  <Typography variant="h6" sx={{ fontWeight: 700 }}>
                    {Number(pb.value).toLocaleString()}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {new Date(pb.achieved_at).toLocaleDateString()}
                  </Typography>
                </Paper>
              </Grid>
            ))}
          </Grid>
        </Paper>
      )}

      {/* Challenge History */}
      {challenges.length > 0 && (
        <Paper sx={{ p: 3, mb: 3 }}>
          <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2 }}>
            {t('profile.challenge_history', 'Challenge History')}
          </Typography>
          {challenges.map((ch) => (
            <Paper key={ch.id} variant="outlined" sx={{ p: 2, mb: 1.5, '&:last-child': { mb: 0 } }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 1 }}>
                <Box>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>{ch.title}</Typography>
                  <Typography variant="caption" color="text.secondary">{ch.description}</Typography>
                </Box>
                <Chip
                  label={ch.status}
                  size="small"
                  color={ch.status === 'Completed' ? 'success' : ch.status === 'Active' ? 'primary' : 'default'}
                />
              </Box>
              <LinearProgress
                variant="determinate"
                value={Math.min(100, Math.round(((ch.current_value || 0) / (ch.target_value || 1)) * 100))}
                sx={{ height: 6, borderRadius: 3 }}
                color={ch.status === 'Completed' ? 'success' : 'primary'}
              />
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 0.5 }}>
                <Typography variant="caption" color="text.secondary">
                  {ch.current_value || 0} / {ch.target_value}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  {ch.month}/{ch.year}
                </Typography>
              </Box>
            </Paper>
          ))}
        </Paper>
      )}
    </Box>
  );
}
