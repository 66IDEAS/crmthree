<script lang="ts">
	import { page } from '$app/state';
	import { goto } from '$app/navigation';
	import { displayName, fieldLabel, formatValue, enumChipClass, objectLabel } from '$lib/display';

	let { data } = $props();
	let importing = $state(false);
	let importResult = $state('');
	let columnsOpen = $state(false);
	let filterTimer: ReturnType<typeof setTimeout> | null = null;

	function withParams(mutate: (params: URLSearchParams) => void, resetCursor = true): string {
		const params = new URLSearchParams(page.url.searchParams);
		if (resetCursor) {
			params.delete('cursorSort');
			params.delete('cursorId');
		}
		mutate(params);
		const text = params.toString();
		return text ? `?${text}` : page.url.pathname;
	}

	function sortHref(field: string): string {
		return withParams((params) => {
			params.set('sort', field);
			params.set('dir', data.sortField === field && data.direction === 'asc' ? 'desc' : 'asc');
		}, false);
	}

	const nextHref = () =>
		withParams((params) => {
			params.set('cursorSort', String(data.cursor?.sort ?? ''));
			params.set('cursorId', data.cursor?.id ?? '');
		}, false);
	const firstHref = () => withParams(() => {});

	function setPageSize(event: Event) {
		goto(withParams((params) => params.set('pageSize', (event.currentTarget as HTMLSelectElement).value)), {
			keepFocus: true
		});
	}

	function toggleColumn(name: string) {
		const current = data.columns.map((c) => c.name);
		const next = current.includes(name) ? current.filter((c) => c !== name) : [...current, name];
		goto(withParams((params) => {
			if (next.length) params.set('cols', next.join(','));
			else params.delete('cols');
		}), { keepFocus: true });
	}

	function setFilter(field: string, value: string) {
		if (filterTimer) clearTimeout(filterTimer);
		filterTimer = setTimeout(() => {
			goto(withParams((params) => {
				if (value) params.set(`f_${field}`, value);
				else params.delete(`f_${field}`);
			}), { keepFocus: true, noScroll: true });
		}, 350);
	}

	function filterValue(field: string): string {
		return page.url.searchParams.get(`f_${field}`) ?? '';
	}

	function clearFilters() {
		goto(withParams((params) => {
			for (const key of [...params.keys()]) if (key.startsWith('f_')) params.delete(key);
		}));
	}

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
</script>

<div class="flex items-center justify-between">
	<h1 class="text-xl font-semibold tracking-tight">
		{objectLabel(data.objectType, true)}
		<span class="ml-2 text-sm font-normal text-steel/70">
			{data.total} record{data.total === 1 ? '' : 's'}{data.filtered ? ' (filtered)' : ''}
		</span>
		{#if data.filtered}
			<button onclick={clearFilters} class="ml-2 text-xs font-normal text-accent-600 hover:underline">Clear filters</button>
		{/if}
	</h1>
	<div class="flex items-center gap-2">
		<div class="relative">
			<button onclick={() => (columnsOpen = !columnsOpen)}
				class="rounded border border-rule px-3 py-1.5 text-sm hover:bg-paper">Columns</button>
			{#if columnsOpen}
				<div class="absolute right-0 z-20 mt-1 max-h-80 w-56 overflow-y-auto rounded-lg border border-rule bg-surface p-2 shadow-lg">
					{#each data.offerable as field (field.name)}
						<label class="flex items-center gap-2 rounded px-2 py-1 text-sm hover:bg-paper">
							<input type="checkbox" class="h-3.5 w-3.5 accent-accent-600"
								checked={data.columns.some((c) => c.name === field.name)}
								onchange={() => toggleColumn(field.name)} />
							{fieldLabel(field.name)}
						</label>
					{/each}
				</div>
			{/if}
		</div>
		<select value={String(data.pageSize)} onchange={setPageSize}
			class="rounded border border-rule bg-surface px-2 py-1.5 text-sm">
			<option value="25">25</option><option value="50">50</option><option value="100">100</option>
		</select>
		<a href={`/api/csv/${data.objectType}`} download
			class="rounded border border-rule px-3 py-1.5 text-sm hover:bg-paper">Export CSV</a>
		<label class="cursor-pointer rounded border border-rule px-3 py-1.5 text-sm hover:bg-paper">
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

<div class="mt-4 overflow-x-auto rounded-lg border border-rule bg-surface">
	<table class="w-full text-sm">
		<thead>
			<tr class="border-b border-rule text-left text-xs uppercase tracking-wider text-steel">
				{#each data.columns as column (column.name)}
					<th class="px-4 pt-2.5 pb-1 font-medium">
						<a href={sortHref(column.name)} class="hover:text-ink">
							{fieldLabel(column.name)}
							{#if data.sortField === column.name}
								<span class="text-accent-600">{data.direction === 'asc' ? '↑' : '↓'}</span>
							{/if}
						</a>
					</th>
				{/each}
			</tr>
			<!-- Filter row: strings match contains, enums and booleans exact; server-side. -->
			<tr class="border-b border-rule">
				{#each data.columns as column (column.name)}
					<th class="px-4 pt-0.5 pb-2 font-normal">
						{#if column.type === 'enum'}
							<select value={filterValue(column.name)}
								onchange={(e) => setFilter(column.name, e.currentTarget.value)}
								class="w-full rounded border border-rule bg-paper px-1.5 py-1 text-xs font-normal normal-case tracking-normal">
								<option value="">All</option>
								{#each column.values ?? [] as option}<option value={option}>{option}</option>{/each}
							</select>
						{:else if column.type === 'boolean'}
							<select value={filterValue(column.name)}
								onchange={(e) => setFilter(column.name, e.currentTarget.value)}
								class="w-full rounded border border-rule bg-paper px-1.5 py-1 text-xs font-normal normal-case tracking-normal">
								<option value="">All</option><option value="true">Yes</option><option value="false">No</option>
							</select>
						{:else if column.type === 'string'}
							<input value={filterValue(column.name)}
								oninput={(e) => setFilter(column.name, e.currentTarget.value)}
								placeholder="Filter…"
								class="w-full rounded border border-rule bg-paper px-1.5 py-1 text-xs font-normal normal-case tracking-normal outline-none placeholder:text-steel/50 focus:border-accent-600" />
						{/if}
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
					{#each data.columns as column (column.name)}
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
					{#if data.filtered}
						No records match the filters. <button onclick={clearFilters} class="text-accent-600 hover:underline">Clear filters</button>
					{:else}
						No records yet. <a class="text-accent-600 hover:underline" href={`/${data.objectType}/new`}>Create the first one.</a>
					{/if}
				</td></tr>
			{/each}
		</tbody>
	</table>
</div>

<div class="mt-3 flex items-center gap-2 text-sm">
	{#if data.pageStart}
		<a href={firstHref()} class="rounded border border-steel/40 px-3 py-1 hover:bg-paper">First page</a>
	{/if}
	{#if data.cursor && data.rows.length === data.pageSize}
		<a href={nextHref()} class="rounded border border-steel/40 px-3 py-1 hover:bg-paper">Next →</a>
	{/if}
</div>
