import { db } from '../config/firebase';
import { doc, updateDoc, increment } from 'firebase/firestore';
import { getCollectionName } from './collectionNames';
import DataService from './DataService';
import NotificationService from './NotificationService';

/**
 * Gamification Service — handles XP awards, level progression, badge evaluation,
 * streak tracking, and personal best checking.
 */

// In-memory caches (refreshed on demand)
let xpEventCache = null;
let levelCache = null;
let badgeCache = null;

/**
 * Fetch and cache all active XP event configs.
 */
export async function getXPEventConfigs(forceRefresh = false) {
  if (xpEventCache && !forceRefresh) return xpEventCache;
  try {
    const events = await DataService.list('XPEvent', { pageSize: 200 });
    xpEventCache = events.filter((e) => e.active !== false);
    return xpEventCache;
  } catch {
    return [];
  }
}

/**
 * Fetch and cache all level definitions, sorted by xp_threshold ascending.
 */
export async function getLevelDefinitions(forceRefresh = false) {
  if (levelCache && !forceRefresh) return levelCache;
  try {
    const levels = await DataService.list('LevelDefinition', { pageSize: 100 });
    levelCache = levels.sort((a, b) => a.xp_threshold - b.xp_threshold);
    return levelCache;
  } catch {
    return [];
  }
}

/**
 * Fetch and cache all active badges.
 */
export async function getAllBadges(forceRefresh = false) {
  if (badgeCache && !forceRefresh) return badgeCache;
  try {
    const badges = await DataService.list('Badge', { pageSize: 200 });
    badgeCache = badges.filter((b) => b.active !== false);
    return badgeCache;
  } catch {
    return [];
  }
}

/**
 * Clear all caches (called when admin updates config).
 */
export function clearCaches() {
  xpEventCache = null;
  levelCache = null;
  badgeCache = null;
}

/**
 * Award XP to a user. Uses Firestore increment for atomicity.
 * Returns { awarded, xpAmount, leveledUp, newLevel, newLevelName } or null.
 */
export async function awardXP(userId, eventType) {
  if (!userId || !eventType) return null;

  const events = await getXPEventConfigs();
  const event = events.find((e) => e.event_type === eventType);
  if (!event) return null;

  const xpAmount = event.xp_value || 0;
  if (xpAmount <= 0) return null;

  try {
    // Atomically increment XP on the UserProfile document
    const collName = getCollectionName('UserProfile');
    const docRef = doc(db, collName, userId);
    await updateDoc(docRef, { xp_total: increment(xpAmount) });

    // Read the updated profile to check level
    const profile = await DataService.getById('UserProfile', userId);
    const newXpTotal = profile?.xp_total || 0;

    // Check for level up
    const levelResult = await checkLevelUp(userId, newXpTotal, profile);

    return {
      awarded: true,
      xpAmount,
      newXpTotal,
      ...levelResult,
    };
  } catch (err) {
    console.warn('GamificationService.awardXP failed:', err);
    return null;
  }
}

/**
 * Check if user should level up based on new XP total.
 * Updates UserProfile.level and level_name if threshold is crossed.
 */
async function checkLevelUp(userId, xpTotal, profile) {
  const levels = await getLevelDefinitions();
  if (levels.length === 0) return { leveledUp: false };

  // Find the highest level the user qualifies for
  let newLevel = levels[0];
  for (const lvl of levels) {
    if (xpTotal >= lvl.xp_threshold) {
      newLevel = lvl;
    } else {
      break;
    }
  }

  const currentLevel = profile?.level || 1;
  if (newLevel.level > currentLevel) {
    // Level up!
    try {
      await DataService.update('UserProfile', userId, {
        level: newLevel.level,
        level_name: newLevel.name,
      });

      // Create level-up notification
      try {
        await NotificationService.createNotification({
          user_id: userId,
          type: 'LevelUp',
          title: `Level Up! You are now ${newLevel.name}`,
          message: `Congratulations! You've reached level ${newLevel.level} — ${newLevel.name}.`,
          link_type: 'UserProfile',
          link_id: userId,
        });
      } catch {
        // Non-blocking
      }

      return {
        leveledUp: true,
        newLevel: newLevel.level,
        newLevelName: newLevel.name,
      };
    } catch (err) {
      console.warn('GamificationService.checkLevelUp failed:', err);
    }
  }

  return { leveledUp: false };
}

/**
 * Evaluate all badge criteria for a user. Awards any newly earned badges.
 * Returns array of newly earned badge names.
 */
export async function evaluateBadges(userId) {
  if (!userId) return [];

  try {
    const [allBadges, userBadges] = await Promise.all([
      getAllBadges(),
      DataService.list('UserBadge', {
        filters: [{ field: 'user_id', op: '==', value: userId }],
        pageSize: 500,
      }),
    ]);

    const earnedBadgeIds = new Set(userBadges.map((ub) => ub.badge_id));
    const unearnedBadges = allBadges.filter((b) => !earnedBadgeIds.has(b.id));
    if (unearnedBadges.length === 0) return [];

    // Gather metrics needed for evaluation
    const metrics = await gatherMetrics(userId, unearnedBadges);
    const newlyEarned = [];

    for (const badge of unearnedBadges) {
      if (!badge.criteria) continue;
      const { metric, threshold, comparison } = badge.criteria;
      const value = metrics[metric];
      if (value === undefined) continue;

      const met = comparison === '>='
        ? value >= threshold
        : comparison === '>'
          ? value > threshold
          : comparison === '==='
            ? value === threshold
            : false;

      if (met) {
        try {
          await DataService.create('UserBadge', {
            user_id: userId,
            badge_id: badge.id,
            earned_at: new Date().toISOString(),
          });

          // Create badge earned notification
          try {
            await NotificationService.createNotification({
              user_id: userId,
              type: 'BadgeEarned',
              title: `Badge Earned: ${badge.name}`,
              message: badge.description,
              link_type: 'UserProfile',
              link_id: userId,
            });
          } catch {
            // Non-blocking
          }

          newlyEarned.push(badge.name);
        } catch (err) {
          console.warn(`Failed to award badge "${badge.name}":`, err);
        }
      }
    }

    return newlyEarned;
  } catch (err) {
    console.warn('GamificationService.evaluateBadges failed:', err);
    return [];
  }
}

/**
 * Gather count-based metrics for badge evaluation.
 */
async function gatherMetrics(userId, badges) {
  // Determine which metrics we actually need
  const neededMetrics = new Set();
  for (const badge of badges) {
    if (badge.criteria?.metric) neededMetrics.add(badge.criteria.metric);
  }

  const metrics = {};
  const metricQueries = {
    accounts_created: () => countRecords('Account', userId),
    contacts_created: () => countRecords('Contact', userId),
    leads_created: () => countRecords('Lead', userId),
    opportunities_created: () => countRecords('Opportunity', userId),
    activities_logged: () => countRecords('Activity', userId),
    tickets_resolved: () => countResolved(userId),
    deals_won: () => countDealsWon(userId),
    leads_converted: () => countLeadsConverted(userId),
    knowledge_articles_created: () => countRecords('KnowledgeArticle', userId),
  };

  const promises = [];
  for (const metric of neededMetrics) {
    const queryFn = metricQueries[metric];
    if (queryFn) {
      promises.push(
        queryFn().then((val) => { metrics[metric] = val; }).catch(() => { metrics[metric] = 0; })
      );
    }
  }

  await Promise.all(promises);
  return metrics;
}

async function countRecords(objectType, userId) {
  const records = await DataService.list(objectType, {
    filters: [{ field: 'created_by', op: '==', value: userId }],
    pageSize: 1,
  });
  // DataService.list may not support count-only, so we get all and count
  // For efficiency, limit pageSize to a reasonable cap
  const all = await DataService.list(objectType, {
    filters: [{ field: 'created_by', op: '==', value: userId }],
    pageSize: 1000,
  });
  return all.length;
}

async function countDealsWon(userId) {
  const opps = await DataService.list('Opportunity', {
    filters: [
      { field: 'owner_id', op: '==', value: userId },
      { field: 'result', op: '==', value: 'Won' },
    ],
    pageSize: 1000,
  });
  return opps.length;
}

async function countLeadsConverted(userId) {
  const leads = await DataService.list('Lead', {
    filters: [
      { field: 'owner_id', op: '==', value: userId },
      { field: 'status', op: '==', value: 'Converted' },
    ],
    pageSize: 1000,
  });
  return leads.length;
}

async function countResolved(userId) {
  const tickets = await DataService.list('Ticket', {
    filters: [{ field: 'assigned_to', op: '==', value: userId }],
    pageSize: 1000,
  });
  // Count tickets with a resolved status — we check the is_resolved flag
  // Since we can't easily filter by joined status, count all assigned tickets
  // and filter client-side for those with a resolved-like status
  return tickets.filter((t) => t.status === 'Resolved' || t.status === 'Closed').length;
}

/**
 * Update user's activity streak.
 * Called after every XP-earning action.
 */
export async function updateStreak(userId) {
  if (!userId) return;

  try {
    const streaks = await DataService.list('Streak', {
      filters: [
        { field: 'user_id', op: '==', value: userId },
        { field: 'activity_type', op: '==', value: 'daily_activity' },
      ],
      pageSize: 1,
    });

    const today = new Date().toISOString().split('T')[0];
    const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];

    if (streaks.length > 0) {
      const streak = streaks[0];
      if (streak.last_activity_date === today) return; // Already counted today

      const newCount = streak.last_activity_date === yesterday
        ? (streak.current_count || 0) + 1
        : 1;

      const newLongest = Math.max(newCount, streak.longest_count || 0);

      await DataService.update('Streak', streak.id, {
        current_count: newCount,
        longest_count: newLongest,
        last_activity_date: today,
      });

      // Update UserProfile streak fields
      await DataService.update('UserProfile', userId, {
        current_streak_days: newCount,
        longest_streak_days: newLongest,
      });
    } else {
      // Create first streak record
      await DataService.create('Streak', {
        user_id: userId,
        activity_type: 'daily_activity',
        current_count: 1,
        longest_count: 1,
        last_activity_date: today,
      });

      await DataService.update('UserProfile', userId, {
        current_streak_days: 1,
        longest_streak_days: Math.max(1, 0),
      });
    }
  } catch (err) {
    console.warn('GamificationService.updateStreak failed:', err);
  }
}

/**
 * Check and record personal bests for a user.
 * Returns array of { metric, newValue, previousValue } for broken records.
 */
export async function checkPersonalBests(userId, objectType, record) {
  if (!userId) return [];

  const broken = [];

  try {
    // Largest deal amount
    if (objectType === 'Opportunity' && record.result === 'Won' && record.amount) {
      const pb = await checkSinglePB(userId, 'largest_deal', record.amount);
      if (pb) broken.push(pb);
    }

    // Deals closed this quarter
    if (objectType === 'Opportunity' && record.result === 'Won') {
      const count = await countDealsThisQuarter(userId);
      const pb = await checkSinglePB(userId, 'deals_closed_quarter', count);
      if (pb) broken.push(pb);
    }

    // Activities logged this week
    if (objectType === 'Activity') {
      const count = await countActivitiesThisWeek(userId);
      const pb = await checkSinglePB(userId, 'activities_logged_week', count);
      if (pb) broken.push(pb);
    }

    // Fastest ticket resolution (hours)
    if (objectType === 'Ticket' && (record.status === 'Resolved' || record.status === 'Closed') && record.created_at) {
      const created = new Date(record.created_at);
      const resolved = new Date();
      const hours = Math.round((resolved - created) / 3600000 * 10) / 10;
      if (hours > 0) {
        const pb = await checkSinglePB(userId, 'fastest_ticket_resolution', hours, 'lower');
        if (pb) broken.push(pb);
      }
    }
  } catch (err) {
    console.warn('GamificationService.checkPersonalBests failed:', err);
  }

  return broken;
}

async function countDealsThisQuarter(userId) {
  const now = new Date();
  const qStart = new Date(now.getFullYear(), Math.floor(now.getMonth() / 3) * 3, 1);
  const opps = await DataService.list('Opportunity', {
    filters: [
      { field: 'owner_id', op: '==', value: userId },
      { field: 'result', op: '==', value: 'Won' },
    ],
    pageSize: 1000,
  });
  return opps.filter((o) => o.close_date && new Date(o.close_date) >= qStart).length;
}

async function countActivitiesThisWeek(userId) {
  const now = new Date();
  const day = now.getDay();
  const weekStart = new Date(now);
  weekStart.setDate(now.getDate() - (day === 0 ? 6 : day - 1));
  weekStart.setHours(0, 0, 0, 0);
  const activities = await DataService.list('Activity', {
    filters: [{ field: 'created_by', op: '==', value: userId }],
    pageSize: 1000,
  });
  return activities.filter((a) => a.date && new Date(a.date) >= weekStart).length;
}

/**
 * Check a single personal best metric.
 * @param {string} direction - 'higher' (default) means higher is better, 'lower' means lower is better
 */
async function checkSinglePB(userId, metric, value, direction = 'higher') {
  const existing = await DataService.list('PersonalBest', {
    filters: [
      { field: 'user_id', op: '==', value: userId },
      { field: 'metric', op: '==', value: metric },
    ],
    pageSize: 1,
  });

  const numValue = Number(value);
  if (isNaN(numValue)) return null;

  if (existing.length > 0) {
    const pb = existing[0];
    const isBetter = direction === 'lower'
      ? numValue < (pb.value || Infinity)
      : numValue > (pb.value || 0);

    if (isBetter) {
      await DataService.update('PersonalBest', pb.id, {
        previous_value: pb.value,
        previous_achieved_at: pb.achieved_at,
        value: numValue,
        achieved_at: new Date().toISOString(),
      });

      try {
        await NotificationService.createNotification({
          user_id: userId,
          type: 'PersonalBest',
          title: 'New Personal Best!',
          message: `You set a new personal best for ${metric.replace(/_/g, ' ')}: ${numValue}`,
          link_type: 'UserProfile',
          link_id: userId,
        });
      } catch {
        // Non-blocking
      }

      return { metric, newValue: numValue, previousValue: pb.value };
    }
  } else {
    // First entry — create it (not a "broken" record, just initializing)
    await DataService.create('PersonalBest', {
      user_id: userId,
      metric,
      value: numValue,
      achieved_at: new Date().toISOString(),
    });
  }

  return null;
}

// Default seed data
export const DEFAULT_LEVELS = [
  { level: 1, name: 'Rookie', xp_threshold: 0 },
  { level: 2, name: 'Contributor', xp_threshold: 500 },
  { level: 3, name: 'Closer', xp_threshold: 2000 },
  { level: 4, name: 'Achiever', xp_threshold: 5000 },
  { level: 5, name: 'Dealmaker', xp_threshold: 10000 },
  { level: 6, name: 'Expert', xp_threshold: 25000 },
  { level: 7, name: 'Legend', xp_threshold: 50000 },
];

export const DEFAULT_XP_EVENTS = [
  { event_type: 'create_account', description: 'Create a new account', xp_value: 10, active: true },
  { event_type: 'create_contact', description: 'Create a new contact', xp_value: 10, active: true },
  { event_type: 'create_lead', description: 'Create a new lead', xp_value: 10, active: true },
  { event_type: 'create_opportunity', description: 'Create a new opportunity', xp_value: 15, active: true },
  { event_type: 'log_activity', description: 'Log an activity', xp_value: 15, active: true },
  { event_type: 'close_deal_won', description: 'Close a deal as Won', xp_value: 100, active: true },
  { event_type: 'resolve_ticket', description: 'Resolve a support ticket', xp_value: 50, active: true },
  { event_type: 'convert_lead', description: 'Convert a lead', xp_value: 75, active: true },
  { event_type: 'create_quotation', description: 'Create a quotation', xp_value: 20, active: true },
  { event_type: 'create_knowledge_article', description: 'Create a knowledge article', xp_value: 25, active: true },
];

export const DEFAULT_BADGES = [
  { name: 'First Steps', description: 'Create your first account', category: 'Milestone', criteria: { metric: 'accounts_created', threshold: 1, comparison: '>=' }, is_custom: false, active: true },
  { name: 'Century Club', description: 'Create 100 accounts', category: 'Milestone', criteria: { metric: 'accounts_created', threshold: 100, comparison: '>=' }, is_custom: false, active: true },
  { name: 'Deal Maker', description: 'Close your first deal', category: 'Sales', criteria: { metric: 'deals_won', threshold: 1, comparison: '>=' }, is_custom: false, active: true },
  { name: 'Deal Master', description: 'Close 25 deals', category: 'Sales', criteria: { metric: 'deals_won', threshold: 25, comparison: '>=' }, is_custom: false, active: true },
  { name: 'SLA Warrior', description: 'Resolve 50 tickets', category: 'Service', criteria: { metric: 'tickets_resolved', threshold: 50, comparison: '>=' }, is_custom: false, active: true },
  { name: 'Connector', description: 'Log 100 activities', category: 'Collaboration', criteria: { metric: 'activities_logged', threshold: 100, comparison: '>=' }, is_custom: false, active: true },
  { name: 'Lead Machine', description: 'Convert 25 leads', category: 'Sales', criteria: { metric: 'leads_converted', threshold: 25, comparison: '>=' }, is_custom: false, active: true },
  { name: 'Knowledge Guru', description: 'Create 10 knowledge articles', category: 'Data Quality', criteria: { metric: 'knowledge_articles_created', threshold: 10, comparison: '>=' }, is_custom: false, active: true },
];
