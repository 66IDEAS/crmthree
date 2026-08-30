import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Chip from '@mui/material/Chip';
import Button from '@mui/material/Button';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import LockIcon from '@mui/icons-material/Lock';
import { useNavigate } from 'react-router';
import { getDisplayName, getAutoNumberField, getObjectLabel, formatAutoNumber } from '../../utils/fieldUtils';
import ModelRegistry from '../../model/ModelRegistry';
import { t } from '../../services/TranslationService';
import { useUI } from '../../contexts/UIContext';

/**
 * UX6: Record detail header showing object type, display name, ID, and action buttons.
 */
export default function RecordDetailHeader({ objectType, slug, record, onEdit, onDelete, extraActions, displayNameOverride, lock }) {
  const navigate = useNavigate();
  const { isMobile } = useUI();
  const fields = ModelRegistry.getSpecificFields(objectType);
  const displayName = displayNameOverride || getDisplayName(record, fields);
  const autoNumber = getAutoNumberField(fields);
  const label = getObjectLabel(objectType);

  return (
    <Box
      sx={{
        display: 'flex',
        alignItems: 'center',
        gap: 1,
        mb: 3,
        flexWrap: 'wrap',
        position: 'sticky',
        top: 0,
        zIndex: 2,
        bgcolor: 'background.default',
        py: 1,
      }}
    >
      <Tooltip title={t('ui.back', 'Back')}>
        <IconButton onClick={() => navigate(-1)} size="small">
          <ArrowBackIcon />
        </IconButton>
      </Tooltip>

      <Typography variant={isMobile ? 'h6' : 'h5'} sx={{ fontWeight: 700, flex: 1, minWidth: 0 }} noWrap>
        {displayName || t('ui.untitled', 'Untitled')}
      </Typography>
      {autoNumber && record[autoNumber.name] && (
        <Chip label={formatAutoNumber(record[autoNumber.name])} size="small" variant="outlined" />
      )}

      {lock && (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
          <LockIcon sx={{ fontSize: 16, color: 'warning.main' }} />
          <Typography variant="caption" color="warning.main" sx={{ fontWeight: 600 }}>
            {lock.locked_by_name || 'Someone'} {t('lock.is_editing', 'is editing')}
          </Typography>
        </Box>
      )}

      <Box sx={{ display: 'flex', gap: isMobile ? 0.5 : 1, flexWrap: 'wrap' }}>
        {extraActions}
        {isMobile ? (
          <>
            <Tooltip title={lock ? t('lock.record_locked', 'Record is locked') : t('ui.edit', 'Edit')}>
              <span>
                <IconButton size="small" onClick={onEdit} disabled={!!lock}>
                  <EditIcon fontSize="small" />
                </IconButton>
              </span>
            </Tooltip>
            <Tooltip title={t('ui.delete', 'Delete')}>
              <IconButton size="small" color="error" onClick={onDelete}>
                <DeleteIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          </>
        ) : (
          <>
            <Tooltip title={lock ? t('lock.record_locked', 'Record is locked') : ''}>
              <span>
                <Button variant="outlined" size="small" startIcon={<EditIcon />} onClick={onEdit} disabled={!!lock}>
                  {t('ui.edit', 'Edit')}
                </Button>
              </span>
            </Tooltip>
            <Button variant="outlined" size="small" color="error" startIcon={<DeleteIcon />} onClick={onDelete}>
              {t('ui.delete', 'Delete')}
            </Button>
          </>
        )}
      </Box>
    </Box>
  );
}
