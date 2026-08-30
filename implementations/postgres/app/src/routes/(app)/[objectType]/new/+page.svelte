<script lang="ts">
	import { goto } from '$app/navigation';
	import DataService from '$lib/DataService';
	import FieldInput from '$lib/components/FieldInput.svelte';
	import { fieldLabel, objectLabel } from '$lib/display';

	let { data } = $props();
	// Model defaults prefill the form, so a required field with a default is one less click.
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

<div class="mx-auto max-w-2xl">
	<h1 class="text-xl font-semibold tracking-tight">New {objectLabel(data.objectType)}</h1>

	<form onsubmit={create} class="mt-5 rounded-lg border border-rule bg-white p-6">
		<div class="grid grid-cols-1 gap-4 md:grid-cols-2">
			{#each data.fields as field (field.name)}
				<label class="flex flex-col gap-1 text-sm {field.type === 'text' ? 'md:col-span-2' : ''}">
					<span class="font-medium text-ink/80">
						{fieldLabel(field.name)}{#if field.required}<span class="text-error"> *</span>{/if}
					</span>
					<FieldInput {field} bind:value={values[field.name]} options={data.options[field.name] ?? []} />
				</label>
			{/each}
		</div>
		{#if problem}
			<p class="mt-4 rounded bg-error/10 p-2 text-sm text-error">{problem}</p>
		{/if}
		<div class="mt-6 flex gap-2">
			<button type="submit" disabled={busy}
				class="rounded bg-accent-600 px-4 py-1.5 text-sm font-medium text-white hover:bg-accent-500 disabled:opacity-50">
				{busy ? 'Creating…' : 'Create'}
			</button>
			<a href={`/${data.objectType}`} class="rounded border border-steel/40 px-4 py-1.5 text-sm hover:bg-paper">Cancel</a>
		</div>
	</form>
</div>
