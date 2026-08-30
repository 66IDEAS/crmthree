import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogContentText from '@mui/material/DialogContentText';
import DialogActions from '@mui/material/DialogActions';
import Button from '@mui/material/Button';
import { t } from '../../services/TranslationService';

export default function DeleteConfirmDialog({ open, onCancel, onConfirm, objectTypeLabel, recordName, loading }) {
  return (
    <Dialog open={open} onClose={onCancel} maxWidth="xs" fullWidth>
      <DialogTitle>{t('dialog.delete_title', 'Delete')} {objectTypeLabel}?</DialogTitle>
      <DialogContent>
        <DialogContentText>
          {t('dialog.delete_confirm', 'Are you sure you want to delete')} &quot;{recordName}&quot;? {t('dialog.delete_undone', 'This action cannot be undone.')}
        </DialogContentText>
      </DialogContent>
      <DialogActions>
        <Button onClick={onCancel} disabled={loading}>
          {t('ui.cancel', 'Cancel')}
        </Button>
        <Button onClick={onConfirm} color="error" variant="contained" disabled={loading}>
          {loading ? t('ui.deleting', 'Deleting...') : t('ui.delete', 'Delete')}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
