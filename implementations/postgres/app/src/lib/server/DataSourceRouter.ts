import { withOwner } from './db';

/**
 * The pluggable data source layer (stories 30-31). Each object type can be served from the
 * local database or read through to an external system of record; the router consults
 * data_source_config - the same model object the reference uses - and PostgresMapper asks
 * it before touching a table, so callers never know the difference.
 *
 * Config reads run on the owner connection: routing is a system concern evaluated before
 * user context, and the application role under RLS with no identity set would - correctly -
 * see no configuration at all, which is how this comment earned its precision.
 */
export type ExternalConfig = {
	object_type: string;
	endpoint_url: string;
	auth_type: string | null;
	auth_config: Record<string, string> | null;
	field_mapping: Record<string, string> | null; // external field -> crm field
};

let cache: Map<string, ExternalConfig> | null = null;
let cacheLoaded = 0;
const CACHE_MS = 30_000;

export function clearConfigCache(): void {
	cache = null;
}

export async function externalConfigFor(objectType: string): Promise<ExternalConfig | null> {
	if (!cache || Date.now() - cacheLoaded > CACHE_MS) {
		const rows = await withOwner((client) =>
			client
				.query(`select object_type, endpoint_url, auth_type, auth_config, field_mapping
				          from data_source_config where source_type = 'External' and active`)
				.then((r) => r.rows)
		).catch(() => []);
		cache = new Map(rows.map((row: ExternalConfig) => [row.object_type, row]));
		cacheLoaded = Date.now();
	}
	return cache.get(objectType) ?? null;
}

function authHeaders(config: ExternalConfig): Record<string, string> {
	const auth = config.auth_config ?? {};
	switch (config.auth_type) {
		case 'BasicAuth':
			return { authorization: `Basic ${Buffer.from(`${auth.username}:${auth.password}`).toString('base64')}` };
		case 'OAuth2':
			return { authorization: `Bearer ${auth.access_token}` };
		case 'APIKey':
			return { [auth.header_name || 'x-api-key']: auth.api_key ?? '' };
		default:
			return {};
	}
}

function toCrm(config: ExternalConfig, record: Record<string, unknown>): Record<string, unknown> {
	const mapping = config.field_mapping ?? {};
	if (!Object.keys(mapping).length) return record;
	const mapped: Record<string, unknown> = { id: record.id };
	for (const [external, crm] of Object.entries(mapping)) {
		if (record[external] !== undefined) mapped[crm] = record[external];
	}
	return mapped;
}

function toExternal(config: ExternalConfig, record: Record<string, unknown>): Record<string, unknown> {
	const mapping = config.field_mapping ?? {};
	if (!Object.keys(mapping).length) return record;
	const reversed: Record<string, unknown> = {};
	for (const [external, crm] of Object.entries(mapping)) {
		if (record[crm] !== undefined) reversed[external] = record[crm];
	}
	return reversed;
}

async function call(config: ExternalConfig, method: string, path = '', body?: unknown) {
	const url = config.endpoint_url.replace(/\/+$/, '') + path;
	const response = await fetch(url, {
		method,
		headers: { 'content-type': 'application/json', ...authHeaders(config) },
		body: body === undefined ? undefined : JSON.stringify(body)
	});
	if (!response.ok) throw new Error(`External source returned ${response.status}`);
	return response.status === 204 ? null : response.json();
}

/** The mapper's operations, served by the external system. Users see no difference. */
export const ExternalSourceAdapter = {
	async listPage(config: ExternalConfig, pageSize: number) {
		const data = await call(config, 'GET');
		const records = (Array.isArray(data) ? data : (data?.records ?? [])) as Record<string, unknown>[];
		return { data: records.slice(0, pageSize).map((r) => toCrm(config, r)), cursor: null };
	},
	async count(config: ExternalConfig) {
		const data = await call(config, 'GET');
		return (Array.isArray(data) ? data : (data?.records ?? [])).length;
	},
	async getById(config: ExternalConfig, id: string) {
		const record = await call(config, 'GET', `/${encodeURIComponent(id)}`).catch(() => null);
		return record ? toCrm(config, record as Record<string, unknown>) : null;
	},
	async create(config: ExternalConfig, data: Record<string, unknown>) {
		const created = await call(config, 'POST', '', toExternal(config, data));
		return toCrm(config, (created ?? data) as Record<string, unknown>);
	},
	async update(config: ExternalConfig, id: string, data: Record<string, unknown>) {
		const updated = await call(config, 'PUT', `/${encodeURIComponent(id)}`, toExternal(config, data));
		return toCrm(config, (updated ?? data) as Record<string, unknown>);
	},
	async remove(config: ExternalConfig, id: string) {
		await call(config, 'DELETE', `/${encodeURIComponent(id)}`);
		return true;
	}
};
