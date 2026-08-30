import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Tooltip from '@mui/material/Tooltip';
import PhoneIcon from '@mui/icons-material/Phone';
import EmailIcon from '@mui/icons-material/Email';
import EventIcon from '@mui/icons-material/Event';
import TaskIcon from '@mui/icons-material/Task';
import DescriptionIcon from '@mui/icons-material/Description';
import ShoppingCartIcon from '@mui/icons-material/ShoppingCart';
import ReceiptIcon from '@mui/icons-material/Receipt';
import TransformIcon from '@mui/icons-material/Transform';
import { useNavigate } from 'react-router';
import { resolveSlug } from '../../config/navigation';
import { t } from '../../services/TranslationService';

/**
 * Maps object types to the Activity foreign key field that links to them.
 */
const ACTIVITY_FK_MAP = {
  Account: 'account_id',
  Contact: 'contact_id',
  Lead: 'lead_id',
  Opportunity: 'opportunity_id',
  Ticket: 'ticket_id',
};

/** Object types that support activity quick actions */
const ACTIVITY_TYPES = new Set(Object.keys(ACTIVITY_FK_MAP));

/** Document conversion quick actions per object type */
const CONVERSION_ACTIONS = {
  Opportunity: [
    { targetType: 'Quotation', labelKey: 'action.new_quote', labelFallback: 'New Quote', icon: DescriptionIcon },
    { targetType: 'SalesOrder', labelKey: 'action.new_sales_order', labelFallback: 'New Sales Order', icon: ShoppingCartIcon },
  ],
  Quotation: [
    { targetType: 'SalesOrder', labelKey: 'action.new_sales_order', labelFallback: 'New Sales Order', icon: ShoppingCartIcon },
  ],
  SalesOrder: [
    { targetType: 'Invoice', labelKey: 'action.new_invoice', labelFallback: 'New Invoice', icon: ReceiptIcon },
  ],
};

/**
 * UX8 + F45: Quick Action Bar with contextual action buttons.
 * Renders below the record detail header, above the details card.
 * Shows activity actions (Log Call, Email, Meeting, Task) and
 * type-specific conversion actions (New Quote, New Sales Order, etc.).
 */
export default function QuickActionBar({ objectType, record, onConvert, onLeadConvert }) {
  const navigate = useNavigate();

  if (!record) return null;

  const supportsActivities = ACTIVITY_TYPES.has(objectType);
  const conversionActions = CONVERSION_ACTIONS[objectType] || [];
  const isLead = objectType === 'Lead';
  const isConverted = isLead && record.status === 'Converted';

  // If no actions at all, don't render
  if (!supportsActivities && conversionActions.length === 0 && !isLead) return null;

  const activitySlug = resolveSlug('Activity');

  const buildActivityUrl = (activityType) => {
    const params = new URLSearchParams();
    params.set('type', activityType);
    params.set('status', 'Planned');

    // Link to the current record
    const fk = ACTIVITY_FK_MAP[objectType];
    if (fk) params.set(fk, record.id);

    // Also propagate account_id if the current record has one (for Contact, Lead, Opportunity, Ticket)
    if (objectType !== 'Account' && record.account_id) {
      params.set('account_id', record.account_id);
    }

    // Also propagate contact_id if available (for Opportunity, Ticket)
    if (objectType !== 'Contact' && objectType !== 'Lead' && record.contact_id) {
      params.set('contact_id', record.contact_id);
    }

    const parentSlug = resolveSlug(objectType);
    if (parentSlug) {
      params.set('_returnTo', `/${parentSlug}/${record.id}`);
    }

    return `/${activitySlug}/new?${params.toString()}`;
  };

  return (
    <Box sx={{ display: 'flex', gap: 1, mb: 2, flexWrap: 'wrap' }}>
      {/* Activity actions */}
      {supportsActivities && activitySlug && [
        { label: t('action.log_call', 'Log Call'), icon: PhoneIcon, url: buildActivityUrl('Call') },
        { label: t('action.log_email', 'Log Email'), icon: EmailIcon, url: buildActivityUrl('Email') },
        { label: t('action.log_meeting', 'Log Meeting'), icon: EventIcon, url: buildActivityUrl('Meeting') },
        { label: t('action.new_task', 'New Task'), icon: TaskIcon, url: buildActivityUrl('Task') },
      ].map((action) => {
        const Icon = action.icon;
        return (
          <Button
            key={action.label}
            variant="outlined"
            size="small"
            startIcon={<Icon />}
            onClick={() => navigate(action.url)}
            sx={{ textTransform: 'none' }}
          >
            {action.label}
          </Button>
        );
      })}

      {/* Lead Convert action */}
      {isLead && onLeadConvert && (
        <Tooltip title={isConverted ? t('dialog.already_converted', 'Already converted') : t('dialog.convert_tooltip', 'Convert to Contact, Account & Opportunity')}>
          <span>
            <Button
              variant="outlined"
              size="small"
              startIcon={<TransformIcon />}
              onClick={onLeadConvert}
              disabled={isConverted}
              sx={{ textTransform: 'none' }}
            >
              {t('ui.convert', 'Convert')}
            </Button>
          </span>
        </Tooltip>
      )}

      {/* Document conversion actions */}
      {conversionActions.map((conv) => {
        const Icon = conv.icon;
        return (
          <Button
            key={conv.targetType}
            variant="outlined"
            size="small"
            startIcon={<Icon />}
            onClick={() => onConvert?.(conv.targetType)}
            sx={{ textTransform: 'none' }}
          >
            {t(conv.labelKey, conv.labelFallback)}
          </Button>
        );
      })}
    </Box>
  );
}
