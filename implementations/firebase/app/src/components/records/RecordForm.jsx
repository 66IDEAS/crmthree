import { useState, useMemo } from 'react';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import Grid from '@mui/material/Grid';
import Collapse from '@mui/material/Collapse';
import Alert from '@mui/material/Alert';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import ExpandLessIcon from '@mui/icons-material/ExpandLess';
import ModelRegistry from '../../model/ModelRegistry';
import { validateField } from '../../model/validators';
import FieldInput from '../fields/FieldInput';
import { formatFieldLabel } from '../../utils/fieldUtils';
import { t } from '../../services/TranslationService';

/**
 * Generic create/edit form with progressive disclosure.
 * Required fields always visible; optional fields in a collapsible section.
 * Fields in defaultValues are pre-filled and hidden from the form.
 */
export default function RecordForm({ objectType, initialData, defaultValues = {}, onSubmit, onCancel, loading }) {
  const hiddenFieldNames = useMemo(
    () => new Set(Object.keys(defaultValues)),
    [defaultValues]
  );

  const allFields = useMemo(() => {
    return ModelRegistry.getSpecificFields(objectType).filter(
      (f) => !f.auto_generated && !f.primary_key
    );
  }, [objectType]);

  // Visible fields exclude those pre-filled via parent context
  const visibleFields = useMemo(
    () => allFields.filter((f) => !hiddenFieldNames.has(f.name)),
    [allFields, hiddenFieldNames]
  );

  const requiredFields = useMemo(() => visibleFields.filter((f) => f.required), [visibleFields]);
  const optionalFields = useMemo(() => visibleFields.filter((f) => !f.required), [visibleFields]);

  // Initialize form values: defaultValues > initialData > field defaults > date auto-init
  const [values, setValues] = useState(() => {
    const init = {};
    const today = new Date().toISOString().split('T')[0];
    allFields.forEach((f) => {
      if (defaultValues[f.name] !== undefined) {
        init[f.name] = defaultValues[f.name];
      } else if (initialData && initialData[f.name] !== undefined) {
        init[f.name] = initialData[f.name];
      } else if (f.default !== undefined) {
        init[f.name] = f.default;
      } else if (f.type === 'date' && f.required && !initialData) {
        init[f.name] = today;
      } else {
        init[f.name] = '';
      }
    });
    return init;
  });

  const [errors, setErrors] = useState({});
  const [showOptional, setShowOptional] = useState(!!initialData);
  const [submitError, setSubmitError] = useState(null);

  const handleChange = (fieldName, value) => {
    setValues((prev) => ({ ...prev, [fieldName]: value }));
    // Clear field error on change
    if (errors[fieldName]) {
      setErrors((prev) => {
        const next = { ...prev };
        delete next[fieldName];
        return next;
      });
    }
  };

  const handleBlur = (field) => {
    const result = validateField(objectType, field.name, values[field.name]);
    if (!result.valid) {
      setErrors((prev) => ({ ...prev, [field.name]: result.error }));
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitError(null);

    // Validate all fields (including hidden ones — they have values from defaults)
    const newErrors = {};
    allFields.forEach((field) => {
      const result = validateField(objectType, field.name, values[field.name]);
      if (!result.valid) {
        newErrors[field.name] = result.error;
      }
    });

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      // If errors are in optional fields, expand the section
      if (optionalFields.some((f) => newErrors[f.name])) {
        setShowOptional(true);
      }
      return;
    }

    // Clean up empty strings to undefined
    const cleanData = {};
    Object.entries(values).forEach(([key, val]) => {
      if (val !== '' && val !== null) {
        cleanData[key] = val;
      }
    });

    try {
      await onSubmit(cleanData);
    } catch (err) {
      setSubmitError(err.message || t('form.save_error', 'An error occurred while saving.'));
    }
  };

  const renderFields = (fields) => (
    <Grid container spacing={2}>
      {fields.map((field) => (
        <Grid key={field.name} size={{ xs: 12, sm: 6 }}>
          <FieldInput
            field={field}
            value={values[field.name]}
            onChange={(val) => handleChange(field.name, val)}
            error={errors[field.name]}
            helperText={errors[field.name]}
            onBlur={() => handleBlur(field)}
          />
        </Grid>
      ))}
    </Grid>
  );

  return (
    <Box component="form" onSubmit={handleSubmit} noValidate>
      {submitError && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {submitError}
        </Alert>
      )}

      <Paper sx={{ p: 3, mb: 2 }}>
        <Typography variant="h6" sx={{ mb: 2, fontWeight: 600 }}>
          {t('section.required_information', 'Required Information')}
        </Typography>
        {renderFields(requiredFields)}
      </Paper>

      {optionalFields.length > 0 && (
        <Paper sx={{ p: 3, mb: 2 }}>
          <Button
            onClick={() => setShowOptional(!showOptional)}
            endIcon={showOptional ? <ExpandLessIcon /> : <ExpandMoreIcon />}
            sx={{ mb: showOptional ? 2 : 0, textTransform: 'none' }}
          >
            {showOptional ? t('form.show_fewer', 'Show fewer fields') : `${t('form.show_more', 'Show all fields')} (${optionalFields.length} more)`}
          </Button>
          <Collapse in={showOptional}>
            {renderFields(optionalFields)}
          </Collapse>
        </Paper>
      )}

      <Box sx={{ display: 'flex', gap: 2, justifyContent: 'flex-end' }}>
        <Button variant="outlined" onClick={onCancel} disabled={loading}>
          {t('ui.cancel', 'Cancel')}
        </Button>
        <Button variant="contained" type="submit" disabled={loading}>
          {loading ? t('ui.saving', 'Saving...') : initialData ? t('ui.save_changes', 'Save Changes') : t('ui.create', 'Create')}
        </Button>
      </Box>
    </Box>
  );
}
