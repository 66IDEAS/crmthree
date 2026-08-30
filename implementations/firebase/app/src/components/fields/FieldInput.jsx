import { useState, useEffect, useCallback, useMemo } from 'react';
import TextField from '@mui/material/TextField';
import MenuItem from '@mui/material/MenuItem';
import Switch from '@mui/material/Switch';
import FormControlLabel from '@mui/material/FormControlLabel';
import Autocomplete from '@mui/material/Autocomplete';
import DataService from '../../services/DataService';
import ModelRegistry from '../../model/ModelRegistry';
import { getPrimaryDisplayField, getDisplayName, formatFieldLabel } from '../../utils/fieldUtils';
import { t } from '../../services/TranslationService';

/**
 * Editable field input. Maps field.type to an appropriate MUI form control.
 */
export default function FieldInput({ field, value, onChange, error, helperText }) {
  switch (field.type) {
    case 'boolean':
      return (
        <FormControlLabel
          control={
            <Switch
              checked={!!value}
              onChange={(e) => onChange(e.target.checked)}
            />
          }
          label={formatFieldLabel(field)}
        />
      );

    case 'enum':
      return (
        <TextField
          select
          fullWidth
          size="small"
          label={formatFieldLabel(field)}
          value={value ?? field.default ?? ''}
          onChange={(e) => onChange(e.target.value)}
          error={!!error}
          helperText={helperText || error}
          required={field.required}
        >
          {!field.required && <MenuItem value="">—</MenuItem>}
          {(field.values || []).map((v) => (
            <MenuItem key={v} value={v}>
              {t(`enum.${v}`, v)}
            </MenuItem>
          ))}
        </TextField>
      );

    case 'text':
      return (
        <TextField
          fullWidth
          multiline
          minRows={2}
          maxRows={6}
          size="small"
          label={formatFieldLabel(field)}
          value={value ?? ''}
          onChange={(e) => onChange(e.target.value)}
          error={!!error}
          helperText={helperText || error}
          required={field.required}
        />
      );

    case 'integer':
      return (
        <TextField
          fullWidth
          type="number"
          size="small"
          label={formatFieldLabel(field)}
          value={value ?? ''}
          onChange={(e) => onChange(e.target.value === '' ? null : parseInt(e.target.value, 10))}
          error={!!error}
          helperText={helperText || error}
          required={field.required}
          slotProps={{ htmlInput: { step: 1 } }}
        />
      );

    case 'decimal':
    case 'currency':
      return (
        <TextField
          fullWidth
          type="number"
          size="small"
          label={formatFieldLabel(field)}
          value={value ?? ''}
          onChange={(e) => onChange(e.target.value === '' ? null : parseFloat(e.target.value))}
          error={!!error}
          helperText={helperText || error}
          required={field.required}
          slotProps={{ htmlInput: { step: field.scale ? Math.pow(10, -field.scale) : 0.01 } }}
        />
      );

    case 'date':
      return (
        <TextField
          fullWidth
          type="date"
          size="small"
          label={formatFieldLabel(field)}
          value={value ?? ''}
          onChange={(e) => onChange(e.target.value)}
          error={!!error}
          helperText={helperText || error}
          required={field.required}
          slotProps={{ inputLabel: { shrink: true } }}
        />
      );

    case 'datetime':
      return (
        <TextField
          fullWidth
          type="datetime-local"
          size="small"
          label={formatFieldLabel(field)}
          value={value ? value.slice(0, 16) : ''}
          onChange={(e) => onChange(e.target.value ? new Date(e.target.value).toISOString() : '')}
          error={!!error}
          helperText={helperText || error}
          required={field.required}
          slotProps={{ inputLabel: { shrink: true } }}
        />
      );

    case 'reference':
      return (
        <ReferenceInput
          field={field}
          value={value}
          onChange={onChange}
          error={error}
          helperText={helperText}
        />
      );

    default:
      return (
        <TextField
          fullWidth
          size="small"
          label={formatFieldLabel(field)}
          value={value ?? ''}
          onChange={(e) => onChange(e.target.value)}
          error={!!error}
          helperText={helperText || error}
          required={field.required}
          slotProps={{ htmlInput: { maxLength: field.length || undefined } }}
        />
      );
  }
}

function ReferenceInput({ field, value, onChange, error, helperText }) {
  const [options, setOptions] = useState([]);
  const [inputValue, setInputValue] = useState('');
  const [selectedOption, setSelectedOption] = useState(null);
  const [loading, setLoading] = useState(false);
  const [initialLoaded, setInitialLoaded] = useState(false);

  const targetFields = useMemo(() => (
    field.target && ModelRegistry.hasObject(field.target)
      ? ModelRegistry.getSpecificFields(field.target)
      : []
  ), [field.target]);

  // Fetch the current value's display name on mount
  useEffect(() => {
    if (!value || !field.target || !ModelRegistry.hasObject(field.target)) return;
    DataService.getById(field.target, value)
      .then((record) => {
        if (record) {
          const label = getDisplayName(record, targetFields);
          setSelectedOption({ id: value, label: label || value });
        }
      })
      .catch(() => {});
  }, [value, field.target, targetFields]);

  // Load initial options (called on focus or first interaction)
  const loadOptions = useCallback(
    async (filterText) => {
      if (!field.target || !ModelRegistry.hasObject(field.target)) return;
      setLoading(true);
      try {
        const results = await DataService.list(field.target, { pageSize: 20 });
        const mapped = results.map((r) => ({
          id: r.id,
          label: getDisplayName(r, targetFields) || r.id,
        }));
        if (filterText) {
          const lower = filterText.toLowerCase();
          setOptions(mapped.filter((o) => o.label.toLowerCase().includes(lower)));
        } else {
          setOptions(mapped);
        }
        setInitialLoaded(true);
      } catch {
        setOptions([]);
      } finally {
        setLoading(false);
      }
    },
    [field.target, targetFields]
  );

  const handleInputChange = useCallback(
    (_event, newInputValue) => {
      setInputValue(newInputValue);
      if (initialLoaded) {
        // Filter already-loaded options client-side
        loadOptions(newInputValue);
      }
    },
    [initialLoaded, loadOptions]
  );

  const handleOpen = useCallback(() => {
    if (!initialLoaded) {
      loadOptions('');
    }
  }, [initialLoaded, loadOptions]);

  return (
    <Autocomplete
      fullWidth
      size="small"
      openOnFocus
      options={options}
      loading={loading}
      value={selectedOption}
      inputValue={inputValue}
      onInputChange={handleInputChange}
      onOpen={handleOpen}
      onChange={(_e, newValue) => {
        setSelectedOption(newValue);
        onChange(newValue?.id || null);
      }}
      getOptionLabel={(option) => option.label || ''}
      isOptionEqualToValue={(option, val) => option.id === val?.id}
      renderInput={(params) => (
        <TextField
          {...params}
          label={formatFieldLabel(field)}
          error={!!error}
          helperText={helperText || error}
          required={field.required}
        />
      )}
    />
  );
}
