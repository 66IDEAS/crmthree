import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { withUser } from '$lib/server/db';
import { buildCatalog } from '$lib/server/label-catalog';
import { callProvider } from '$lib/server/ai';

function requireAdmin(locals: App.Locals) {
	if (locals.profile?.role_name !== 'Admin') throw error(403, 'Administrators only');
	return locals.profile;
}

export const GET: RequestHandler = async ({ locals }) => {
	if (!locals.profile) throw error(401, 'Not provisioned');
	const rows = await withUser(locals.profile.id, (client) =>
		client.query('select code, language_name, updated_at from translation order by code').then((r) => r.rows)
	);
	return json({ languages: rows, catalogSize: Object.keys(buildCatalog()).length });
};

/** Adds or updates a language. With translate=true the catalog is AI-translated in batches. */
export const PUT: RequestHandler = async ({ request, locals }) => {
	const admin = requireAdmin(locals);
	const body = await request.json().catch(() => null);
	if (!body?.code || !body?.language_name) throw error(400, 'code and language_name required');

	let labels: Record<string, string> = body.labels ?? {};
	if (body.translate) {
		const catalog = Object.entries(buildCatalog());
		for (let i = 0; i < catalog.length; i += 50) {
			const batch = Object.fromEntries(catalog.slice(i, i + 50));
			const result = await callProvider([
				{
					role: 'system',
					content: `Translate the JSON values to ${body.language_name} for a CRM UI. Reply with ONLY the JSON object, same keys, translated values.`
				},
				{ role: 'user', content: JSON.stringify(batch) }
			]);
			try {
				const parsed = JSON.parse(result.content.replace(/^```(json)?|```$/g, '').trim());
				Object.assign(labels, parsed);
			} catch {
				// A malformed batch keeps its English defaults rather than failing the run.
			}
		}
	}
	await withUser(admin.id, (client) =>
		client.query(
			`insert into translation (code, language_name, labels, created_by)
			 values ($1, $2, $3, $4)
			 on conflict (code) do update set language_name = $2,
			   labels = translation.labels || $3, updated_at = now()`,
			[body.code, body.language_name, JSON.stringify(labels), admin.id]
		)
	);
	return json({ ok: true, translated: Object.keys(labels).length }, { status: 201 });
};

export const DELETE: RequestHandler = async ({ url, locals }) => {
	const admin = requireAdmin(locals);
	const code = url.searchParams.get('code');
	if (!code) throw error(400, 'code required');
	await withUser(admin.id, (client) => client.query('delete from translation where code = $1', [code]));
	return new Response(null, { status: 204 });
};
