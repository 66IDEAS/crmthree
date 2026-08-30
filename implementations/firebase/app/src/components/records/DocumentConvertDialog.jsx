import { useState, useEffect } from 'react';
import useMediaQuery from '@mui/material/useMediaQuery';
import { useTheme } from '@mui/material/styles';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import Button from '@mui/material/Button';
import Typography from '@mui/material/Typography';
import Alert from '@mui/material/Alert';
import CircularProgress from '@mui/material/CircularProgress';
import Box from '@mui/material/Box';
import Divider from '@mui/material/Divider';
import DataService from '../../services/DataService';
import { getObjectLabel, getDisplayName } from '../../utils/fieldUtils';
import ModelRegistry from '../../model/ModelRegistry';
import { t } from '../../services/TranslationService';

/**
 * UX32: Generic document-to-document conversion dialog.
 * Copies mapped fields and optionally copies all line items from source to target.
 */
export default function DocumentConvertDialog({
  open,
  onClose,
  sourceRecord,
  sourceType,
  targetType,
  fieldMap,
  setFields,
  copyLineItems,
  onConverted,
}) {
  const theme = useTheme();
  const fullScreen = useMediaQuery(theme.breakpoints.down('sm'));
  const [lineItemCount, setLineItemCount] = useState(0);
  const [converting, setConverting] = useState(false);
  const [error, setError] = useState(null);
  const [accountName, setAccountName] = useState('');

  const sourceLabel = getObjectLabel(sourceType).replace(/s$/, '');
  const targetLabel = getObjectLabel(targetType).replace(/s$/, '');

  const sourceFields = ModelRegistry.getSpecificFields(sourceType);
  const sourceName = getDisplayName(sourceRecord, sourceFields);

  // Count source line items and resolve account name on open
  useEffect(() => {
    if (!open || !sourceRecord) return;

    if (copyLineItems) {
      DataService.list('LineItem', {
        filters: [
          { field: 'parent_id', op: '==', value: sourceRecord.id },
          { field: 'parent_type', op: '==', value: sourceType },
        ],
      })
        .then((items) => setLineItemCount(items.length))
        .catch(() => setLineItemCount(0));
    }

    if (sourceRecord.account_id) {
      DataService.getById('Account', sourceRecord.account_id)
        .then((acc) => {
          if (acc) {
            const accFields = ModelRegistry.getSpecificFields('Account');
            setAccountName(getDisplayName(acc, accFields) || '');
          }
        })
        .catch(() => {});
    }
  }, [open, sourceRecord, sourceType, copyLineItems]);

  const handleConvert = async () => {
    setConverting(true);
    setError(null);

    try {
      // Build target record — copy mapped fields from source
      const data = {};
      for (const [targetField, sourceField] of Object.entries(fieldMap || {})) {
        const val = sourceRecord[sourceField];
        if (val !== undefined && val !== null && val !== '') {
          data[targetField] = val;
        }
      }

      // Apply computed / static fields
      for (const [targetField, value] of Object.entries(setFields || {})) {
        data[targetField] = typeof value === 'function' ? value(sourceRecord) : value;
      }

      // Create target record
      const newRecord = await DataService.create(targetType, data);

      // Copy line items
      if (copyLineItems) {
        const lineItems = await DataService.list('LineItem', {
          filters: [
            { field: 'parent_id', op: '==', value: sourceRecord.id },
            { field: 'parent_type', op: '==', value: sourceType },
          ],
        });

        const clean = (obj) =>
          Object.fromEntries(
            Object.entries(obj).filter(([, v]) => v !== undefined && v !== null && v !== '')
          );

        for (const item of lineItems) {
          await DataService.create(
            'LineItem',
            clean({
              parent_id: newRecord.id,
              parent_type: targetType,
              item_number: item.item_number,
              product_id: item.product_id,
              quantity: item.quantity,
              unit_price: item.unit_price,
              discount_percent: item.discount_percent,
              total_price: item.total_price,
              unit_of_measure: item.unit_of_measure,
              comment: item.comment,
              alternative_to: item.alternative_to,
            })
          );
        }
      }

      onConverted(newRecord);
    } catch (err) {
      setError(err.message || t('dialog.conversion_failed', 'Conversion failed. Please try again.'));
      setConverting(false);
    }
  };

  return (
    <Dialog open={open} onClose={converting ? undefined : onClose} maxWidth="sm" fullWidth fullScreen={fullScreen}>
      <DialogTitle>
        {t('dialog.create_from', `Create ${targetLabel} from ${sourceLabel}`)}
      </DialogTitle>
      <DialogContent>
        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
          {t('dialog.create_from_description', `This will create a new ${targetLabel} based on this ${sourceLabel}.`)}
        </Typography>

        <Box sx={{ mb: 2 }}>
          <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 0.5 }}>
            {t('dialog.source', 'Source')}
          </Typography>
          <Typography variant="body2">{sourceName || sourceLabel}</Typography>
          {accountName && (
            <Typography variant="body2" color="text.secondary">
              Account: {accountName}
            </Typography>
          )}
        </Box>

        <Divider sx={{ mb: 2 }} />

        <Box>
          <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 0.5 }}>
            {t('dialog.what_created', 'What will be created')}
          </Typography>
          <Typography variant="body2">
            &bull; New {targetLabel} record with copied fields
          </Typography>
          {copyLineItems && lineItemCount > 0 && (
            <Typography variant="body2">
              &bull; {lineItemCount} line item{lineItemCount !== 1 ? 's' : ''} will be copied
            </Typography>
          )}
          {copyLineItems && lineItemCount === 0 && (
            <Typography variant="body2" color="text.secondary">
              &bull; {t('dialog.no_line_items', 'No line items to copy')}
            </Typography>
          )}
        </Box>
      </DialogContent>

      <DialogActions sx={{ px: 3, pb: 2 }}>
        <Button onClick={onClose} disabled={converting}>
          {t('ui.cancel', 'Cancel')}
        </Button>
        <Button
          variant="contained"
          onClick={handleConvert}
          disabled={converting}
          startIcon={converting ? <CircularProgress size={16} /> : null}
        >
          {converting ? t('ui.creating', 'Creating...') : t('dialog.create_target', `Create ${targetLabel}`)}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
