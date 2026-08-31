<script lang="ts">
	import { goto } from '$app/navigation';
	import DataService from '$lib/DataService';
	import FieldInput from '$lib/components/FieldInput.svelte';
	import { t } from '$lib/i18n';
	import { fieldLabel, objectLabel } from '$lib/display';

	let { data } = $props();
	// Model defaults prefill the form, so a required field with a default is one less click.
	let duplicates = $state<{ id: string; display: string; score: number }[]>([]);
	let dupTimer: ReturnType<typeof setTimeout> | null = null;
	const NAME_FIELDS = ['name', 'name1', 'first_name', 'last_name', 'subject', 'title'];

	function checkDuplicates() {
		if (dupTimer) clearTimeout(dupTimer);
		dupTimer = setTimeout(async () => {
			const candidate = NAME_FIELDS.map((f) => values[f]).filter(Boolean).join(' ');
			if (candidate.length < 3) { duplicates = []; return; }
			const response = await fetch(`/api/duplicates?type=${data.objectType}&name=${encodeURIComponent(candidate)}`);
			duplicates = response.ok ? (await response.json()).matches : [];
		}, 400);
	}
	$effect(() => {
		NAME_FIELDS.forEach((f) => values[f]);   // track the name fields
		checkDuplicates();
	});

	let values = $state<Record<string, unknown>>({
		...Object.fromEntries(data.fields.filter((f) => f.default !== undefined).map((f) => [f.name, f.default])),
		...data.prefill
	});
	let problem = $state('');
	let busy = $state(false);

	async function create(event: SubmitEvent) {
		event.preventDefault();
		busy = true;
		problem = '';
		try {
			const clean = Object.fromEntries(
				Object.entries(values).filter(([, v]) => v !== '' && v !== null && v !== undefined)
			);
			const record = await DataService.create<{ id: string }>(data.objectType, clean);
			await goto(`/${data.objectType}/${record.id}`);
		} catch (e) {
			problem = (e as Error).message;
		} finally {
			busy = false;
		}
	}
</script>
<svelte:head>
	<title>{t('ui.new', 'New')} {objectLabel(data.objectType)} · CRMTHREE</title>
</svelte:head>


<div class="mx-auto max-w-2xl">
	<h1 class="text-xl font-semibold tracking-tight">{t('ui.new', 'New')} {objectLabel(data.objectType)}</h1>

	<form onsubmit={create} class="mt-5 rounded-lg border border-rule bg-surface p-6">
		<div class="grid grid-cols-1 gap-4 md:grid-cols-2">
			{#each data.fields as field (field.name)}
				<label class="flex flex-col gap-1 text-sm {field.type === 'text' ? 'md:col-span-2' : ''}">
					<span class="font-medium text-ink/80">
						{fieldLabel(field, data.objectType)}{#if field.required}<span class="text-error"> *</span>{/if}
					</span>
					<FieldInput {field} bind:value={values[field.name]} options={data.options[field.name] ?? []} />
				</label>
			{/each}
		</div>
		{#if duplicates.length}
			<div class="mt-4 rounded bg-warning/10 p-3 text-sm">
				<p class="font-medium text-warning">Possible duplicates - is one of these the same record?</p>
				<ul class="mt-1.5 flex flex-col gap-1">
					{#each duplicates as dup (dup.id)}
						<li><a href={`/${data.objectType}/${dup.id}`} target="_blank" class="text-accent-600 hover:underline">{dup.display}</a>
							<span class="ml-1 text-xs text-steel">{dup.score}% similar</span></li>
					{/each}
				</ul>
			</div>
		{/if}
		{#if problem}
			<p class="mt-4 rounded bg-error/10 p-2 text-sm text-error">{problem}</p>
		{/if}
		<div class="mt-6 flex gap-2">
			<button type="submit" disabled={busy}
				class="rounded bg-accent-600 px-4 py-1.5 text-sm font-medium text-white hover:bg-accent-500 disabled:opacity-50">
				{busy ? t('ui.creating', 'Creating...') : t('ui.create', 'Create')}
			</button>
			<a href={`/${data.objectType}`} class="rounded border border-steel/40 px-4 py-1.5 text-sm hover:bg-paper">{t('ui.cancel', 'Cancel')}</a>
		</div>
	</form>
</div>
