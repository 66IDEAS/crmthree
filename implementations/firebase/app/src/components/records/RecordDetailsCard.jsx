import { useState, useMemo } from 'react';
import Box from '@mui/material/Box';
import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import Grid from '@mui/material/Grid';
import Button from '@mui/material/Button';
import Collapse from '@mui/material/Collapse';
import Divider from '@mui/material/Divider';
import Alert from '@mui/material/Alert';
import SaveIcon from '@mui/icons-material/Save';
import CancelIcon from '@mui/icons-material/Cancel';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import ExpandLessIcon from '@mui/icons-material/ExpandLess';
import ModelRegistry from '../../model/ModelRegistry';
import { useMutation } from '../../hooks/useDataService';
import { validateField } from '../../model/validators';
import FieldRenderer from '../fields/FieldRenderer';
import FieldInput from '../fields/FieldInput';
import { formatFieldLabel } from '../../utils/fieldUtils';
import { useAuth } from '../../contexts/AuthContext';
import { checkAndCreateNotifications } from '../../services/NotificationTrigger';
import { checkAndAwardXPForUpdate } from '../../services/GamificationTrigger';
import { logFieldChanges } from '../../services/AuditLogService';
import { t } from '../../services/TranslationService';

function isEmpty(value) {
  return value === null || value === undefined || value === '';
}

/**
 * UX9: Object Details Card showing all field values with inline edit support.
 * Edit is triggered from the header — this card only shows Save/Cancel when in edit mode.
 * In read mode, fields without a value are hidden.
 */
export default function RecordDetailsCard({ objectType, record, onRefetch, editing, onEditToggle }) {
  const { update, loading } = useMutation(objectType);
  const { userProfile } = useAuth();

  const specificFields = useMemo(
    () =>
      ModelRegistry.getSpecificFields(objectType).filter(
        (f) => !f.primary_key
      ),
    [objectType]
  );

  const commonFields = useMemo(
    () => ModelRegistry.getCommonFields(),
    []
  );

  const [editValues, setEditValues] = useState({});
  const [errors, setErrors] = useState({});
  const [saveError, setSaveError] = useState(null);
  const [showSystem, setShowSystem] = useState(false);

  // Called from ObjectDetailPage when header Edit button is clicked
  const startEdit = () => {
    const vals = {};
    specificFields.filter((f) => !f.auto_generated).forEach((f) => {
      vals[f.name] = record[f.name] ?? '';
    });
    setEditValues(vals);
    setErrors({});
    setSaveError(null);
    onEditToggle(true);
  };

  // Expose startEdit so the parent can trigger it
  // (We detect when editing transitions from false→true via onEditToggle)
  // The parent sets editing=true, and we initialize edit values via useEffect-like check
  if (editing && Object.keys(editValues).length === 0) {
    const vals = {};
    specificFields.filter((f) => !f.auto_generated).forEach((f) => {
      vals[f.name] = record[f.name] ?? '';
    });
    setEditValues(vals);
  }

  const cancelEdit = () => {
    onEditToggle(false);
    setEditValues({});
    setErrors({});
    setSaveError(null);
  };

  const handleChange = (fieldName, value) => {
    setEditValues((prev) => ({ ...prev, [fieldName]: value }));
    if (errors[fieldName]) {
      setErrors((prev) => {
        const next = { ...prev };
        delete next[fieldName];
        return next;
      });
    }
  };

  const handleSave = async () => {
    const newErrors = {};
    specificFields.forEach((field) => {
      const result = validateField(objectType, field.name, editValues[field.name]);
      if (!result.valid) {
        newErrors[field.name] = result.error;
      }
    });

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    // Only send changed fields (skip auto_generated)
    const changes = {};
    specificFields.filter((f) => !f.auto_generated).forEach((f) => {
      const newVal = editValues[f.name];
      const oldVal = record[f.name];
      if (newVal !== oldVal && !(newVal === '' && (oldVal === undefined || oldVal === null))) {
        changes[f.name] = newVal === '' ? null : newVal;
      }
    });

    if (Object.keys(changes).length === 0) {
      cancelEdit();
      return;
    }

    try {
      await update(record.id, changes);
      // Fire notification and gamification triggers (silent — never blocks save)
      try {
        await checkAndCreateNotifications(objectType, record.id, changes, record, userProfile?.id);
      } catch {
        // Notification creation should never block saves
      }
      try {
        await checkAndAwardXPForUpdate(objectType, record.id, changes, record, userProfile?.id);
      } catch {
        // Gamification should never block saves
      }
      try {
        await logFieldChanges(objectType, record.id, changes, record, userProfile?.id);
      } catch {
        // Audit logging should never block saves
      }
      onEditToggle(false);
      setEditValues({});
      onRefetch();
    } catch (err) {
      setSaveError(err.message || t('misc.failed_save', 'Failed to save changes.'));
    }
  };

  // In read mode, filter out fields with empty values
  const visibleFields = editing
    ? specificFields
    : specificFields.filter((f) => !isEmpty(record[f.name]));

  const visibleCommonFields = commonFields.filter((f) => !isEmpty(record[f.name]));

  return (
    <Paper sx={{ p: 3, mb: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
        <Typography variant="h6" sx={{ fontWeight: 600 }}>
          {t('section.details', 'Details')}
        </Typography>
        {editing && (
          <Box sx={{ display: 'flex', gap: 1 }}>
            <Button
              size="small"
              variant="contained"
              startIcon={<SaveIcon />}
              onClick={handleSave}
              disabled={loading}
            >
              {loading ? t('ui.saving', 'Saving...') : t('ui.save', 'Save')}
            </Button>
            <Button size="small" startIcon={<CancelIcon />} onClick={cancelEdit} disabled={loading}>
              {t('ui.cancel', 'Cancel')}
            </Button>
          </Box>
        )}
      </Box>

      {saveError && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {saveError}
        </Alert>
      )}

      <Grid container spacing={2}>
        {visibleFields.map((field) => (
          <Grid key={field.name} size={{ xs: 12, sm: 6 }}>
            {editing && !field.auto_generated ? (
              <FieldInput
                field={field}
                value={editValues[field.name]}
                onChange={(val) => handleChange(field.name, val)}
                error={errors[field.name]}
                helperText={errors[field.name]}
              />
            ) : (
              <Box>
                <Typography variant="caption" display="block" sx={{ fontWeight: 600, color: 'text.primary' }}>
                  {formatFieldLabel(field, objectType)}
                </Typography>
                <FieldRenderer field={field} value={record[field.name]} />
              </Box>
            )}
          </Grid>
        ))}
      </Grid>

      <Divider sx={{ my: 2 }} />
      <Button
        size="small"
        onClick={() => setShowSystem(!showSystem)}
        endIcon={showSystem ? <ExpandLessIcon /> : <ExpandMoreIcon />}
        sx={{ textTransform: 'none' }}
      >
        {t('section.system_information', 'System Information')}
      </Button>
      <Collapse in={showSystem}>
        <Grid container spacing={2} sx={{ mt: 1 }}>
          {visibleCommonFields.map((field) => (
            <Grid key={field.name} size={{ xs: 12, sm: 6 }}>
              <Box>
                <Typography variant="caption" display="block" sx={{ fontWeight: 600, color: 'text.primary' }}>
                  {formatFieldLabel(field, objectType)}
                </Typography>
                <FieldRenderer field={field} value={record[field.name]} />
              </Box>
            </Grid>
          ))}
        </Grid>
      </Collapse>
    </Paper>
  );
}
