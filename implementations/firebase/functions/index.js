const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

const app = initializeApp();
const db = getFirestore(app);

// ─── Provider Adapters ───────────────────────────────────────────

const OPENAI_COMPAT_DEFAULTS = {
  OpenAI: 'https://api.openai.com/v1/chat/completions',
  Moonshot: 'https://api.moonshot.cn/v1/chat/completions',
};

function buildOpenAIRequest(config, messages) {
  let url = config.endpoint_url || OPENAI_COMPAT_DEFAULTS[config.provider] || OPENAI_COMPAT_DEFAULTS.OpenAI;
  // Append /chat/completions if the user provided a base URL
  if (!url.endsWith('/chat/completions')) {
    url = url.replace(/\/+$/, '') + '/chat/completions';
  }
  return {
    url,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${config.api_key}`,
    },
    body: { model: config.model, messages },
  };
}

function parseOpenAIResponse(data) {
  return {
    content: data.choices?.[0]?.message?.content || '',
    model: data.model || '',
    tokens_used: data.usage?.total_tokens || 0,
  };
}

function buildGoogleRequest(config, messages) {
  const model = config.model || 'gemini-2.0-flash';
  const base = config.endpoint_url || 'https://generativelanguage.googleapis.com/v1beta';
  const url = `${base}/models/${model}:generateContent?key=${config.api_key}`;
  // Convert chat messages to Google format
  const contents = messages
    .filter((m) => m.role !== 'system')
    .map((m) => ({
      role: m.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: m.content }],
    }));
  // Prepend system instruction if present
  const systemMsg = messages.find((m) => m.role === 'system');
  const systemInstruction = systemMsg ? { parts: [{ text: systemMsg.content }] } : undefined;
  return {
    url,
    headers: { 'Content-Type': 'application/json' },
    body: { contents, ...(systemInstruction && { systemInstruction }) },
  };
}

function parseGoogleResponse(data) {
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text || '';
  return {
    content: text,
    model: data.modelVersion || '',
    tokens_used: data.usageMetadata?.totalTokenCount || 0,
  };
}

function buildAnthropicRequest(config, messages) {
  const url = config.endpoint_url || 'https://api.anthropic.com/v1/messages';
  // Extract system message
  const systemMsg = messages.find((m) => m.role === 'system');
  const chatMessages = messages
    .filter((m) => m.role !== 'system')
    .map((m) => ({ role: m.role, content: m.content }));
  return {
    url,
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': config.api_key,
      'anthropic-version': '2023-06-01',
    },
    body: {
      model: config.model,
      max_tokens: 1024,
      messages: chatMessages,
      ...(systemMsg && { system: systemMsg.content }),
    },
  };
}

function parseAnthropicResponse(data) {
  const text = data.content?.[0]?.text || '';
  return {
    content: text,
    model: data.model || '',
    tokens_used: (data.usage?.input_tokens || 0) + (data.usage?.output_tokens || 0),
  };
}

const PROVIDER_ADAPTERS = {
  OpenAI: { build: buildOpenAIRequest, parse: parseOpenAIResponse },
  Moonshot: { build: buildOpenAIRequest, parse: parseOpenAIResponse }, // OpenAI-compatible
  Google: { build: buildGoogleRequest, parse: parseGoogleResponse },
  Anthropic: { build: buildAnthropicRequest, parse: parseAnthropicResponse },
};

// ─── Data-Aware Context Injection ────────────────────────────────

const OBJECT_TYPE_KEYWORDS = {
  Account: ['account', 'customer', 'company', 'client', 'partner', 'vendor'],
  Contact: ['contact', 'person', 'people'],
  Lead: ['lead'],
  Opportunity: ['opportunity', 'deal', 'pipeline', 'forecast'],
  Quotation: ['quote', 'quotation', 'proposal'],
  SalesOrder: ['sales order', 'order'],
  Invoice: ['invoice', 'billing', 'payment'],
  Product: ['product', 'material', 'item', 'catalog'],
  Activity: ['activity', 'call', 'meeting', 'task', 'email', 'event'],
  Ticket: ['ticket', 'case', 'issue', 'support', 'service request'],
  KnowledgeArticle: ['knowledge', 'article', 'faq'],
  Asset: ['asset', 'equipment', 'device', 'hardware'],
  SLA: ['sla', 'service level'],
  ServiceContract: ['contract', 'service contract', 'agreement'],
};

const COLLECTION_NAMES = {
  Account: 'accounts',
  Contact: 'contacts',
  Lead: 'leads',
  Opportunity: 'opportunities',
  Quotation: 'quotations',
  SalesOrder: 'salesOrders',
  Invoice: 'invoices',
  Product: 'products',
  Activity: 'activities',
  Ticket: 'tickets',
  KnowledgeArticle: 'knowledgeArticles',
  Asset: 'assets',
  SLA: 'slas',
  ServiceContract: 'serviceContracts',
};

const KEY_FIELDS = {
  Account: ['name1', 'name2', 'industry', 'annual_revenue', 'company_size', 'city', 'country', 'phone'],
  Contact: ['first_name', 'last_name', 'email', 'phone', 'title', 'department'],
  Lead: ['first_name', 'last_name', 'company', 'status', 'source', 'email'],
  Opportunity: ['name', 'stage_id', 'amount', 'close_date', 'probability'],
  Quotation: ['quotation_number', 'status', 'total_amount', 'valid_to'],
  SalesOrder: ['order_number', 'status', 'total_amount', 'order_date'],
  Invoice: ['invoice_number', 'status', 'total_amount', 'due_date'],
  Product: ['name', 'product_number', 'base_price', 'product_group', 'status'],
  Activity: ['subject', 'type', 'status', 'due_date', 'priority'],
  Ticket: ['subject', 'status_id', 'priority', 'category', 'created_at'],
  KnowledgeArticle: ['title', 'category', 'status', 'published_at'],
  Asset: ['name', 'serial_number', 'status', 'install_date'],
  SLA: ['name', 'response_time_hours', 'resolution_time_hours'],
  ServiceContract: ['name', 'status', 'start_date', 'end_date'],
};

/**
 * Scans user messages for keywords to determine which object types to query.
 * Returns up to 3 matched types. Defaults to Account + Opportunity if none match.
 */
function detectRelevantTypes(messages) {
  const userText = messages
    .filter((m) => m.role !== 'system')
    .map((m) => m.content)
    .join(' ')
    .toLowerCase();

  const matched = [];
  for (const [objectType, keywords] of Object.entries(OBJECT_TYPE_KEYWORDS)) {
    if (keywords.some((kw) => userText.includes(kw))) {
      matched.push(objectType);
      if (matched.length >= 3) break;
    }
  }

  return matched.length > 0 ? matched : ['Account', 'Opportunity'];
}

/**
 * Fetches up to 200 records per type from Firestore, selecting only key fields.
 */
async function fetchContextData(types, firestore, recordLimit = 200) {
  const result = {};
  await Promise.all(
    types.map(async (type) => {
      const collection = COLLECTION_NAMES[type];
      const fields = KEY_FIELDS[type];
      if (!collection || !fields) return;
      try {
        const snap = await firestore.collection(collection).limit(recordLimit).get();
        result[type] = snap.docs.map((doc) => {
          const data = doc.data();
          const picked = { _id: doc.id };
          for (const f of fields) {
            if (data[f] !== undefined && data[f] !== null && data[f] !== '') {
              picked[f] = data[f];
            }
          }
          return picked;
        });
      } catch {
        // Skip failed collections
      }
    })
  );
  return result;
}

/**
 * Formats fetched records into compact pipe-separated text for AI context.
 */
function formatContextText(data) {
  const sections = [];
  for (const [type, records] of Object.entries(data)) {
    if (!records || records.length === 0) continue;
    const fields = KEY_FIELDS[type];
    const header = 'id | ' + fields.join(' | ');
    const rows = records.map((r) => {
      const vals = fields.map((f) => {
        const val = r[f];
        if (val === undefined || val === null) return '';
        if (val instanceof Date) return val.toISOString().split('T')[0];
        if (typeof val === 'object' && val._seconds) {
          return new Date(val._seconds * 1000).toISOString().split('T')[0];
        }
        return String(val);
      });
      return (r._id || '') + ' | ' + vals.join(' | ');
    });
    sections.push(`=== ${type} (${records.length} records) ===\n${header}\n${rows.join('\n')}`);
  }
  return sections.join('\n\n');
}

// ─── Operation → Messages Mapping ────────────────────────────────

function operationToMessages(operation, params) {
  switch (operation) {
    case 'chat':
      return params.messages || [];
    case 'summarize':
      return [
        { role: 'system', content: 'You are a helpful assistant. Provide a concise summary.' },
        { role: 'user', content: params.context ? `Context: ${params.context}\n\n${params.text}` : params.text },
      ];
    case 'generate':
      return [
        { role: 'system', content: 'You are a helpful assistant.' },
        { role: 'user', content: params.context ? `Context: ${params.context}\n\n${params.prompt}` : params.prompt },
      ];
    case 'semanticSearch':
      return [
        {
          role: 'system',
          content: `You are a CRM search engine. The user will provide a natural language search query. You will receive CRM data with records that have real database IDs in the "id" column.

CRITICAL RULES:
- You MUST ONLY return records that actually exist in the provided data
- You MUST use the EXACT id values from the "id" column in the data — these are long alphanumeric strings like "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
- NEVER invent, guess, or fabricate IDs — if you cannot find the exact id from the data, do not include that record
- If no records match the query, return {"results":[]}

You MUST respond with ONLY a valid JSON object in this exact format, with no other text:
{"results":[{"type":"Account","id":"exact-id-from-data","name":"Display Name","reason":"Brief match explanation"}]}

Return up to 20 results maximum. Match by intent and meaning, not just keywords.`,
        },
        { role: 'user', content: params.query },
      ];
    default:
      return params.messages || [{ role: 'user', content: params.prompt || params.text || '' }];
  }
}

// ─── Cloud Function: callAIProvider ──────────────────────────────

/**
 * A20: Secure AI proxy Cloud Function.
 * Accepts { operation, params }, fetches the active AI provider config,
 * builds a provider-specific request, and returns a normalized response.
 */
exports.callAIProvider = onCall(
  { region: 'europe-west1', invoker: 'public' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be authenticated');
    }

    const { operation, params } = request.data;
    if (!operation || !params) {
      throw new HttpsError('invalid-argument', 'Missing operation or params');
    }

    // Fetch active AI provider config
    const snapshot = await db
      .collection('aiProviderConfigs')
      .where('is_active', '==', true)
      .limit(1)
      .get();

    if (snapshot.empty) {
      throw new HttpsError('failed-precondition', 'No active AI provider configured');
    }

    const config = snapshot.docs[0].data();
    const adapter = PROVIDER_ADAPTERS[config.provider];
    if (!adapter) {
      throw new HttpsError('internal', `Unsupported AI provider: ${config.provider}`);
    }

    let messages = operationToMessages(operation, params);

    // Data-aware context injection for chat operations
    if (operation === 'chat' && messages.length > 0) {
      try {
        const types = detectRelevantTypes(messages);
        const contextData = await fetchContextData(types, db);
        const contextText = formatContextText(contextData);
        if (contextText) {
          const contextMsg = {
            role: 'system',
            content: `Below is the relevant CRM data from the database. Use this data to answer the user's question accurately. If the data doesn't contain enough information to answer, say so.\n\n${contextText}`,
          };
          // Insert data context before the first message
          messages = [contextMsg, ...messages];
        }
      } catch {
        // Context injection failure should not block the AI call
      }
    }

    // Data-aware context injection for semantic search
    if (operation === 'semanticSearch' && messages.length > 0) {
      try {
        const types = detectRelevantTypes(messages);
        const contextData = await fetchContextData(types, db);
        const contextText = formatContextText(contextData);
        if (contextText) {
          const contextMsg = {
            role: 'system',
            content: `Below is the CRM data from the database. Each record has a real "id" value in the first column — you MUST use these exact IDs in your results. NEVER make up IDs.\n\n${contextText}`,
          };
          // Insert data context between system prompt and user query
          messages = [messages[0], contextMsg, ...messages.slice(1)];
        }
      } catch {
        // Context injection failure should not block the AI call
      }
    }

    const { url, headers, body } = adapter.build(config, messages);

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers,
        body: JSON.stringify(body),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new HttpsError(
          'internal',
          `AI provider error (${response.status}): ${errorText.slice(0, 500)}`
        );
      }

      const data = await response.json();
      const parsed = adapter.parse(data);

      // Post-process semantic search: parse JSON from AI response
      if (operation === 'semanticSearch') {
        try {
          let jsonStr = parsed.content.trim();
          // Strip markdown code fences if present
          const fenceMatch = jsonStr.match(/```(?:json)?\s*([\s\S]*?)```/);
          if (fenceMatch) jsonStr = fenceMatch[1].trim();
          const searchResults = JSON.parse(jsonStr);
          return { ...parsed, results: searchResults.results || [] };
        } catch {
          return { ...parsed, results: [] };
        }
      }

      return parsed;
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      throw new HttpsError('internal', `AI call failed: ${err.message}`);
    }
  }
);

// ─── Cloud Function: replicationProxy ────────────────────────────

/**
 * Generic HTTP proxy for data replication.
 * Accepts { url, body } and forwards the POST to the target URL.
 * Solves CORS issues when calling external APIs from the browser.
 */
exports.replicationProxy = onCall(
  { region: 'europe-west1', invoker: 'public' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be authenticated');
    }

    const { url, body } = request.data;
    if (!url) {
      throw new HttpsError('invalid-argument', 'Missing url parameter');
    }

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });

      if (!response.ok) {
        const text = await response.text();
        throw new HttpsError('internal', `External API error ${response.status}: ${text}`);
      }

      const data = await response.json();
      return data;
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      throw new HttpsError('internal', err.message);
    }
  }
);

// ─── External Data Source Helpers ─────────────────────────────────

/**
 * Applies authentication headers based on the DataSourceConfig auth_type.
 */
function applyExternalAuth(headers, config) {
  const authConfig = config.auth_config || {};
  switch (config.auth_type) {
    case 'BasicAuth':
      headers['Authorization'] = 'Basic ' + Buffer.from(`${authConfig.username || ''}:${authConfig.password || ''}`).toString('base64');
      break;
    case 'OAuth2':
      headers['Authorization'] = `Bearer ${authConfig.access_token || ''}`;
      break;
    case 'APIKey':
      headers[authConfig.header_name || 'X-API-Key'] = authConfig.api_key || '';
      break;
    default:
      break;
  }
}

/**
 * Maps CRM field names to external field names using field_mapping.
 * field_mapping is { externalFieldName: crmFieldName }.
 * For writes we reverse: CRM → external.
 */
function mapCrmToExternal(fieldMapping, data) {
  if (!fieldMapping || !data) return data;
  const reversed = {};
  for (const [ext, crm] of Object.entries(fieldMapping)) {
    reversed[crm] = ext;
  }
  const mapped = {};
  for (const [key, value] of Object.entries(data)) {
    mapped[reversed[key] || key] = value;
  }
  return mapped;
}

/**
 * Maps external field names to CRM field names using field_mapping.
 */
function mapExternalToCrm(fieldMapping, record) {
  if (!fieldMapping || !record) return record;
  const mapped = {};
  for (const [key, value] of Object.entries(record)) {
    mapped[fieldMapping[key] || key] = value;
  }
  return mapped;
}

/**
 * Builds the HTTP request URL and method for the external system.
 */
function buildExternalRequest(config, operation, args) {
  const baseUrl = (config.endpoint_url || '').replace(/\/+$/, '');
  switch (operation) {
    case 'getById':
      return { url: `${baseUrl}/${args.id}`, method: 'GET', body: null };
    case 'list':
      return { url: baseUrl, method: 'GET', body: null };
    case 'create':
      return { url: baseUrl, method: 'POST', body: mapCrmToExternal(config.field_mapping, args.data) };
    case 'update':
      return { url: `${baseUrl}/${args.id}`, method: 'PUT', body: mapCrmToExternal(config.field_mapping, args.data) };
    case 'remove':
      return { url: `${baseUrl}/${args.id}`, method: 'DELETE', body: null };
    default:
      throw new HttpsError('invalid-argument', `Unknown operation: ${operation}`);
  }
}

/**
 * Transforms the external system response to CRM format.
 */
function transformExternalResponse(fieldMapping, operation, data) {
  switch (operation) {
    case 'getById':
      return mapExternalToCrm(fieldMapping, data);
    case 'list': {
      const records = Array.isArray(data) ? data : (data.records || data.results || data.value || data.d?.results || []);
      return records.map((r) => mapExternalToCrm(fieldMapping, r));
    }
    case 'create':
    case 'update':
      return mapExternalToCrm(fieldMapping, data);
    case 'remove':
      return { success: true };
    default:
      return data;
  }
}

// ─── Cloud Function: externalDataProxy ───────────────────────────

/**
 * A16/F30: Secure proxy for external data source operations.
 * Credentials stay server-side. The client sends only objectType, operation, and args.
 */
exports.externalDataProxy = onCall(
  { region: 'europe-west1', invoker: 'public' },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be authenticated');
    }

    const { objectType, operation, args } = request.data;
    if (!objectType || !operation) {
      throw new HttpsError('invalid-argument', 'Missing objectType or operation');
    }

    // Fetch DataSourceConfig server-side
    const configSnap = await db.collection('dataSourceConfigs')
      .where('object_type', '==', objectType)
      .where('active', '==', true)
      .limit(1)
      .get();

    if (configSnap.empty) {
      throw new HttpsError('not-found', `No active external data source config for ${objectType}`);
    }
    const config = configSnap.docs[0].data();
    if (config.source_type !== 'External') {
      throw new HttpsError('failed-precondition', `Data source for ${objectType} is not configured as External`);
    }
    if (!config.endpoint_url) {
      throw new HttpsError('failed-precondition', `No endpoint URL configured for ${objectType}`);
    }

    const headers = { 'Content-Type': 'application/json', Accept: 'application/json' };
    applyExternalAuth(headers, config);

    const { url, method, body } = buildExternalRequest(config, operation, args || {});

    try {
      const fetchOpts = { method, headers };
      if (body) fetchOpts.body = JSON.stringify(body);
      const response = await fetch(url, fetchOpts);

      if (!response.ok) {
        const errorText = await response.text();
        throw new HttpsError('internal', `External system error (${response.status}): ${errorText.slice(0, 500)}`);
      }

      // DELETE may return empty body
      if (operation === 'remove') return { success: true };

      const data = await response.json();
      return transformExternalResponse(config.field_mapping, operation, data);
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      throw new HttpsError('internal', `External data source call failed: ${err.message}`);
    }
  }
);

// ─── REST API (A18/F32) ──────────────────────────────────────────

const express = require('express');
const cors = require('cors');

const apiApp = express();
apiApp.use(cors({ origin: true }));
apiApp.use(express.json());

// Slug → ObjectType mapping (mirrors client navigation.js)
const SLUG_TO_TYPE = {
  accounts: 'Account',
  contacts: 'Contact',
  leads: 'Lead',
  opportunities: 'Opportunity',
  quotes: 'Quotation',
  'sales-orders': 'SalesOrder',
  invoices: 'Invoice',
  products: 'Product',
  activities: 'Activity',
  tickets: 'Ticket',
  knowledge: 'KnowledgeArticle',
  assets: 'Asset',
  slas: 'SLA',
  contracts: 'ServiceContract',
};

/**
 * Firebase Auth middleware — verifies Bearer token.
 */
async function verifyAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or invalid Authorization header. Use: Bearer <Firebase ID Token>' });
  }
  try {
    req.user = await getAuth().verifyIdToken(authHeader.split('Bearer ')[1]);
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}
apiApp.use('/api/v1', verifyAuth);

/**
 * Resolve slug param to objectType and collection.
 */
function resolveType(slug) {
  const objectType = SLUG_TO_TYPE[slug];
  if (!objectType) return null;
  const col = COLLECTION_NAMES[objectType];
  if (!col) return null;
  return { objectType, collection: col };
}

/**
 * Fetches DataSourceConfig for a given objectType.
 * Returns { source_type: 'Local' } if no config exists.
 */
async function getDataSourceConfig(objectType) {
  const snap = await db.collection('dataSourceConfigs')
    .where('object_type', '==', objectType)
    .where('active', '==', true)
    .limit(1)
    .get();
  if (snap.empty) return { source_type: 'Local' };
  return snap.docs[0].data();
}

/**
 * Proxies a request to an external data source from the REST API.
 */
async function proxyToExternal(config, operation, args) {
  const headers = { 'Content-Type': 'application/json', Accept: 'application/json' };
  applyExternalAuth(headers, config);
  const { url, method, body } = buildExternalRequest(config, operation, args);
  const fetchOpts = { method, headers };
  if (body) fetchOpts.body = JSON.stringify(body);
  const response = await fetch(url, fetchOpts);
  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`External error (${response.status}): ${errorText.slice(0, 500)}`);
  }
  if (operation === 'remove') return { success: true };
  const data = await response.json();
  return transformExternalResponse(config.field_mapping, operation, data);
}

/**
 * Server-side auto-number generation (mirrors FirestoreMapper.getNextAutoNumber).
 */
async function serverGetNextAutoNumber(objectType) {
  const counterRef = db.collection('counters').doc(objectType);
  const result = await db.runTransaction(async (tx) => {
    const doc = await tx.get(counterRef);
    const next = doc.exists ? (doc.data().next || 1) : 1;
    tx.set(counterRef, { next: next + 1 });
    return next;
  });
  return result;
}

// ─── Auto-documentation endpoint ─────────────────────────────────

apiApp.get('/api/v1/_docs', (req, res) => {
  const objects = {};
  for (const [slug, objectType] of Object.entries(SLUG_TO_TYPE)) {
    objects[slug] = {
      objectType,
      endpoints: {
        list: { method: 'GET', path: `/api/v1/${slug}`, params: 'pageSize (default 25), sortField, sortDir (asc/desc)' },
        get: { method: 'GET', path: `/api/v1/${slug}/:id` },
        create: { method: 'POST', path: `/api/v1/${slug}`, body: 'Record fields as JSON' },
        update: { method: 'PUT', path: `/api/v1/${slug}/:id`, body: 'Fields to update as JSON' },
        delete: { method: 'DELETE', path: `/api/v1/${slug}/:id` },
      },
    };
  }
  res.json({
    title: 'CRMThree REST API',
    version: 'v1',
    authentication: 'Bearer token (Firebase Auth ID token) in Authorization header',
    baseUrl: `${req.protocol}://${req.get('host')}/api/v1`,
    objects,
  });
});

// ─── List records ────────────────────────────────────────────────

apiApp.get('/api/v1/:objectType', async (req, res) => {
  const resolved = resolveType(req.params.objectType);
  if (!resolved) return res.status(404).json({ error: `Unknown object type: ${req.params.objectType}` });

  try {
    const dsConfig = await getDataSourceConfig(resolved.objectType);
    if (dsConfig.source_type === 'External' && dsConfig.active !== false) {
      const data = await proxyToExternal(dsConfig, 'list', { options: req.query });
      return res.json({ data, count: Array.isArray(data) ? data.length : 0 });
    }

    const { pageSize = '25', sortField, sortDir = 'asc' } = req.query;
    let q = db.collection(resolved.collection);
    if (sortField) q = q.orderBy(sortField, sortDir);
    q = q.limit(parseInt(pageSize, 10));
    const snap = await q.get();
    const records = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    return res.json({ data: records, count: records.length });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ─── Get single record ──────────────────────────────────────────

apiApp.get('/api/v1/:objectType/:id', async (req, res) => {
  const resolved = resolveType(req.params.objectType);
  if (!resolved) return res.status(404).json({ error: `Unknown object type: ${req.params.objectType}` });

  try {
    const dsConfig = await getDataSourceConfig(resolved.objectType);
    if (dsConfig.source_type === 'External' && dsConfig.active !== false) {
      const data = await proxyToExternal(dsConfig, 'getById', { id: req.params.id });
      return res.json({ data });
    }

    const doc = await db.collection(resolved.collection).doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ error: 'Record not found' });
    return res.json({ data: { id: doc.id, ...doc.data() } });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ─── Create record ──────────────────────────────────────────────

apiApp.post('/api/v1/:objectType', async (req, res) => {
  const resolved = resolveType(req.params.objectType);
  if (!resolved) return res.status(404).json({ error: `Unknown object type: ${req.params.objectType}` });

  try {
    const dsConfig = await getDataSourceConfig(resolved.objectType);
    if (dsConfig.source_type === 'External' && dsConfig.active !== false) {
      const data = await proxyToExternal(dsConfig, 'create', { data: req.body });
      return res.status(201).json({ data });
    }

    const now = new Date().toISOString();
    const id = req.body.id || require('crypto').randomUUID();
    const record = { ...req.body, id, created_at: now, updated_at: now };
    if (req.user) {
      record.created_by = req.user.uid;
      record.updated_by = req.user.uid;
    }

    await db.collection(resolved.collection).doc(id).set(record);
    return res.status(201).json({ data: record });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ─── Update record ──────────────────────────────────────────────

apiApp.put('/api/v1/:objectType/:id', async (req, res) => {
  const resolved = resolveType(req.params.objectType);
  if (!resolved) return res.status(404).json({ error: `Unknown object type: ${req.params.objectType}` });

  try {
    const dsConfig = await getDataSourceConfig(resolved.objectType);
    if (dsConfig.source_type === 'External' && dsConfig.active !== false) {
      const data = await proxyToExternal(dsConfig, 'update', { id: req.params.id, data: req.body });
      return res.json({ data });
    }

    const ref = db.collection(resolved.collection).doc(req.params.id);
    const doc = await ref.get();
    if (!doc.exists) return res.status(404).json({ error: 'Record not found' });

    const updates = { ...req.body, updated_at: new Date().toISOString() };
    if (req.user) updates.updated_by = req.user.uid;
    await ref.update(updates);
    return res.json({ data: { id: req.params.id, ...doc.data(), ...updates } });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// ─── Delete record ──────────────────────────────────────────────

apiApp.delete('/api/v1/:objectType/:id', async (req, res) => {
  const resolved = resolveType(req.params.objectType);
  if (!resolved) return res.status(404).json({ error: `Unknown object type: ${req.params.objectType}` });

  try {
    const dsConfig = await getDataSourceConfig(resolved.objectType);
    if (dsConfig.source_type === 'External' && dsConfig.active !== false) {
      await proxyToExternal(dsConfig, 'remove', { id: req.params.id });
      return res.json({ success: true });
    }

    const ref = db.collection(resolved.collection).doc(req.params.id);
    const doc = await ref.get();
    if (!doc.exists) return res.status(404).json({ error: 'Record not found' });
    await ref.delete();
    return res.json({ success: true });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

exports.api = onRequest(
  { region: 'europe-west1' },
  apiApp
);
