import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import Alert from '@mui/material/Alert';
import { useParams } from 'react-router';
import navigationItems, { resolveObjectType } from '../config/navigation';
import { getObjectLabel } from '../utils/fieldUtils';
import { usePaginatedList } from '../hooks/usePaginatedList';
import RecordListView from '../components/records/RecordListView';
import { t } from '../services/TranslationService';

export default function ObjectListPage() {
  const { objectType: slug } = useParams();
  const objectType = resolveObjectType(slug);

  if (!objectType) {
    return (
      <Box sx={{ p: 2 }}>
        <Alert severity="warning">{t('ui.unknown_object_type', 'Unknown object type')}: {slug}</Alert>
      </Box>
    );
  }

  return <ObjectList objectType={objectType} slug={slug} />;
}

function ObjectList({ objectType, slug }) {
  const {
    data, loading, error, rowCount,
    pagination, sorting,
    setPagination, setSorting,
    refetch,
    globalFilter, setGlobalFilter,
    columnFilters, setColumnFilters,
    isFiltered,
  } = usePaginatedList(objectType);
  const navItem = navigationItems.find((n) => n.path === `/${slug}`);
  const label = navItem ? navItem.label : getObjectLabel(objectType);

  return (
    <Box>
      <Typography
        variant="h5"
        sx={{
          fontWeight: 700,
          mb: 2,
          position: 'sticky',
          top: 0,
          zIndex: 2,
          bgcolor: 'background.default',
          py: 1,
        }}
      >
        {label}
      </Typography>
      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error.message || t('ui.failed_to_load_records', 'Failed to load records.')}
        </Alert>
      )}
      <RecordListView
        objectType={objectType}
        slug={slug}
        data={data}
        loading={loading}
        onRefetch={refetch}
        rowCount={rowCount}
        pagination={pagination}
        sorting={sorting}
        onPaginationChange={setPagination}
        onSortingChange={setSorting}
        globalFilter={globalFilter}
        onGlobalFilterChange={setGlobalFilter}
        columnFilters={columnFilters}
        onColumnFiltersChange={setColumnFilters}
        isFiltered={isFiltered}
      />
    </Box>
  );
}
