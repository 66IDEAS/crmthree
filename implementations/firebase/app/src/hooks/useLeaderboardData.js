import { useState, useEffect, useMemo } from 'react';
import DataService from '../services/DataService';

/**
 * Hook to fetch leaderboard data across multiple dimensions and time periods.
 * Dimensions: XP Total, Deals Closed, Activities Logged, Tickets Resolved
 * Time periods: All Time, Quarter, Month, Week
 */
export default function useLeaderboardData(dimension = 'xp_total', period = 'all') {
  const [users, setUsers] = useState([]);
  const [extraData, setExtraData] = useState({});
  const [loading, setLoading] = useState(true);

  // Load all user profiles
  useEffect(() => {
    DataService.list('UserProfile', { pageSize: 500 })
      .then(setUsers)
      .catch(() => setUsers([]))
      .finally(() => setLoading(false));
  }, []);

  // For dimensions other than xp_total, load the relevant records
  useEffect(() => {
    if (dimension === 'xp_total' || users.length === 0) return;

    setLoading(true);
    const loadData = async () => {
      try {
        if (dimension === 'deals_closed') {
          const opps = await DataService.list('Opportunity', {
            filters: [{ field: 'result', op: '==', value: 'Won' }],
            pageSize: 5000,
          });
          setExtraData({ opportunities: opps });
        } else if (dimension === 'activities_logged') {
          const acts = await DataService.list('Activity', { pageSize: 5000 });
          setExtraData({ activities: acts });
        } else if (dimension === 'tickets_resolved') {
          const tickets = await DataService.list('Ticket', { pageSize: 5000 });
          setExtraData({
            tickets: tickets.filter((t) => t.status === 'Resolved' || t.status === 'Closed'),
          });
        }
      } catch {
        setExtraData({});
      } finally {
        setLoading(false);
      }
    };
    loadData();
  }, [dimension, users.length]);

  const periodStart = useMemo(() => {
    if (period === 'all') return null;
    const now = new Date();
    if (period === 'week') {
      const day = now.getDay();
      const start = new Date(now);
      start.setDate(now.getDate() - (day === 0 ? 6 : day - 1));
      start.setHours(0, 0, 0, 0);
      return start;
    }
    if (period === 'month') {
      return new Date(now.getFullYear(), now.getMonth(), 1);
    }
    if (period === 'quarter') {
      return new Date(now.getFullYear(), Math.floor(now.getMonth() / 3) * 3, 1);
    }
    return null;
  }, [period]);

  const rankings = useMemo(() => {
    if (users.length === 0) return [];

    if (dimension === 'xp_total') {
      // XP is on the UserProfile — no time filtering for XP (cumulative)
      return users
        .map((u) => ({
          userId: u.id,
          name: [u.first_name, u.last_name].filter(Boolean).join(' ') || u.email || 'Unknown',
          avatarUrl: u.avatar_url,
          value: u.xp_total || 0,
          level: u.level || 1,
          levelName: u.level_name || 'Rookie',
        }))
        .sort((a, b) => b.value - a.value);
    }

    // For record-based dimensions, count per user
    let records = [];
    let ownerField = 'owner_id';

    if (dimension === 'deals_closed') {
      records = extraData.opportunities || [];
      ownerField = 'owner_id';
    } else if (dimension === 'activities_logged') {
      records = extraData.activities || [];
      ownerField = 'created_by';
    } else if (dimension === 'tickets_resolved') {
      records = extraData.tickets || [];
      ownerField = 'assigned_to';
    }

    // Apply time filter
    const dateField = dimension === 'deals_closed' ? 'close_date'
      : dimension === 'activities_logged' ? 'date'
      : 'updated_at';

    const filtered = periodStart
      ? records.filter((r) => {
          const d = r[dateField];
          return d && new Date(d) >= periodStart;
        })
      : records;

    // Count per user
    const counts = {};
    for (const r of filtered) {
      const uid = r[ownerField];
      if (uid) counts[uid] = (counts[uid] || 0) + 1;
    }

    return users
      .map((u) => ({
        userId: u.id,
        name: [u.first_name, u.last_name].filter(Boolean).join(' ') || u.email || 'Unknown',
        avatarUrl: u.avatar_url,
        value: counts[u.id] || 0,
        level: u.level || 1,
        levelName: u.level_name || 'Rookie',
      }))
      .sort((a, b) => b.value - a.value);
  }, [users, dimension, extraData, periodStart]);

  return { rankings, loading };
}
