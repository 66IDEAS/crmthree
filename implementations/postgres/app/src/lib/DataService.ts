import type { ListOptions } from './server/PostgresMapper';

/**
 * Client-side data access. Keeps the operation names and shapes of the reference
 * implementation's DataService, so calling code reads the same.
 *
 * The implementation is necessarily different, and this is where the portability claim needs
 * qualifying. In the reference stack the browser holds a database client and DataService
 * talks to Firestore directly. A browser cannot hold a Postgres connection, so here the same
 * interface is an HTTP client and the mapper runs on the server. The interface ports; the
 * implementation splits in two.
 *
 * That turns out to be the better arrangement anyway: every read and write crosses a server
 * boundary that establishes identity, so row level security applies to the UI and the public
 * API by the same path.
 */
async function request<T>(path: string, init?: RequestInit): Promise<T> {
	const response = await fetch(path, {
		...init,
		headers: { 'content-type': 'application/json', ...(init?.headers ?? {}) }
	});
	if (!response.ok) {
		const body = await response.json().catch(() => ({ message: response.statusText }));
		throw new Error(body.message ?? `Request failed: ${response.status}`);
	}
	return response.status === 204 ? (undefined as T) : ((await response.json()) as T);
}

function query(options: ListOptions = {}): string {
	const params = new URLSearchParams();
	if (options.pageSize) params.set('pageSize', String(options.pageSize));
	if (options.filters?.length) params.set('filters', JSON.stringify(options.filters));
	if (options.sort?.field) {
		params.set('sort', options.sort.field);
		params.set('direction', options.sort.direction ?? 'asc');
	}
	if (options.cursor) {
		params.set('cursorSort', String(options.cursor.sort));
		params.set('cursorId', options.cursor.id);
	}
	const search = params.toString();
	return search ? `?${search}` : '';
}

const DataService = {
	getById: <T>(objectType: string, id: string) => request<T>(`/api/v1/${objectType}/${id}`),

	listPage: <T>(objectType: string, options: ListOptions = {}) =>
		request<{ data: T[]; cursor: { sort: unknown; id: string } | null }>(
			`/api/v1/${objectType}${query(options)}`
		),

	async list<T>(objectType: string, options: ListOptions = {}) {
		const page = await this.listPage<T>(objectType, { ...options, pageSize: options.pageSize ?? 1000 });
		return page.data;
	},

	async count(objectType: string, options: ListOptions = {}) {
		const params = new URLSearchParams(query(options).replace(/^\?/, ''));
		params.set('count', 'true');
		const result = await request<{ total: number }>(`/api/v1/${objectType}?${params}`);
		return result.total;
	},

	create: <T>(objectType: string, data: Record<string, unknown>) =>
		request<T>(`/api/v1/${objectType}`, { method: 'POST', body: JSON.stringify(data) }),

	update: <T>(objectType: string, id: string, data: Record<string, unknown>) =>
		request<T>(`/api/v1/${objectType}/${id}`, { method: 'PUT', body: JSON.stringify(data) }),

	remove: (objectType: string, id: string) =>
		request<void>(`/api/v1/${objectType}/${id}`, { method: 'DELETE' })
};

export default DataService;
