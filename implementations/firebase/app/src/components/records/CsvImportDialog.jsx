import { useState, useCallback, useMemo } from 'react';
import useMediaQuery from '@mui/material/useMediaQuery';
import { useTheme } from '@mui/material/styles';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import Button from '@mui/material/Button';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Alert from '@mui/material/Alert';
import LinearProgress from '@mui/material/LinearProgress';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import TextField from '@mui/material/TextField';
import MenuItem from '@mui/material/MenuItem';
import FileUploadIcon from '@mui/icons-material/FileUpload';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import { parseCsv, autoMapFields, getImportFields } from '../../utils/csvUtils';
import { formatFieldLabel } from '../../utils/fieldUtils';
import DataService from '../../services/DataService';
import { getObjectLabel } from '../../utils/fieldUtils';
import { t } from '../../services/TranslationService';

const SOURCE_OPTIONS = [
  { value: 'csv', label: 'CSV Column' },
  { value: 'fixed', label: 'Fixed Value' },
  { value: 'skip', label: 'Skip' },
];

/**
 * Build a field-centric mapping from CSV headers and CRM fields.
 * Each CRM field gets: { source: 'csv'|'fixed'|'skip', csvHeader?, value? }
 */
function buildFieldMapping(csvHeaders, objectType) {
  const fields = getImportFields(objectType);
  const csvToField = autoMapFields(csvHeaders, objectType);

  // Invert: field name → csv header
  const fieldToCsv = {};
  for (const [header, fieldName] of Object.entries(csvToField)) {
    if (fieldName) fieldToCsv[fieldName] = header;
  }

  const mapping = {};
  for (const field of fields) {
    if (fieldToCsv[field.name]) {
      mapping[field.name] = { source: 'csv', csvHeader: fieldToCsv[field.name] };
    } else if (field.default !== undefined && field.default !== null) {
      mapping[field.name] = { source: 'fixed', value: String(field.default) };
    } else {
      mapping[field.name] = { source: 'skip' };
    }
  }
  return mapping;
}

/**
 * F19 + UX35: CSV Import Dialog.
 * CRM-field-centric mapping with required/optional indicators and fixed value support.
 */
export default function CsvImportDialog({ open, onClose, objectType, onComplete }) {
  const theme = useTheme();
  const fullScreen = useMediaQuery(theme.breakpoints.down('sm'));
  const [csvData, setCsvData] = useState(null);
  const [fieldMapping, setFieldMapping] = useState({});
  const [importing, setImporting] = useState(false);
  const [progress, setProgress] = useState('');
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);

  const importFields = getImportFields(objectType);
  const label = getObjectLabel(objectType);

  // Sort: required first, then optional — preserve data model order within each group
  const sortedFields = useMemo(() => {
    const required = importFields.filter((f) => f.required);
    const optional = importFields.filter((f) => !f.required);
    return [...required, ...optional];
  }, [importFields]);

  // CSV headers already used by another field
  const usedCsvHeaders = useMemo(() => {
    const used = new Set();
    for (const m of Object.values(fieldMapping)) {
      if (m.source === 'csv' && m.csvHeader) used.add(m.csvHeader);
    }
    return used;
  }, [fieldMapping]);

  // Unmapped required fields
  const unmappedRequired = useMemo(() => {
    return sortedFields.filter(
      (f) => f.required && (!fieldMapping[f.name] || fieldMapping[f.name].source === 'skip')
    );
  }, [sortedFields, fieldMapping]);

  const mappedCount = useMemo(() => {
    return Object.values(fieldMapping).filter((m) => m.source !== 'skip').length;
  }, [fieldMapping]);

  const handleFileSelect = useCallback(
    (e) => {
      const file = e.target.files?.[0];
      if (!file) return;
      setError(null);
      setResult(null);

      const reader = new FileReader();
      reader.onload = (evt) => {
        try {
          const parsed = parseCsv(evt.target.result);
          if (parsed.rows.length === 0) {
            setError(t('dialog.csv_empty', 'CSV file is empty or has no data rows.'));
            return;
          }
          setCsvData(parsed);
          setFieldMapping(buildFieldMapping(parsed.headers, objectType));
        } catch (err) {
          setError(t('dialog.csv_parse_error', 'Failed to parse CSV file:') + ' ' + err.message);
        }
      };
      reader.readAsText(file);
    },
    [objectType]
  );

  const handleSourceChange = (fieldName, newSource) => {
    setFieldMapping((prev) => {
      const field = importFields.find((f) => f.name === fieldName);
      const entry = { source: newSource };
      if (newSource === 'csv') {
        entry.csvHeader = '';
      } else if (newSource === 'fixed') {
        // Pre-fill with data model default if available
        entry.value = field?.default !== undefined && field?.default !== null ? String(field.default) : '';
      }
      return { ...prev, [fieldName]: entry };
    });
  };

  const handleCsvHeaderChange = (fieldName, csvHeader) => {
    setFieldMapping((prev) => ({
      ...prev,
      [fieldName]: { source: 'csv', csvHeader },
    }));
  };

  const handleFixedValueChange = (fieldName, value) => {
    setFieldMapping((prev) => ({
      ...prev,
      [fieldName]: { source: 'fixed', value },
    }));
  };

  const handleImport = async () => {
    if (!csvData) return;
    setImporting(true);
    setProgress(t('dialog.starting_import', 'Starting import...'));
    setError(null);

    const created = [];
    const errors = [];
    const skipped = [];

    for (let i = 0; i < csvData.rows.length; i++) {
      const row = csvData.rows[i];
      try {
        const record = {};
        let hasData = false;

        for (const [fieldName, mapping] of Object.entries(fieldMapping)) {
          if (mapping.source === 'csv' && mapping.csvHeader) {
            const val = row[mapping.csvHeader];
            if (val !== undefined && val !== '') {
              record[fieldName] = val;
              hasData = true;
            }
          } else if (mapping.source === 'fixed' && mapping.value !== undefined && mapping.value !== '') {
            record[fieldName] = mapping.value;
            hasData = true;
          }
        }

        if (!hasData) {
          skipped.push(i + 2);
          continue;
        }

        await DataService.create(objectType, record);
        created.push(i + 2);

        if ((i + 1) % 5 === 0) {
          setProgress(t('dialog.import_progress', `Imported ${i + 1} of ${csvData.rows.length} rows...`));
        }
      } catch (err) {
        const msg = err.errors
          ? err.errors.map((e) => e.error).join('; ')
          : err.message;
        errors.push({ row: i + 2, error: msg });
      }
    }

    setResult({
      created: created.length,
      skipped: skipped.length,
      errors,
      total: csvData.rows.length,
    });
    setImporting(false);
    setProgress('');

    if (created.length > 0) {
      onComplete?.();
    }
  };

  const handleClose = () => {
    setCsvData(null);
    setFieldMapping({});
    setResult(null);
    setError(null);
    setImporting(false);
    onClose();
  };

  return (
    <Dialog open={open} onClose={importing ? undefined : handleClose} maxWidth="md" fullWidth fullScreen={fullScreen}>
      <DialogTitle>{t('dialog.import_from_csv', `Import ${label} from CSV`)}</DialogTitle>
      <DialogContent>
        {error && (
          <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
            {error}
          </Alert>
        )}

        {result && (
          <Alert
            severity={result.errors.length > 0 ? 'warning' : 'success'}
            sx={{ mb: 2 }}
            icon={result.errors.length === 0 ? <CheckCircleIcon /> : undefined}
          >
            {t('dialog.import_complete', 'Import complete:')} {result.created} {t('dialog.import_created', 'created')}, {result.skipped} {t('dialog.import_skipped', 'skipped')}
            {result.errors.length > 0 && `, ${result.errors.length} ${t('dialog.import_errors', 'errors')}`}
            {result.errors.length > 0 && (
              <Box sx={{ mt: 1, maxHeight: 120, overflowY: 'auto' }}>
                {result.errors.slice(0, 10).map((e, i) => (
                  <Typography key={i} variant="body2">
                    Row {e.row}: {e.error}
                  </Typography>
                ))}
                {result.errors.length > 10 && (
                  <Typography variant="body2" sx={{ fontStyle: 'italic' }}>
                    {t('dialog.more_errors', `...and ${result.errors.length - 10} more errors`)}
                  </Typography>
                )}
              </Box>
            )}
          </Alert>
        )}

        {importing && (
          <Box sx={{ mb: 2 }}>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 0.5 }}>
              {progress}
            </Typography>
            <LinearProgress />
          </Box>
        )}

        {/* File selection */}
        {!csvData && !result && (
          <Box
            sx={{
              border: 2,
              borderStyle: 'dashed',
              borderColor: 'divider',
              borderRadius: 2,
              p: 4,
              textAlign: 'center',
            }}
          >
            <FileUploadIcon sx={{ fontSize: 48, color: 'text.secondary', mb: 1 }} />
            <Typography variant="body1" sx={{ mb: 2 }}>
              {t('dialog.select_csv', 'Select a CSV file to import')}
            </Typography>
            <Button variant="contained" component="label">
              {t('ui.choose_file', 'Choose File')}
              <input type="file" accept=".csv" hidden onChange={handleFileSelect} />
            </Button>
          </Box>
        )}

        {/* Field mapping + preview */}
        {csvData && !result && (
          <>
            {/* Field Mapping — CRM-field-centric */}
            <Box sx={{ mb: 2 }}>
              <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1 }}>
                {t('dialog.field_mapping', 'Field Mapping')} — {mappedCount} {t('dialog.of', 'of')} {sortedFields.length} {t('dialog.fields_mapped', 'fields mapped')}
              </Typography>

              {unmappedRequired.length > 0 && (
                <Alert severity="warning" sx={{ mb: 1 }}>
                  {t('dialog.unmapped_required', 'Required fields not mapped:')} {unmappedRequired.map((f) => formatFieldLabel(f, objectType)).join(', ')}
                </Alert>
              )}

              <TableContainer sx={{ maxHeight: 360 }}>
                <Table size="small" stickyHeader>
                  <TableHead>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 600, minWidth: 160 }}>{t('dialog.crm_field', 'CRM Field')}</TableCell>
                      <TableCell sx={{ fontWeight: 600, minWidth: 130 }}>{t('dialog.source', 'Source')}</TableCell>
                      <TableCell sx={{ fontWeight: 600, minWidth: 180 }}>{t('dialog.value', 'Value')}</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {sortedFields.map((field) => {
                      const mapping = fieldMapping[field.name] || { source: 'skip' };
                      return (
                        <TableRow key={field.name}>
                          {/* Field label + required indicator */}
                          <TableCell>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                              <Typography variant="body2">
                                {formatFieldLabel(field, objectType)}
                              </Typography>
                              {field.required && (
                                <Typography variant="body2" color="error.main" sx={{ fontWeight: 700 }}>*</Typography>
                              )}
                            </Box>
                          </TableCell>

                          {/* Source selector */}
                          <TableCell>
                            <TextField
                              select
                              size="small"
                              value={mapping.source}
                              onChange={(e) => handleSourceChange(field.name, e.target.value)}
                              fullWidth
                              sx={{ minWidth: 120 }}
                            >
                              {SOURCE_OPTIONS.map((opt) => (
                                <MenuItem key={opt.value} value={opt.value}>
                                  {t(`dialog.source_${opt.value}`, opt.label)}
                                </MenuItem>
                              ))}
                            </TextField>
                          </TableCell>

                          {/* Value input */}
                          <TableCell>
                            {mapping.source === 'csv' && (
                              <TextField
                                select
                                size="small"
                                value={mapping.csvHeader || ''}
                                onChange={(e) => handleCsvHeaderChange(field.name, e.target.value)}
                                fullWidth
                                sx={{ minWidth: 160 }}
                                SelectProps={{ displayEmpty: true }}
                              >
                                <MenuItem value="">
                                  <em>{t('dialog.select_column', 'Select column...')}</em>
                                </MenuItem>
                                {csvData.headers.map((h) => (
                                  <MenuItem
                                    key={h}
                                    value={h}
                                    disabled={usedCsvHeaders.has(h) && mapping.csvHeader !== h}
                                  >
                                    {h}
                                  </MenuItem>
                                ))}
                              </TextField>
                            )}
                            {mapping.source === 'fixed' && field.type === 'enum' && field.values ? (
                              <TextField
                                select
                                size="small"
                                value={mapping.value || ''}
                                onChange={(e) => handleFixedValueChange(field.name, e.target.value)}
                                fullWidth
                                sx={{ minWidth: 160 }}
                                SelectProps={{ displayEmpty: true }}
                              >
                                <MenuItem value="">
                                  <em>{t('dialog.select_value', 'Select value...')}</em>
                                </MenuItem>
                                {field.values.map((v) => (
                                  <MenuItem key={v} value={v}>{v}</MenuItem>
                                ))}
                              </TextField>
                            ) : mapping.source === 'fixed' ? (
                              <TextField
                                size="small"
                                value={mapping.value || ''}
                                onChange={(e) => handleFixedValueChange(field.name, e.target.value)}
                                fullWidth
                                sx={{ minWidth: 160 }}
                                placeholder={t('dialog.enter_value', 'Enter value...')}
                              />
                            ) : null}
                            {mapping.source === 'skip' && (
                              <Typography variant="body2" color="text.disabled" sx={{ fontStyle: 'italic', py: 0.5 }}>
                                —
                              </Typography>
                            )}
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              </TableContainer>
            </Box>

            {/* CSV Preview */}
            <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 1 }}>
              {t('dialog.preview', 'Preview')} ({t('dialog.first', 'first')} {Math.min(5, csvData.rows.length)} {t('dialog.of', 'of')} {csvData.rows.length} {t('dialog.rows', 'rows')})
            </Typography>
            <TableContainer sx={{ maxHeight: 200, mb: 1 }}>
              <Table size="small" stickyHeader>
                <TableHead>
                  <TableRow>
                    {csvData.headers.map((h) => (
                      <TableCell key={h} sx={{ fontWeight: 600, whiteSpace: 'nowrap' }}>
                        {h}
                      </TableCell>
                    ))}
                  </TableRow>
                </TableHead>
                <TableBody>
                  {csvData.rows.slice(0, 5).map((row, i) => (
                    <TableRow key={i}>
                      {csvData.headers.map((h) => (
                        <TableCell key={h}>
                          <Typography variant="body2" noWrap sx={{ maxWidth: 200 }}>
                            {row[h] || ''}
                          </Typography>
                        </TableCell>
                      ))}
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          </>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={handleClose} disabled={importing}>
          {result ? t('ui.close', 'Close') : t('ui.cancel', 'Cancel')}
        </Button>
        {csvData && !result && (
          <Button
            variant="contained"
            onClick={handleImport}
            disabled={importing || mappedCount === 0 || unmappedRequired.length > 0}
          >
            {t('dialog.import_records', `Import ${csvData.rows.length} Records`)}
          </Button>
        )}
      </DialogActions>
    </Dialog>
  );
}
