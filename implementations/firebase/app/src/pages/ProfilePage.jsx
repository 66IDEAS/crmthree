import { useState, useEffect, useMemo } from 'react';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Paper from '@mui/material/Paper';
import TextField from '@mui/material/TextField';
import MenuItem from '@mui/material/MenuItem';
import Grid from '@mui/material/Grid';
import Chip from '@mui/material/Chip';
import Avatar from '@mui/material/Avatar';
import Button from '@mui/material/Button';
import LinearProgress from '@mui/material/LinearProgress';
import CircularProgress from '@mui/material/CircularProgress';
import WhatshotIcon from '@mui/icons-material/Whatshot';
import EmojiEventsIcon from '@mui/icons-material/EmojiEvents';
import StarIcon from '@mui/icons-material/Star';
import LockIcon from '@mui/icons-material/Lock';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import AutoAwesomeIcon from '@mui/icons-material/AutoAwesome';
import GroupsIcon from '@mui/icons-material/Groups';
import { useNavigate } from 'react-router';
import { useThemeMode } from '../theme/ThemeProvider';
import { useTranslation } from '../contexts/TranslationContext';
import { useGamification } from '../contexts/GamificationContext';
import { listTranslationDocs } from '../services/TranslationStore';
import DataService from '../services/DataService';
import AIService from '../services/AIService';
import ChallengeService from '../services/ChallengeService';
import { useAuth } from '../contexts/AuthContext';
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

export default function ProfilePage() {
  const { preference, setPreference } = useThemeMode();
  const { language, setLanguage } = useTranslation();
  const { xpTotal, level, levelName, currentStreak, longestStreak, earnedBadges, allBadges, activeChallenge, nextLevelXP } = useGamification();
  const { userProfile, role, user } = useAuth();
  const navigate = useNavigate();
  const [availableLanguages, setAvailableLanguages] = useState([]);
  const [personalBests, setPersonalBests] = useState([]);
  const [aiConfigured, setAiConfigured] = useState(false);
  const [generatingChallenge, setGeneratingChallenge] = useState(false);
  const [localChallenge, setLocalChallenge] = useState(null);
  const [challengeError, setChallengeError] = useState(null);
  const [isTeamManager, setIsTeamManager] = useState(false);

  useEffect(() => {
    listTranslationDocs().then((docs) => {
      setAvailableLanguages(docs.map((d) => ({ code: d.language_code, name: d.language_name })));
    }).catch(() => {});
  }, []);

  // Load personal bests
  useEffect(() => {
    DataService.list('PersonalBest', { pageSize: 50 })
      .then(setPersonalBests)
      .catch(() => {});
  }, []);

  // Check if AI is configured for challenge generation
  useEffect(() => {
    AIService.isConfigured().then(setAiConfigured).catch(() => {});
  }, []);

  // Check if user is a team manager
  useEffect(() => {
    if (!userProfile?.id) return;
    DataService.list('Team', {
      filters: [{ field: 'manager_id', op: '==', value: userProfile.id }],
      pageSize: 1,
    }).then((teams) => setIsTeamManager(teams.length > 0)).catch(() => {});
  }, [userProfile?.id]);

  const currentChallenge = localChallenge || activeChallenge;

  const handleGenerateChallenge = async () => {
    setGeneratingChallenge(true);
    setChallengeError(null);
    try {
      const challenge = await ChallengeService.generateMonthlyChallenge(userProfile?.id);
      if (challenge) {
        setLocalChallenge(challenge);
      } else {
        setChallengeError(t('profile.challenge_failed', 'Could not generate a challenge. Please ensure an AI provider is configured.'));
      }
    } catch {
      setChallengeError(t('profile.challenge_failed', 'Could not generate a challenge. Please ensure an AI provider is configured.'));
    } finally {
      setGeneratingChallenge(false);
    }
  };

  // Map earned badges by badge_id for quick lookup
  const earnedMap = useMemo(() => {
    const map = {};
    for (const ub of earnedBadges) {
      map[ub.badge_id] = ub;
    }
    return map;
  }, [earnedBadges]);

  // XP progress to next level
  const xpProgress = useMemo(() => {
    if (!nextLevelXP) return 100;
    // Find current level threshold
    const currentThreshold = 0; // simplified — find from levels
    return Math.min(100, Math.round((xpTotal / nextLevelXP) * 100));
  }, [xpTotal, nextLevelXP]);

  return (
    <Box>
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
        <Typography variant="h5" sx={{ fontWeight: 700 }}>
          {t('profile.title', 'Profile')}
        </Typography>
        {isTeamManager && (
          <Button
            variant="outlined"
            size="small"
            startIcon={<GroupsIcon />}
            onClick={() => navigate('/team-timeline')}
          >
            {t('profile.team_timeline', 'Team Timeline')}
          </Button>
        )}
      </Box>

      {/* User Info */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2 }}>
          {t('profile.user_info', 'User Information')}
        </Typography>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
          <Box sx={{ display: 'flex', gap: 1 }}>
            <Typography variant="body2" color="text.secondary" sx={{ minWidth: 80 }}>
              {t('profile.user_id', 'User ID')}:
            </Typography>
            <Typography variant="body2" sx={{ fontFamily: 'monospace', fontSize: '0.8rem' }}>
              {userProfile?.id || user?.uid || '—'}
            </Typography>
          </Box>
          <Box sx={{ display: 'flex', gap: 1 }}>
            <Typography variant="body2" color="text.secondary" sx={{ minWidth: 80 }}>
              {t('profile.email', 'Email')}:
            </Typography>
            <Typography variant="body2">
              {user?.email || userProfile?.email || '—'}
            </Typography>
          </Box>
          <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
            <Typography variant="body2" color="text.secondary" sx={{ minWidth: 80 }}>
              {t('profile.role', 'Role')}:
            </Typography>
            <Chip label={role?.name || t('profile.no_role', 'No role assigned')} size="small" color="primary" variant="outlined" />
          </Box>
        </Box>
      </Paper>

      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2 }}>
          {t('profile.preferences', 'Preferences')}
        </Typography>
        <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
          <TextField
            select
            label={t('profile.language', 'Language')}
            value={language}
            onChange={(e) => setLanguage(e.target.value)}
            size="small"
            sx={{ minWidth: 200, flex: { xs: '1 1 100%', sm: '0 0 auto' } }}
          >
            <MenuItem value="en">English</MenuItem>
            {availableLanguages.map((lang) => (
              <MenuItem key={lang.code} value={lang.code}>{lang.name}</MenuItem>
            ))}
          </TextField>
          <TextField
            select
            label={t('settings.theme', 'Theme')}
            value={preference}
            onChange={(e) => setPreference(e.target.value)}
            size="small"
            sx={{ minWidth: 200, flex: { xs: '1 1 100%', sm: '0 0 auto' } }}
          >
            <MenuItem value="light">{t('settings.light', 'Light')}</MenuItem>
            <MenuItem value="dark">{t('settings.dark', 'Dark')}</MenuItem>
            <MenuItem value="system">{t('settings.system', 'System')}</MenuItem>
          </TextField>
        </Box>
      </Paper>

      {/* Gamification Stats */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2 }}>
          {t('profile.gamification', 'Gamification')}
        </Typography>
        <Grid container spacing={2}>
          {/* Level + XP Progress */}
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <Box sx={{ textAlign: 'center' }}>
              <Avatar sx={{ width: 48, height: 48, bgcolor: 'primary.main', mx: 'auto', mb: 1 }}>
                <StarIcon />
              </Avatar>
              <Typography variant="h6" sx={{ fontWeight: 700 }}>{levelName}</Typography>
              <Typography variant="caption" color="text.secondary">
                {t('profile.level', 'Level')} {level}
              </Typography>
              <Box sx={{ mt: 1 }}>
                <LinearProgress
                  variant="determinate"
                  value={xpProgress}
                  sx={{ height: 8, borderRadius: 4 }}
                />
                <Typography variant="caption" color="text.secondary">
                  {xpTotal.toLocaleString()} / {nextLevelXP ? nextLevelXP.toLocaleString() : '---'} XP
                </Typography>
              </Box>
            </Box>
          </Grid>

          {/* XP Total */}
          <Grid size={{ xs: 6, sm: 3, md: 3 }}>
            <Box sx={{ textAlign: 'center' }}>
              <Avatar sx={{ width: 48, height: 48, bgcolor: '#F7941D', mx: 'auto', mb: 1 }}>
                <TrendingUpIcon />
              </Avatar>
              <Typography variant="h6" sx={{ fontWeight: 700 }}>{xpTotal.toLocaleString()}</Typography>
              <Typography variant="caption" color="text.secondary">{t('profile.total_xp', 'Total XP')}</Typography>
            </Box>
          </Grid>

          {/* Current Streak */}
          <Grid size={{ xs: 6, sm: 3, md: 3 }}>
            <Box sx={{ textAlign: 'center' }}>
              <Avatar sx={{ width: 48, height: 48, bgcolor: currentStreak > 0 ? 'error.main' : 'action.disabled', mx: 'auto', mb: 1 }}>
                <WhatshotIcon />
              </Avatar>
              <Typography variant="h6" sx={{ fontWeight: 700 }}>{currentStreak}</Typography>
              <Typography variant="caption" color="text.secondary">{t('profile.current_streak', 'Day Streak')}</Typography>
            </Box>
          </Grid>

          {/* Longest Streak */}
          <Grid size={{ xs: 6, sm: 3, md: 3 }}>
            <Box sx={{ textAlign: 'center' }}>
              <Avatar sx={{ width: 48, height: 48, bgcolor: 'success.main', mx: 'auto', mb: 1 }}>
                <EmojiEventsIcon />
              </Avatar>
              <Typography variant="h6" sx={{ fontWeight: 700 }}>{longestStreak}</Typography>
              <Typography variant="caption" color="text.secondary">{t('profile.longest_streak', 'Best Streak')}</Typography>
            </Box>
          </Grid>
        </Grid>
      </Paper>

      {/* Monthly Challenge */}
      {(currentChallenge || aiConfigured) && (
        <Paper sx={{ p: 3, mb: 3 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
            <AutoAwesomeIcon sx={{ color: '#F7941D' }} />
            <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
              {t('profile.monthly_challenge', 'Monthly Challenge')}
            </Typography>
          </Box>

          {currentChallenge ? (
            <Box>
              <Typography variant="body1" sx={{ fontWeight: 600 }}>
                {currentChallenge.title}
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5 }}>
                {currentChallenge.description}
              </Typography>
              <Box sx={{ mb: 1 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                  <Typography variant="caption" color="text.secondary">
                    {t('profile.progress', 'Progress')}
                  </Typography>
                  <Typography variant="caption" sx={{ fontWeight: 600 }}>
                    {currentChallenge.current_value || 0} / {currentChallenge.target_value}
                  </Typography>
                </Box>
                <LinearProgress
                  variant="determinate"
                  value={Math.min(100, Math.round(((currentChallenge.current_value || 0) / currentChallenge.target_value) * 100))}
                  sx={{ height: 10, borderRadius: 5 }}
                  color={currentChallenge.status === 'Completed' ? 'success' : 'primary'}
                />
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Chip
                  label={currentChallenge.status === 'Completed'
                    ? t('profile.completed', 'Completed')
                    : t('profile.active', 'Active')}
                  size="small"
                  color={currentChallenge.status === 'Completed' ? 'success' : 'primary'}
                />
                <Chip
                  label={`+${currentChallenge.xp_reward} XP`}
                  size="small"
                  variant="outlined"
                  sx={{ fontSize: '0.7rem' }}
                />
              </Box>
            </Box>
          ) : (
            <Box sx={{ textAlign: 'center', py: 2 }}>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                {t('profile.no_challenge', 'No challenge for this month yet.')}
              </Typography>
              <Button
                variant="outlined"
                startIcon={generatingChallenge ? <CircularProgress size={16} /> : <AutoAwesomeIcon />}
                onClick={handleGenerateChallenge}
                disabled={generatingChallenge}
              >
                {generatingChallenge
                  ? t('profile.generating', 'Generating...')
                  : t('profile.generate_challenge', 'Generate Challenge')}
              </Button>
              {challengeError && (
                <Typography variant="caption" color="error" sx={{ mt: 1 }}>
                  {challengeError}
                </Typography>
              )}
            </Box>
          )}
        </Paper>
      )}

      {/* Trophy Case */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
          <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
            {t('profile.trophy_case', 'Trophy Case')}
          </Typography>
          <Chip
            label={`${earnedBadges.length} / ${allBadges.length}`}
            size="small"
            variant="outlined"
          />
        </Box>

        {allBadges.length === 0 ? (
          <Typography variant="body2" color="text.secondary" sx={{ fontStyle: 'italic' }}>
            {t('profile.no_badges_configured', 'No badges configured yet. An admin can initialize defaults in Settings > Gamification.')}
          </Typography>
        ) : (
          <Grid container spacing={2}>
            {allBadges.map((badge) => {
              const earned = earnedMap[badge.id];
              return (
                <Grid key={badge.id} size={{ xs: 6, sm: 4, md: 3 }}>
                  <Paper
                    variant="outlined"
                    sx={{
                      p: 2,
                      textAlign: 'center',
                      opacity: earned ? 1 : 0.4,
                      position: 'relative',
                    }}
                  >
                    {!earned && (
                      <LockIcon
                        sx={{
                          position: 'absolute',
                          top: 8,
                          right: 8,
                          fontSize: 16,
                          color: 'text.disabled',
                        }}
                      />
                    )}
                    <Avatar
                      sx={{
                        width: 40,
                        height: 40,
                        mx: 'auto',
                        mb: 1,
                        bgcolor: earned ? 'primary.main' : 'action.disabled',
                      }}
                    >
                      <EmojiEventsIcon fontSize="small" />
                    </Avatar>
                    <Typography variant="body2" sx={{ fontWeight: 600 }} noWrap>
                      {badge.name}
                    </Typography>
                    <Chip
                      label={badge.category}
                      size="small"
                      color={CATEGORY_COLORS[badge.category] || 'default'}
                      sx={{ mt: 0.5, fontSize: '0.65rem', height: 20 }}
                    />
                    <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 0.5 }}>
                      {badge.description}
                    </Typography>
                    {earned && (
                      <Typography variant="caption" color="success.main" sx={{ display: 'block', mt: 0.5 }}>
                        {new Date(earned.earned_at).toLocaleDateString()}
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
                  {pb.previous_value !== null && pb.previous_value !== undefined && (
                    <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                      {t('profile.previous', 'Previous')}: {Number(pb.previous_value).toLocaleString()}
                    </Typography>
                  )}
                </Paper>
              </Grid>
            ))}
          </Grid>
        </Paper>
      )}

    </Box>
  );
}
