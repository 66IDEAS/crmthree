import { useEffect, useRef, useCallback } from 'react';
import Snackbar from '@mui/material/Snackbar';
import Alert from '@mui/material/Alert';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import StarIcon from '@mui/icons-material/Star';
import EmojiEventsIcon from '@mui/icons-material/EmojiEvents';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import confetti from 'canvas-confetti';
import { useGamification } from '../../contexts/GamificationContext';
import { t } from '../../services/TranslationService';

const CELEBRATION_CONFIG = {
  level_up: {
    icon: StarIcon,
    color: 'success',
    getTitle: (data) => t('gamification.level_up', 'Level Up!'),
    getMessage: (data) =>
      `${t('gamification.reached_level', 'You reached')} ${data.levelName || `Level ${data.level}`}!`,
    confetti: { particleCount: 150, spread: 100, origin: { y: 0.6 } },
  },
  badge_earned: {
    icon: EmojiEventsIcon,
    color: 'info',
    getTitle: (data) => t('gamification.badge_earned', 'Badge Earned!'),
    getMessage: (data) => data.badgeName || t('gamification.new_badge', 'You earned a new badge!'),
    confetti: { particleCount: 80, spread: 60, origin: { y: 0.7 } },
  },
  personal_best: {
    icon: TrendingUpIcon,
    color: 'warning',
    getTitle: (data) => t('gamification.personal_best', 'New Personal Best!'),
    getMessage: (data) =>
      data.metric
        ? `${(data.metric || '').replace(/_/g, ' ')}: ${Number(data.newValue).toLocaleString()}`
        : t('gamification.new_record', 'You set a new record!'),
    confetti: { particleCount: 60, spread: 45, origin: { y: 0.7 } },
  },
  deal_won: {
    icon: EmojiEventsIcon,
    color: 'success',
    getTitle: () => t('gamification.deal_won', 'Deal Won!'),
    getMessage: (data) => data.message || t('gamification.congratulations', 'Congratulations!'),
    confetti: { particleCount: 200, spread: 120, startVelocity: 35, origin: { y: 0.6 } },
  },
};

const AUTO_DISMISS_MS = 4000;

export default function CelebrationOverlay() {
  const { celebrations, dismissCelebration } = useGamification();
  const confettiTimeoutRef = useRef(null);

  // Fire confetti for the first celebration in queue
  const fireConfetti = useCallback((config) => {
    if (confettiTimeoutRef.current) clearTimeout(confettiTimeoutRef.current);
    try {
      confetti({
        ...config,
        colors: ['#F7941D', '#FFD700', '#26a69a', '#42a5f5', '#ab47bc', '#ef5350'],
        ticks: 200,
        zIndex: 9999,
      });
    } catch {
      // canvas-confetti may fail in some environments
    }
  }, []);

  const current = celebrations[0] || null;

  useEffect(() => {
    if (!current) return;

    const cfg = CELEBRATION_CONFIG[current.type];
    if (cfg?.confetti) {
      fireConfetti(cfg.confetti);
    }

    const timer = setTimeout(() => {
      dismissCelebration(current.id);
    }, AUTO_DISMISS_MS);

    return () => clearTimeout(timer);
  }, [current, fireConfetti, dismissCelebration]);

  if (!current) return null;

  const cfg = CELEBRATION_CONFIG[current.type] || CELEBRATION_CONFIG.level_up;
  const Icon = cfg.icon;

  return (
    <Snackbar
      open
      anchorOrigin={{ vertical: 'top', horizontal: 'center' }}
      onClose={() => dismissCelebration(current.id)}
    >
      <Alert
        severity={cfg.color}
        variant="filled"
        icon={<Icon />}
        onClose={() => dismissCelebration(current.id)}
        sx={{
          minWidth: 300,
          boxShadow: 6,
          '& .MuiAlert-icon': { fontSize: 28 },
        }}
      >
        <Box>
          <Typography variant="subtitle2" sx={{ fontWeight: 700 }}>
            {cfg.getTitle(current)}
          </Typography>
          <Typography variant="body2">
            {cfg.getMessage(current)}
          </Typography>
        </Box>
      </Alert>
    </Snackbar>
  );
}
