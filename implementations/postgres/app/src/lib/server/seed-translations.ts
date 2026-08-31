import { withOwner } from './db';

/**
 * First-run seeding of the bundled language packs (shared architecture, section 13).
 * The packs are part of the server build - imported from specs/translations/ the same way
 * the data model is - and seeding is per language, at most once per code, tracked in
 * translation_seed: a registered code is never touched again, a code with an existing row
 * (imported or admin-created) is adopted into the registry untouched, and an unseen code is
 * inserted. Deleting a language therefore sticks, while a pack added to the product later
 * appears on the next server start.
 */
const packs = import.meta.glob('$translations/*.json', { eager: true }) as Record<
	string,
	{ default: { code: string; language_name: string; labels: Record<string, string> } }
>;

let seeding: Promise<void> | null = null;

export function seedTranslations(): Promise<void> {
	seeding ??= run().catch((error) => {
		// A failed attempt (e.g. database not up yet) retries on the next call instead of
		// permanently giving up for the process lifetime.
		console.error('Translation seeding failed:', error);
		seeding = null;
	}) as Promise<void>;
	return seeding;
}

async function run(): Promise<void> {
	await withOwner(async (client) => {
		const registered = new Set<string>(
			(await client.query('select code from translation_seed')).rows.map((row) => row.code)
		);
		for (const module of Object.values(packs)) {
			const pack = module.default;
			if (registered.has(pack.code)) continue;
			await client.query('begin');
			try {
				await client.query(
					`insert into translation (code, language_name, labels)
					 values ($1, $2, $3) on conflict (code) do nothing`,
					[pack.code, pack.language_name, JSON.stringify(pack.labels)]
				);
				await client.query(
					'insert into translation_seed (code) values ($1) on conflict (code) do nothing',
					[pack.code]
				);
				await client.query('commit');
			} catch (error) {
				await client.query('rollback');
				throw error;
			}
		}
	});
}
