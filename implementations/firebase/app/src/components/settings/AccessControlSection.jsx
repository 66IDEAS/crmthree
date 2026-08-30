import { useState, useEffect } from 'react';
import Accordion from '@mui/material/Accordion';
import AccordionSummary from '@mui/material/AccordionSummary';
import AccordionDetails from '@mui/material/AccordionDetails';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import TextField from '@mui/material/TextField';
import MenuItem from '@mui/material/MenuItem';
import Button from '@mui/material/Button';
import IconButton from '@mui/material/IconButton';
import List from '@mui/material/List';
import ListItem from '@mui/material/ListItem';
import ListItemText from '@mui/material/ListItemText';
import Chip from '@mui/material/Chip';
import Alert from '@mui/material/Alert';
import CircularProgress from '@mui/material/CircularProgress';
import DeleteIcon from '@mui/icons-material/Delete';
import { useAuth } from '../../contexts/AuthContext';
import {
  fetchWhitelistEntries,
  addWhitelistEntry,
  removeWhitelistEntry,
} from '../../services/WhitelistService';
import { t } from '../../services/TranslationService';

export default function AccessControlSection() {
  const { userProfile } = useAuth();
  const [entries, setEntries] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [newType, setNewType] = useState('email');
  const [newValue, setNewValue] = useState('');

  useEffect(() => {
    loadEntries();
  }, []);

  const loadEntries = async () => {
    setLoading(true);
    try {
      const data = await fetchWhitelistEntries();
      setEntries(data);
    } catch (err) {
      setError(err.message || t('settings.access.load_failed', 'Failed to load whitelist entries'));
    } finally {
      setLoading(false);
    }
  };

  const handleAdd = async () => {
    const trimmed = newValue.trim();
    if (!trimmed) return;

    // Validate
    if (newType === 'email') {
      if (!trimmed.includes('@') || !trimmed.split('@')[1]?.includes('.')) {
        setError(t('settings.access.invalid_email', 'Please enter a valid email address.'));
        return;
      }
    } else {
      const domain = trimmed.replace(/^@/, '');
      if (!domain.includes('.')) {
        setError(t('settings.access.invalid_domain', 'Please enter a valid domain (e.g., example.com).'));
        return;
      }
    }

    // Check for duplicates
    const normalized = newType === 'domain' ? trimmed.replace(/^@/, '').toLowerCase() : trimmed.toLowerCase();
    if (entries.some((e) => e.type === newType && e.value === normalized)) {
      setError(t('settings.access.duplicate', 'This entry already exists.'));
      return;
    }

    setSaving(true);
    setError(null);
    try {
      const entry = await addWhitelistEntry(newType, trimmed, userProfile?.id);
      setEntries((prev) => [...prev, entry]);
      setNewValue('');
    } catch (err) {
      setError(err.message || t('settings.access.add_failed', 'Failed to add entry'));
    } finally {
      setSaving(false);
    }
  };

  const handleRemove = async (id) => {
    setSaving(true);
    setError(null);
    try {
      await removeWhitelistEntry(id);
      setEntries((prev) => prev.filter((e) => e.id !== id));
    } catch (err) {
      setError(err.message || t('settings.access.remove_failed', 'Failed to remove entry'));
    } finally {
      setSaving(false);
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter') handleAdd();
  };

  return (
    <Accordion defaultExpanded={false} sx={{ mt: 1 }}>
      <AccordionSummary expandIcon={<ExpandMoreIcon />}>
        <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
          {t('settings.access.title', 'Access Control')}
        </Typography>
      </AccordionSummary>
      <AccordionDetails>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
        {t('settings.access.description', 'Restrict application access to specific email addresses or domains. When the list is empty, any authenticated user can access the app.')}
      </Typography>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      <Box sx={{ display: 'flex', gap: 1, mb: 2, alignItems: 'flex-start' }}>
        <TextField
          select
          size="small"
          label={t('settings.access.type', 'Type')}
          value={newType}
          onChange={(e) => setNewType(e.target.value)}
          sx={{ minWidth: 120 }}
        >
          <MenuItem value="email">{t('settings.access.email', 'Email')}</MenuItem>
          <MenuItem value="domain">{t('settings.access.domain', 'Domain')}</MenuItem>
        </TextField>
        <TextField
          size="small"
          label={newType === 'email' ? t('settings.access.email_address', 'Email address') : t('settings.access.domain', 'Domain')}
          placeholder={newType === 'email' ? 'john@example.com' : 'example.com'}
          value={newValue}
          onChange={(e) => setNewValue(e.target.value)}
          onKeyDown={handleKeyDown}
          sx={{ flex: 1 }}
          disabled={saving}
        />
        <Button
          variant="contained"
          size="small"
          onClick={handleAdd}
          disabled={saving || !newValue.trim()}
          sx={{ minHeight: 40 }}
        >
          {t('ui.add', 'Add')}
        </Button>
      </Box>

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 2 }}>
          <CircularProgress size={24} />
        </Box>
      ) : entries.length === 0 ? (
        <Typography variant="body2" color="text.secondary" sx={{ fontStyle: 'italic' }}>
          {t('settings.access.empty', 'No restrictions configured. All authenticated users can access the app.')}
        </Typography>
      ) : (
        <List dense disablePadding>
          {entries.map((entry) => (
            <ListItem
              key={entry.id}
              secondaryAction={
                <IconButton
                  edge="end"
                  size="small"
                  onClick={() => handleRemove(entry.id)}
                  disabled={saving}
                >
                  <DeleteIcon fontSize="small" />
                </IconButton>
              }
            >
              <Chip
                label={entry.type}
                size="small"
                color={entry.type === 'domain' ? 'primary' : 'default'}
                sx={{ mr: 1, minWidth: 60 }}
              />
              <ListItemText primary={entry.value} />
            </ListItem>
          ))}
        </List>
      )}
    </AccordionDetails>
    </Accordion>
  );
}
