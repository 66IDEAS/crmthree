import { useMemo } from 'react';
import Box from '@mui/material/Box';
import Typography from '@mui/material/Typography';
import Stack from '@mui/material/Stack';
import ModelRegistry from '../../model/ModelRegistry';
import { resolveSlug } from '../../config/navigation';
import LinkedRecordCard from './LinkedRecordCard';
import LineItemsCard from './LineItemsCard';
import ParentRecordCard from './ParentRecordCard';
import { t } from '../../services/TranslationService';

/** Reference fields to exclude from parent cards (internal/owner refs, not navigable parents) */
const EXCLUDED_REFS = new Set([
  'owner_id', 'assigned_to', 'created_by', 'updated_by',
  'stage_id', 'status_id', 'sla_id',
  'converted_account_id', 'converted_contact_id', 'converted_opportunity_id',
]);

/**
 * UX10 + F58: Renders parent reference cards and child linked record cards.
 * Parent cards appear first, showing single referenced parent records.
 * Child cards show one-to-many and many-to-many relationships.
 */
export default function LinkedRecordsSection({ objectType, recordId, record }) {
  const relationships = useMemo(
    () => ModelRegistry.getRelationships(objectType),
    [objectType]
  );

  // F58: Detect reference fields that point to navigable parent objects
  const parentRefs = useMemo(() => {
    if (!record) return [];
    const fields = ModelRegistry.getSpecificFields(objectType);
    return fields.filter((f) => {
      if (f.type !== 'reference' || !f.target) return false;
      if (EXCLUDED_REFS.has(f.name)) return false;
      // Only show if the target has a navigable slug and the field has a value
      if (!resolveSlug(f.target)) return false;
      if (!record[f.name]) return false;
      return true;
    });
  }, [objectType, record]);

  const hasRelationships = relationships && relationships.length > 0;
  const hasParentRefs = parentRefs.length > 0;

  if (!hasRelationships && !hasParentRefs) return null;

  return (
    <Box sx={{ mb: 3 }}>
      <Typography variant="h6" sx={{ fontWeight: 600, mb: 2 }}>
        {t('section.linked_records', 'Linked Records')}
      </Typography>
      <Stack spacing={2}>
        {parentRefs.map((fieldDef) => (
          <ParentRecordCard
            key={fieldDef.name}
            fieldDef={fieldDef}
            recordId={record[fieldDef.name]}
          />
        ))}
        {relationships.map((rel) =>
          rel.target === 'LineItem' ? (
            <LineItemsCard key={rel.name} relationship={rel} parentId={recordId} parentObjectType={objectType} />
          ) : (
            <LinkedRecordCard key={rel.name} relationship={rel} parentId={recordId} parentObjectType={objectType} />
          )
        )}
      </Stack>
    </Box>
  );
}
