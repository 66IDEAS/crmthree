<script lang="ts">
	import { page } from '$app/state';
	import { displayName, fieldLabel, formatValue, enumChipClass, objectLabel } from '$lib/display';

	let { data } = $props();
	let importing = $state(false);
	let importResult = $state('');

	async function importCsv(event: Event) {
		const input = event.currentTarget as HTMLInputElement;
		const file = input.files?.[0];
		if (!file) return;
		importing = true;
		importResult = '';
		const response = await fetch(`/api/csv/${data.objectType}`, {
			method: 'POST',
			headers: { 'content-type': 'text/csv' },
			body: await file.text()
		});
		importing = false;
		input.value = '';
		const result = await response.json().catch(() => null);
		if (!response.ok) {
			importResult = result?.message ?? 'Import failed';
			return;
		}
		importResult = `Imported ${result.created} record${result.created === 1 ? '' : 's'}`
			+ (result.failed ? `, ${result.failed} failed (first: line ${result.problems[0]?.line}: ${result.problems[0]?.error})` : '');
		if (result.created) window.location.reload();
	}

	function sortHref(field: string): string {
		const params = new URLSearchParams();
		params.set('sort', field);
		params.set('dir', data.sortField === field && data.direction === 'asc' ? 'desc' : 'asc');
		return `?${params}`;
	}

	function nextHref(): string {
		const params = new URLSearchParams(page.url.searchParams);
		params.set('cursorSort', String(data.cursor?.sort ?? ''));
		params.set('cursorId', data.cursor?.id ?? '');
		return `?${params}`;
	}

	function firstHref(): string {
		const params = new URLSearchParams(page.url.searchParams);
		params.delete('cursorSort');
		params.delete('cursorId');
		return `?${params}`;
	}
</script>

<div class="flex items-center justify-between">
	<h1 class="text-xl font-semibold tracking-tight">
		{objectLabel(data.objectType, true)}
		<span class="ml-2 text-sm font-normal text-steel/70">{data.total} record{data.total === 1 ? '' : 's'}</span>
	</h1>
	<div class="flex items-center gap-2">
		<a href={`/api/csv/${data.objectType}`} download
			class="rounded border border-rule px-3 py-1.5 text-sm hover:bg-white">Export CSV</a>
		<label class="cursor-pointer rounded border border-rule px-3 py-1.5 text-sm hover:bg-white">
			{importing ? 'Importing…' : 'Import CSV'}
			<input type="file" accept=".csv,text/csv" class="hidden" onchange={importCsv} disabled={importing} />
		</label>
		<a href={`/${data.objectType}/new`}
			class="rounded bg-accent-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-accent-500">
			New {objectLabel(data.objectType)}
		</a>
	</div>
</div>
{#if importResult}<p class="mt-2 rounded bg-accent-50 px-3 py-2 text-sm">{importResult}</p>{/if}

<div class="mt-4 overflow-x-auto rounded-lg border border-rule bg-white">
	<table class="w-full text-sm">
		<thead>
			<tr class="border-b border-rule text-left text-xs uppercase tracking-wider text-steel">
				{#each data.columns as column}
					<th class="px-4 py-2.5 font-medium">
						<a href={sortHref(column.name)} class="hover:text-ink">
							{fieldLabel(column.name)}
							{#if data.sortField === column.name}
								<span class="text-accent-600">{data.direction === 'asc' ? '↑' : '↓'}</span>
							{/if}
						</a>
					</th>
				{/each}
			</tr>
		</thead>
		<tbody>
			{#each data.rows as row (row.id)}
				<tr
					class="cursor-pointer border-b border-rule/50 last:border-0 hover:bg-accent-50/60"
					onclick={() => (window.location.href = `/${data.objectType}/${row.id}`)}
				>
					{#each data.columns as column}
						<td class="px-4 py-2.5">
							{#if column.type === 'enum' && row[column.name]}
								<span class="rounded-full px-2 py-0.5 text-xs font-medium {enumChipClass(String(row[column.name]))}">
									{row[column.name]}
								</span>
							{:else if column.type === 'currency'}
								<span class="tabular-nums">{formatValue(column, row[column.name])}</span>
							{:else}
								{formatValue(column, row[column.name])}
							{/if}
						</td>
					{/each}
				</tr>
			{:else}
				<tr><td colspan={data.columns.length} class="px-4 py-10 text-center text-steel/70">
					No records yet. <a class="text-accent-600 hover:underline" href={`/${data.objectType}/new`}>Create the first one.</a>
				</td></tr>
			{/each}
		</tbody>
	</table>
</div>

<div class="mt-3 flex items-center gap-2 text-sm">
	{#if data.pageStart}
		<a href={firstHref()} class="rounded border border-steel/40 px-3 py-1 hover:bg-white">First page</a>
	{/if}
	{#if data.cursor && data.rows.length === 25}
		<a href={nextHref()} class="rounded border border-steel/40 px-3 py-1 hover:bg-white">Next →</a>
	{/if}
</div>
