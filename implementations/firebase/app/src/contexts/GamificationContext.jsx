import { createContext, useContext, useState, useEffect, useMemo, useCallback, useRef } from 'react';
import { db } from '../config/firebase';
import { collection, query, where, onSnapshot } from 'firebase/firestore';
import { useAuth } from './AuthContext';
import { getCollectionName } from '../services/collectionNames';
import DataService from '../services/DataService';

const GamificationContext = createContext(null);

export function useGamification() {
  const ctx = useContext(GamificationContext);
  if (!ctx) throw new Error('useGamification must be used within GamificationProvider');
  return ctx;
}

/**
 * GamificationProvider — real-time gamification state for the authenticated user.
 * Subscribes to UserProfile changes and UserBadge collection.
 */
export default function GamificationProvider({ children }) {
  const { userProfile } = useAuth();
  const [xpTotal, setXpTotal] = useState(userProfile?.xp_total ?? 0);
  const [level, setLevel] = useState(userProfile?.level ?? 1);
  const [levelName, setLevelName] = useState(userProfile?.level_name ?? 'Rookie');
  const [currentStreak, setCurrentStreak] = useState(userProfile?.current_streak_days ?? 0);
  const [longestStreak, setLongestStreak] = useState(userProfile?.longest_streak_days ?? 0);
  const [earnedBadges, setEarnedBadges] = useState([]);
  const [allBadges, setAllBadges] = useState([]);
  const [celebrations, setCelebrations] = useState([]);
  const [activeChallenge, setActiveChallenge] = useState(null);
  const celebrationIdRef = useRef(0);

  // Sync from userProfile when it changes (initial load)
  useEffect(() => {
    if (userProfile) {
      setXpTotal(userProfile.xp_total ?? 0);
      setLevel(userProfile.level ?? 1);
      setLevelName(userProfile.level_name ?? 'Rookie');
      setCurrentStreak(userProfile.current_streak_days ?? 0);
      setLongestStreak(userProfile.longest_streak_days ?? 0);
    }
  }, [userProfile]);

  // Subscribe to UserProfile changes for live XP updates
  useEffect(() => {
    if (!userProfile?.id) return;

    const collName = getCollectionName('UserProfile');
    const q = query(
      collection(db, collName),
      where('__name__', '==', userProfile.id)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      snapshot.docChanges().forEach((change) => {
        if (change.type === 'modified') {
          const data = change.doc.data();
          setXpTotal(data.xp_total ?? 0);
          setLevel(data.level ?? 1);
          setLevelName(data.level_name ?? 'Rookie');
          setCurrentStreak(data.current_streak_days ?? 0);
          setLongestStreak(data.longest_streak_days ?? 0);
        }
      });
    });

    return unsubscribe;
  }, [userProfile?.id]);

  // Subscribe to user's earned badges
  useEffect(() => {
    if (!userProfile?.id) return;

    const collName = getCollectionName('UserBadge');
    const q = query(
      collection(db, collName),
      where('user_id', '==', userProfile.id)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const badges = snapshot.docs.map((d) => ({ id: d.id, ...d.data() }));
      setEarnedBadges(badges);
    });

    return unsubscribe;
  }, [userProfile?.id]);

  // Load all badge definitions (not real-time, refresh on demand)
  useEffect(() => {
    DataService.list('Badge', { pageSize: 200 })
      .then(setAllBadges)
      .catch(() => {});
  }, []);

  // Load active challenge for current month
  useEffect(() => {
    if (!userProfile?.id) return;

    const now = new Date();
    DataService.list('Challenge', {
      filters: [
        { field: 'user_id', op: '==', value: userProfile.id },
        { field: 'status', op: '==', value: 'Active' },
      ],
      pageSize: 1,
    })
      .then((challenges) => {
        const current = challenges.find(
          (c) => c.month === now.getMonth() + 1 && c.year === now.getFullYear()
        );
        setActiveChallenge(current || null);
      })
      .catch(() => {});
  }, [userProfile?.id]);

  // Listen for celebration events from GamificationTrigger
  useEffect(() => {
    const handler = (e) => {
      const id = ++celebrationIdRef.current;
      setCelebrations((prev) => [...prev, { id, ...e.detail }]);
    };
    window.addEventListener('gamification-celebration', handler);
    return () => window.removeEventListener('gamification-celebration', handler);
  }, []);

  const dismissCelebration = useCallback((id) => {
    setCelebrations((prev) => prev.filter((c) => c.id !== id));
  }, []);

  const addCelebration = useCallback((type, data = {}) => {
    const id = ++celebrationIdRef.current;
    setCelebrations((prev) => [...prev, { id, type, ...data }]);
  }, []);

  const refreshBadges = useCallback(() => {
    DataService.list('Badge', { pageSize: 200 })
      .then(setAllBadges)
      .catch(() => {});
  }, []);

  // Compute next level info
  const [nextLevelXP, setNextLevelXP] = useState(null);
  useEffect(() => {
    DataService.list('LevelDefinition', { pageSize: 100 })
      .then((levels) => {
        const sorted = levels.sort((a, b) => a.xp_threshold - b.xp_threshold);
        const next = sorted.find((l) => l.xp_threshold > xpTotal);
        setNextLevelXP(next ? next.xp_threshold : null);
      })
      .catch(() => {});
  }, [xpTotal]);

  const value = useMemo(
    () => ({
      xpTotal,
      level,
      levelName,
      currentStreak,
      longestStreak,
      earnedBadges,
      allBadges,
      celebrations,
      activeChallenge,
      nextLevelXP,
      dismissCelebration,
      addCelebration,
      refreshBadges,
    }),
    [xpTotal, level, levelName, currentStreak, longestStreak, earnedBadges, allBadges,
      celebrations, activeChallenge, nextLevelXP, dismissCelebration, addCelebration, refreshBadges]
  );

  return (
    <GamificationContext.Provider value={value}>
      {children}
    </GamificationContext.Provider>
  );
}
