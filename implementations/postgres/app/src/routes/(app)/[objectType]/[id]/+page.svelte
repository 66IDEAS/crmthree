<script lang="ts">
	import { onMount } from 'svelte';
	import { goto, invalidateAll } from '$app/navigation';
	import DataService from '$lib/DataService';
	import FieldInput from '$lib/components/FieldInput.svelte';
	import { displayName, fieldLabel, formatValue, enumChipClass, objectLabel } from '$lib/display';
	import { onChange } from '$lib/realtime-client';

	let { data } = $props();

	let editing = $state(false);
	let values = $state<Record<string, unknown>>({});
	let problem = $state('');
	let busy = $state(false);
	type Lock = { locked_by: string; locked_by_name: string; expires_at: string };
	let lock = $state<Lock | null>(null);
	let heartbeat: ReturnType<typeof setInterval> | null = null;

	const lockedByOther = $derived(lock !== null && lock.locked_by !== data.profileId);

	async function refreshLock() {
		const response = await fetch(`/api/locks/${data.objectType}/${data.record.id}`);
		lock = response.ok ? (await response.json()).lock : null;
	}

	onMount(() => {
		refreshLock();
		// Every lock event triggers a re-read of this record's lock; the payload has only an
		// id, so this is the cheap-and-authorised way to stay current.
		const off = onChange('record_lock', refreshLock);
		return () => {
			off();
			if (heartbeat) clearInterval(heartbeat);
			if (editing) releaseLock();
		};
	});

	async function acquireLock(): Promise<boolean> {
		const response = await fetch('/api/locks', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({ objectType: data.objectType, recordId: data.record.id })
		});
		if (!response.ok) {
			await refreshLock();
			return false;
		}
		return true;
	}

	function releaseLock() {
		fetch(`/api/locks/${data.objectType}/${data.record.id}`, { method: 'DELETE' });
	}

	async function startEdit() {
		if (!(await acquireLock())) return;
		values = Object.fromEntries(
			data.fields
				.filter((f) => !f.auto_generated)
				.map((f) => {
					let value = data.record[f.name];
					if (f.type === 'datetime' && value) value = String(value).slice(0, 16);
					if (f.type === 'date' && value) value = String(value).slice(0, 10);
					return [f.name, value];
				})
		);
		problem = '';
		editing = true;
		// The reference TTL is 15 minutes; renew comfortably inside it.
		heartbeat = setInterval(acquireLock, 5 * 60 * 1000);
	}

	function stopEdit() {
		editing = false;
		if (heartbeat) clearInterval(heartbeat);
		heartbeat = null;
		releaseLock();
	}

	async function save(event: SubmitEvent) {
		event.preventDefault();
		busy = true;
		problem = '';
		try {
			await DataService.update(data.objectType, String(data.record.id), values);
			stopEdit();
			await invalidateAll();
		} catch (e) {
			problem = (e as Error).message;
		} finally {
			busy = false;
		}
	}

	async function remove() {
		if (!confirm(`Delete this ${objectLabel(data.objectType)}? This cannot be undone.`)) return;
		try {
			await DataService.remove(data.objectType, String(data.record.id));
			await goto(`/${data.objectType}`);
		} catch (e) {
			problem = (e as Error).message;
		}
	}
</script>

<div class="mx-auto max-w-3xl">
	<div class="flex items-center justify-between">
		<div>
			<a href={`/${data.objectType}`} class="text-sm text-zinc-500 hover:text-zinc-900">← {objectLabel(data.objectType, true)}</a>
			<h1 class="mt-1 text-xl font-semibold tracking-tight">{displayName(data.record)}</h1>
		</div>
		{#if !editing}
			<div class="flex gap-2">
				<button onclick={startEdit} disabled={lockedByOther}
					class="rounded bg-accent-600 px-4 py-1.5 text-sm font-medium text-white hover:bg-accent-700 disabled:cursor-not-allowed disabled:opacity-40">
					Edit
				</button>
				<button onclick={remove} class="rounded border border-red-200 px-4 py-1.5 text-sm text-red-600 hover:bg-red-50">Delete</button>
			</div>
		{/if}
	</div>

	{#if lockedByOther && lock}
		<p class="mt-3 flex items-center gap-2 rounded bg-amber-50 px-3 py-2 text-sm text-amber-800">
			<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
				<path stroke-linecap="round" stroke-linejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z" />
			</svg>
			{lock.locked_by_name} is editing this record
		</p>
	{/if}

	{#if editing}
		<form onsubmit={save} class="mt-5 rounded-lg border border-zinc-200 bg-white p-6">
			<div class="grid grid-cols-1 gap-4 md:grid-cols-2">
				{#each data.fields.filter((f) => !f.auto_generated) as field (field.name)}
					<label class="flex flex-col gap-1 text-sm {field.type === 'text' ? 'md:col-span-2' : ''}">
						<span class="font-medium text-zinc-700">
							{fieldLabel(field.name)}{#if field.required}<span class="text-red-500"> *</span>{/if}
						</span>
						<FieldInput {field} bind:value={values[field.name]} options={data.options[field.name] ?? []} />
					</label>
				{/each}
			</div>
			{#if problem}<p class="mt-4 rounded bg-red-50 p-2 text-sm text-red-700">{problem}</p>{/if}
			<div class="mt-6 flex gap-2">
				<button type="submit" disabled={busy}
					class="rounded bg-accent-600 px-4 py-1.5 text-sm font-medium text-white hover:bg-accent-700 disabled:opacity-50">
					{busy ? 'Saving…' : 'Save'}
				</button>
				<button type="button" onclick={stopEdit} class="rounded border border-zinc-300 px-4 py-1.5 text-sm hover:bg-zinc-50">Cancel</button>
			</div>
		</form>
	{:else}
		<dl class="mt-5 grid grid-cols-1 gap-x-8 gap-y-3 rounded-lg border border-zinc-200 bg-white p-6 md:grid-cols-2">
			{#each data.fields as field (field.name)}
				<div class="flex flex-col gap-0.5 {field.type === 'text' ? 'md:col-span-2' : ''}">
					<dt class="text-xs font-medium uppercase tracking-wider text-zinc-400">{fieldLabel(field.name)}</dt>
					<dd class="text-sm">
						{#if field.type === 'reference' && data.record[field.name]}
							{data.referenceNames[field.name] ?? data.record[field.name]}
						{:else if field.type === 'enum' && data.record[field.name]}
							<span class="rounded-full px-2 py-0.5 text-xs font-medium {enumChipClass(String(data.record[field.name]))}">
								{data.record[field.name]}
							</span>
						{:else}
							{formatValue(field, data.record[field.name])}
						{/if}
					</dd>
				</div>
			{/each}
		</dl>
		{#if problem}<p class="mt-3 rounded bg-red-50 p-2 text-sm text-red-700">{problem}</p>{/if}
		<p class="mt-3 text-xs text-zinc-400">
			Created {formatValue({ type: 'datetime' }, data.record.created_at)}
			· Updated {formatValue({ type: 'datetime' }, data.record.updated_at)}
		</p>
	{/if}
</div>
