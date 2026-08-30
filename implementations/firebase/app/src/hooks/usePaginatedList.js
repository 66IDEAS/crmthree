import { useState, useRef, useCallback, useEffect } from 'react';
import DataService from '../services/DataService';
import { loadListSortSettings, getDefaultSorting } from '../services/ListSortService';

/**
 * Hook for server-side paginated and sorted data fetching.
 * Designed for use with Material React Table's manualPagination/manualSorting.
 *
 * Dual mode:
 * - No filter active → server-side pagination (only current page fetched)
 * - Filter/search active → fetches ALL records, MRT filters client-side
 *
 * Cursor caching: after fetching page N, the lastDoc DocumentSnapshot is stored
 * as the cursor for page N+1. Forward/backward navigation uses cached cursors.
 * Sort changes clear the cache and reset to page 0.
 */
export function usePaginatedList(objectType, { filters = [] } = {}) {
  const [pageData, setPageData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rowCount, setRowCount] = useState(0);
  const [pagination, setPagination] = useState({ pageIndex: 0, pageSize: 50 });
  const [sorting, setSorting] = useState([]);
  // The configured default sort is resolved before the first fetch, so a list
  // issues one query on open instead of an unsorted one followed by a sorted one.
  const [sortReady, setSortReady] = useState(false);

  // Filter state (controlled by MRT callbacks)
  const [globalFilter, setGlobalFilter] = useState('');
  const [columnFilters, setColumnFilters] = useState([]);

  // All-data cache for filtered mode
  const [allData, setAllData] = useState(null);
  const [allDataLoading, setAllDataLoading] = useState(false);

  const isFiltered = globalFilter !== '' || columnFilters.length > 0;

  // Cache of DocumentSnapshot cursors keyed by pageIndex
  const cursorCache = useRef({});

  const filtersKey = JSON.stringify(filters);

  // Fetch total count (for paginated mode)
  const fetchCount = useCallback(async () => {
    if (!objectType) return;
    try {
      const count = await DataService.count(objectType, { filters });
      setRowCount(count);
    } catch (err) {
      console.warn('Failed to fetch count:', err);
      setRowCount(0);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [objectType, filtersKey]);

  // Fetch a single page of data (paginated mode)
  const fetchPage = useCallback(async () => {
    if (!objectType) {
      setPageData([]);
      setLoading(false);
      return;
    }
    if (isFiltered || !sortReady) return;
    setLoading(true);
    setError(null);

    try {
      const sort = sorting.length > 0
        ? { field: sorting[0].id, direction: sorting[0].desc ? 'desc' : 'asc' }
        : undefined;

      const cursor = cursorCache.current[pagination.pageIndex] || null;

      const result = await DataService.listPage(objectType, {
        filters,
        sort,
        pageSize: pagination.pageSize,
        cursor,
      });

      setPageData(result.data);

      // Cache the lastDoc as the cursor for the NEXT page
      if (result.lastDoc) {
        cursorCache.current[pagination.pageIndex + 1] = result.lastDoc;
      }
    } catch (err) {
      setError(err);
      setPageData([]);
    } finally {
      setLoading(false);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [objectType, filtersKey, pagination.pageIndex, pagination.pageSize, sorting, isFiltered, sortReady]);

  // Seed the sort from the admin-configured default for this object type
  useEffect(() => {
    let cancelled = false;
    setSortReady(false);
    loadListSortSettings().then(() => {
      if (cancelled) return;
      cursorCache.current = {};
      setSorting(objectType ? getDefaultSorting(objectType) : []);
      setSortReady(true);
    });
    return () => { cancelled = true; };
  }, [objectType]);

  // Fetch all records when filters become active; reset page on mode switch
  useEffect(() => {
    setPagination((prev) => ({ ...prev, pageIndex: 0 }));
    if (!isFiltered || !objectType) {
      setAllData(null);
      return;
    }
    let cancelled = false;
    setAllDataLoading(true);
    DataService.list(objectType, { pageSize: 0 })
      .then((result) => {
        if (!cancelled) {
          setAllData(result);
          setAllDataLoading(false);
        }
      })
      .catch((err) => {
        if (!cancelled) {
          console.warn('Failed to fetch all data for filtering:', err);
          setAllDataLoading(false);
        }
      });
    return () => { cancelled = true; };
  }, [isFiltered, objectType]);

  // When sort changes, reset pagination and clear cursor cache
  const handleSortingChange = useCallback((updater) => {
    setSorting(updater);
    setPagination((prev) => ({ ...prev, pageIndex: 0 }));
    cursorCache.current = {};
  }, []);

  // Refetch resets everything
  const refetch = useCallback(() => {
    cursorCache.current = {};
    setAllData(null);
    setPagination((prev) => ({ ...prev, pageIndex: 0 }));
    fetchCount();
  }, [fetchCount]);

  // Fetch count on mount and when filters/objectType change
  useEffect(() => {
    cursorCache.current = {};
    setPagination((prev) => ({ ...prev, pageIndex: 0 }));
    fetchCount();
  }, [fetchCount]);

  // Fetch page data when pagination, sorting, or filters change
  useEffect(() => {
    fetchPage();
  }, [fetchPage]);

  return {
    data: isFiltered ? (allData || []) : pageData,
    loading: isFiltered ? allDataLoading : loading,
    error,
    rowCount,
    pagination,
    sorting,
    setPagination,
    setSorting: handleSortingChange,
    refetch,
    // Filter state
    globalFilter,
    setGlobalFilter,
    columnFilters,
    setColumnFilters,
    isFiltered,
  };
}
