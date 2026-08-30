import { useState, useEffect } from 'react';
import Typography from '@mui/material/Typography';
import Chip from '@mui/material/Chip';
import Link from '@mui/material/Link';
import { Link as RouterLink } from 'react-router';
import DataService from '../../services/DataService';
import { resolveSlug } from '../../config/navigation';
import ModelRegistry from '../../model/ModelRegistry';
import { getPrimaryDisplayField, formatAutoNumber } from '../../utils/fieldUtils';
import { t } from '../../services/TranslationService';

/**
 * Read-only field renderer. Maps field.type to an appropriate display component.
 */
export default function FieldRenderer({ field, value }) {
  if (value === null || value === undefined || value === '') {
    return (
      <Typography variant="body2" color="text.secondary">
        —
      </Typography>
    );
  }

  switch (field.type) {
    case 'boolean':
      return (
        <Chip
          label={value ? t('ui.yes', 'Yes') : t('ui.no', 'No')}
          size="small"
          color={value ? 'success' : 'default'}
        />
      );

    case 'enum':
      return <Chip label={t(`enum.${value}`, value)} size="small" color={getEnumChipColor(value)} />;

    case 'currency':
      return (
        <Typography variant="body2" color="text.primary">
          {typeof value === 'number' ? value.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : value}
        </Typography>
      );

    case 'decimal':
      return (
        <Typography variant="body2" color="text.primary">
          {typeof value === 'number'
            ? value.toLocaleString(undefined, {
                minimumFractionDigits: field.scale || 0,
                maximumFractionDigits: field.scale || 2,
              })
            : value}
        </Typography>
      );

    case 'integer':
      return (
        <Typography variant="body2" color="text.primary">
          {typeof value === 'number' ? value.toLocaleString() : value}
        </Typography>
      );

    case 'date':
      return (
        <Typography variant="body2" color="text.primary">
          {formatDate(value)}
        </Typography>
      );

    case 'datetime':
      return (
        <Typography variant="body2" color="text.primary">
          {formatDateTime(value)}
        </Typography>
      );

    case 'reference':
      return <ReferenceDisplay field={field} value={value} />;

    case 'text':
      return (
        <Typography variant="body2" color="text.primary" sx={{ whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}>
          {value}
        </Typography>
      );

    default:
      if (field.auto_generated && field.name.endsWith('_number')) {
        return <Typography variant="body2" color="text.primary">{formatAutoNumber(value)}</Typography>;
      }
      if (isUrl(value) || (field.name === 'website' && value)) {
        return (
          <Link href={value.startsWith('http') ? value : `https://${value}`} target="_blank" rel="noopener noreferrer" underline="hover" variant="body2">
            {value}
          </Link>
        );
      }
      return <Typography variant="body2" color="text.primary">{String(value)}</Typography>;
  }
}

function ReferenceDisplay({ field, value }) {
  const [displayName, setDisplayName] = useState(null);
  const slug = resolveSlug(field.target);

  useEffect(() => {
    let cancelled = false;
    if (!value || !field.target) return;

    DataService.getById(field.target, value)
      .then((record) => {
        if (cancelled || !record) return;
        const targetFields = ModelRegistry.hasObject(field.target)
          ? ModelRegistry.getSpecificFields(field.target)
          : [];
        const primaryField = getPrimaryDisplayField(targetFields);
        if (primaryField === 'first_name+last_name') {
          setDisplayName([record.first_name, record.last_name].filter(Boolean).join(' '));
        } else {
          setDisplayName(record[primaryField] || value);
        }
      })
      .catch(() => {
        if (!cancelled) setDisplayName(value);
      });

    return () => { cancelled = true; };
  }, [field.target, value]);

  if (!slug) {
    return <Typography variant="body2">{displayName || value}</Typography>;
  }

  return (
    <Link component={RouterLink} to={`/${slug}/${value}`} underline="hover" variant="body2">
      {displayName || value}
    </Link>
  );
}

const ENUM_COLORS = {
  // Positive / success
  Active: 'success',
  Completed: 'success',
  Won: 'success',
  Paid: 'success',
  Accepted: 'success',
  Published: 'success',
  Qualified: 'success',
  Converted: 'success',
  Shipped: 'success',
  // Negative / error
  Inactive: 'error',
  Lost: 'error',
  Rejected: 'error',
  Overdue: 'error',
  Cancelled: 'error',
  Discontinued: 'error',
  Failed: 'error',
  Unqualified: 'error',
  Terminated: 'error',
  Expired: 'error',
  Retired: 'error',
  // Warning / in-progress
  'In Progress': 'warning',
  'In Review': 'warning',
  'In Repair': 'warning',
  'Partially Paid': 'warning',
  Sent: 'warning',
  Contacted: 'warning',
  Confirmed: 'warning',
  // Informational
  New: 'info',
  Draft: 'info',
  Open: 'info',
  Planned: 'info',
  // Priority
  Critical: 'error',
  High: 'error',
  Medium: 'warning',
  Low: 'success',
};

function getEnumChipColor(value) {
  return ENUM_COLORS[value] || 'default';
}

function isUrl(value) {
  if (typeof value !== 'string') return false;
  return /^(https?:\/\/|www\.)\S+/i.test(value);
}

function formatDate(value) {
  if (!value) return '';
  try {
    return new Date(value).toLocaleDateString();
  } catch {
    return value;
  }
}

function formatDateTime(value) {
  if (!value) return '';
  try {
    return new Date(value).toLocaleString();
  } catch {
    return value;
  }
}
