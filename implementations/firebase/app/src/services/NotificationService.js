import { db } from '../config/firebase';
import {
  collection,
  query,
  where,
  orderBy,
  limit,
  onSnapshot,
  getDocs,
  writeBatch,
  doc,
} from 'firebase/firestore';
import DataService from './DataService';

const COLLECTION = 'notifications';

/**
 * F17 / A21: Notification Service.
 * Provides real-time subscription and CRUD for user notifications.
 */
const NotificationService = {
  /**
   * Subscribe to real-time notifications for a user.
   * Returns an unsubscribe function.
   */
  subscribeToNotifications(userId, callback) {
    const q = query(
      collection(db, COLLECTION),
      where('user_id', '==', userId),
      orderBy('created_at', 'desc'),
      limit(50)
    );
    return onSnapshot(q, (snapshot) => {
      const notifications = snapshot.docs.map((d) => ({ id: d.id, ...d.data() }));
      callback(notifications);
    });
  },

  /** Mark a single notification as read. */
  async markAsRead(notificationId) {
    return DataService.update('Notification', notificationId, { read: true });
  },

  /** Mark all unread notifications as read for a user. */
  async markAllAsRead(userId) {
    const q = query(
      collection(db, COLLECTION),
      where('user_id', '==', userId),
      where('read', '==', false)
    );
    const snapshot = await getDocs(q);
    if (snapshot.empty) return;

    const batch = writeBatch(db);
    snapshot.docs.forEach((d) => {
      batch.update(doc(db, COLLECTION, d.id), { read: true });
    });
    await batch.commit();
  },

  /** Delete a notification. */
  async deleteNotification(notificationId) {
    return DataService.remove('Notification', notificationId);
  },

  /** Create a new notification. */
  async createNotification({ user_id, type, title, message, link_type, link_id }) {
    return DataService.create('Notification', {
      user_id,
      type,
      title,
      message: message || '',
      read: false,
      link_type: link_type || '',
      link_id: link_id || '',
      send_email: false,
      email_sent: false,
    });
  },
};

export default NotificationService;
