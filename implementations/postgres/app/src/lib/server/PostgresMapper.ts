import type pg from 'pg';
import { randomUUID } from 'node:crypto';
import ModelRegistry from '$lib/model/ModelRegistry';
import { withUser } from './db';
import { externalConfigFor, ExternalSourceAdapter } from './DataSourceRouter';

/**
 * The Postgres counterpart of the reference implementation's FirestoreMapper (P4, P5).
 *
 * Exposes the same operations behind the same names, so DataService is unchanged in shape.
 * Everything runs inside withUser(), meaning row level security decides what each caller can
 * see; this layer never filters by permission itself.
 */

/** PascalCase object name to snake_case table name. Must match db/generate-ddl.mjs. */
export const tableName = (objectType: string): string =>
	objectType
		.replace(/([a-z0-9])([A-Z])/g, '$1_$2')
		.replace(/([A-Z]+)([A-Z][a-z])/g, '$1_$2')
		.toLowerCase();

/**
 * Identifiers cannot be parameterised, so every table and column name is resolved through
 * ModelRegistry rather than taken from the request. An unknown name is rejected outright,
 * which is what keeps this layer free of injection despite building SQL by hand.
 */
function safeTable(objectType: string): string {
	if (!ModelRegistry.hasObject(objectType)) throw new Error(`Unknown object type: ${objectType}`);
	return tableName(objectType);
}

function safeColumn(objectType: string, field: string): string {
	const definition = ModelRegistry.getFieldDefinition(objectType, field);
	if (!definition) throw new Error(`Unknown field ${objectType}.${field}`);
	return definition.name;
}

/**
 * node-postgres serializes JS arrays as Postgres ARRAY literals, so a json-typed field
 * holding an array binds as invalid jsonb - and an empty array silently becomes '{}',
 * which is valid JSON but the wrong value. Everything destined for a jsonb column is
 * stringified explicitly.
 */
function bindValue(field: { type: string }, value: unknown): unknown {
	if (field.type === 'json' && value !== null && typeof value === 'object') {
		return JSON.stringify(value);
	}
	return value;
}

const OPERATORS: Record<string, string> = {
	eq: '=',
	ne: '<>',
	gt: '>',
	gte: '>=',
	lt: '<',
	lte: '<='
};

type Filter = { field: string; op?: string; value: unknown };
type Sort = { field: string; direction?: 'asc' | 'desc' };
export type ListOptions = {
	filters?: Filter[];
	sort?: Sort;
	pageSize?: number;
	cursor?: { sort: unknown; id: string } | null;
};

function buildWhere(objectType: string, filters: Filter[] = [], params: unknown[]) {
	const clauses: string[] = [];
	for (const filter of filters) {
		const column = safeColumn(objectType, filter.field);
		const op = filter.op ?? 'eq';
		if (op === 'in') {
			if (!Array.isArray(filter.value) || filter.value.length === 0) {
				clauses.push('false');
				continue;
			}
			params.push(filter.value);
			clauses.push(`"${column}" = any($${params.length})`);
		} else if (op === 'contains') {
			params.push(`%${String(filter.value)}%`);
			clauses.push(`"${column}" ilike $${params.length}`);
		} else {
			const sql = OPERATORS[op];
			if (!sql) throw new Error(`Unsupported operator: ${op}`);
			params.push(filter.value);
			clauses.push(`"${column}" ${sql} $${params.length}`);
		}
	}
	return clauses.length ? `where ${clauses.join(' and ')}` : '';
}

/**
 * Insert on an existing transaction, so multi-record operations such as conversions are
 * atomic. PostgresMapper.create wraps this in its own transaction for the single-row case.
 */
export async function createInTx(
	client: pg.PoolClient,
	profileId: string | null,
	objectType: string,
	data: Record<string, unknown>
) {
	const table = safeTable(objectType);
	const id = (data.id as string) ?? randomUUID();

	// Model defaults apply on the server, so API-first consumers (R9) get the same
	// behaviour as the form, and validation sees the record it will actually store.
	for (const field of ModelRegistry.getSpecificFields(objectType)) {
		if (field.default !== undefined && (data[field.name] === undefined || data[field.name] === null)) {
			data = { ...data, [field.name]: field.default };
		}
	}

	// Auto-numbers are sequence defaults here, so unlike the reference implementation the
	// caller never supplies one; omitted columns simply take their default.
	const names = ['id', 'created_at', 'updated_at', 'created_by', 'updated_by'];
	const placeholders = ['$1', 'now()', 'now()', '$2', '$2'];
	const params: unknown[] = [id, profileId];

	for (const key of Object.keys(data)) {
		const field = ModelRegistry.getFieldDefinition(objectType, key);
		if (key === 'id' || !field) continue;
		params.push(bindValue(field, data[key]));
		names.push(safeColumn(objectType, key));
		placeholders.push(`$${params.length}`);
	}

	const result = await client.query(
		`insert into ${table} (${names.map((n) => `"${n}"`).join(', ')})
		 values (${placeholders.join(', ')}) returning *`,
		params
	);
	return result.rows[0];
}

const PostgresMapper = {
	async getById(profileId: string | null, objectType: string, id: string) {
		const external = await externalConfigFor(objectType);
		if (external) return ExternalSourceAdapter.getById(external, id);
		const table = safeTable(objectType);
		return withUser(profileId, async (client) => {
			const result = await client.query(`select * from ${table} where id = $1`, [id]);
			return result.rows[0] ?? null;
		});
	},

	async list(profileId: string | null, objectType: string, options: ListOptions = {}) {
		const page = await this.listPage(profileId, objectType, {
			...options,
			pageSize: options.pageSize ?? 1000
		});
		return page.data;
	},

	/**
	 * Keyset pagination (P4). The cursor is the last row's sort value and id rather than an
	 * offset, so paging stays O(1) at any depth and cannot skip or repeat rows when the data
	 * changes underneath. Sorting on any column is free, so unlike Firestore no composite
	 * index has to be declared in advance.
	 */
	async listPage(profileId: string | null, objectType: string, options: ListOptions = {}) {
		const external = await externalConfigFor(objectType);
		if (external) return ExternalSourceAdapter.listPage(external, Math.min(options.pageSize ?? 25, 1000));
		const table = safeTable(objectType);
		const sortField = options.sort?.field ?? 'created_at';
		const sortColumn = safeColumn(objectType, sortField);
		const direction = options.sort?.direction === 'desc' ? 'desc' : 'asc';
		const comparison = direction === 'desc' ? '<' : '>';
		const pageSize = Math.min(Math.max(options.pageSize ?? 25, 1), 1000);

		const params: unknown[] = [];
		let where = buildWhere(objectType, options.filters, params);
		if (options.cursor) {
			params.push(options.cursor.sort, options.cursor.id);
			const keyset = `("${sortColumn}", id) ${comparison} ($${params.length - 1}, $${params.length})`;
			where = where ? `${where} and ${keyset}` : `where ${keyset}`;
		}
		params.push(pageSize);

		return withUser(profileId, async (client) => {
			const result = await client.query(
				`select * from ${table} ${where}
				 order by "${sortColumn}" ${direction}, id ${direction}
				 limit $${params.length}`,
				params
			);
			const last = result.rows[result.rows.length - 1];
			return {
				data: result.rows,
				// Replaces the Firestore DocumentSnapshot cursor: plain values, so it survives
				// a round trip to the browser and back.
				cursor: last ? { sort: last[sortColumn], id: last.id } : null
			};
		});
	},

	async count(profileId: string | null, objectType: string, options: ListOptions = {}) {
		const external = await externalConfigFor(objectType);
		if (external) return ExternalSourceAdapter.count(external);
		const table = safeTable(objectType);
		const params: unknown[] = [];
		const where = buildWhere(objectType, options.filters, params);
		return withUser(profileId, async (client) => {
			const result = await client.query(`select count(*)::int as total from ${table} ${where}`, params);
			return result.rows[0].total as number;
		});
	},

	async create(profileId: string | null, objectType: string, data: Record<string, unknown>) {
		const external = await externalConfigFor(objectType);
		if (external) return ExternalSourceAdapter.create(external, data);
		return withUser(profileId, (client) => createInTx(client, profileId, objectType, data));
	},

	async update(profileId: string | null, objectType: string, id: string, data: Record<string, unknown>) {
		const external = await externalConfigFor(objectType);
		if (external) return ExternalSourceAdapter.update(external, id, data);
		const table = safeTable(objectType);
		const columns = Object.keys(data).filter(
			(key) => key !== 'id' && ModelRegistry.getFieldDefinition(objectType, key)
		);
		const params: unknown[] = [id, profileId];
		const assignments = columns.map((column) => {
			params.push(bindValue(ModelRegistry.getFieldDefinition(objectType, column)!, data[column]));
			return `"${safeColumn(objectType, column)}" = $${params.length}`;
		});
		assignments.push('updated_at = now()', 'updated_by = $2');

		return withUser(profileId, async (client) => {
			const result = await client.query(
				`update ${table} set ${assignments.join(', ')} where id = $1 returning *`,
				params
			);
			return result.rows[0] ?? null;
		});
	},

	async remove(profileId: string | null, objectType: string, id: string) {
		const external = await externalConfigFor(objectType);
		if (external) return ExternalSourceAdapter.remove(external, id);
		const table = safeTable(objectType);
		return withUser(profileId, async (client) => {
			const result = await client.query(`delete from ${table} where id = $1`, [id]);
			return (result.rowCount ?? 0) > 0;
		});
	}
};

export default PostgresMapper;
