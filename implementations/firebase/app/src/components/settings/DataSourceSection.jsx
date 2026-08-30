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
import RemoveCircleOutlineIcon from '@mui/icons-material/RemoveCircleOutline';
import DataService from '../../services/DataService';
import { clearConfigCache } from '../../services/DataSourceRouter';
import navigationItems from '../../config/navigation';
import ModelRegistry from '../../model/ModelRegistry';
import { t } from '../../services/TranslationService';

const SOURCE_TYPES = ['Local', 'External'];
const AUTH_TYPES = ['None', 'BasicAuth', 'OAuth2', 'APIKey'];

const EMPTY_CONFIG = {
  object_type: '',
  source_type: 'Local',
  endpoint_url: '',
  auth_type: 'None',
  auth_config: {},
  field_mapping: {},
  active: true,
};

/**
 * A16/UX34b: Admin-only Settings section for managing per-object data source configurations.
 */
export default function DataSourceSection() {
  const [configs, setConfigs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingConfig, setEditingConfig] = useState(null);
  const [saving, setSaving] = useState(false);
  const [mappingPairs, setMappingPairs] = useState([]);

  useEffect(() => {
    loadConfigs();
  }, []);

  const loadConfigs = async () => {
    setLoading(true);
    try {
      const data = await DataService.list('DataSourceConfig', { pageSize: 100 });
      setConfigs(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleAdd = () => {
    setEditingConfig({ ...EMPTY_CONFIG });
    setMappingPairs([]);
    setDialogOpen(true);
  };

  const handleEdit = (config) => {
    const pairs = config.field_mapping
      ? Object.entries(config.field_mapping).map(([ext, crm]) => ({ external: ext, crm }))
      : [];
    setEditingConfig({ ...config, auth_config: config.auth_config || {} });
    setMappingPairs(pairs);
    setDialogOpen(true);
  };

  const handleDelete = async (config) => {
    try {
      await DataService.remove('DataSourceConfig', config.id);
      clearConfigCache();
      loadConfigs();
    } catch (err) {
      setError(err.message);
    }
  };

  const handleSave = async () => {
    setSaving(true);
    setError(null);
    try {
      // Convert mapping pairs to object
      const fieldMapping = {};
      for (const pair of mappingPairs) {
        if (pair.external && pair.crm) {
          fieldMapping[pair.external] = pair.crm;
        }
      }

      const data = {
        ...editingConfig,
        field_mapping: fieldMapping,
      };

      if (editingConfig.id) {
        await DataService.update('DataSourceConfig', editingConfig.id, data);
      } else {
        await DataService.create('DataSourceConfig', data);
      }

      clearConfigCache();
      setDialogOpen(false);
      setEditingConfig(null);
      loadConfigs();
    } catch (err) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleClose = () => {
    setDialogOpen(false);
    setEditingConfig(null);
    setError(null);
  };

  const isExternal = editingConfig?.source_type === 'External';

  // Object types already configured
  const configuredTypes = new Set(configs.map((c) => c.object_type));

  return (
    <Accordion defaultExpanded={false} sx={{ mt: 1 }}>
      <AccordionSummary expandIcon={<ExpandMoreIcon />}>
        <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
          {t('settings.datasource.title', 'Data Sources')}
        </Typography>
      </AccordionSummary>
      <AccordionDetails>
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
        <Typography variant="body2" color="text.secondary">
          {t('settings.datasource.description', 'Configure per-object data source routing. By default all objects use the local database.')}
        </Typography>
        <Button variant="outlined" size="small" startIcon={<AddIcon />} onClick={handleAdd}>
          {t('settings.datasource.add', 'Add Data Source')}
        </Button>
      </Box>

      {error && !dialogOpen && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 3 }}>
          <CircularProgress size={24} />
        </Box>
      ) : configs.length === 0 ? (
        <Typography variant="body2" color="text.secondary">
          {t('settings.datasource.empty', 'No custom data source configurations. All objects use the local database.')}
        </Typography>
      ) : (
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>{t('settings.datasource.object_type', 'Object Type')}</TableCell>
                <TableCell>{t('settings.datasource.source', 'Source')}</TableCell>
                <TableCell>{t('settings.datasource.endpoint_url', 'Endpoint URL')}</TableCell>
                <TableCell>{t('settings.datasource.auth', 'Auth')}</TableCell>
                <TableCell>{t('ui.active', 'Active')}</TableCell>
                <TableCell align="right">{t('settings.datasource.actions', 'Actions')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {configs.map((config) => (
                <TableRow key={config.id}>
                  <TableCell>{config.object_type}</TableCell>
                  <TableCell>
                    <Chip
                      label={config.source_type}
                      size="small"
                      color={config.source_type === 'External' ? 'warning' : 'default'}
                    />
                  </TableCell>
                  <TableCell sx={{ maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {config.endpoint_url || '—'}
                  </TableCell>
                  <TableCell>{config.auth_type || 'None'}</TableCell>
                  <TableCell>
                    <Chip label={config.active ? 'Yes' : 'No'} size="small" color={config.active ? 'success' : 'default'} />
                  </TableCell>
                  <TableCell align="right">
                    <IconButton size="small" onClick={() => handleEdit(config)} title={t('ui.edit', 'Edit')}>
                      <EditIcon fontSize="small" />
                    </IconButton>
                    <IconButton size="small" onClick={() => handleDelete(config)} title={t('ui.delete', 'Delete')}>
                      <DeleteIcon fontSize="small" />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      {/* Add/Edit Dialog */}
      <Dialog open={dialogOpen} onClose={handleClose} maxWidth="sm" fullWidth>
        <DialogTitle>{editingConfig?.id ? t('settings.datasource.edit_title', 'Edit Data Source') : t('settings.datasource.add_title', 'Add Data Source')}</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
            {error && dialogOpen && <Alert severity="error">{error}</Alert>}

            <TextField
              select
              label={t('settings.datasource.object_type', 'Object Type')}
              value={editingConfig?.object_type || ''}
              onChange={(e) => setEditingConfig((c) => ({ ...c, object_type: e.target.value }))}
              size="small"
              required
              disabled={!!editingConfig?.id}
            >
              {navigationItems
                .filter((nav) => !configuredTypes.has(nav.objectType) || editingConfig?.object_type === nav.objectType)
                .map((nav) => (
                  <MenuItem key={nav.objectType} value={nav.objectType}>{nav.label} ({nav.objectType})</MenuItem>
                ))}
            </TextField>

            <TextField
              select
              label={t('settings.datasource.source_type', 'Source Type')}
              value={editingConfig?.source_type || 'Local'}
              onChange={(e) => setEditingConfig((c) => ({ ...c, source_type: e.target.value }))}
              size="small"
            >
              {SOURCE_TYPES.map((t) => <MenuItem key={t} value={t}>{t}</MenuItem>)}
            </TextField>

            {isExternal && (
              <>
                <TextField
                  label={t('settings.datasource.endpoint_url', 'Endpoint URL')}
                  value={editingConfig?.endpoint_url || ''}
                  onChange={(e) => setEditingConfig((c) => ({ ...c, endpoint_url: e.target.value }))}
                  size="small"
                  placeholder="https://api.example.com/accounts"
                  required
                />

                <TextField
                  select
                  label={t('settings.datasource.auth_type', 'Authentication Type')}
                  value={editingConfig?.auth_type || 'None'}
                  onChange={(e) => setEditingConfig((c) => ({ ...c, auth_type: e.target.value, auth_config: {} }))}
                  size="small"
                >
                  {AUTH_TYPES.map((t) => <MenuItem key={t} value={t}>{t}</MenuItem>)}
                </TextField>

                {editingConfig?.auth_type === 'BasicAuth' && (
                  <>
                    <TextField
                      label={t('settings.datasource.username', 'Username')}
                      value={editingConfig?.auth_config?.username || ''}
                      onChange={(e) => setEditingConfig((c) => ({
                        ...c, auth_config: { ...c.auth_config, username: e.target.value },
                      }))}
                      size="small"
                    />
                    <TextField
                      label={t('settings.datasource.password', 'Password')}
                      type="password"
                      value={editingConfig?.auth_config?.password || ''}
                      onChange={(e) => setEditingConfig((c) => ({
                        ...c, auth_config: { ...c.auth_config, password: e.target.value },
                      }))}
                      size="small"
                    />
                  </>
                )}

                {editingConfig?.auth_type === 'OAuth2' && (
                  <TextField
                    label={t('settings.datasource.access_token', 'Access Token')}
                    type="password"
                    value={editingConfig?.auth_config?.access_token || ''}
                    onChange={(e) => setEditingConfig((c) => ({
                      ...c, auth_config: { ...c.auth_config, access_token: e.target.value },
                    }))}
                    size="small"
                  />
                )}

                {editingConfig?.auth_type === 'APIKey' && (
                  <>
                    <TextField
                      label={t('settings.datasource.api_key', 'API Key')}
                      type="password"
                      value={editingConfig?.auth_config?.api_key || ''}
                      onChange={(e) => setEditingConfig((c) => ({
                        ...c, auth_config: { ...c.auth_config, api_key: e.target.value },
                      }))}
                      size="small"
                    />
                    <TextField
                      label={t('settings.datasource.header_name', 'Header Name')}
                      value={editingConfig?.auth_config?.header_name || ''}
                      onChange={(e) => setEditingConfig((c) => ({
                        ...c, auth_config: { ...c.auth_config, header_name: e.target.value },
                      }))}
                      size="small"
                      placeholder="X-API-Key"
                    />
                  </>
                )}

                {/* Field Mapping */}
                <Box>
                  <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1 }}>
                    {t('settings.datasource.field_mapping', 'Field Mapping')}
                  </Typography>
                  <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 1 }}>
                    {t('settings.datasource.field_mapping_help', 'Map external system field names to CRM field names.')}
                  </Typography>
                  {mappingPairs.map((pair, idx) => (
                    <Box key={idx} sx={{ display: 'flex', gap: 1, mb: 1, alignItems: 'center' }}>
                      <TextField
                        label={t('settings.datasource.external_field', 'External Field')}
                        value={pair.external}
                        onChange={(e) => {
                          const updated = [...mappingPairs];
                          updated[idx] = { ...updated[idx], external: e.target.value };
                          setMappingPairs(updated);
                        }}
                        size="small"
                        sx={{ flex: 1 }}
                      />
                      <Typography variant="body2" color="text.secondary">→</Typography>
                      <TextField
                        select
                        label={t('settings.datasource.crm_field', 'CRM Field')}
                        value={pair.crm}
                        onChange={(e) => {
                          const updated = [...mappingPairs];
                          updated[idx] = { ...updated[idx], crm: e.target.value };
                          setMappingPairs(updated);
                        }}
                        size="small"
                        sx={{ flex: 1 }}
                      >
                        {(editingConfig?.object_type
                          ? ModelRegistry.getObjectSchema(editingConfig.object_type).fields
                          : []
                        ).map((f) => (
                          <MenuItem key={f.name} value={f.name}>{f.name}</MenuItem>
                        ))}
                      </TextField>
                      <IconButton
                        size="small"
                        onClick={() => setMappingPairs((p) => p.filter((_, i) => i !== idx))}
                        title={t('ui.remove', 'Remove')}
                      >
                        <RemoveCircleOutlineIcon fontSize="small" />
                      </IconButton>
                    </Box>
                  ))}
                  <Button
                    size="small"
                    onClick={() => setMappingPairs((p) => [...p, { external: '', crm: '' }])}
                  >
                    + {t('settings.datasource.add_mapping', 'Add Mapping')}
                  </Button>
                </Box>
              </>
            )}

            <FormControlLabel
              control={
                <Switch
                  checked={editingConfig?.active ?? true}
                  onChange={(e) => setEditingConfig((c) => ({ ...c, active: e.target.checked }))}
                />
              }
              label={t('ui.active', 'Active')}
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose}>{t('ui.cancel', 'Cancel')}</Button>
          <Button
            variant="contained"
            onClick={handleSave}
            disabled={saving || !editingConfig?.object_type}
          >
            {saving ? <CircularProgress size={20} /> : t('ui.save', 'Save')}
          </Button>
        </DialogActions>
      </Dialog>
    </AccordionDetails>
    </Accordion>
  );
}
