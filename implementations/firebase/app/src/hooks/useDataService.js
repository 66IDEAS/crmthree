import { useState, useEffect, useCallback } from 'react';
import DataService from '../services/DataService';

/**
 * Hook for fetching a list of records.
 * @param {string} objectType - The object type to query
 * @param {Object} options - { filters, sort, pageSize, cursor }
 * @returns {{ data, loading, error, refetch }}
 */
export function useList(objectType, options = {}) {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const optionsKey = JSON.stringify(options);

  const fetch = useCallback(async () => {
    if (!objectType) {
      setData([]);
      setLoading(false);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const result = await DataService.list(objectType, options);
      setData(result);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [objectType, optionsKey]);

  useEffect(() => {
    fetch();
  }, [fetch]);

  return { data, loading, error, refetch: fetch };
}

/**
 * Hook for fetching a single record by ID.
 * @param {string} objectType
 * @param {string} id
 * @returns {{ data, loading, error, refetch }}
 */
export function useRecord(objectType, id) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetch = useCallback(async () => {
    if (!id) {
      setData(null);
      setLoading(false);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const result = await DataService.getById(objectType, id);
      setData(result);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, [objectType, id]);

  useEffect(() => {
    fetch();
  }, [fetch]);

  return { data, loading, error, refetch: fetch };
}

/**
 * Hook for performing mutations (create, update, delete).
 * @param {string} objectType
 * @returns {{ create, update, remove, loading, error }}
 */
export function useMutation(objectType) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const create = useCallback(
    async (data) => {
      setLoading(true);
      setError(null);
      try {
        const result = await DataService.create(objectType, data);
        return result;
      } catch (err) {
        setError(err);
        throw err;
      } finally {
        setLoading(false);
      }
    },
    [objectType]
  );

  const update = useCallback(
    async (id, data) => {
      setLoading(true);
      setError(null);
      try {
        const result = await DataService.update(objectType, id, data);
        return result;
      } catch (err) {
        setError(err);
        throw err;
      } finally {
        setLoading(false);
      }
    },
    [objectType]
  );

  const remove = useCallback(
    async (id) => {
      setLoading(true);
      setError(null);
      try {
        await DataService.remove(objectType, id);
      } catch (err) {
        setError(err);
        throw err;
      } finally {
        setLoading(false);
      }
    },
    [objectType]
  );

  return { create, update, remove, loading, error };
}
