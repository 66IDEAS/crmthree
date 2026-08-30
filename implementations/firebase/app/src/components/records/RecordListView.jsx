import { useMemo, useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router';
import { MaterialReactTable, useMaterialReactTable } from 'material-react-table';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';
import AddIcon from '@mui/icons-material/Add';
import FileDownloadIcon from '@mui/icons-material/FileDownload';
import VisibilityIcon from '@mui/icons-material/Visibility';
import ModelRegistry from '../../model/ModelRegistry';
import { useMutation } from '../../hooks/useDataService';
import FieldRenderer from '../fields/FieldRenderer';
import { formatFieldLabel, getColumnWidth, getObjectLabel } from '../../utils/fieldUtils';
import { exportToCsv, downloadCsv } from '../../utils/csvUtils';
import { t } from '../../services/TranslationService';
import { useUI } from '../../contexts/UIContext';

const MOBILE_VISIBLE_FIELDS = {
  Account: ['account_number', 'name1'],
  Contact: ['contact_number', 'first_name', 'last_name'],
  Lead: ['lead_number', 'first_name', 'last_name'],
  Opportunity: ['opportunity_number', 'name'],
  Quotation: ['quotation_number', 'status'],
  SalesOrder: ['order_number', 'status'],
  Invoice: ['invoice_number', 'status'],
  Product: ['product_number', 'name'],
  Activity: ['activity_number', 'subject'],
  Ticket: ['ticket_number', 'subject'],
  KnowledgeArticle: ['article_number', 'title'],
  Asset: ['asset_number', 'name'],
  SLA: ['name', 'active'],
  ServiceContract: ['contract_number', 'name'],
};

const DEFAULT_VISIBLE_FIELDS = {
  Account: ['account_number', 'name1', 'city', 'phone', 'status'],
  Contact: ['contact_number', 'first_name', 'last_name', 'account_id', 'status'],
  Lead: ['lead_number', 'first_name', 'last_name', 'company', 'status'],
  Opportunity: ['opportunity_number', 'name', 'stage_id', 'amount', 'result'],
  Quotation: ['quotation_number', 'account_id', 'status', 'valid_to', 'total_amount'],
  SalesOrder: ['order_number', 'account_id', 'status', 'order_date', 'total_amount'],
  Invoice: ['invoice_number', 'account_id', 'status', 'invoice_date', 'total_amount'],
  Product: ['product_number', 'name', 'product_type', 'base_price', 'status'],
  Activity: ['activity_number', 'type', 'subject', 'status', 'priority'],
  Ticket: ['ticket_number', 'subject', 'priority', 'status_id', 'account_id'],
  KnowledgeArticle: ['article_number', 'title', 'category', 'status', 'source'],
  Asset: ['asset_number', 'name', 'product_id', 'account_id', 'status'],
  SLA: ['name', 'response_time_hours', 'resolution_time_hours', 'business_hours_only', 'active'],
  ServiceContract: ['contract_number', 'name', 'account_id', 'status', 'end_date'],
};

/**
 * Generic table-based list view driven by ModelRegistry.
 * Uses Material React Table 3 with sorting, pagination, and inline edit.
 * Supports both client-side and server-side pagination modes.
 */
export default function RecordListView({
  objectType, slug, data, loading, onRefetch,
  // Optional server-side pagination props
  rowCount,
  pagination: paginationProp,
  sorting: sortingProp,
  onPaginationChange,
  onSortingChange,
  // Optional filter props (dual-mode: server-side ↔ client-side)
  globalFilter: globalFilterProp,
  onGlobalFilterChange,
  columnFilters: columnFiltersProp,
  onColumnFiltersChange,
  isFiltered,
}) {
  const navigate = useNavigate();
  const { update } = useMutation(objectType);
  const { isMobile } = useUI();

  const hasPaginationProps = onPaginationChange != null;
  // Server-side mode is active only when we have pagination props AND no filter is active
  const isServerPaginated = hasPaginationProps && !isFiltered;

  const [exporting, setExporting] = useState(false);

  const handleExport = useCallback(async () => {
    let exportData = data;
    if (hasPaginationProps && !isFiltered) {
      // Fetch all records on demand for CSV export
      setExporting(true);
      try {
        const DataService = (await import('../../services/DataService')).default;
        exportData = await DataService.list(objectType, { pageSize: 0 });
      } catch {
        setExporting(false);
        return;
      }
      setExporting(false);
    }
    if (!exportData || exportData.length === 0) return;
    const csv = exportToCsv(objectType, exportData);
    const label = getObjectLabel(objectType).toLowerCase().replace(/\s+/g, '-');
    downloadCsv(csv, `${label}-export.csv`);
  }, [data, hasPaginationProps, isFiltered, objectType]);

  const columns = useMemo(() => {
    const fields = ModelRegistry.getSpecificFields(objectType);
    return fields
      .filter((f) => !f.primary_key)
      .map((field) => ({
        accessorKey: field.name,
        header: formatFieldLabel(field, objectType),
        size: getColumnWidth(field),
        Cell: ({ cell }) => <FieldRenderer field={field} value={cell.getValue()} />,
        filterVariant: field.type === 'enum' ? 'select' : undefined,
        filterSelectOptions: field.type === 'enum' ? field.values.map((v) => ({ label: t(`enum.${v}`, v), value: v })) : undefined,
        editVariant: field.type === 'enum' ? 'select' : undefined,
        editSelectOptions: field.type === 'enum' ? (field.required ? field.values.map((v) => ({ label: t(`enum.${v}`, v), value: v })) : [{ label: '—', value: '' }, ...field.values.map((v) => ({ label: t(`enum.${v}`, v), value: v }))]) : undefined,
        enableEditing: !field.auto_generated && field.type !== 'reference',
      }));
  }, [objectType]);

  const defaultColumnVisibility = useMemo(() => {
    const visible = isMobile
      ? (MOBILE_VISIBLE_FIELDS[objectType] || null)
      : (DEFAULT_VISIBLE_FIELDS[objectType] || null);
    if (!visible) {
      const vis = {};
      columns.forEach((col, i) => {
        if (i >= (isMobile ? 2 : 5)) vis[col.accessorKey] = false;
      });
      return vis;
    }
    const vis = {};
    columns.forEach((col) => {
      if (!visible.includes(col.accessorKey)) {
        vis[col.accessorKey] = false;
      }
    });
    return vis;
  }, [objectType, columns, isMobile]);

  const [columnVisibility, setColumnVisibility] = useState(defaultColumnVisibility);

  useEffect(() => {
    setColumnVisibility(defaultColumnVisibility);
  }, [defaultColumnVisibility]);

  const handleSaveCell = async (cell, value) => {
    const rowId = cell.row.original.id;
    const fieldName = cell.column.id;
    try {
      await update(rowId, { [fieldName]: value });
      onRefetch?.();
    } catch {
      // Error is captured by useMutation
    }
  };

  const table = useMaterialReactTable({
    columns,
    data: data || [],
    enableColumnFilters: true,
    enableSorting: true,
    enablePagination: true,
    enableEditing: true,
    editDisplayMode: 'cell',
    enableRowActions: !isMobile,
    positionActionsColumn: 'last',

    // Server-side pagination (disabled when filtering — MRT handles client-side)
    manualPagination: isServerPaginated || undefined,
    rowCount: isServerPaginated ? rowCount : undefined,

    // Server-side sorting (disabled when filtering — MRT handles client-side)
    manualSorting: isServerPaginated || undefined,

    // Always keep pagination/sorting/filter state controlled to avoid MRT resetting to defaults
    ...(onPaginationChange ? { onPaginationChange } : {}),
    ...(onSortingChange ? { onSortingChange } : {}),
    ...(onGlobalFilterChange ? { onGlobalFilterChange } : {}),
    ...(onColumnFiltersChange ? { onColumnFiltersChange } : {}),

    state: {
      isLoading: loading,
      columnVisibility,
      ...(paginationProp ? { pagination: paginationProp } : {}),
      ...(sortingProp ? { sorting: sortingProp } : {}),
      ...(onGlobalFilterChange ? { globalFilter: globalFilterProp } : {}),
      ...(onColumnFiltersChange ? { columnFilters: columnFiltersProp } : {}),
    },
    onColumnVisibilityChange: setColumnVisibility,
    initialState: {
      density: 'compact',
    },

    // Prev/next only for server-side pagination (no arbitrary page jumps)
    ...(isServerPaginated ? {
      muiPaginationProps: {
        showFirstButton: false,
        showLastButton: false,
      },
    } : {}),

    muiTableBodyRowProps: ({ row }) => ({
      onClick: () => navigate(`/${slug}/${row.original.id}`),
      sx: { cursor: 'pointer' },
    }),
    muiEditTextFieldProps: ({ cell }) => ({
      onBlur: (e) => handleSaveCell(cell, e.target.value),
      variant: 'outlined',
      size: 'small',
    }),
    renderRowActions: ({ row }) => (
      <Tooltip title={t('ui.view_details', 'View details')}>
        <IconButton
          size="small"
          onClick={(e) => {
            e.stopPropagation();
            navigate(`/${slug}/${row.original.id}`);
          }}
        >
          <VisibilityIcon fontSize="small" />
        </IconButton>
      </Tooltip>
    ),
    renderTopToolbarCustomActions: () => (
      <Box sx={{ display: 'flex', gap: 1 }}>
        <Button
          variant="contained"
          size="small"
          startIcon={<AddIcon />}
          onClick={() => navigate(`/${slug}/new`)}
        >
          {t('ui.new', 'New')}
        </Button>
        <Button
          variant="outlined"
          size="small"
          startIcon={<FileDownloadIcon />}
          onClick={handleExport}
          disabled={exporting || (!data || data.length === 0)}
        >
          {exporting ? t('ui.exporting', 'Exporting...') : t('ui.export', 'Export')}
        </Button>
      </Box>
    ),
  });

  return <MaterialReactTable table={table} />;
}
