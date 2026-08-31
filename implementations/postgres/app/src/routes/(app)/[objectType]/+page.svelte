<script lang="ts">
	import { page } from '$app/state';
	import { goto } from '$app/navigation';
	import { t } from '$lib/i18n';
	import { displayName, fieldLabel, formatValue, enumChipClass, objectLabel } from '$lib/display';

	import DataService from '$lib/DataService';
	import { invalidateAll } from '$app/navigation';

	let { data } = $props();
	let importing = $state(false);

	// New-from-email (story 27), leads only.
	let emailOpen = $state(false);
	let emailText = $state('');
	let parsing = $state(false);

	async function parseEmail() {
		parsing = true;
		const response = await fetch('/api/ai', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({ operation: 'parseEmail', params: { text: emailText } })
		});
		parsing = false;
		if (!response.ok) return;
		const { fields } = await response.json();
		const params = new URLSearchParams();
		for (const [key, value] of Object.entries(fields)) if (value) params.set(key, String(value));
		window.location.href = `/Lead/new?${params}`;
	}

	// Inline editing (story 42): double-click a cell, Enter saves, Escape cancels.
	let editing = $state<{ rowId: string; field: string } | null>(null);
	let editValue = $state<unknown>('');
	let editProblem = $state('');

	function startEdit(row: Record<string, unknown>, column: { name: string; type: string }, event: Event) {
		event.stopPropagation();
		editing = { rowId: String(row.id), field: column.name };
		editValue = row[column.name] ?? '';
		editProblem = '';
	}

	async function commitEdit() {
		if (!editing) return;
		try {
			await DataService.update(data.objectType, editing.rowId, {
				[editing.field]: editValue === '' ? null : editValue
			});
			editing = null;
			await invalidateAll();
		} catch (e) {
			editProblem = (e as Error).message;
		}
	}

	function editKey(event: KeyboardEvent) {
		if (event.key === 'Enter') commitEdit();
		if (event.key === 'Escape') editing = null;
	}
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
			{data.total} {t('ui.records', 'records')}{data.filtered ? ' (filtered)' : ''}
		</span>
		{#if data.filtered}
			<button onclick={clearFilters} class="ml-2 text-xs font-normal text-accent-600 hover:underline">Clear filters</button>
		{/if}
	</h1>
	<div class="flex items-center gap-2">
		<div class="relative">
			<button onclick={() => (columnsOpen = !columnsOpen)}
				class="rounded border border-rule px-3 py-1.5 text-sm hover:bg-paper">{t('ui.columns', 'Columns')}</button>
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
			class="rounded border border-rule px-3 py-1.5 text-sm hover:bg-paper">{t('ui.export_csv', 'Export CSV')}</a>
		<label class="cursor-pointer rounded border border-rule px-3 py-1.5 text-sm hover:bg-paper">
			{importing ? 'Importing…' : t('ui.import_csv', 'Import CSV')}
			<input type="file" accept=".csv,text/csv" class="hidden" onchange={importCsv} disabled={importing} />
		</label>
		{#if data.objectType === 'Lead'}
			<button onclick={() => (emailOpen = true)}
				class="rounded border border-accent-600 px-3 py-1.5 text-sm font-medium text-accent-600 hover:bg-accent-50">
				✦ New from Email
			</button>
		{/if}
		<a href={`/${data.objectType}/new`}
			class="rounded bg-accent-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-accent-500">
			{t('ui.new', 'New')} {objectLabel(data.objectType)}
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
						<td class="px-4 py-2.5"
							ondblclick={(e) => startEdit(row, column, e)}
							title="Double-click to edit">
							{#if editing && editing.rowId === String(row.id) && editing.field === column.name}
								<!-- svelte-ignore a11y_no_static_element_interactions -->
								<span onclick={(e) => e.stopPropagation()} onkeydown={editKey}>
									{#if column.type === 'enum'}
										<!-- svelte-ignore a11y_autofocus -->
										<select bind:value={editValue} onchange={commitEdit} autofocus
											class="rounded border border-accent-600 bg-surface px-1.5 py-1 text-xs">
											{#each column.values ?? [] as option}<option value={option}>{option}</option>{/each}
										</select>
									{:else if column.type === 'boolean'}
										<select bind:value={editValue} onchange={commitEdit} autofocus
											class="rounded border border-accent-600 bg-surface px-1.5 py-1 text-xs">
											<option value={true}>Yes</option><option value={false}>No</option>
										</select>
									{:else}
										<!-- svelte-ignore a11y_autofocus -->
										<input bind:value={editValue} onblur={commitEdit} autofocus
											type={['integer', 'decimal', 'currency'].includes(column.type) ? 'number' : column.type === 'date' ? 'date' : 'text'}
											class="w-full min-w-24 rounded border border-accent-600 bg-surface px-1.5 py-1 text-sm" />
									{/if}
									{#if editProblem}<span class="ml-1 text-xs text-error">{editProblem}</span>{/if}
								</span>
							{:else if column.type === 'enum' && row[column.name]}
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

{#if emailOpen}
	<div class="fixed inset-0 z-30 flex items-center justify-center bg-ink/40" role="presentation" onclick={() => (emailOpen = false)}>
		<div class="w-full max-w-lg rounded-lg bg-surface p-6 shadow-xl" role="dialog" onclick={(e) => e.stopPropagation()}>
			<h2 class="text-lg font-semibold">New Lead from Email</h2>
			<p class="mt-1 text-sm text-steel">Paste an email; the AI extracts name, company and contact details into a prefilled lead form.</p>
			<textarea bind:value={emailText} rows="8" placeholder="Paste the email here…"
				class="mt-3 w-full rounded border border-steel/40 px-3 py-2 text-sm outline-none focus:border-accent-600"></textarea>
			<div class="mt-4 flex justify-end gap-2">
				<button onclick={() => (emailOpen = false)} class="rounded border border-rule px-4 py-1.5 text-sm hover:bg-paper">Cancel</button>
				<button onclick={parseEmail} disabled={parsing || !emailText.trim()}
					class="rounded bg-accent-600 px-4 py-1.5 text-sm font-medium text-white hover:bg-accent-500 disabled:opacity-50">
					{parsing ? 'Extracting…' : 'Extract & Prefill'}
				</button>
			</div>
		</div>
	</div>
{/if}
