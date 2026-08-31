<script lang="ts">
	import { enumChipClass } from '$lib/display';
	let { data } = $props();
</script>
<svelte:head>
	<title>Case Rooms · CRMTHREE</title>
</svelte:head>


<h1 class="text-xl font-semibold tracking-tight">Case Rooms
	<span class="ml-2 text-sm font-normal text-steel/70">{data.rows.length} case{data.rows.length === 1 ? '' : 's'}</span>
</h1>
<div class="mt-4 overflow-x-auto rounded-lg border border-rule bg-surface">
	<table class="w-full text-sm">
		<thead><tr class="border-b border-rule text-left text-xs uppercase tracking-wider text-steel">
			<th class="px-4 py-2.5 font-medium">Ticket</th><th class="px-4 py-2.5 font-medium">Subject</th>
			<th class="px-4 py-2.5 font-medium">Priority</th><th class="px-4 py-2.5 font-medium">Status</th>
			<th class="px-4 py-2.5 font-medium">Account</th>
		</tr></thead>
		<tbody>
			{#each data.rows as row (row.id)}
				<tr class="cursor-pointer border-b border-rule/50 last:border-0 hover:bg-accent-50/60"
					onclick={() => (window.location.href = `/CaseRoom/${row.id}`)}>
					<td class="px-4 py-2.5 tabular-nums">{Number(row.ticket_number) || row.ticket_number}</td>
					<td class="px-4 py-2.5 font-medium">{row.subject}</td>
					<td class="px-4 py-2.5"><span class="rounded-full px-2 py-0.5 text-xs font-medium {enumChipClass(String(row.priority))}">{row.priority}</span></td>
					<td class="px-4 py-2.5">{row.status ?? '—'}</td>
					<td class="px-4 py-2.5">{row.account ?? '—'}</td>
				</tr>
			{/each}
		</tbody>
	</table>
</div>
