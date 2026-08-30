import { useState, useEffect, useMemo } from 'react';
import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Chip from '@mui/material/Chip';
import CircularProgress from '@mui/material/CircularProgress';
import OpenInNewIcon from '@mui/icons-material/OpenInNew';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import { useNavigate } from 'react-router';
import DataService from '../../services/DataService';
import ModelRegistry from '../../model/ModelRegistry';
import { resolveSlug } from '../../config/navigation';
import { getDisplayName, formatFieldLabel, formatAutoNumber } from '../../utils/fieldUtils';
import FieldRenderer from '../fields/FieldRenderer';
import { t } from '../../services/TranslationService';

/**
 * F58: Compact card showing a single parent record that the current record references.
 * Auto-detected from reference fields pointing to navigable object types.
 */
export default function ParentRecordCard({ fieldDef, recordId }) {
  const navigate = useNavigate();
  const [parentRecord, setParentRecord] = useState(null);
  const [loading, setLoading] = useState(true);

  const targetType = fieldDef.target;
  const targetSlug = resolveSlug(targetType);

  const targetFields = useMemo(() => {
    if (!ModelRegistry.hasObject(targetType)) return [];
    return ModelRegistry.getSpecificFields(targetType);
  }, [targetType]);

  // Show up to 4 key fields from the parent
  const displayFields = useMemo(() => {
    return targetFields
      .filter((f) => !f.primary_key && !f.auto_generated && f.type !== 'text')
      .slice(0, 4);
  }, [targetFields]);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    DataService.getById(targetType, recordId)
      .then((rec) => {
        if (!cancelled) setParentRecord(rec);
      })
      .catch(() => {})
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => { cancelled = true; };
  }, [targetType, recordId]);

  if (loading) {
    return (
      <Paper variant="outlined" sx={{ p: 1.5, display: 'flex', alignItems: 'center', gap: 1 }}>
        <CircularProgress size={16} />
        <Typography variant="body2" color="text.secondary">
          Loading {formatFieldLabel(fieldDef).replace(' Id', '')}...
        </Typography>
      </Paper>
    );
  }

  if (!parentRecord) return null;

  const displayName = getDisplayName(parentRecord, targetFields);
  const label = formatFieldLabel(fieldDef).replace(' Id', '');

  return (
    <Paper
      variant="outlined"
      sx={{
        p: 1.5,
        display: 'flex',
        alignItems: 'center',
        gap: 1.5,
        cursor: targetSlug ? 'pointer' : 'default',
        '&:hover': targetSlug ? { bgcolor: 'action.hover' } : {},
        flexWrap: 'wrap',
      }}
      onClick={() => targetSlug && navigate(`/${targetSlug}/${recordId}`)}
    >
      <Chip label={label} size="small" color="primary" variant="outlined" />
      <Typography variant="subtitle2" sx={{ fontWeight: 600, minWidth: 0 }} noWrap>
        {displayName || t('ui.untitled', 'Untitled')}
      </Typography>
      {displayFields.map((f) => {
        const val = parentRecord[f.name];
        if (val === null || val === undefined || val === '') return null;
        return (
          <Box key={f.name} sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
            <Typography variant="caption" color="text.secondary" noWrap>
              {formatFieldLabel(f, targetType)}:
            </Typography>
            <Typography variant="body2" noWrap sx={{ maxWidth: 150 }}>
              <FieldRenderer field={f} value={val} compact />
            </Typography>
          </Box>
        );
      })}
      <Box sx={{ flex: 1 }} />
      {targetSlug && (
        <Tooltip title={`Open ${label}`}>
          <IconButton size="small" onClick={(e) => { e.stopPropagation(); navigate(`/${targetSlug}/${recordId}`); }}>
            <OpenInNewIcon fontSize="small" />
          </IconButton>
        </Tooltip>
      )}
    </Paper>
  );
}
