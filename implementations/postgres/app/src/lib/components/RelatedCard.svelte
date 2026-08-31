<script lang="ts">
	import type { RelatedCard } from '$lib/server/related';
	import { fieldLabel, formatValue, enumChipClass, objectLabel, monogram } from '$lib/display';
	import type { FieldDefinition } from '$model';
	import DataService from '$lib/DataService';
	import { invalidateAll } from '$app/navigation';

	let {
		card,
		columns,
		linkOptions = []
	}: {
		card: RelatedCard;
		columns: FieldDefinition[];
		linkOptions?: { id: string; label: string }[];
	} = $props();

	let linking = $state(false);
	let selected = $state('');
	let problem = $state('');
	let uploading = $state(false);
	const isDocuments = $derived(card.target === 'Document' && card.kind === 'one-to-many');

	/** Documents upload a real file: bytes to storage, metadata as the Document record. */
	async function uploadDocument(event: Event) {
		const input = event.currentTarget as HTMLInputElement;
		const file = input.files?.[0];
		if (!file || !card.prefill) return;
		uploading = true;
		problem = '';
		try {
			const form = new FormData();
			form.append('file', file);
			const response = await fetch('/api/files', { method: 'POST', body: form });
			if (!response.ok) throw new Error((await response.json()).message ?? 'Upload failed');
			const stored = await response.json();
			const me = await fetch('/api/me').then((r) => r.json());
			await DataService.create('Document', {
				name: stored.name,
				file_path: stored.url,
				file_type: stored.type,
				file_size: stored.size,
				...card.prefill,
				uploaded_by: me.profile.id
			});
			await invalidateAll();
		} catch (e) {
			problem = (e as Error).message;
		} finally {
			uploading = false;
			input.value = '';
		}
	}

	function openRow(row: Record<string, unknown>) {
		// A document row opens its file; everything else opens its record.
		if (isDocuments && typeof row.file_path === 'string' && row.file_path.startsWith('/api/files/')) {
			window.open(row.file_path, '_blank');
		} else {
			window.location.href = `/${card.target}/${row.id}`;
		}
	}
	const title = $derived(fieldLabel(card.name));
	const alreadyLinked = $derived(new Set(card.rows.map((r) => String(r.id))));

	function newHref(): string {
		const params = new URLSearchParams(card.prefill ?? {});
		return `/${card.target}/new?${params}`;
	}

	async function link() {
		if (!selected || !card.junction) return;
		problem = '';
		try {
			await DataService.create(card.junction.objectType, {
				[card.junction.thisField]: currentId(),
				[card.junction.otherField]: selected
			});
		} catch (e) {
			problem = (e as Error).message;
			return;
		}
		linking = false;
		selected = '';
		await invalidateAll();
	}

	// The record id this card belongs to arrives via the page URL.
	function currentId(): string {
		return window.location.pathname.split('/')[2];
	}

	async function unlink(row: { _junctionId?: string }) {
		if (!row._junctionId || !card.junction) return;
		await DataService.remove(card.junction.objectType, row._junctionId);
		await invalidateAll();
	}
</script>

<section class="mt-4 rounded-lg border border-rule bg-surface">
	<header class="flex items-center justify-between border-b border-rule/50 px-4 py-2.5">
		<h2 class="text-sm font-semibold">
			{title}
			<span class="ml-1.5 font-normal text-steel">{card.total}</span>
		</h2>
		{#if isDocuments}
			<label class="cursor-pointer rounded border border-rule px-2.5 py-1 text-xs font-medium hover:bg-paper">
				{uploading ? 'Uploading…' : 'Upload'}
				<input type="file" class="hidden" onchange={uploadDocument} disabled={uploading} />
			</label>
		{:else if card.kind === 'many-to-many'}
			<button onclick={() => (linking = !linking)}
				class="rounded border border-rule px-2.5 py-1 text-xs font-medium hover:bg-paper">Link</button>
		{:else if card.prefill}
			<a href={newHref()} class="rounded border border-rule px-2.5 py-1 text-xs font-medium hover:bg-paper">
				New {objectLabel(card.target)}
			</a>
		{/if}
	</header>

	{#if problem && isDocuments}
		<p class="border-b border-rule/50 px-4 py-2 text-sm text-error">{problem}</p>
	{/if}
	{#if linking}
		<div class="flex items-center gap-2 border-b border-rule/50 bg-paper px-4 py-2">
			<select bind:value={selected}
				class="flex-1 rounded border border-steel/40 px-2 py-1 text-sm outline-none focus:border-accent-600">
				<option value="">Select {objectLabel(card.target)}…</option>
				{#each linkOptions.filter((o) => !alreadyLinked.has(o.id)) as option (option.id)}
					<option value={option.id}>{option.label}</option>
				{/each}
			</select>
			<button onclick={link} disabled={!selected}
				class="rounded bg-accent-600 px-3 py-1 text-xs font-medium text-white hover:bg-accent-500 disabled:opacity-50">Add</button>
			{#if problem}<span class="text-xs text-error">{problem}</span>{/if}
		</div>
	{/if}

	{#if card.rows.length === 0}
		<p class="px-4 py-5 text-center text-sm text-steel/70">No {objectLabel(card.target, true).toLowerCase()} yet</p>
	{:else}
		<table class="w-full text-sm">
			<thead>
				<tr class="text-left text-[11px] uppercase tracking-wider text-steel/80">
					<th class="px-4 py-1.5 font-medium">Name</th>
					{#each columns as column}<th class="px-4 py-1.5 font-medium">{fieldLabel(column.name)}</th>{/each}
					{#if card.kind === 'many-to-many'}<th></th>{/if}
				</tr>
			</thead>
			<tbody>
				{#each card.rows as row (row.id)}
					<tr class="cursor-pointer border-t border-rule/40 hover:bg-accent-50/60"
						onclick={() => openRow(row)}>
						<td class="flex items-center gap-2 px-4 py-2 font-medium">
							<span class="flex h-5 w-5 items-center justify-center rounded bg-rule/40 text-[9px] font-semibold text-steel">{monogram(card.target)}</span>
							{row._display}
						</td>
						{#each columns as column}
							<td class="px-4 py-2">
								{#if column.type === 'enum' && row[column.name]}
									<span class="rounded-full px-2 py-0.5 text-xs font-medium {enumChipClass(String(row[column.name]))}">{row[column.name]}</span>
								{:else}
									{formatValue(column, row[column.name])}
								{/if}
							</td>
						{/each}
						{#if card.kind === 'many-to-many'}
							<td class="px-4 py-2 text-right">
								<button onclick={(e) => { e.stopPropagation(); unlink(row); }}
									class="text-xs text-steel hover:text-error" title="Unlink">✕</button>
							</td>
						{/if}
					</tr>
				{/each}
			</tbody>
		</table>
		{#if card.total > card.rows.length}
			<p class="border-t border-rule/40 px-4 py-2 text-xs text-steel">
				Showing {card.rows.length} of {card.total}
			</p>
		{/if}
	{/if}
</section>
