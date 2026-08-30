import { useState } from 'react';
import useMediaQuery from '@mui/material/useMediaQuery';
import { useTheme } from '@mui/material/styles';
import Dialog from '@mui/material/Dialog';
import DialogTitle from '@mui/material/DialogTitle';
import DialogContent from '@mui/material/DialogContent';
import DialogActions from '@mui/material/DialogActions';
import Button from '@mui/material/Button';
import Typography from '@mui/material/Typography';
import TextField from '@mui/material/TextField';
import Box from '@mui/material/Box';
import Checkbox from '@mui/material/Checkbox';
import FormControlLabel from '@mui/material/FormControlLabel';
import Divider from '@mui/material/Divider';
import Alert from '@mui/material/Alert';
import CircularProgress from '@mui/material/CircularProgress';
import PersonIcon from '@mui/icons-material/Person';
import BusinessIcon from '@mui/icons-material/Business';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import DataService from '../../services/DataService';
import { useAuth } from '../../contexts/AuthContext';
import { t } from '../../services/TranslationService';

/**
 * Dialog for converting a Lead into Contact + Account + optionally Opportunity.
 */
export default function LeadConvertDialog({ open, onClose, lead, onConverted }) {
  const theme = useTheme();
  const fullScreen = useMediaQuery(theme.breakpoints.down('sm'));
  const { userProfile } = useAuth();
  const fullName = `${lead?.first_name || ''} ${lead?.last_name || ''}`.trim();

  const [accountName, setAccountName] = useState(lead?.company || '');
  const [createOpportunity, setCreateOpportunity] = useState(false);
  const [opportunityName, setOpportunityName] = useState(fullName ? `Opportunity — ${fullName}` : '');
  const [converting, setConverting] = useState(false);
  const [error, setError] = useState(null);

  const handleConvert = async () => {
    if (!accountName.trim()) {
      setError(t('dialog.account_name_required', 'Account name is required.'));
      return;
    }
    if (createOpportunity && !opportunityName.trim()) {
      setError(t('dialog.opportunity_name_required', 'Opportunity name is required when creating an opportunity.'));
      return;
    }

    setConverting(true);
    setError(null);

    try {
      const ownerId = lead.owner_id || userProfile?.id;

      // Helper: omit falsy values so Firestore never receives undefined
      const clean = (obj) => Object.fromEntries(
        Object.entries(obj).filter(([, v]) => v !== undefined && v !== null && v !== '')
      );

      // 1. Create Account
      const account = await DataService.create('Account', clean({
        name1: accountName.trim(),
        phone: lead.phone,
        email: lead.email,
        website: lead.website,
        owner_id: ownerId,
        status: 'Active',
      }));

      // 2. Create Contact (linked to the new account)
      const contact = await DataService.create('Contact', clean({
        first_name: lead.first_name,
        last_name: lead.last_name,
        email: lead.email,
        phone: lead.phone,
        mobile: lead.mobile,
        position: lead.position,
        account_id: account.id,
        owner_id: ownerId,
        status: 'Active',
      }));

      // 3. Create ContactAccount junction record
      await DataService.create('ContactAccount', {
        contact_id: contact.id,
        account_id: account.id,
        is_primary: true,
      });

      // 4. Optionally create Opportunity
      let opportunity = null;
      if (createOpportunity) {
        // Find or create a default pipeline stage
        let stages = await DataService.list('PipelineStage', { pageSize: 1 });
        let stageId;
        if (stages.length > 0) {
          stageId = stages[0].id;
        } else {
          const stage = await DataService.create('PipelineStage', {
            name: 'Prospecting',
            sort_order: 1,
            is_closed: false,
            is_won: false,
            active: true,
          });
          stageId = stage.id;
        }

        opportunity = await DataService.create('Opportunity', {
          name: opportunityName.trim(),
          account_id: account.id,
          lead_id: lead.id,
          stage_id: stageId,
          result: 'Open',
          currency: 'USD',
          owner_id: ownerId,
        });

        // Link contact to opportunity via junction
        await DataService.create('OpportunityContact', {
          opportunity_id: opportunity.id,
          contact_id: contact.id,
          role: 'Primary',
        });
      }

      // 5. Update Lead with conversion data
      await DataService.update('Lead', lead.id, {
        status: 'Converted',
        converted_at: new Date().toISOString(),
        converted_account_id: account.id,
        converted_contact_id: contact.id,
        converted_opportunity_id: opportunity?.id || null,
      });

      onConverted({
        account,
        contact,
        opportunity,
      });
    } catch (err) {
      setError(err.message || t('dialog.conversion_failed', 'Conversion failed. Please try again.'));
      setConverting(false);
    }
  };

  if (!lead) return null;

  return (
    <Dialog open={open} onClose={converting ? undefined : onClose} maxWidth="sm" fullWidth fullScreen={fullScreen}>
      <DialogTitle>{t('dialog.convert_lead', 'Convert Lead')}</DialogTitle>
      <DialogContent>
        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
          {t('dialog.convert_description', 'Converting this lead will create the following records:')}
        </Typography>

        {/* Contact section — read-only preview */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
          <PersonIcon color="primary" fontSize="small" />
          <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>{t('dialog.contact', 'Contact')}</Typography>
        </Box>
        <Box sx={{ pl: 4, mb: 2 }}>
          <Typography variant="body2">
            {fullName}
            {lead.email ? ` — ${lead.email}` : ''}
          </Typography>
          {lead.position && (
            <Typography variant="body2" color="text.secondary">{lead.position}</Typography>
          )}
          {(lead.phone || lead.mobile) && (
            <Typography variant="body2" color="text.secondary">
              {[lead.phone, lead.mobile].filter(Boolean).join(' / ')}
            </Typography>
          )}
        </Box>

        <Divider sx={{ mb: 2 }} />

        {/* Account section — editable name */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
          <BusinessIcon color="primary" fontSize="small" />
          <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>{t('dialog.account', 'Account')}</Typography>
        </Box>
        <Box sx={{ pl: 4, mb: 2 }}>
          <TextField
            fullWidth
            size="small"
            label={t('dialog.account_name', 'Account Name')}
            value={accountName}
            onChange={(e) => setAccountName(e.target.value)}
            required
            error={!accountName.trim() && !!error}
          />
        </Box>

        <Divider sx={{ mb: 2 }} />

        {/* Opportunity section — opt-in */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
          <TrendingUpIcon color="primary" fontSize="small" />
          <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>{t('dialog.opportunity', 'Opportunity')}</Typography>
        </Box>
        <Box sx={{ pl: 4 }}>
          <FormControlLabel
            control={
              <Checkbox
                checked={createOpportunity}
                onChange={(e) => setCreateOpportunity(e.target.checked)}
              />
            }
            label={t('dialog.create_opportunity', 'Create an opportunity')}
          />
          {createOpportunity && (
            <TextField
              fullWidth
              size="small"
              label={t('dialog.opportunity_name', 'Opportunity Name')}
              value={opportunityName}
              onChange={(e) => setOpportunityName(e.target.value)}
              required
              sx={{ mt: 1 }}
            />
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
          {converting ? t('ui.converting', 'Converting...') : t('ui.convert', 'Convert')}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
