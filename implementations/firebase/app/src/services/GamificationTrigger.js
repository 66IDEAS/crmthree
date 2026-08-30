import { awardXP, evaluateBadges, updateStreak, checkPersonalBests } from './GamificationService';
import ChallengeService from './ChallengeService';

/**
 * Gamification trigger rules — maps CRM actions to XP event types.
 * Follows the same pattern as NotificationTrigger.js.
 */
const XP_RULES = [
  // Record creation rules (matched by objectType + action)
  { objectType: 'Account', action: 'create', eventType: 'create_account' },
  { objectType: 'Contact', action: 'create', eventType: 'create_contact' },
  { objectType: 'Lead', action: 'create', eventType: 'create_lead' },
  { objectType: 'Opportunity', action: 'create', eventType: 'create_opportunity' },
  { objectType: 'Activity', action: 'create', eventType: 'log_activity' },
  { objectType: 'Quotation', action: 'create', eventType: 'create_quotation' },
  { objectType: 'KnowledgeArticle', action: 'create', eventType: 'create_knowledge_article' },

  // Field change rules (matched by objectType + field + value)
  { objectType: 'Opportunity', field: 'result', value: 'Won', eventType: 'close_deal_won' },
  { objectType: 'Lead', field: 'status', value: 'Converted', eventType: 'convert_lead' },
  { objectType: 'Ticket', field: 'status', value: 'Resolved', eventType: 'resolve_ticket' },
];

/**
 * Check a create action against XP rules and award XP.
 * Called after successful record creation.
 *
 * @param {string} objectType
 * @param {string} recordId
 * @param {object} data - The created record data
 * @param {string} userId - Current user's ID
 */
export async function checkAndAwardXPForCreate(objectType, recordId, data, userId) {
  if (!userId) return;

  const results = [];

  // Check creation rules
  const createRules = XP_RULES.filter((r) => r.objectType === objectType && r.action === 'create');
  for (const rule of createRules) {
    try {
      const result = await awardXP(userId, rule.eventType);
      if (result?.awarded) results.push(result);
    } catch {
      // Silent
    }
  }

  // Check if created data matches any field-value rules (e.g., creating an already-Won opportunity)
  const fieldRules = XP_RULES.filter(
    (r) => r.objectType === objectType && r.field && data[r.field] === r.value
  );
  for (const rule of fieldRules) {
    try {
      const result = await awardXP(userId, rule.eventType);
      if (result?.awarded) results.push(result);
    } catch {
      // Silent
    }
  }

  // Post-XP side effects (run in parallel, all non-blocking)
  let newBadges = [];
  let brokenPBs = [];
  try {
    const [badges, , pbs] = await Promise.all([
      evaluateBadges(userId).catch(() => []),
      updateStreak(userId).catch(() => {}),
      checkPersonalBests(userId, objectType, data).catch(() => []),
    ]);
    newBadges = badges || [];
    brokenPBs = pbs || [];
  } catch {
    // Silent
  }

  // Fire celebration events
  for (const r of results) {
    if (r.leveledUp) {
      fireCelebration('level_up', { level: r.newLevel, levelName: r.newLevelName });
    }
  }
  for (const badgeName of newBadges) {
    fireCelebration('badge_earned', { badgeName });
  }
  for (const pb of brokenPBs) {
    fireCelebration('personal_best', pb);
  }
  // Special celebration for deal won
  if (objectType === 'Opportunity' && data.result === 'Won') {
    fireCelebration('deal_won', { message: data.name || 'Deal closed!' });
  }

  // Update challenge progress
  try {
    const challengeAction = data.result === 'Won' ? 'Won'
      : data.status === 'Converted' ? 'Converted'
      : data.status === 'Resolved' ? 'Resolved'
      : 'create';
    ChallengeService.updateChallengeProgress(userId, objectType, challengeAction).catch(() => {});
  } catch {
    // Silent
  }
}

/**
 * Check an update action against XP rules and award XP.
 * Called after successful record update.
 *
 * @param {string} objectType
 * @param {string} recordId
 * @param {object} changes - The changed fields
 * @param {object} previousRecord - The record before the update
 * @param {string} userId - Current user's ID
 */
export async function checkAndAwardXPForUpdate(objectType, recordId, changes, previousRecord, userId) {
  if (!userId) return;

  const results = [];

  // Check field-value rules (only if the field actually changed to the target value)
  const fieldRules = XP_RULES.filter(
    (r) => r.objectType === objectType && r.field && changes[r.field] === r.value
      && previousRecord[r.field] !== r.value
  );

  for (const rule of fieldRules) {
    try {
      const result = await awardXP(userId, rule.eventType);
      if (result?.awarded) results.push(result);
    } catch {
      // Silent
    }
  }

  if (results.length === 0) return;

  // Post-XP side effects
  const mergedRecord = { ...previousRecord, ...changes };
  let newBadges = [];
  let brokenPBs = [];
  try {
    const [badges, , pbs] = await Promise.all([
      evaluateBadges(userId).catch(() => []),
      updateStreak(userId).catch(() => {}),
      checkPersonalBests(userId, objectType, mergedRecord).catch(() => []),
    ]);
    newBadges = badges || [];
    brokenPBs = pbs || [];
  } catch {
    // Silent
  }

  // Fire celebration events
  for (const r of results) {
    if (r.leveledUp) {
      fireCelebration('level_up', { level: r.newLevel, levelName: r.newLevelName });
    }
  }
  for (const badgeName of newBadges) {
    fireCelebration('badge_earned', { badgeName });
  }
  for (const pb of brokenPBs) {
    fireCelebration('personal_best', pb);
  }
  // Special celebration for deal won (via update to Won)
  if (objectType === 'Opportunity' && changes.result === 'Won' && previousRecord.result !== 'Won') {
    fireCelebration('deal_won', { message: mergedRecord.name || 'Deal closed!' });
  }

  // Update challenge progress
  try {
    const challengeAction = changes.result === 'Won' ? 'Won'
      : changes.status === 'Converted' ? 'Converted'
      : changes.status === 'Resolved' ? 'Resolved'
      : null;
    if (challengeAction) {
      ChallengeService.updateChallengeProgress(userId, objectType, challengeAction).catch(() => {});
    }
  } catch {
    // Silent
  }
}

/**
 * Fire a celebration event via CustomEvent on the window.
 * The GamificationContext listens for these events.
 */
function fireCelebration(type, data) {
  try {
    window.dispatchEvent(new CustomEvent('gamification-celebration', {
      detail: { type, ...data },
    }));
  } catch {
    // Silent — window may not be available
  }
}
