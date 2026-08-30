import DataService from './DataService';
import NotificationService from './NotificationService';

/**
 * A22: Client-side notification trigger utility.
 * Called after successful record saves to create notifications for affected users.
 * Checks target user's notification_preferences before creating.
 * Never throws — failures are silently logged.
 */

const TRIGGER_RULES = [
  {
    objectType: 'Ticket',
    field: 'assigned_to',
    notificationType: 'TicketAssigned',
    getTargetUserId: (changes) => changes.assigned_to,
    getTitle: () => 'Ticket assigned to you',
    getMessage: (record) => `Ticket ${record.ticket_number || ''} has been assigned to you`.trim(),
  },
  {
    objectType: 'Opportunity',
    field: 'stage_id',
    notificationType: 'DealStageChange',
    getTargetUserId: (_changes, record) => record.owner_id,
    getTitle: () => 'Deal stage changed',
    getMessage: (record, changes) =>
      `Opportunity "${record.name || ''}" stage has been updated${changes.stage_id ? ` to ${changes.stage_id}` : ''}`.trim(),
  },
  {
    objectType: 'Lead',
    field: 'owner_id',
    notificationType: 'LeadAssigned',
    getTargetUserId: (changes) => changes.owner_id,
    getTitle: () => 'Lead assigned to you',
    getMessage: (record) => {
      const name = [record.first_name, record.last_name].filter(Boolean).join(' ');
      return name ? `Lead "${name}" has been assigned to you` : 'A lead has been assigned to you';
    },
  },
];

/**
 * Check if a notification type is enabled in a user's preferences.
 * Defaults to enabled if preferences are null/undefined or the type key is missing.
 */
function isTypeEnabled(preferences, notificationType) {
  if (!preferences) return true;
  const val = preferences[notificationType];
  return val !== false;
}

/**
 * Check changes against trigger rules and create notifications as needed.
 * @param {string} objectType - The object type being saved
 * @param {string} recordId - The record ID
 * @param {object} changes - The changed fields (delta)
 * @param {object} previousRecord - The record state before the save
 * @param {string} currentUserId - The current user's ID (to prevent self-notifications)
 */
export async function checkAndCreateNotifications(objectType, recordId, changes, previousRecord, currentUserId) {
  const applicableRules = TRIGGER_RULES.filter(
    (rule) => rule.objectType === objectType && changes[rule.field] !== undefined
  );

  for (const rule of applicableRules) {
    try {
      const targetUserId = rule.getTargetUserId(changes, previousRecord);

      // Skip if no target, or if target is the current user
      if (!targetUserId || targetUserId === currentUserId) continue;

      // Check target user's notification preferences
      const targetProfile = await DataService.getById('UserProfile', targetUserId);
      if (targetProfile && !isTypeEnabled(targetProfile.notification_preferences, rule.notificationType)) {
        continue;
      }

      await NotificationService.createNotification({
        user_id: targetUserId,
        type: rule.notificationType,
        title: rule.getTitle(previousRecord, changes),
        message: rule.getMessage(previousRecord, changes),
        link_type: objectType,
        link_id: recordId,
      });
    } catch (err) {
      console.warn(`Notification trigger failed for ${rule.notificationType}:`, err);
    }
  }
}
