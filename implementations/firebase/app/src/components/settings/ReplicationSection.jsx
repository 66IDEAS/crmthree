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
import Chip from '@mui/material/Chip';
import Alert from '@mui/material/Alert';
import CircularProgress from '@mui/material/CircularProgress';
import LinearProgress from '@mui/material/LinearProgress';
import DeleteIcon from '@mui/icons-material/Delete';
import EditIcon from '@mui/icons-material/Edit';
import PlayArrowIcon from '@mui/icons-material/PlayArrow';
import AddIcon from '@mui/icons-material/Add';
import RemoveCircleOutlineIcon from '@mui/icons-material/RemoveCircleOutline';
import AddCircleOutlineIcon from '@mui/icons-material/AddCircleOutline';
import navigationItems from '../../config/navigation';
import ModelRegistry from '../../model/ModelRegistry';
import ReplicationService from '../../services/ReplicationService';
import { t } from '../../services/TranslationService';

const EMPTY_CONFIG = {
  objectType: '',
  url: '',
  requestBody: '',
  fieldMapping: {},
  keyField: '',
  sourceKeyField: '',
  deleteField: '',
};

export default function ReplicationSection() {
  const [configs, setConfigs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Dialog state
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingConfig, setEditingConfig] = useState(null);
  const [saving, setSaving] = useState(false);

  // Run state
  const [runningId, setRunningId] = useState(null);
  const [runProgress, setRunProgress] = useState('');
  const [runResult, setRunResult] = useState(null);

  useEffect(() => {
    loadConfigs();
  }, []);

  const loadConfigs = async () => {
    setLoading(true);
    try {
      const data = await ReplicationService.listConfigs();
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
    setEditingConfig({
      ...config,
      requestBody:
        typeof config.requestBody === 'string'
          ? config.requestBody
          : JSON.stringify(config.requestBody, null, 2),
    });
    setDialogOpen(true);
  };

  const handleSave = async () => {
    setSaving(true);
    setError(null);
    try {
      let body = editingConfig.requestBody;
      if (typeof body === 'string') {
        body = JSON.parse(body);
      }
      const saved = await ReplicationService.saveConfig({
        ...editingConfig,
        requestBody: body,
      });
      setConfigs((prev) => {
        const idx = prev.findIndex((c) => c.id === saved.id);
        if (idx >= 0) {
          const updated = [...prev];
          updated[idx] = saved;
          return updated;
        }
        return [...prev, saved];
      });
      setDialogOpen(false);
      setEditingConfig(null);
    } catch (err) {
      setError(err.message || t('settings.replication.save_failed', 'Failed to save config'));
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id) => {
    setError(null);
    try {
      await ReplicationService.deleteConfig(id);
      setConfigs((prev) => prev.filter((c) => c.id !== id));
    } catch (err) {
      setError(err.message);
    }
  };

  const handleRun = async (config) => {
    setRunningId(config.id);
    setRunProgress(t('settings.replication.starting', 'Starting replication...'));
    setRunResult(null);
    setError(null);
    try {
      const result = await ReplicationService.runReplication(config, (msg) =>
        setRunProgress(msg)
      );
      setRunResult({ configId: config.id, ...result });
      await loadConfigs(); // Refresh to get updated last_run
    } catch (err) {
      setError(err.message);
    } finally {
      setRunningId(null);
      setRunProgress('');
    }
  };

  const objectTypeLabel = (ot) => {
    const nav = navigationItems.find((n) => n.objectType === ot);
    return nav ? nav.label : ot;
  };

  return (
    <Accordion defaultExpanded={false} sx={{ mt: 1 }}>
      <AccordionSummary expandIcon={<ExpandMoreIcon />}>
        <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
          {t('settings.replication.title', 'Data Replication')}
        </Typography>
      </AccordionSummary>
      <AccordionDetails>
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
        <Typography variant="body2" color="text.secondary">
          {t('settings.replication.description', 'Replicate data from external web services into CRMThree. Configure a source per object type with field mappings, then run to import records.')}
        </Typography>
        <Button size="small" variant="contained" startIcon={<AddIcon />} onClick={handleAdd}>
          {t('settings.replication.add', 'Add Source')}
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {runResult && (
        <Alert
          severity={runResult.errors.length > 0 ? 'warning' : 'success'}
          sx={{ mb: 2 }}
          onClose={() => setRunResult(null)}
        >
          {t('settings.replication.complete', 'Replication complete:')} {runResult.created} {t('dialog.import_created', 'created')}, {runResult.updated} {t('settings.replication.updated', 'updated')},{' '}
          {runResult.skipped} {t('dialog.import_skipped', 'skipped')}
          {runResult.errors.length > 0 && `, ${runResult.errors.length} ${t('dialog.import_errors', 'errors')}`}
        </Alert>
      )}

      {runningId && (
        <Box sx={{ mb: 2 }}>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 0.5 }}>
            {runProgress}
          </Typography>
          <LinearProgress />
        </Box>
      )}

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 2 }}>
          <CircularProgress size={24} />
        </Box>
      ) : configs.length === 0 ? (
        <Typography variant="body2" color="text.secondary" sx={{ fontStyle: 'italic' }}>
          {t('settings.replication.empty', 'No replication sources configured.')}
        </Typography>
      ) : (
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell sx={{ fontWeight: 600 }}>{t('settings.replication.object_type', 'Object Type')}</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>{t('settings.replication.url', 'Web Service URL')}</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>{t('settings.replication.last_run', 'Last Run')}</TableCell>
                <TableCell sx={{ fontWeight: 600 }}>{t('settings.replication.last_result', 'Last Result')}</TableCell>
                <TableCell sx={{ fontWeight: 600 }} align="right">
                  {t('settings.replication.actions', 'Actions')}
                </TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {configs.map((config) => (
                <TableRow key={config.id}>
                  <TableCell>
                    <Chip label={objectTypeLabel(config.objectType)} size="small" color="primary" />
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" noWrap sx={{ maxWidth: 300 }}>
                      {config.url}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    {config.last_run ? (
                      <Typography variant="body2">
                        {new Date(config.last_run).toLocaleString()}
                      </Typography>
                    ) : (
                      <Typography variant="body2" color="text.secondary">
                        {t('settings.replication.never', 'Never')}
                      </Typography>
                    )}
                  </TableCell>
                  <TableCell>
                    {config.last_run_result ? (
                      <Typography variant="body2">
                        {config.last_run_result.created}C / {config.last_run_result.updated}U /{' '}
                        {config.last_run_result.skipped}S
                        {config.last_run_result.errorCount > 0 &&
                          ` / ${config.last_run_result.errorCount}E`}
                      </Typography>
                    ) : (
                      '—'
                    )}
                  </TableCell>
                  <TableCell align="right">
                    <IconButton
                      size="small"
                      color="success"
                      onClick={() => handleRun(config)}
                      disabled={!!runningId}
                      title={t('settings.replication.run', 'Run replication')}
                    >
                      <PlayArrowIcon fontSize="small" />
                    </IconButton>
                    <IconButton
                      size="small"
                      onClick={() => handleEdit(config)}
                      disabled={!!runningId}
                      title={t('ui.edit', 'Edit')}
                    >
                      <EditIcon fontSize="small" />
                    </IconButton>
                    <IconButton
                      size="small"
                      color="error"
                      onClick={() => handleDelete(config.id)}
                      disabled={!!runningId}
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
        <ReplicationConfigDialog
          config={editingConfig}
          onChange={setEditingConfig}
          onSave={handleSave}
          onCancel={() => {
            setDialogOpen(false);
            setEditingConfig(null);
          }}
          saving={saving}
          error={error}
        />
      )}
    </AccordionDetails>
    </Accordion>
  );
}

function ReplicationConfigDialog({ config, onChange, onSave, onCancel, saving, error }) {
  const [mappings, setMappings] = useState(
    Object.entries(config.fieldMapping || {}).map(([source, crm]) => ({ source, crm }))
  );

  const handleChange = (field, value) => {
    onChange({ ...config, [field]: value });
  };

  const handleMappingChange = (idx, key, value) => {
    const updated = [...mappings];
    updated[idx] = { ...updated[idx], [key]: value };
    setMappings(updated);
    // Sync back to config
    const mapped = {};
    updated.forEach((m) => {
      if (m.source && m.crm) mapped[m.source] = m.crm;
    });
    onChange({ ...config, fieldMapping: mapped });
  };

  const addMapping = () => setMappings([...mappings, { source: '', crm: '' }]);
  const removeMapping = (idx) => {
    const updated = mappings.filter((_, i) => i !== idx);
    setMappings(updated);
    const mapped = {};
    updated.forEach((m) => {
      if (m.source && m.crm) mapped[m.source] = m.crm;
    });
    onChange({ ...config, fieldMapping: mapped });
  };

  // Get fields for selected object type
  const crmFields = config.objectType
    ? ModelRegistry.getSpecificFields(config.objectType).map((f) => f.name)
    : [];

  return (
    <Dialog open onClose={onCancel} maxWidth="md" fullWidth>
      <DialogTitle>{config.id ? t('settings.replication.edit_title', 'Edit Replication Source') : t('settings.replication.add_title', 'Add Replication Source')}</DialogTitle>
      <DialogContent>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
          {error && <Alert severity="error">{error}</Alert>}

          <TextField
            select
            label={t('settings.replication.object_type', 'Object Type')}
            value={config.objectType}
            onChange={(e) => handleChange('objectType', e.target.value)}
            size="small"
            fullWidth
          >
            {navigationItems.map((nav) => (
              <MenuItem key={nav.objectType} value={nav.objectType}>
                {nav.label}
              </MenuItem>
            ))}
          </TextField>

          <TextField
            label={t('settings.replication.url', 'Web Service URL')}
            value={config.url}
            onChange={(e) => handleChange('url', e.target.value)}
            size="small"
            fullWidth
            placeholder="https://example.com/api/run"
          />

          <TextField
            label={t('settings.replication.request_body', 'Request Body (JSON)')}
            value={config.requestBody}
            onChange={(e) => handleChange('requestBody', e.target.value)}
            size="small"
            fullWidth
            multiline
            minRows={4}
            maxRows={10}
            placeholder='{"fields": [...], "where": {...}, "limit": 1000}'
          />

          <TextField
            label={t('settings.replication.key_field', 'Key Field (CRM)')}
            value={config.keyField}
            onChange={(e) => handleChange('keyField', e.target.value)}
            size="small"
            fullWidth
            select={crmFields.length > 0}
            placeholder="e.g., account_number"
            helperText={t('settings.replication.key_field_help', 'CRM field used to match existing records')}
          >
            {crmFields.map((f) => (
              <MenuItem key={f} value={f}>
                {f}
              </MenuItem>
            ))}
          </TextField>

          <TextField
            label={t('settings.replication.source_key_field', 'Source Key Field')}
            value={config.sourceKeyField}
            onChange={(e) => handleChange('sourceKeyField', e.target.value)}
            size="small"
            fullWidth
            placeholder="e.g., Customer"
            helperText={t('settings.replication.source_key_field_help', 'Field in the web service response that maps to the key field')}
          />

          <TextField
            label={t('settings.replication.delete_field', 'Delete Flag Field')}
            value={config.deleteField}
            onChange={(e) => handleChange('deleteField', e.target.value)}
            size="small"
            fullWidth
            placeholder="e.g., Delete"
            helperText={t('settings.replication.delete_field_help', 'Source field that indicates the record should be skipped')}
          />

          {/* Field Mappings */}
          <Box>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
              <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                {t('settings.replication.field_mapping', 'Field Mapping')}
              </Typography>
              <IconButton size="small" color="primary" onClick={addMapping}>
                <AddCircleOutlineIcon />
              </IconButton>
            </Box>
            {mappings.map((m, idx) => (
              <Box key={idx} sx={{ display: 'flex', gap: 1, mb: 1, alignItems: 'center' }}>
                <TextField
                  label={t('settings.replication.source_field', 'Source Field')}
                  value={m.source}
                  onChange={(e) => handleMappingChange(idx, 'source', e.target.value)}
                  size="small"
                  sx={{ flex: 1 }}
                  placeholder="e.g., Name1"
                />
                <Typography variant="body2" sx={{ px: 0.5 }}>
                  →
                </Typography>
                <TextField
                  label={t('settings.replication.crm_field', 'CRM Field')}
                  value={m.crm}
                  onChange={(e) => handleMappingChange(idx, 'crm', e.target.value)}
                  size="small"
                  sx={{ flex: 1 }}
                  select={crmFields.length > 0}
                  placeholder="e.g., name1"
                >
                  {crmFields.map((f) => (
                    <MenuItem key={f} value={f}>
                      {f}
                    </MenuItem>
                  ))}
                </TextField>
                <IconButton size="small" color="error" onClick={() => removeMapping(idx)}>
                  <RemoveCircleOutlineIcon fontSize="small" />
                </IconButton>
              </Box>
            ))}
            {mappings.length === 0 && (
              <Typography variant="body2" color="text.secondary" sx={{ fontStyle: 'italic' }}>
                {t('settings.replication.no_mappings', 'No field mappings configured. Click + to add one.')}
              </Typography>
            )}
          </Box>
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={onCancel}>{t('ui.cancel', 'Cancel')}</Button>
        <Button
          variant="contained"
          onClick={onSave}
          disabled={saving || !config.objectType || !config.url}
        >
          {saving ? <CircularProgress size={20} /> : t('ui.save', 'Save')}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
