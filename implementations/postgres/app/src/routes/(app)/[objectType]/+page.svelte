<script lang="ts">
	import { page } from '$app/state';
	import { displayName, fieldLabel, formatValue, enumChipClass, objectLabel } from '$lib/display';

	let { data } = $props();

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
		<span class="ml-2 text-sm font-normal text-zinc-400">{data.total} record{data.total === 1 ? '' : 's'}</span>
	</h1>
	<a href={`/${data.objectType}/new`}
		class="rounded bg-accent-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-accent-700">
		New {objectLabel(data.objectType)}
	</a>
</div>

<div class="mt-4 overflow-x-auto rounded-lg border border-zinc-200 bg-white">
	<table class="w-full text-sm">
		<thead>
			<tr class="border-b border-zinc-200 text-left text-xs uppercase tracking-wider text-zinc-500">
				{#each data.columns as column}
					<th class="px-4 py-2.5 font-medium">
						<a href={sortHref(column.name)} class="hover:text-zinc-900">
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
					class="cursor-pointer border-b border-zinc-100 last:border-0 hover:bg-accent-50/60"
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
				<tr><td colspan={data.columns.length} class="px-4 py-10 text-center text-zinc-400">
					No records yet. <a class="text-accent-600 hover:underline" href={`/${data.objectType}/new`}>Create the first one.</a>
				</td></tr>
			{/each}
		</tbody>
	</table>
</div>

<div class="mt-3 flex items-center gap-2 text-sm">
	{#if data.pageStart}
		<a href={firstHref()} class="rounded border border-zinc-300 px-3 py-1 hover:bg-white">First page</a>
	{/if}
	{#if data.cursor && data.rows.length === 25}
		<a href={nextHref()} class="rounded border border-zinc-300 px-3 py-1 hover:bg-white">Next →</a>
	{/if}
</div>
