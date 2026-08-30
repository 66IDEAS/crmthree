import { useState, useEffect, useMemo } from 'react';
import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemText from '@mui/material/ListItemText';
import ListItemIcon from '@mui/material/ListItemIcon';
import Chip from '@mui/material/Chip';
import CircularProgress from '@mui/material/CircularProgress';
import AccountTreeIcon from '@mui/icons-material/AccountTree';
import ArrowRightIcon from '@mui/icons-material/ArrowRight';
import SubdirectoryArrowRightIcon from '@mui/icons-material/SubdirectoryArrowRight';
import { useNavigate } from 'react-router';
import ModelRegistry from '../../model/ModelRegistry';
import DataService from '../../services/DataService';
import { useList } from '../../hooks/useDataService';
import { getDisplayName, getAutoNumberField } from '../../utils/fieldUtils';
import { t } from '../../services/TranslationService';

/**
 * Displays parent/child hierarchy for objects with self-referencing reference fields.
 * Generically detects the parent field by looking for reference fields targeting the same objectType.
 */
export default function HierarchyTree({ objectType, slug, record }) {
  const fields = useMemo(() => ModelRegistry.getSpecificFields(objectType), [objectType]);

  // Find self-referencing parent field
  const parentField = useMemo(
    () => fields.find((f) => f.type === 'reference' && f.target === objectType),
    [fields, objectType]
  );

  if (!parentField || !record) return null;

  return (
    <HierarchyContent
      objectType={objectType}
      slug={slug}
      record={record}
      parentField={parentField}
      fields={fields}
    />
  );
}

function HierarchyContent({ objectType, slug, record, parentField, fields }) {
  const navigate = useNavigate();
  const [ancestors, setAncestors] = useState([]);
  const [loadingAncestors, setLoadingAncestors] = useState(false);
  const autoNumber = getAutoNumberField(fields);

  // Fetch ancestor chain
  useEffect(() => {
    let cancelled = false;
    const parentValue = record[parentField.name];
    if (!parentValue) {
      setAncestors([]);
      return;
    }

    setLoadingAncestors(true);
    fetchAncestors(objectType, parentField.name, record).then((result) => {
      if (!cancelled) {
        setAncestors(result);
        setLoadingAncestors(false);
      }
    });

    return () => { cancelled = true; };
  }, [objectType, parentField.name, record]);

  // Fetch direct children
  const { data: children, loading: loadingChildren } = useList(objectType, {
    filters: [{ field: parentField.name, op: '==', value: record.id }],
    pageSize: 50,
  });

  const loading = loadingAncestors || loadingChildren;
  const hasHierarchy = ancestors.length > 0 || (children && children.length > 0);

  if (!loading && !hasHierarchy) return null;

  return (
    <Paper sx={{ p: 2, mb: 3 }}>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
        <AccountTreeIcon fontSize="small" color="action" />
        <Typography variant="h6" sx={{ fontWeight: 600 }}>
          {t('section.hierarchy', 'Hierarchy')}
        </Typography>
        {loading && <CircularProgress size={16} />}
      </Box>

      <List dense disablePadding>
        {/* Ancestors */}
        {ancestors.map((ancestor, idx) => (
          <ListItemButton
            key={ancestor.id}
            sx={{ pl: idx * 2 + 1 }}
            onClick={() => navigate(`/${slug}/${ancestor.id}`)}
          >
            <ListItemIcon sx={{ minWidth: 28 }}>
              <ArrowRightIcon fontSize="small" />
            </ListItemIcon>
            <ListItemText
              primary={getDisplayName(ancestor, fields)}
              secondary={autoNumber ? ancestor[autoNumber.name] : null}
            />
          </ListItemButton>
        ))}

        {/* Current record (highlighted) */}
        <ListItemButton
          selected
          sx={{ pl: ancestors.length * 2 + 1 }}
          disabled
        >
          <ListItemIcon sx={{ minWidth: 28 }}>
            <ArrowRightIcon fontSize="small" />
          </ListItemIcon>
          <ListItemText
            primary={getDisplayName(record, fields)}
            secondary={autoNumber ? record[autoNumber.name] : null}
          />
          <Chip label={t('ui.current', 'Current')} size="small" color="primary" />
        </ListItemButton>

        {/* Children */}
        {children &&
          children.map((child) => (
            <ListItemButton
              key={child.id}
              sx={{ pl: (ancestors.length + 1) * 2 + 1 }}
              onClick={() => navigate(`/${slug}/${child.id}`)}
            >
              <ListItemIcon sx={{ minWidth: 28 }}>
                <SubdirectoryArrowRightIcon fontSize="small" />
              </ListItemIcon>
              <ListItemText
                primary={getDisplayName(child, fields)}
                secondary={autoNumber ? child[autoNumber.name] : null}
              />
            </ListItemButton>
          ))}
      </List>
    </Paper>
  );
}

/**
 * Recursively fetches ancestor records by following the parent reference.
 * Includes cycle detection via a visited Set.
 */
async function fetchAncestors(objectType, parentFieldName, startRecord, maxDepth = 10) {
  const ancestors = [];
  const visited = new Set([startRecord.id]);
  let current = startRecord;

  for (let i = 0; i < maxDepth; i++) {
    const parentId = current[parentFieldName];
    if (!parentId || visited.has(parentId)) break;

    visited.add(parentId);
    try {
      const parent = await DataService.getById(objectType, parentId);
      if (!parent) break;
      ancestors.unshift(parent);
      current = parent;
    } catch {
      break;
    }
  }

  return ancestors;
}
