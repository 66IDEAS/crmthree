import { useState, useEffect } from 'react';
import Accordion from '@mui/material/Accordion';
import AccordionSummary from '@mui/material/AccordionSummary';
import AccordionDetails from '@mui/material/AccordionDetails';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import TextField from '@mui/material/TextField';
import IconButton from '@mui/material/IconButton';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import Alert from '@mui/material/Alert';
import CircularProgress from '@mui/material/CircularProgress';
import Chip from '@mui/material/Chip';
import Divider from '@mui/material/Divider';
import EditIcon from '@mui/icons-material/Edit';
import SaveIcon from '@mui/icons-material/Save';
import CancelIcon from '@mui/icons-material/Cancel';
import DataService from '../../services/DataService';
import {
  DEFAULT_LEVELS,
  DEFAULT_XP_EVENTS,
  DEFAULT_BADGES,
  clearCaches,
} from '../../services/GamificationService';
import { t } from '../../services/TranslationService';

export default function GamificationSettingsSection() {
  const [xpEvents, setXpEvents] = useState([]);
  const [levels, setLevels] = useState([]);
  const [badges, setBadges] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  const [editId, setEditId] = useState(null);
  const [editValues, setEditValues] = useState({});

  useEffect(() => {
    loadAll();
  }, []);

  const loadAll = async () => {
    setLoading(true);
    try {
      const [xp, lvl, bdg] = await Promise.all([
        DataService.list('XPEvent', { pageSize: 200 }),
        DataService.list('LevelDefinition', { pageSize: 100 }),
        DataService.list('Badge', { pageSize: 200 }),
      ]);
      setXpEvents(xp.sort((a, b) => (a.event_type || '').localeCompare(b.event_type || '')));
      setLevels(lvl.sort((a, b) => a.xp_threshold - b.xp_threshold));
      setBadges(bdg.sort((a, b) => (a.name || '').localeCompare(b.name || '')));
    } catch (err) {
      setError(err.message || 'Failed to load gamification config');
    } finally {
      setLoading(false);
    }
  };

  const handleSeedDefaults = async () => {
    setSaving(true);
    setError(null);
    try {
      // Seed levels if none exist
      if (levels.length === 0) {
        for (const lvl of DEFAULT_LEVELS) {
          await DataService.create('LevelDefinition', lvl);
        }
      }
      // Seed XP events if none exist
      if (xpEvents.length === 0) {
        for (const evt of DEFAULT_XP_EVENTS) {
          await DataService.create('XPEvent', evt);
        }
      }
      // Seed badges if none exist
      if (badges.length === 0) {
        for (const badge of DEFAULT_BADGES) {
          await DataService.create('Badge', badge);
        }
      }
      clearCaches();
      setSuccess(t('settings.gamification.seeded', 'Default gamification config initialized successfully.'));
      await loadAll();
    } catch (err) {
      setError(err.message || 'Failed to seed defaults');
    } finally {
      setSaving(false);
    }
  };

  const handleEditXP = (evt) => {
    setEditId(evt.id);
    setEditValues({ xp_value: evt.xp_value });
  };

  const handleSaveXP = async () => {
    setSaving(true);
    setError(null);
    try {
      await DataService.update('XPEvent', editId, {
        xp_value: Number(editValues.xp_value) || 0,
      });
      clearCaches();
      setEditId(null);
      await loadAll();
    } catch (err) {
      setError(err.message || 'Failed to update');
    } finally {
      setSaving(false);
    }
  };

  const needsSeed = levels.length === 0 || xpEvents.length === 0 || badges.length === 0;

  return (
    <Accordion defaultExpanded={false} sx={{ mt: 1 }}>
      <AccordionSummary expandIcon={<ExpandMoreIcon />}>
        <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
          {t('settings.gamification.title', 'Gamification')}
        </Typography>
      </AccordionSummary>
      <AccordionDetails>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
          {t('settings.gamification.description', 'Configure XP events, level definitions, and badges for the gamification engine.')}
        </Typography>

        {error && (
          <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>{error}</Alert>
        )}
        {success && (
          <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccess(null)}>{success}</Alert>
        )}

        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 2 }}>
            <CircularProgress size={24} />
          </Box>
        ) : (
          <>
            {needsSeed && (
              <Box sx={{ mb: 2 }}>
                <Button
                  variant="contained"
                  size="small"
                  onClick={handleSeedDefaults}
                  disabled={saving}
                >
                  {t('settings.gamification.seed', 'Initialize Defaults')}
                </Button>
              </Box>
            )}

            {/* XP Events */}
            <Typography variant="subtitle2" sx={{ fontWeight: 600, mt: 1, mb: 1 }}>
              {t('settings.gamification.xp_events', 'XP Events')}
            </Typography>
            {xpEvents.length > 0 && (
              <TableContainer sx={{ mb: 2 }}>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 600 }}>{t('settings.gamification.event', 'Event')}</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>{t('settings.gamification.desc', 'Description')}</TableCell>
                      <TableCell sx={{ fontWeight: 600 }} align="right">{t('settings.gamification.xp', 'XP')}</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>{t('settings.gamification.actions', 'Actions')}</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {xpEvents.map((evt) => (
                      <TableRow key={evt.id}>
                        <TableCell>
                          <Chip label={evt.event_type} size="small" variant="outlined" />
                        </TableCell>
                        <TableCell>{evt.description}</TableCell>
                        <TableCell align="right">
                          {editId === evt.id ? (
                            <TextField
                              size="small"
                              type="number"
                              value={editValues.xp_value}
                              onChange={(e) => setEditValues({ xp_value: e.target.value })}
                              sx={{ width: 80 }}
                            />
                          ) : (
                            <Typography variant="body2" sx={{ fontWeight: 600 }}>{evt.xp_value}</Typography>
                          )}
                        </TableCell>
                        <TableCell>
                          {editId === evt.id ? (
                            <Box sx={{ display: 'flex', gap: 0.5 }}>
                              <IconButton size="small" onClick={handleSaveXP} disabled={saving} color="primary">
                                <SaveIcon fontSize="small" />
                              </IconButton>
                              <IconButton size="small" onClick={() => setEditId(null)}>
                                <CancelIcon fontSize="small" />
                              </IconButton>
                            </Box>
                          ) : (
                            <IconButton size="small" onClick={() => handleEditXP(evt)}>
                              <EditIcon fontSize="small" />
                            </IconButton>
                          )}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            )}

            <Divider sx={{ my: 2 }} />

            {/* Level Definitions */}
            <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1 }}>
              {t('settings.gamification.levels', 'Level Definitions')}
            </Typography>
            {levels.length > 0 && (
              <TableContainer sx={{ mb: 2 }}>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 600 }}>{t('settings.gamification.level', 'Level')}</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>{t('settings.gamification.level_name', 'Name')}</TableCell>
                      <TableCell sx={{ fontWeight: 600 }} align="right">{t('settings.gamification.xp_threshold', 'XP Threshold')}</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {levels.map((lvl) => (
                      <TableRow key={lvl.id}>
                        <TableCell>{lvl.level}</TableCell>
                        <TableCell>
                          <Chip label={lvl.name} size="small" color="primary" />
                        </TableCell>
                        <TableCell align="right">{lvl.xp_threshold.toLocaleString()}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            )}

            <Divider sx={{ my: 2 }} />

            {/* Badges */}
            <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1 }}>
              {t('settings.gamification.badges', 'Badges')}
            </Typography>
            {badges.length > 0 && (
              <TableContainer>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 600 }}>{t('settings.gamification.badge_name', 'Name')}</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>{t('settings.gamification.badge_desc', 'Description')}</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>{t('settings.gamification.category', 'Category')}</TableCell>
                      <TableCell sx={{ fontWeight: 600 }}>{t('settings.gamification.criteria', 'Criteria')}</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {badges.map((badge) => (
                      <TableRow key={badge.id}>
                        <TableCell sx={{ fontWeight: 600 }}>{badge.name}</TableCell>
                        <TableCell>{badge.description}</TableCell>
                        <TableCell>
                          <Chip label={badge.category} size="small" variant="outlined" />
                        </TableCell>
                        <TableCell>
                          {badge.criteria && (
                            <Typography variant="caption" color="text.secondary">
                              {badge.criteria.metric} {badge.criteria.comparison} {badge.criteria.threshold}
                            </Typography>
                          )}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            )}
          </>
        )}
      </AccordionDetails>
    </Accordion>
  );
}
