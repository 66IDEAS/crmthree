import AIService from './AIService';
import DataService from './DataService';

/**
 * ChallengeService — generates and manages monthly AI challenges.
 */
const ChallengeService = {
  /**
   * Generate a monthly challenge for a user using AI.
   * Returns the created Challenge record or null.
   */
  async generateMonthlyChallenge(userId) {
    if (!userId) return null;

    const isAI = await AIService.isConfigured();
    if (!isAI) return null;

    // Get user profile + recent activity data for context
    const [profile, recentActivities, recentOpps] = await Promise.all([
      DataService.getById('UserProfile', userId),
      DataService.list('Activity', {
        filters: [{ field: 'created_by', op: '==', value: userId }],
        pageSize: 20,
      }).catch(() => []),
      DataService.list('Opportunity', {
        filters: [{ field: 'owner_id', op: '==', value: userId }],
        pageSize: 20,
      }).catch(() => []),
    ]);

    const now = new Date();
    const month = now.getMonth() + 1;
    const year = now.getFullYear();

    const context = [
      `User: ${profile?.first_name || 'User'} ${profile?.last_name || ''}`.trim(),
      `Level: ${profile?.level_name || 'Rookie'} (Level ${profile?.level || 1})`,
      `XP Total: ${profile?.xp_total || 0}`,
      `Current Streak: ${profile?.current_streak_days || 0} days`,
      `Recent activities logged: ${recentActivities.length}`,
      `Recent opportunities: ${recentOpps.length}`,
      `Deals won: ${recentOpps.filter((o) => o.result === 'Won').length}`,
    ].join('\n');

    try {
      const response = await AIService.chat([
        {
          role: 'system',
          content: `You are a CRM gamification coach. Generate a personalized monthly challenge for a CRM user.
The challenge should be specific, achievable, and relevant to their current performance level.
Respond in exactly this JSON format (no markdown, no explanation):
{"title": "Challenge Title", "description": "1-2 sentence description", "metric": "one of: deals_closed, activities_logged, accounts_created, leads_converted, tickets_resolved", "target_value": <number>, "xp_reward": <number between 50-500>}`,
        },
        {
          role: 'user',
          content: `Generate a challenge for ${now.toLocaleString('default', { month: 'long' })} ${year}.\n\nUser context:\n${context}`,
        },
      ]);

      // Strip markdown code fences if the AI wrapped the JSON
      let raw = response.content.trim();
      raw = raw.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/i, '');
      const parsed = JSON.parse(raw);

      const challenge = await DataService.create('Challenge', {
        user_id: userId,
        title: parsed.title,
        description: parsed.description,
        metric: parsed.metric,
        target_value: parsed.target_value,
        current_value: 0,
        xp_reward: parsed.xp_reward || 100,
        month,
        year,
        status: 'Active',
        created_at: now.toISOString(),
      });

      return challenge;
    } catch (err) {
      console.warn('ChallengeService.generateMonthlyChallenge failed:', err);
      return null;
    }
  },

  /**
   * Update challenge progress based on a CRM action.
   */
  async updateChallengeProgress(userId, objectType, action) {
    if (!userId) return;

    try {
      const now = new Date();
      const challenges = await DataService.list('Challenge', {
        filters: [
          { field: 'user_id', op: '==', value: userId },
          { field: 'status', op: '==', value: 'Active' },
        ],
        pageSize: 5,
      });

      const current = challenges.find(
        (c) => c.month === now.getMonth() + 1 && c.year === now.getFullYear()
      );
      if (!current) return;

      // Map CRM actions to challenge metrics
      const metricMap = {
        'Opportunity:Won': 'deals_closed',
        'Activity:create': 'activities_logged',
        'Account:create': 'accounts_created',
        'Lead:Converted': 'leads_converted',
        'Ticket:Resolved': 'tickets_resolved',
      };

      const actionKey = `${objectType}:${action}`;
      if (metricMap[actionKey] !== current.metric) return;

      const newValue = (current.current_value || 0) + 1;
      const updates = { current_value: newValue };

      if (newValue >= current.target_value && current.status === 'Active') {
        updates.status = 'Completed';
        updates.completed_at = now.toISOString();
      }

      await DataService.update('Challenge', current.id, updates);
    } catch (err) {
      console.warn('ChallengeService.updateChallengeProgress failed:', err);
    }
  },
};

export default ChallengeService;
