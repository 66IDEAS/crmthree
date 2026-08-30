import { useState, useEffect } from 'react';
import Accordion from '@mui/material/Accordion';
import AccordionSummary from '@mui/material/AccordionSummary';
import AccordionDetails from '@mui/material/AccordionDetails';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import Typography from '@mui/material/Typography';
import FormGroup from '@mui/material/FormGroup';
import FormControlLabel from '@mui/material/FormControlLabel';
import Switch from '@mui/material/Switch';
import Divider from '@mui/material/Divider';
import Alert from '@mui/material/Alert';
import { useAuth } from '../../contexts/AuthContext';
import DataService from '../../services/DataService';
import { t } from '../../services/TranslationService';

const NOTIFICATION_TYPES = [
  { key: 'TicketAssigned', labelKey: 'settings.notifications.ticket_assigned', fallback: 'Ticket Assigned' },
  { key: 'SLABreach', labelKey: 'settings.notifications.sla_breach', fallback: 'SLA Breach' },
  { key: 'DealStageChange', labelKey: 'settings.notifications.deal_stage_change', fallback: 'Deal Stage Change' },
  { key: 'MentionedInComment', labelKey: 'settings.notifications.mentioned_in_comment', fallback: 'Mentioned in Comment' },
  { key: 'LeadAssigned', labelKey: 'settings.notifications.lead_assigned', fallback: 'Lead Assigned' },
  { key: 'ChallengeAssigned', labelKey: 'settings.notifications.challenge_assigned', fallback: 'Challenge Assigned' },
  { key: 'BadgeEarned', labelKey: 'settings.notifications.badge_earned', fallback: 'Badge Earned' },
  { key: 'LevelUp', labelKey: 'settings.notifications.level_up', fallback: 'Level Up' },
  { key: 'PersonalBest', labelKey: 'settings.notifications.personal_best', fallback: 'Personal Best' },
  { key: 'System', labelKey: 'settings.notifications.system', fallback: 'System Notifications' },
];

/**
 * UX36: Notification Preferences section in Settings.
 * Visible to all users (not admin-only).
 * Saves preferences as JSON on the user's UserProfile.
 */
export default function NotificationPreferencesSection() {
  const { userProfile } = useAuth();
  const [prefs, setPrefs] = useState({});
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (userProfile?.notification_preferences) {
      setPrefs(userProfile.notification_preferences);
    }
  }, [userProfile]);

  const handleToggle = async (key) => {
    const current = prefs[key] !== false; // default to true
    const updated = { ...prefs, [key]: !current };
    setPrefs(updated);
    setError(null);
    setSaving(true);

    try {
      await DataService.update('UserProfile', userProfile.id, {
        notification_preferences: updated,
      });
    } catch (err) {
      setError(err.message || t('settings.notifications.save_failed', 'Failed to save preferences.'));
      // Revert
      setPrefs((prev) => ({ ...prev, [key]: current }));
    } finally {
      setSaving(false);
    }
  };

  const handleDesktopToggle = async () => {
    const current = prefs.desktop_enabled !== false;
    const newVal = !current;

    // Request permission if enabling
    if (newVal && 'Notification' in window && Notification.permission === 'default') {
      const result = await Notification.requestPermission();
      if (result !== 'granted') return;
    }

    const updated = { ...prefs, desktop_enabled: newVal };
    setPrefs(updated);
    setError(null);
    setSaving(true);

    try {
      await DataService.update('UserProfile', userProfile.id, {
        notification_preferences: updated,
      });
    } catch (err) {
      setError(err.message || t('settings.notifications.save_failed', 'Failed to save preferences.'));
      setPrefs((prev) => ({ ...prev, desktop_enabled: current }));
    } finally {
      setSaving(false);
    }
  };

  return (
    <Accordion defaultExpanded={false} sx={{ mt: 1 }}>
      <AccordionSummary expandIcon={<ExpandMoreIcon />}>
        <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
          {t('settings.notifications.title', 'Notification Preferences')}
        </Typography>
      </AccordionSummary>
      <AccordionDetails>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
        {t('settings.notifications.description', 'Choose which notifications you want to receive.')}
      </Typography>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      <FormGroup>
        {NOTIFICATION_TYPES.map(({ key, labelKey, fallback }) => (
          <FormControlLabel
            key={key}
            control={
              <Switch
                checked={prefs[key] !== false}
                onChange={() => handleToggle(key)}
                disabled={saving}
              />
            }
            label={t(labelKey, fallback)}
          />
        ))}
      </FormGroup>

      <Divider sx={{ my: 2 }} />

      <FormControlLabel
        control={
          <Switch
            checked={prefs.desktop_enabled !== false}
            onChange={handleDesktopToggle}
            disabled={saving}
          />
        }
        label={t('settings.notifications.desktop_enabled', 'Desktop Browser Notifications')}
      />
      <Typography variant="caption" display="block" color="text.secondary" sx={{ ml: 6 }}>
        {t('settings.notifications.desktop_helper', 'Show native browser notifications when new notifications arrive.')}
      </Typography>
    </AccordionDetails>
    </Accordion>
  );
}
