import { useState, useMemo, useCallback, useEffect } from 'react';
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
import DeleteIcon from '@mui/icons-material/Delete';
import { MaterialReactTable, useMaterialReactTable } from 'material-react-table';
import { useList, useMutation } from '../../hooks/useDataService';
import DataService from '../../services/DataService';
import ModelRegistry from '../../model/ModelRegistry';
import { getDisplayName } from '../../utils/fieldUtils';
import FieldRenderer from '../fields/FieldRenderer';
import { t } from '../../services/TranslationService';

/**
 * Parse a simple condition string like "parent_type = 'Opportunity'"
 */
function parseCondition(condition) {
  if (!condition) return null;
  const match = condition.match(/^(\w+)\s*=\s*'([^']+)'$/);
  return match ? { field: match[1], value: match[2] } : null;
}

/**
 * Calculate net value from quantity, unit_price, discount_percent.
 */
function calcNetValue(qty, price, discount) {
  const q = parseFloat(qty) || 0;
  const p = parseFloat(price) || 0;
  const d = parseFloat(discount) || 0;
  return Math.round(q * p * (1 - d / 100) * 100) / 100;
}

/**
 * Compute next item number (max existing + 10, or 10 if none).
 */
function nextItemNumber(data) {
  if (!data || data.length === 0) return '10';
  const nums = data.map((r) => parseInt(r.item_number, 10) || 0);
  return String(Math.max(...nums) + 10);
}

/**
 * Product autocomplete for inline editing.
 */
function ProductEditCell({ cell, column, row, table }) {
  const [options, setOptions] = useState([]);
  const [loading, setLoading] = useState(false);
  const [loaded, setLoaded] = useState(false);
  const [inputValue, setInputValue] = useState('');
  const currentValue = cell.getValue();

  const targetFields = useMemo(() => (
    ModelRegistry.hasObject('Product')
      ? ModelRegistry.getSpecificFields('Product')
      : []
  ), []);

  // Resolve current value to display label
  const [selectedOption, setSelectedOption] = useState(null);
  useEffect(() => {
    if (!currentValue) return;
    DataService.getById('Product', currentValue)
      .then((record) => {
        if (record) {
          setSelectedOption({ id: currentValue, label: getDisplayName(record, targetFields) || currentValue });
        }
      })
      .catch(() => {});
  }, [currentValue, targetFields]);

  const loadOptions = useCallback(async () => {
    if (loaded) return;
    setLoading(true);
    try {
      const results = await DataService.list('Product', { pageSize: 200 });
      setOptions(results.map((r) => ({
        id: r.id,
        label: getDisplayName(r, targetFields) || r.id,
      })));
      setLoaded(true);
    } catch {
      setOptions([]);
    } finally {
      setLoading(false);
    }
  }, [loaded, targetFields]);

  return (
    <Autocomplete
      size="small"
      openOnFocus
      options={options}
      loading={loading}
      value={selectedOption}
      inputValue={inputValue}
      onInputChange={(_e, v) => setInputValue(v)}
      onOpen={loadOptions}
      onChange={(_e, newValue) => {
        setSelectedOption(newValue);
        row._valuesCache[column.id] = newValue?.id || null;
      }}
      getOptionLabel={(o) => o.label || ''}
      isOptionEqualToValue={(o, v) => o.id === v?.id}
      sx={{ minWidth: 180 }}
      renderInput={(params) => (
        <TextField {...params} variant="outlined" size="small" placeholder={t('line_items.select_product', 'Select product')} />
      )}
    />
  );
}

/**
 * Number edit cell that triggers live net value recalculation.
 */
function NumberEditCell({ cell, column, row, table, step, onValueChange }) {
  const [localValue, setLocalValue] = useState(cell.getValue() ?? '');

  return (
    <TextField
      variant="outlined"
      size="small"
      type="number"
      inputProps={{ step: step || 1 }}
      value={localValue}
      onChange={(e) => {
        const v = e.target.value;
        setLocalValue(v);
        row._valuesCache[column.id] = v === '' ? '' : parseFloat(v);
        onValueChange?.(row);
      }}
      sx={{ minWidth: 90 }}
    />
  );
}

/**
 * Specialized inline-editable line items table for parent detail pages.
 * Used for Opportunity, Quotation, SalesOrder, Invoice.
 */
export default function LineItemsCard({ relationship, parentId, parentObjectType }) {
  const parsedCondition = useMemo(() => parseCondition(relationship.condition), [relationship.condition]);

  const options = useMemo(() => {
    const filters = [
      { field: relationship.foreign_key, op: '==', value: parentId },
    ];
    if (parsedCondition) {
      filters.push({ field: parsedCondition.field, op: '==', value: parsedCondition.value });
    }
    return { filters, pageSize: 200 };
  }, [relationship, parentId, parsedCondition]);

  const { data: rawData, loading, refetch } = useList('LineItem', options);
  const { create, update, remove } = useMutation('LineItem');
  const [netValues, setNetValues] = useState({});

  // Sort data by item_number ascending
  const data = useMemo(() => {
    if (!rawData) return rawData;
    return [...rawData].sort((a, b) => (parseInt(a.item_number, 10) || 0) - (parseInt(b.item_number, 10) || 0));
  }, [rawData]);

  // Calculate grand total of all line items
  const grandTotal = useMemo(() => {
    if (!data || data.length === 0) return 0;
    return data.reduce((sum, row) => {
      const live = netValues[row.id];
      const val = live !== undefined ? live : (row.total_price || 0);
      return sum + (parseFloat(val) || 0);
    }, 0);
  }, [data, netValues]);

  // Product field definition for FieldRenderer
  const productField = useMemo(
    () => ({ name: 'product_id', type: 'reference', target: 'Product' }),
    []
  );
  const totalField = useMemo(
    () => ({ name: 'total_price', type: 'currency', precision: 15, scale: 2 }),
    []
  );
  const discountField = useMemo(
    () => ({ name: 'discount_percent', type: 'decimal', precision: 5, scale: 2 }),
    []
  );
  const qtyField = useMemo(
    () => ({ name: 'quantity', type: 'decimal', precision: 13, scale: 3 }),
    []
  );
  const priceField = useMemo(
    () => ({ name: 'unit_price', type: 'currency', precision: 11, scale: 2 }),
    []
  );

  // Recalculate net value for a row being edited
  const recalcRow = useCallback((row) => {
    const vals = row._valuesCache || {};
    const qty = vals.quantity ?? row.original?.quantity ?? 0;
    const price = vals.unit_price ?? row.original?.unit_price ?? 0;
    const discount = vals.discount_percent ?? row.original?.discount_percent ?? 0;
    const nv = calcNetValue(qty, price, discount);
    setNetValues((prev) => ({ ...prev, [row.id]: nv }));
  }, []);

  const columns = useMemo(() => [
    {
      accessorKey: 'item_number',
      header: t('line_items.item_number', 'Item #'),
      size: 80,
      enableEditing: false,
      Footer: () => null,
    },
    {
      accessorKey: 'product_id',
      header: t('line_items.product', 'Product'),
      size: 200,
      Cell: ({ cell }) => <FieldRenderer field={productField} value={cell.getValue()} />,
      Edit: (props) => <ProductEditCell {...props} />,
      Footer: () => null,
    },
    {
      accessorKey: 'quantity',
      header: t('line_items.quantity', 'Quantity'),
      size: 100,
      Cell: ({ cell }) => <FieldRenderer field={qtyField} value={cell.getValue()} />,
      Edit: (props) => <NumberEditCell {...props} step={1} onValueChange={recalcRow} />,
      Footer: () => null,
    },
    {
      accessorKey: 'unit_price',
      header: t('line_items.net_price', 'Net Price'),
      size: 120,
      Cell: ({ cell }) => <FieldRenderer field={priceField} value={cell.getValue()} />,
      Edit: (props) => <NumberEditCell {...props} step={0.01} onValueChange={recalcRow} />,
      Footer: () => null,
    },
    {
      accessorKey: 'discount_percent',
      header: t('line_items.discount', 'Discount %'),
      size: 110,
      Cell: ({ cell }) => {
        const v = cell.getValue();
        return v ? <FieldRenderer field={discountField} value={v} /> : <Typography variant="body2" color="text.secondary">—</Typography>;
      },
      Edit: (props) => <NumberEditCell {...props} step={0.01} onValueChange={recalcRow} />,
      Footer: () => (
        <Typography variant="body2" sx={{ fontWeight: 700, textAlign: 'right', width: '100%' }}>
          {t('line_items.total', 'Total:')}
        </Typography>
      ),
    },
    {
      accessorKey: 'total_price',
      header: t('line_items.net_value', 'Net Value'),
      size: 120,
      enableEditing: false,
      Cell: ({ cell, row }) => {
        const live = netValues[row.id];
        const v = live !== undefined ? live : cell.getValue();
        return <FieldRenderer field={totalField} value={v} />;
      },
      Footer: () => (
        <Typography variant="body2" sx={{ fontWeight: 700 }}>
          {grandTotal.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
        </Typography>
      ),
    },
  ], [productField, qtyField, priceField, discountField, totalField, netValues, recalcRow, grandTotal]);

  // Handle creating a new row
  const handleCreate = async ({ values, table: tbl }) => {
    const qty = parseFloat(values.quantity) || 1;
    const price = parseFloat(values.unit_price) || 0;
    const discount = parseFloat(values.discount_percent) || 0;
    const total = calcNetValue(qty, price, discount);
    const itemNum = nextItemNumber(data);

    const record = {
      parent_type: parsedCondition?.value || parentObjectType,
      parent_id: parentId,
      item_number: itemNum,
      product_id: values.product_id || null,
      quantity: qty,
      unit_price: price,
      discount_percent: discount,
      total_price: total,
    };

    await create(record);
    tbl.setCreatingRow(null);
    refetch();
  };

  // Handle saving an edited row
  const handleSave = async ({ values, row, table: tbl }) => {
    const qty = parseFloat(values.quantity) || row.original.quantity;
    const price = parseFloat(values.unit_price) || row.original.unit_price;
    const discount = parseFloat(values.discount_percent) ?? row.original.discount_percent ?? 0;
    const total = calcNetValue(qty, price, discount);

    await update(row.original.id, {
      product_id: values.product_id || row.original.product_id,
      quantity: qty,
      unit_price: price,
      discount_percent: discount,
      total_price: total,
    });

    tbl.setEditingRow(null);
    setNetValues((prev) => {
      const next = { ...prev };
      delete next[row.id];
      return next;
    });
    refetch();
  };

  // Handle deleting a row
  const handleDelete = async (id) => {
    await remove(id);
    refetch();
  };

  const table = useMaterialReactTable({
    columns,
    data: data || [],
    enableEditing: true,
    editDisplayMode: 'row',
    createDisplayMode: 'row',
    enableColumnFilters: false,
    enableColumnActions: false,
    enableSorting: false,
    enablePagination: false,
    enableTopToolbar: false,
    enableBottomToolbar: false,
    enableRowActions: true,
    positionActionsColumn: 'last',
    state: { isLoading: loading },
    initialState: { density: 'compact' },
    onCreatingRowSave: handleCreate,
    onEditingRowSave: handleSave,
    onEditingRowCancel: ({ row }) => {
      setNetValues((prev) => {
        const next = { ...prev };
        delete next[row.id];
        return next;
      });
    },
    getRowId: (row) => row.id,
    renderRowActions: ({ row, table: tbl }) => {
      if (tbl.getState().editingRow?.id === row.id || tbl.getState().creatingRow?.id === row.id) {
        return null; // MRT renders save/cancel for editing rows
      }
      return (
        <Box sx={{ display: 'flex', gap: '4px' }}>
          <Tooltip title={t('ui.edit', 'Edit')}>
            <IconButton size="small" onClick={() => tbl.setEditingRow(row)}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04a1 1 0 000-1.41l-2.34-2.34a1 1 0 00-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z"/></svg>
            </IconButton>
          </Tooltip>
          <Tooltip title={t('ui.delete', 'Delete')}>
            <IconButton size="small" color="error" onClick={() => handleDelete(row.original.id)}>
              <DeleteIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>
      );
    },
    muiTablePaperProps: { elevation: 0, sx: { boxShadow: 'none' } },
  });

  return (
    <Paper variant="outlined" sx={{ p: 2 }}>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
        <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
          {t('line_items.title', 'Line Items')}
        </Typography>
        {!loading && <Chip label={data?.length || 0} size="small" />}
        {loading && <CircularProgress size={16} />}
        <Box sx={{ flex: 1 }} />
        <Button
          size="small"
          startIcon={<AddIcon />}
          onClick={() => {
            table.setCreatingRow(true);
          }}
        >
          {t('ui.add_new', 'Add New')}
        </Button>
      </Box>

      <MaterialReactTable table={table} />
    </Paper>
  );
}
