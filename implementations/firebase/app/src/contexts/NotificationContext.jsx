import { createContext, useContext, useState, useEffect, useMemo, useRef, useCallback } from 'react';
import { useAuth } from './AuthContext';
import NotificationService from '../services/NotificationService';

const NotificationContext = createContext(null);

export function useNotifications() {
  const ctx = useContext(NotificationContext);
  if (!ctx) throw new Error('useNotifications must be used within NotificationProvider');
  return ctx;
}

/**
 * A21: NotificationProvider — real-time notification state for the authenticated user.
 * Subscribes to Firestore onSnapshot and dispatches desktop browser notifications for new items.
 */
export default function NotificationProvider({ children }) {
  const { userProfile } = useAuth();
  const [notifications, setNotifications] = useState([]);
  const [loading, setLoading] = useState(true);
  const prevIdsRef = useRef(new Set());
  const initialLoadRef = useRef(true);

  // Request desktop notification permission on mount
  useEffect(() => {
    if ('Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission();
    }
  }, []);

  // Subscribe to notifications when user is authenticated
  useEffect(() => {
    if (!userProfile?.id) {
      setNotifications([]);
      setLoading(false);
      return;
    }

    setLoading(true);
    initialLoadRef.current = true;
    prevIdsRef.current = new Set();

    const unsubscribe = NotificationService.subscribeToNotifications(
      userProfile.id,
      (items) => {
        setNotifications(items);
        setLoading(false);

        // Detect newly added unread notifications for desktop notifications
        const currentIds = new Set(items.map((n) => n.id));
        if (!initialLoadRef.current) {
          const newItems = items.filter(
            (n) => !prevIdsRef.current.has(n.id) && !n.read
          );
          if (
            newItems.length > 0 &&
            'Notification' in window &&
            Notification.permission === 'granted'
          ) {
            for (const n of newItems) {
              new Notification(n.title, { body: n.message || '' });
            }
          }
        }
        initialLoadRef.current = false;
        prevIdsRef.current = currentIds;
      }
    );

    return unsubscribe;
  }, [userProfile?.id]);

  const unreadCount = useMemo(
    () => notifications.filter((n) => !n.read).length,
    [notifications]
  );

  const markAsRead = useCallback(async (id) => {
    setNotifications((prev) =>
      prev.map((n) => (n.id === id ? { ...n, read: true } : n))
    );
    try {
      await NotificationService.markAsRead(id);
    } catch {
      // Optimistic update — revert handled by next snapshot
    }
  }, []);

  const markAllAsRead = useCallback(async () => {
    if (!userProfile?.id) return;
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
    try {
      await NotificationService.markAllAsRead(userProfile.id);
    } catch {
      // Optimistic update
    }
  }, [userProfile?.id]);

  const deleteNotification = useCallback(async (id) => {
    setNotifications((prev) => prev.filter((n) => n.id !== id));
    try {
      await NotificationService.deleteNotification(id);
    } catch {
      // Optimistic update
    }
  }, []);

  const value = useMemo(
    () => ({
      notifications,
      unreadCount,
      loading,
      markAsRead,
      markAllAsRead,
      deleteNotification,
    }),
    [notifications, unreadCount, loading, markAsRead, markAllAsRead, deleteNotification]
  );

  return (
    <NotificationContext.Provider value={value}>
      {children}
    </NotificationContext.Provider>
  );
}
