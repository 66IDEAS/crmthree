import { useState, useCallback } from 'react';
import Accordion from '@mui/material/Accordion';
import AccordionSummary from '@mui/material/AccordionSummary';
import AccordionDetails from '@mui/material/AccordionDetails';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import Alert from '@mui/material/Alert';
import CircularProgress from '@mui/material/CircularProgress';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import Select from '@mui/material/Select';
import MenuItem from '@mui/material/MenuItem';
import Tooltip from '@mui/material/Tooltip';
import Snackbar from '@mui/material/Snackbar';
import navigationItems from '../../config/navigation';
import ModelRegistry from '../../model/ModelRegistry';
import { formatFieldLabel, getObjectLabel, getAutoNumberField } from '../../utils/fieldUtils';
import { useAuth } from '../../contexts/AuthContext';
import { t } from '../../services/TranslationService';
import {
  loadListSortSettings,
  getListSortSetting,
  getSortFieldFor,
  saveListSortSetting,
  countHiddenBySort,
  assignMissingAutoNumbers,
} from '../../services/ListSortService';

/** The objects a user can open a list for, minus nav entries with no model object. */
const SORTABLE_OBJECTS = navigationItems
  .map((n) => n.objectType)
  .filter((o) => o && ModelRegistry.hasObject(o));

/** Human label for a field that may be object-specific or a common field. */
function fieldLabel(objectType, fieldName) {
  const def =
    ModelRegistry.getSpecificFields(objectType).find((f) => f.name === fieldName) ||
    ModelRegistry.getCommonFields().find((f) => f.name === fieldName);
  return def ? formatFieldLabel(def, objectType) : fieldName;
}

export default function ListSortSection() {
  const { userProfile } = useAuth();
  const [expanded, setExpanded] = useState(false);
  const [loaded, setLoaded] = useState(false);
  const [loading, setLoading] = useState(false);
  const [settings, setSettings] = useState({});
  const [hidden, setHidden] = useState({});
  const [checking, setChecking] = useState(false);
  const [savingId, setSavingId] = useState(null);
  const [fixingId, setFixingId] = useState(null);
  const [error, setError] = useState(null);
  const [toast, setToast] = useState(null);

  /** Counts records each object's current sort would leave out of its list. */
  const runHiddenChecks = useCallback(async (current) => {
    setChecking(true);
    const results = {};
    await Promise.all(
      SORTABLE_OBJECTS.map(async (objectType) => {
        const field = getSortFieldFor(objectType, current[objectType].sort_by);
        if (!field) return;
        results[objectType] = await countHiddenBySort(objectType, field);
      })
    );
    setHidden(results);
    setChecking(false);
  }, []);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      await loadListSortSettings(true);
      const current = {};
      SORTABLE_OBJECTS.forEach((o) => { current[o] = getListSortSetting(o); });
      setSettings(current);
      setLoaded(true);
      setLoading(false);
      runHiddenChecks(current);
    } catch (err) {
      setError(err.message || t('settings.list_sort.load_failed', 'Failed to load list sort settings'));
      setLoading(false);
    }
  }, [runHiddenChecks]);

  const handleExpand = (_e, isExpanded) => {
    setExpanded(isExpanded);
    if (isExpanded && !loaded) load();
  };

  const change = async (objectType, changes) => {
    const next = { ...settings[objectType], ...changes };
    setSavingId(objectType);
    setError(null);
    try {
      await saveListSortSetting(objectType, next, userProfile?.id);
      const updated = { ...settings, [objectType]: next };
      setSettings(updated);
      setToast(t('settings.list_sort.saved', 'Sort order saved'));
      const field = getSortFieldFor(objectType, next.sort_by);
      if (field) {
        setHidden((prev) => ({ ...prev, [objectType]: undefined }));
        const n = await countHiddenBySort(objectType, field);
        setHidden((prev) => ({ ...prev, [objectType]: n }));
      }
    } catch (err) {
      setError(err.message || t('settings.list_sort.save_failed', 'Failed to save sort order'));
    } finally {
      setSavingId(null);
    }
  };

  const fix = async (objectType) => {
    setFixingId(objectType);
    setError(null);
    try {
      const n = await assignMissingAutoNumbers(objectType);
      setToast(
        t('settings.list_sort.fixed', 'Assigned numbers to {n} record(s)').replace('{n}', n)
      );
      const field = getSortFieldFor(objectType, settings[objectType].sort_by);
      const remaining = await countHiddenBySort(objectType, field);
      setHidden((prev) => ({ ...prev, [objectType]: remaining }));
    } catch (err) {
      setError(err.message || t('settings.list_sort.fix_failed', 'Failed to assign numbers'));
    } finally {
      setFixingId(null);
    }
  };

  const totalHidden = Object.values(hidden).reduce((sum, n) => sum + (n || 0), 0);

  return (
    <Accordion expanded={expanded} onChange={handleExpand} sx={{ mb: 2 }}>
      <AccordionSummary expandIcon={<ExpandMoreIcon />}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
            {t('settings.list_sort.title', 'List Sorting')}
          </Typography>
          {totalHidden > 0 && (
            <Chip
              size="small"
              color="warning"
              icon={<WarningAmberIcon />}
              label={t('settings.list_sort.total_hidden', '{n} hidden').replace('{n}', totalHidden)}
            />
          )}
        </Box>
      </AccordionSummary>
      <AccordionDetails>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
          {t(
            'settings.list_sort.description',
            'Sets the order each list opens in. Clicking a column header still re-sorts that list for the current visit only.'
          )}
        </Typography>

        {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 3 }}>
            <CircularProgress size={28} />
          </Box>
        ) : (
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>{t('settings.list_sort.object', 'Object')}</TableCell>
                <TableCell sx={{ width: 150 }}>{t('settings.list_sort.sort_by', 'Sort By')}</TableCell>
                <TableCell sx={{ width: 170 }}>{t('settings.list_sort.direction', 'Direction')}</TableCell>
                <TableCell>{t('settings.list_sort.sorted_field', 'Sorted Field')}</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {SORTABLE_OBJECTS.map((objectType) => {
                const setting = settings[objectType] || { sort_by: 'number', sort_direction: 'asc' };
                const field = getSortFieldFor(objectType, setting.sort_by);
                const autoField = getAutoNumberField(ModelRegistry.getSpecificFields(objectType));
                const hiddenCount = hidden[objectType];
                const fixable = autoField && field === autoField.name;
                const busy = savingId === objectType;

                return (
                  <TableRow key={objectType} hover>
                    <TableCell>{getObjectLabel(objectType)}</TableCell>
                    <TableCell>
                      <Select
                        size="small"
                        fullWidth
                        value={setting.sort_by}
                        disabled={busy}
                        onChange={(e) => change(objectType, { sort_by: e.target.value })}
                      >
                        <MenuItem value="number">{t('settings.list_sort.by_number', 'Number')}</MenuItem>
                        <MenuItem value="name">{t('settings.list_sort.by_name', 'Name')}</MenuItem>
                      </Select>
                    </TableCell>
                    <TableCell>
                      <Select
                        size="small"
                        fullWidth
                        value={setting.sort_direction}
                        disabled={busy}
                        onChange={(e) => change(objectType, { sort_direction: e.target.value })}
                      >
                        <MenuItem value="asc">{t('settings.list_sort.ascending', 'Ascending')}</MenuItem>
                        <MenuItem value="desc">{t('settings.list_sort.descending', 'Descending')}</MenuItem>
                      </Select>
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexWrap: 'wrap' }}>
                        <Tooltip title={fieldLabel(objectType, field)}>
                          <Typography
                            variant="body2"
                            color="text.secondary"
                            sx={{ fontFamily: 'monospace' }}
                          >
                            {field}
                          </Typography>
                        </Tooltip>
                        {checking && hiddenCount === undefined && <CircularProgress size={12} />}
                        {hiddenCount > 0 && (
                          <>
                            <Tooltip
                              title={t(
                                'settings.list_sort.hidden_help',
                                'These records have no value for this field, so a sorted list leaves them out entirely.'
                              )}
                            >
                              <Chip
                                size="small"
                                color="warning"
                                icon={<WarningAmberIcon />}
                                label={t('settings.list_sort.hidden', '{n} hidden').replace('{n}', hiddenCount)}
                              />
                            </Tooltip>
                            {fixable && (
                              <Button
                                size="small"
                                onClick={() => fix(objectType)}
                                disabled={fixingId === objectType}
                              >
                                {fixingId === objectType
                                  ? t('settings.list_sort.fixing', 'Fixing…')
                                  : t('settings.list_sort.fix', 'Fix')}
                              </Button>
                            )}
                          </>
                        )}
                      </Box>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        )}
      </AccordionDetails>

      <Snackbar
        open={!!toast}
        autoHideDuration={3000}
        onClose={() => setToast(null)}
        message={toast}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      />
    </Accordion>
  );
}
