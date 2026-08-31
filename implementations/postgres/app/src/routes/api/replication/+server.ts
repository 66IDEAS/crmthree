import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { withUser } from '$lib/server/db';
import { createInTx, tableName } from '$lib/server/PostgresMapper';
import ModelRegistry from '$lib/model/ModelRegistry';

function requireAdmin(locals: App.Locals) {
	if (locals.profile?.role_name !== 'Admin') throw error(403, 'Administrators only');
	return locals.profile;
}

export const GET: RequestHandler = async ({ locals }) => {
	const admin = requireAdmin(locals);
	const rows = await withUser(admin.id, (client) =>
		client.query('select * from replication_config order by created_at').then((r) => r.rows)
	);
	return json({ configs: rows });
};

export const PUT: RequestHandler = async ({ request, locals }) => {
	const admin = requireAdmin(locals);
	const body = await request.json().catch(() => null);
	for (const required of ['name', 'object_type', 'url', 'key_field', 'source_key_field', 'field_mapping']) {
		if (!body?.[required]) throw error(400, `${required} is required`);
	}
	if (!ModelRegistry.hasObject(body.object_type)) throw error(400, 'Unknown object type');
	await withUser(admin.id, (client) =>
		client.query(
			`insert into replication_config
			   (id, name, object_type, url, request_body, key_field, source_key_field, delete_field,
			    field_mapping, defaults, created_by)
			 values (coalesce($1::uuid, gen_random_uuid()), $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
			 on conflict (id) do update set name = $2, object_type = $3, url = $4, request_body = $5,
			   key_field = $6, source_key_field = $7, delete_field = $8, field_mapping = $9, defaults = $10`,
			[body.id ?? null, body.name, body.object_type, body.url,
			 body.request_body ? JSON.stringify(body.request_body) : null,
			 body.key_field, body.source_key_field, body.delete_field ?? null,
			 JSON.stringify(body.field_mapping), JSON.stringify(body.defaults ?? {}), admin.id]
		)
	);
	return json({ ok: true }, { status: 201 });
};

export const DELETE: RequestHandler = async ({ url, locals }) => {
	const admin = requireAdmin(locals);
	const id = url.searchParams.get('id');
	if (!id) throw error(400, 'id required');
	await withUser(admin.id, (client) => client.query('delete from replication_config where id = $1', [id]));
	return new Response(null, { status: 204 });
};

/**
 * Execute a replication run (story 59): fetch the external records, map fields, and upsert
 * by key field - all inside one transaction, so a run either lands or leaves no trace.
 * The reference performs the same loop record-by-record from the browser.
 */
export const POST: RequestHandler = async ({ request, locals }) => {
	const admin = requireAdmin(locals);
	const { id } = await request.json().catch(() => ({}));
	if (!id) throw error(400, 'id required');

	const config = await withUser(admin.id, (client) =>
		client.query('select * from replication_config where id = $1', [id]).then((r) => r.rows[0])
	);
	if (!config) throw error(404, 'No such configuration');

	const response = await fetch(config.url, {
		method: config.request_body ? 'POST' : 'GET',
		headers: { 'content-type': 'application/json' },
		body: config.request_body ? JSON.stringify(config.request_body) : undefined
	}).catch((e: Error) => {
		throw error(502, `Web service call failed: ${e.message}`);
	});
	if (!response.ok) throw error(502, `Web service returned ${response.status}`);
	const payload = await response.json();
	const records = Array.isArray(payload) ? payload : payload?.records;
	if (!Array.isArray(records)) throw error(502, 'Response does not contain a records array');

	const table = tableName(config.object_type);
	const result = { received: records.length, created: 0, updated: 0, skipped: 0 };

	await withUser(admin.id, async (client) => {
		const existing = await client.query(
			`select id, "${config.key_field}" as key from ${table} where "${config.key_field}" is not null`
		);
		const byKey = new Map(existing.rows.map((row) => [String(row.key), row.id]));

		for (const source of records) {
			if (config.delete_field && source[config.delete_field]) {
				result.skipped += 1;
				continue;
			}
			const mapped: Record<string, unknown> = {};
			for (const [sourceField, crmField] of Object.entries(config.field_mapping as Record<string, string>)) {
				if (source[sourceField] !== undefined && source[sourceField] !== null) {
					mapped[crmField] = String(source[sourceField]);
				}
			}
			const key = mapped[config.key_field];
			if (!key) {
				result.skipped += 1;
				continue;
			}
			const existingId = byKey.get(String(key));
			if (existingId) {
				const assignments = Object.keys(mapped).map((column, index) => `"${column}" = $${index + 2}`);
				await client.query(
					`update ${table} set ${assignments.join(', ')}, updated_at = now(), updated_by = $1
					  where id = $${Object.keys(mapped).length + 2}`,
					[admin.id, ...Object.values(mapped), existingId]
				);
				result.updated += 1;
			} else {
				// Required user references the source cannot know anchor to the running
				// admin - an external system has no notion of CRM ownership.
				const anchored: Record<string, unknown> = { ...config.defaults, ...mapped };
				for (const field of ModelRegistry.getSpecificFields(config.object_type)) {
					if (field.type === 'reference' && field.required && field.target === 'UserProfile'
							&& anchored[field.name] === undefined) {
						anchored[field.name] = admin.id;
					}
				}
				await createInTx(client, admin.id, config.object_type, anchored);
				result.created += 1;
			}
		}
		await client.query(
			`update replication_config set last_run_at = now(), last_result = $2 where id = $1`,
			[id, `${result.created} created, ${result.updated} updated, ${result.skipped} skipped`]
		);
	});
	return json(result);
};
