import { useState, useEffect } from 'react';
import Accordion from '@mui/material/Accordion';
import AccordionSummary from '@mui/material/AccordionSummary';
import AccordionDetails from '@mui/material/AccordionDetails';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import IconButton from '@mui/material/IconButton';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import TextField from '@mui/material/TextField';
import MenuItem from '@mui/material/MenuItem';
import Switch from '@mui/material/Switch';
import FormControlLabel from '@mui/material/FormControlLabel';
import Chip from '@mui/material/Chip';
import Alert from '@mui/material/Alert';
import CircularProgress from '@mui/material/CircularProgress';
import DeleteIcon from '@mui/icons-material/Delete';
import EditIcon from '@mui/icons-material/Edit';
import AddIcon from '@mui/icons-material/Add';
import DataService from '../../services/DataService';
import { t } from '../../services/TranslationService';

const PROVIDERS = ['OpenAI', 'Google', 'Anthropic', 'Moonshot'];

const MODEL_PLACEHOLDERS = {
  OpenAI: 'e.g., gpt-4o, gpt-4o-mini',
  Google: 'e.g., gemini-2.0-flash, gemini-1.5-pro',
  Anthropic: 'e.g., claude-sonnet-4-20250514, claude-haiku-4-5-20251001',
  Moonshot: 'e.g., kimi-k2-0711, moonshot-v1-8k',
};

const EMPTY_CONFIG = {
  provider: '',
  model: '',
  api_key: '',
  endpoint_url: '',
  is_active: false,
};

/**
 * A19: Admin-only Settings section for managing AI provider configurations.
 * Only one provider can be active at a time.
 */
export default function AIProviderSection() {
  const [configs, setConfigs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingConfig, setEditingConfig] = useState(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    loadConfigs();
  }, []);

  const loadConfigs = async () => {
    setLoading(true);
    try {
      const data = await DataService.list('AIProviderConfig', { pageSize: 100 });
      setConfigs(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleAdd = () => {
    setEditingConfig({ ...EMPTY_CONFIG });
    setDialogOpen(true);
  };

  const handleEdit = (config) => {
    // Don't show the actual API key — let the user re-enter if they want to change it
    setEditingConfig({ ...config, api_key: '' });
    setDialogOpen(true);
  };

  const handleSave = async () => {
    setSaving(true);
    setError(null);
    try {
      const toSave = { ...editingConfig };

      // If editing and api_key is empty, preserve the existing key
      if (toSave.id && !toSave.api_key) {
        const existing = configs.find((c) => c.id === toSave.id);
        if (existing) toSave.api_key = existing.api_key;
      }

      // If activating, deactivate all others first
      if (toSave.is_active) {
        const others = configs.filter((c) => c.id !== toSave.id && c.is_active);
        for (const other of others) {
          await DataService.update('AIProviderConfig', other.id, { is_active: false });
        }
      }

      let saved;
      if (toSave.id) {
        saved = await DataService.update('AIProviderConfig', toSave.id, toSave);
      } else {
        saved = await DataService.create('AIProviderConfig', toSave);
      }

      await loadConfigs();
      setDialogOpen(false);
      setEditingConfig(null);
    } catch (err) {
      setError(err.message || t('settings.ai.save_failed', 'Failed to save'));
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id) => {
    setError(null);
    try {
      await DataService.remove('AIProviderConfig', id);
      setConfigs((prev) => prev.filter((c) => c.id !== id));
    } catch (err) {
      setError(err.message);
    }
  };

  return (
    <Accordion defaultExpanded={false} sx={{ mt: 1 }}>
      <AccordionSummary expandIcon={<ExpandMoreIcon />}>
        <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
          {t('settings.ai.title', 'AI Provider')}
        </Typography>
      </AccordionSummary>
      <AccordionDetails>
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
        <Typography variant="body2" color="text.secondary">
          {t('settings.ai.description', 'Configure an AI provider for the AI assistant. Only one provider can be active at a time. API keys are stored securely and only accessed server-side.')}
        </Typography>
        <Button size="small" variant="contained" startIcon={<AddIcon />} onClick={handleAdd}>
          {t('settings.ai.add', 'Add Provider')}
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 2 }}>
          <CircularProgress size={24} />
        </Box>
      ) : configs.length === 0 ? (
        <Typography variant="body2" color="text.secondary" sx={{ fontStyle: 'italic' }}>
          {t('settings.ai.empty', 'No AI providers configured. Click "Add Provider" to get started.')}
        </Typography>
      ) : (
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell sx={{ fontWeight: 600 }}>{t('settings.ai.provider', 'Provider')}</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>{t('settings.ai.model', 'Model')}</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>{t('settings.ai.status', 'Status')}</TableCell>
                <TableCell sx={{ fontWeight: 600 }} align="right">{t('settings.ai.actions', 'Actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {configs.map((config) => (
                <TableRow key={config.id}>
                  <TableCell>
                    <Chip label={config.provider} size="small" color="primary" />
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">{config.model}</Typography>
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={config.is_active ? t('ui.active', 'Active') : t('ui.inactive', 'Inactive')}
                      size="small"
                      color={config.is_active ? 'success' : 'default'}
                    />
                  </TableCell>
                  <TableCell align="right">
                    <IconButton size="small" onClick={() => handleEdit(config)} title={t('ui.edit', 'Edit')}>
                      <EditIcon fontSize="small" />
                    </IconButton>
                    <IconButton
                      size="small"
                      color="error"
                      onClick={() => handleDelete(config.id)}
                      title={t('ui.delete', 'Delete')}
                    >
                      <DeleteIcon fontSize="small" />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      {/* Add / Edit Dialog */}
      {dialogOpen && editingConfig && (
        <Dialog open onClose={() => { setDialogOpen(false); setEditingConfig(null); }} maxWidth="sm" fullWidth>
          <DialogTitle>{editingConfig.id ? t('settings.ai.edit_title', 'Edit AI Provider') : t('settings.ai.add_title', 'Add AI Provider')}</DialogTitle>
          <DialogContent>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
              <TextField
                select
                label={t('settings.ai.provider', 'Provider')}
                value={editingConfig.provider}
                onChange={(e) => setEditingConfig({ ...editingConfig, provider: e.target.value })}
                size="small"
                fullWidth
                required
              >
                {PROVIDERS.map((p) => (
                  <MenuItem key={p} value={p}>{p}</MenuItem>
                ))}
              </TextField>

              <TextField
                label={t('settings.ai.model', 'Model')}
                value={editingConfig.model}
                onChange={(e) => setEditingConfig({ ...editingConfig, model: e.target.value })}
                size="small"
                fullWidth
                required
                placeholder={MODEL_PLACEHOLDERS[editingConfig.provider] || 'Model identifier'}
              />

              <TextField
                label={t('settings.ai.api_key', 'API Key')}
                value={editingConfig.api_key}
                onChange={(e) => setEditingConfig({ ...editingConfig, api_key: e.target.value })}
                size="small"
                fullWidth
                type="password"
                required={!editingConfig.id}
                placeholder={editingConfig.id ? 'Leave blank to keep current key' : 'Enter API key'}
                helperText={editingConfig.id ? t('settings.ai.keep_key_hint', 'Leave blank to keep the existing key') : ''}
              />

              <TextField
                label={t('settings.ai.endpoint_url', 'Endpoint URL (optional)')}
                value={editingConfig.endpoint_url}
                onChange={(e) => setEditingConfig({ ...editingConfig, endpoint_url: e.target.value })}
                size="small"
                fullWidth
                placeholder="Custom endpoint URL (leave blank for default)"
              />

              <FormControlLabel
                control={
                  <Switch
                    checked={editingConfig.is_active}
                    onChange={(e) => setEditingConfig({ ...editingConfig, is_active: e.target.checked })}
                  />
                }
                label={t('ui.active', 'Active')}
              />
            </Box>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => { setDialogOpen(false); setEditingConfig(null); }}>{t('ui.cancel', 'Cancel')}</Button>
            <Button
              variant="contained"
              onClick={handleSave}
              disabled={saving || !editingConfig.provider || !editingConfig.model || (!editingConfig.id && !editingConfig.api_key)}
            >
              {saving ? <CircularProgress size={20} /> : t('ui.save', 'Save')}
            </Button>
          </DialogActions>
        </Dialog>
      )}
    </AccordionDetails>
    </Accordion>
  );
}
