import { useState, useEffect } from 'react';
import DataService from '../services/DataService';

/**
 * Hook to fetch all gamification data for a user — for performance reviews.
 * Returns profile, badges, personal bests, XP history, challenges, and streaks.
 */
export default function usePerformancePortfolio(userId) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!userId) {
      setLoading(false);
      return;
    }

    const loadAll = async () => {
      setLoading(true);
      try {
        const [profile, userBadges, allBadges, personalBests, challenges, streaks] = await Promise.all([
          DataService.getById('UserProfile', userId),
          DataService.list('UserBadge', {
            filters: [{ field: 'user_id', op: '==', value: userId }],
            pageSize: 500,
          }),
          DataService.list('Badge', { pageSize: 200 }),
          DataService.list('PersonalBest', {
            filters: [{ field: 'user_id', op: '==', value: userId }],
            pageSize: 100,
          }),
          DataService.list('Challenge', {
            filters: [{ field: 'user_id', op: '==', value: userId }],
            pageSize: 50,
          }),
          DataService.list('Streak', {
            filters: [{ field: 'user_id', op: '==', value: userId }],
            pageSize: 10,
          }),
        ]);

        // Enrich earned badges with badge details
        const badgeMap = {};
        for (const b of allBadges) badgeMap[b.id] = b;
        const enrichedBadges = userBadges.map((ub) => ({
          ...ub,
          badge: badgeMap[ub.badge_id] || {},
        }));

        setData({
          profile,
          earnedBadges: enrichedBadges,
          allBadges,
          personalBests,
          challenges: challenges.sort((a, b) => {
            const da = (b.year || 0) * 100 + (b.month || 0);
            const db = (a.year || 0) * 100 + (a.month || 0);
            return da - db;
          }),
          streaks,
        });
      } catch (err) {
        console.warn('usePerformancePortfolio failed:', err);
        setData(null);
      } finally {
        setLoading(false);
      }
    };

    loadAll();
  }, [userId]);

  return { data, loading };
}

/**
 * Export portfolio data as CSV.
 */
export function exportPortfolioCSV(data) {
  if (!data?.profile) return;

  const { profile, earnedBadges, personalBests, challenges } = data;
  const lines = [];

  // Header
  lines.push('Section,Field,Value');

  // Profile
  lines.push(`Profile,Name,${profile.first_name || ''} ${profile.last_name || ''}`);
  lines.push(`Profile,Email,${profile.email || ''}`);
  lines.push(`Profile,Level,${profile.level || 1}`);
  lines.push(`Profile,Level Name,${profile.level_name || 'Rookie'}`);
  lines.push(`Profile,XP Total,${profile.xp_total || 0}`);
  lines.push(`Profile,Current Streak,${profile.current_streak_days || 0}`);
  lines.push(`Profile,Longest Streak,${profile.longest_streak_days || 0}`);
  lines.push('');

  // Badges
  for (const ub of earnedBadges) {
    lines.push(`Badge,"${ub.badge?.name || ub.badge_id}",${ub.earned_at || ''}`);
  }
  lines.push('');

  // Personal Bests
  for (const pb of personalBests) {
    lines.push(`Personal Best,"${(pb.metric || '').replace(/_/g, ' ')}",${pb.value}`);
  }
  lines.push('');

  // Challenges
  for (const c of challenges) {
    lines.push(`Challenge,"${c.title || ''}",${c.status || ''} (${c.current_value || 0}/${c.target_value || 0})`);
  }

  const csv = lines.join('\n');
  const blob = new Blob([csv], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `performance_${profile.first_name || 'user'}_${profile.last_name || ''}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}
