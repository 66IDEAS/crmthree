import ModelRegistry from '$lib/model/ModelRegistry';

/**
 * The master label catalog (story 60): static UI keys plus keys generated from the model,
 * each with its English default. This is what a new language gets translated from.
 */
const STATIC_LABELS: Record<string, string> = {
	'ui.save': 'Save', 'ui.cancel': 'Cancel', 'ui.edit': 'Edit', 'ui.delete': 'Delete',
	'ui.new': 'New', 'ui.search': 'Search…', 'ui.sign_out': 'Sign out',
	'ui.columns': 'Columns', 'ui.export_csv': 'Export CSV', 'ui.import_csv': 'Import CSV',
	'ui.settings': 'Settings', 'ui.navigation': 'Navigation', 'ui.records': 'records',
	'ui.comments': 'Comments', 'ui.notifications': 'Notifications',
	'ui.welcome_back': 'Welcome back', 'ui.profile': 'Profile', 'ui.leaderboard': 'Leaderboard'
};

function humanize(name: string): string {
	return name.replace(/_id$/, '').split('_')
		.map((part) => part.charAt(0).toUpperCase() + part.slice(1)).join(' ');
}

export function buildCatalog(): Record<string, string> {
	const catalog: Record<string, string> = { ...STATIC_LABELS };
	for (const objectType of ModelRegistry.getObjectTypes()) {
		const spaced = objectType.replace(/([a-z])([A-Z])/g, '$1 $2');
		catalog[`object.${objectType}`] = spaced;
		catalog[`object.${objectType}.plural`] = spaced.endsWith('y')
			? spaced.slice(0, -1) + 'ies' : spaced + 's';
		for (const field of ModelRegistry.getSpecificFields(objectType)) {
			catalog[`field.${field.name}`] ??= humanize(field.name);
		}
	}
	return catalog;
}
