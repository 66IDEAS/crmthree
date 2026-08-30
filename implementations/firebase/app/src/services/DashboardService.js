import { db } from '../config/firebase';
import { collection, query, where, getDocs, doc, setDoc } from 'firebase/firestore';

const COLLECTION = 'dashboard_configs';

const DashboardService = {
  async loadConfig(userId) {
    const q = query(
      collection(db, COLLECTION),
      where('user_id', '==', userId),
      where('is_default', '==', true)
    );
    const snapshot = await getDocs(q);
    if (snapshot.empty) return null;
    return { id: snapshot.docs[0].id, ...snapshot.docs[0].data() };
  },

  async saveConfig(userId, widgetVisibility) {
    const existing = await this.loadConfig(userId);
    const docId = existing?.id || `dashboard_${userId}`;
    const data = {
      user_id: userId,
      name: 'My Dashboard',
      is_default: true,
      widgets: widgetVisibility,
      updated_at: new Date().toISOString(),
    };
    if (!existing) {
      data.created_at = new Date().toISOString();
    }
    await setDoc(doc(db, COLLECTION, docId), data, { merge: true });
    return data;
  },
};

export default DashboardService;
