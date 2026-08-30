import { useAuth } from '../contexts/AuthContext';

/**
 * Hook for checking user permissions against the current role.
 * @returns {{ hasPermission, canCreate, canRead, canReadAll, canUpdate, canDelete, isAdmin }}
 */
export default function usePermissions() {
  const { hasPermission, role } = useAuth();

  const canCreate = (objectType) => hasPermission(objectType, 'create');
  const canRead = (objectType) => hasPermission(objectType, 'read');
  const canReadAll = (objectType) => hasPermission(objectType, 'read_all');
  const canUpdate = (objectType) => hasPermission(objectType, 'update');
  const canDelete = (objectType) => hasPermission(objectType, 'delete');
  const isAdmin = role?.name === 'Admin';

  return { hasPermission, canCreate, canRead, canReadAll, canUpdate, canDelete, isAdmin };
}
