import { useMemo, useState, useEffect, useCallback } from 'react';
import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Chip from '@mui/material/Chip';
import Button from '@mui/material/Button';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import TextField from '@mui/material/TextField';
import Autocomplete from '@mui/material/Autocomplete';
import CircularProgress from '@mui/material/CircularProgress';
import AddIcon from '@mui/icons-material/Add';
import LinkOffIcon from '@mui/icons-material/LinkOff';
import LinkIcon from '@mui/icons-material/Link';
import { MaterialReactTable, useMaterialReactTable } from 'material-react-table';
import { useNavigate } from 'react-router';
import { useList, useMutation } from '../../hooks/useDataService';
import DataService from '../../services/DataService';
import ModelRegistry from '../../model/ModelRegistry';
import { resolveSlug } from '../../config/navigation';
import { formatRelationshipName, formatFieldLabel, getColumnWidth, getDisplayName } from '../../utils/fieldUtils';
import FieldRenderer from '../fields/FieldRenderer';
import { t } from '../../services/TranslationService';

/**
 * Parse a simple condition string like "parent_type = 'Opportunity'"
 * into { field, value } or null if it can't be parsed.
 */
function parseCondition(condition) {
  if (!condition) return null;
  const match = condition.match(/^(\w+)\s*=\s*'([^']+)'$/);
  return match ? { field: match[1], value: match[2] } : null;
}

/**
 * Displays a single linked record type as a card with an MRT table.
 * Supports one-to-many and many-to-many relationships.
 */
export default function LinkedRecordCard({ relationship, parentId, parentObjectType }) {
  if (relationship.type === 'many-to-many' && relationship.through) {
    return (
      <ManyToManyCard
        relationship={relationship}
        parentId={parentId}
        parentObjectType={parentObjectType}
      />
    );
  }

  return (
    <OneToManyCard
      relationship={relationship}
      parentId={parentId}
      parentObjectType={parentObjectType}
    />
  );
}

/**
 * One-to-many linked record card (existing behavior).
 */
function OneToManyCard({ relationship, parentId, parentObjectType }) {
  const navigate = useNavigate();
  const targetSlug = resolveSlug(relationship.target);
  const parsedCondition = useMemo(() => parseCondition(relationship.condition), [relationship.condition]);

  const options = useMemo(() => {
    if (relationship.type === 'one-to-many' && relationship.foreign_key) {
      const filters = [
        { field: relationship.foreign_key, op: '==', value: parentId },
      ];
      if (parsedCondition) {
        filters.push({ field: parsedCondition.field, op: '==', value: parsedCondition.value });
      }
      return { filters, pageSize: 200 };
    }
    return { pageSize: 0 };
  }, [relationship, parentId, parsedCondition]);

  const canQuery = relationship.foreign_key && ModelRegistry.hasObject(relationship.target);
  const { data, loading } = useList(canQuery ? relationship.target : null, canQuery ? options : {});

  // Build "Add New" URL with parent context as search params
  const createUrl = useMemo(() => {
    if (!targetSlug) return null;
    const params = new URLSearchParams();
    if (relationship.foreign_key) {
      params.set(relationship.foreign_key, parentId);
    }
    if (parsedCondition) {
      params.set(parsedCondition.field, parsedCondition.value);
    }
    const parentSlug = resolveSlug(parentObjectType);
    if (parentSlug) {
      params.set('_returnTo', `/${parentSlug}/${parentId}`);
    }
    const qs = params.toString();
    return `/${targetSlug}/new${qs ? `?${qs}` : ''}`;
  }, [targetSlug, relationship, parentId, parentObjectType, parsedCondition]);

  // Build MRT columns from target object's fields
  const columns = useMemo(() => {
    if (!ModelRegistry.hasObject(relationship.target)) return [];
    return ModelRegistry.getSpecificFields(relationship.target)
      .filter((f) => !f.primary_key)
      .slice(0, 5)
      .map((field) => ({
        accessorKey: field.name,
        header: formatFieldLabel(field, relationship.target),
        size: getColumnWidth(field),
        Cell: ({ cell }) => <FieldRenderer field={field} value={cell.getValue()} />,
      }));
  }, [relationship.target]);

  const table = useMaterialReactTable({
    columns,
    data: data || [],
    enableColumnFilters: false,
    enableSorting: true,
    enablePagination: (data?.length || 0) > 5,
    enableTopToolbar: false,
    enableBottomToolbar: (data?.length || 0) > 5,
    enableColumnActions: false,
    state: { isLoading: loading },
    initialState: {
      density: 'compact',
      pagination: { pageIndex: 0, pageSize: 5 },
    },
    muiTableBodyRowProps: ({ row }) => ({
      onClick: () => targetSlug && navigate(`/${targetSlug}/${row.original.id}`),
      sx: { cursor: targetSlug ? 'pointer' : 'default' },
    }),
    muiTablePaperProps: { elevation: 0, sx: { boxShadow: 'none' } },
  });

  if (!canQuery) return null;

  return (
    <Paper variant="outlined" sx={{ p: 2 }}>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
        <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
          {formatRelationshipName(relationship.name)}
        </Typography>
        {!loading && <Chip label={data?.length || 0} size="small" />}
        {loading && <CircularProgress size={16} />}
        <Box sx={{ flex: 1 }} />
        {targetSlug && (
          <Box sx={{ display: 'flex', gap: 1 }}>
            {data?.length > 0 && (
              <Button size="small" onClick={() => navigate(`/${targetSlug}`)}>
                {t('ui.view_all', 'View All')}
              </Button>
            )}
            <Button size="small" startIcon={<AddIcon />} onClick={() => navigate(createUrl)}>
              {t('ui.add_new', 'Add New')}
            </Button>
          </Box>
        )}
      </Box>

      {!loading && data?.length > 0 && (
        <MaterialReactTable table={table} />
      )}

      {!loading && (!data || data.length === 0) && (
        <Typography variant="body2" color="text.secondary">
          {t('misc.no_linked_records', 'No linked records.')}
        </Typography>
      )}
    </Paper>
  );
}

/**
 * Many-to-many linked record card.
 * Queries junction table, resolves target records, supports link/unlink.
 */
function ManyToManyCard({ relationship, parentId, parentObjectType }) {
  const navigate = useNavigate();
  const targetSlug = resolveSlug(relationship.target);
  const junctionType = relationship.through;

  // Determine source and target fields from junction table schema
  const { sourceField, targetField, extraFields } = useMemo(() => {
    if (!ModelRegistry.hasObject(junctionType)) return {};
    const junctionFields = ModelRegistry.getSpecificFields(junctionType);
    const src = junctionFields.find(
      (f) => f.type === 'reference' && f.target === parentObjectType
    );
    const tgt = junctionFields.find(
      (f) => f.type === 'reference' && f.target === relationship.target
    );
    const extras = junctionFields.filter(
      (f) => f.type !== 'reference' && !f.primary_key && !f.auto_generated
    );
    return {
      sourceField: src?.name,
      targetField: tgt?.name,
      extraFields: extras || [],
    };
  }, [junctionType, parentObjectType, relationship.target]);

  // Query junction table
  const junctionOptions = useMemo(() => {
    if (!sourceField) return { pageSize: 0 };
    return {
      filters: [{ field: sourceField, op: '==', value: parentId }],
      pageSize: 200,
    };
  }, [sourceField, parentId]);

  const canQuery = sourceField && targetField && ModelRegistry.hasObject(junctionType);
  const { data: junctionData, loading: junctionLoading, refetch } = useList(
    canQuery ? junctionType : null,
    canQuery ? junctionOptions : {}
  );

  // Resolve target records
  const [resolvedData, setResolvedData] = useState([]);
  const [resolving, setResolving] = useState(false);

  useEffect(() => {
    if (!junctionData || junctionData.length === 0 || !targetField) {
      setResolvedData([]);
      return;
    }

    let cancelled = false;
    setResolving(true);

    const resolveAll = async () => {
      const results = await Promise.all(
        junctionData.map(async (junctionRecord) => {
          const targetId = junctionRecord[targetField];
          if (!targetId) return null;
          try {
            const target = await DataService.getById(relationship.target, targetId);
            if (!target) return null;
            return {
              ...target,
              _junctionId: junctionRecord.id,
              _junctionData: junctionRecord,
            };
          } catch {
            return null;
          }
        })
      );
      if (!cancelled) {
        setResolvedData(results.filter(Boolean));
        setResolving(false);
      }
    };

    resolveAll();
    return () => { cancelled = true; };
  }, [junctionData, targetField, relationship.target]);

  // Unlink handler — deletes junction record
  const { remove: removeJunction } = useMutation(junctionType);
  const handleUnlink = async (junctionId) => {
    await removeJunction(junctionId);
    refetch();
  };

  // Link existing record
  const [showLinkInput, setShowLinkInput] = useState(false);
  const [linkOptions, setLinkOptions] = useState([]);
  const [linkLoading, setLinkLoading] = useState(false);
  const [linkLoaded, setLinkLoaded] = useState(false);
  const [linkKey, setLinkKey] = useState(0); // forces Autocomplete reset
  const { create: createJunction } = useMutation(junctionType);

  const targetFields = useMemo(() => {
    if (!ModelRegistry.hasObject(relationship.target)) return [];
    return ModelRegistry.getSpecificFields(relationship.target);
  }, [relationship.target]);

  const loadLinkOptions = useCallback(async () => {
    if (linkLoaded) return;
    setLinkLoading(true);
    try {
      const results = await DataService.list(relationship.target, { pageSize: 200 });
      // Exclude already-linked records
      const linkedIds = new Set(resolvedData.map((r) => r.id));
      setLinkOptions(
        results
          .filter((r) => !linkedIds.has(r.id))
          .map((r) => ({
            id: r.id,
            label: getDisplayName(r, targetFields) || r.id,
          }))
      );
      setLinkLoaded(true);
    } catch {
      setLinkOptions([]);
    } finally {
      setLinkLoading(false);
    }
  }, [linkLoaded, relationship.target, targetFields, resolvedData]);

  const handleLink = async (targetId) => {
    if (!targetId || !sourceField || !targetField) return;
    const junctionRecord = {
      [sourceField]: parentId,
      [targetField]: targetId,
    };
    // Apply defaults for required junction fields (e.g., is_primary)
    if (ModelRegistry.hasObject(junctionType)) {
      for (const field of ModelRegistry.getSpecificFields(junctionType)) {
        if (field.required && field.default !== undefined && !(field.name in junctionRecord)) {
          junctionRecord[field.name] = field.default;
        }
      }
    }
    try {
      await createJunction(junctionRecord);
      // Stay in link mode — reset autocomplete for next selection
      setLinkLoaded(false);
      setLinkKey((k) => k + 1);
      refetch();
    } catch (err) {
      // Error already captured by useMutation
    }
  };

  // Build MRT columns: target fields + junction extra fields + unlink action
  const columns = useMemo(() => {
    if (!ModelRegistry.hasObject(relationship.target)) return [];
    const targetCols = ModelRegistry.getSpecificFields(relationship.target)
      .filter((f) => !f.primary_key)
      .slice(0, 4)
      .map((field) => ({
        accessorKey: field.name,
        header: formatFieldLabel(field, relationship.target),
        size: getColumnWidth(field),
        Cell: ({ cell }) => <FieldRenderer field={field} value={cell.getValue()} />,
      }));

    // Add junction-specific columns (e.g., role)
    const junctionCols = extraFields.map((field) => ({
      accessorKey: `_junction_${field.name}`,
      header: formatFieldLabel(field, junctionType),
      size: getColumnWidth(field),
      Cell: ({ row }) => {
        const val = row.original._junctionData?.[field.name];
        return val ? (
          <Typography variant="body2">{String(val)}</Typography>
        ) : (
          <Typography variant="body2" color="text.secondary">—</Typography>
        );
      },
    }));

    return [...targetCols, ...junctionCols];
  }, [relationship.target, extraFields, junctionType]);

  const loading = junctionLoading || resolving;

  const table = useMaterialReactTable({
    columns,
    data: resolvedData,
    enableColumnFilters: false,
    enableSorting: true,
    enablePagination: resolvedData.length > 5,
    enableTopToolbar: false,
    enableBottomToolbar: resolvedData.length > 5,
    enableColumnActions: false,
    enableRowActions: true,
    positionActionsColumn: 'last',
    state: { isLoading: loading },
    initialState: {
      density: 'compact',
      pagination: { pageIndex: 0, pageSize: 5 },
    },
    muiTableBodyRowProps: ({ row }) => ({
      onClick: () => targetSlug && navigate(`/${targetSlug}/${row.original.id}`),
      sx: { cursor: targetSlug ? 'pointer' : 'default' },
    }),
    renderRowActions: ({ row }) => (
      <Tooltip title={t('ui.unlink', 'Unlink')}>
        <IconButton
          size="small"
          color="error"
          onClick={(e) => {
            e.stopPropagation();
            handleUnlink(row.original._junctionId);
          }}
        >
          <LinkOffIcon fontSize="small" />
        </IconButton>
      </Tooltip>
    ),
    muiTablePaperProps: { elevation: 0, sx: { boxShadow: 'none' } },
  });

  if (!canQuery) return null;

  return (
    <Paper variant="outlined" sx={{ p: 2 }}>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
        <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
          {formatRelationshipName(relationship.name)}
        </Typography>
        {!loading && <Chip label={resolvedData.length} size="small" />}
        {loading && <CircularProgress size={16} />}
        <Box sx={{ flex: 1 }} />
        <Button
          size="small"
          startIcon={<LinkIcon />}
          onClick={() => {
            setShowLinkInput((prev) => !prev);
            setLinkLoaded(false);
          }}
        >
          {showLinkInput ? t('ui.done', 'Done') : t('ui.link', 'Link')}
        </Button>
      </Box>

      {showLinkInput && (
        <Box sx={{ mb: 1 }}>
          <Autocomplete
            key={linkKey}
            size="small"
            openOnFocus
            options={linkOptions}
            loading={linkLoading}
            onOpen={loadLinkOptions}
            onChange={(_e, newValue) => {
              if (newValue) handleLink(newValue.id);
            }}
            getOptionLabel={(o) => o.label || ''}
            isOptionEqualToValue={(o, v) => o.id === v?.id}
            renderInput={(params) => (
              <TextField
                {...params}
                variant="outlined"
                size="small"
                placeholder={`Search ${formatRelationshipName(relationship.name)}...`}
                autoFocus
              />
            )}
          />
        </Box>
      )}

      {!loading && resolvedData.length > 0 && (
        <MaterialReactTable table={table} />
      )}

      {!loading && resolvedData.length === 0 && (
        <Typography variant="body2" color="text.secondary">
          {t('misc.no_linked_records', 'No linked records.')}
        </Typography>
      )}
    </Paper>
  );
}
