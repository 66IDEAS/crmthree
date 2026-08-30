import { functions } from '../config/firebase';
import { httpsCallable } from 'firebase/functions';
import DataService from './DataService';

let configuredCache = null;
let configuredCacheTime = 0;
const CACHE_TTL = 60000; // 1 minute

/**
 * A20: Client-side AI service abstraction.
 * All AI calls are routed through the callAIProvider Cloud Function.
 */
const AIService = {
  /**
   * Check if an active AI provider is configured.
   * Caches the result for 1 minute.
   */
  async isConfigured() {
    const now = Date.now();
    if (configuredCache !== null && now - configuredCacheTime < CACHE_TTL) {
      return configuredCache;
    }
    try {
      const configs = await DataService.list('AIProviderConfig', { pageSize: 100 });
      const active = configs.some((c) => c.is_active);
      configuredCache = active;
      configuredCacheTime = now;
      return active;
    } catch {
      configuredCache = false;
      configuredCacheTime = now;
      return false;
    }
  },

  /** Clear the isConfigured cache (e.g., after saving a provider config) */
  clearCache() {
    configuredCache = null;
    configuredCacheTime = 0;
  },

  /**
   * Send a chat message to the AI provider.
   * @param {Array<{role: string, content: string}>} messages
   * @returns {Promise<{content: string, model: string, tokens_used: number}>}
   */
  async chat(messages) {
    return this._call('chat', { messages });
  },

  /**
   * Summarize text using the AI provider.
   * @param {string} text
   * @param {string} [context]
   * @returns {Promise<{content: string}>}
   */
  async summarize(text, context) {
    return this._call('summarize', { text, context });
  },

  /**
   * Generate content using the AI provider.
   * @param {string} prompt
   * @param {string} [context]
   * @returns {Promise<{content: string}>}
   */
  async generate(prompt, context) {
    return this._call('generate', { prompt, context });
  },

  /**
   * F23: Perform AI-powered semantic search across CRM records.
   * @param {string} query - Natural language search query
   * @returns {Promise<{content: string, results: Array<{type: string, id: string, name: string, reason: string}>}>}
   */
  async semanticSearch(query) {
    const response = await this._call('semanticSearch', { query });
    // Results are already parsed by the Cloud Function
    return { ...response, results: response.results || [] };
  },

  /**
   * Internal: call the Cloud Function.
   */
  async _call(operation, params) {
    if (!functions) {
      throw new Error('Firebase is not configured');
    }
    const callAIProvider = httpsCallable(functions, 'callAIProvider');
    const result = await callAIProvider({ operation, params });
    return result.data;
  },
};

export default AIService;
