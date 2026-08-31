<script lang="ts">
	import { enumChipClass } from '$lib/display';
	let { data } = $props();
</script>
<svelte:head>
	<title>Team Timeline · CRMTHREE</title>
</svelte:head>


<h1 class="text-xl font-semibold tracking-tight">Team Timeline</h1>

<div class="mt-4 grid grid-cols-1 gap-4 lg:grid-cols-3">
	<section class="rounded-lg border border-rule bg-surface lg:col-span-2">
		<h2 class="border-b border-rule/50 px-4 py-2.5 text-sm font-semibold">Recent Activities</h2>
		<div class="flex flex-col">
			{#each data.feed as item (item.id)}
				<a href={`/Activity/${item.id}`} class="flex items-center gap-3 border-b border-rule/40 px-4 py-2.5 last:border-0 hover:bg-paper">
					<span class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-accent-100 text-xs font-semibold text-accent-700">
						{String(item.first_name ?? '?')[0]}{String(item.last_name ?? '?')[0]}
					</span>
					<span class="min-w-0 flex-1">
						<span class="block truncate text-sm">{item.subject}</span>
						<span class="block text-xs text-steel">{item.first_name ?? 'Unknown'} {item.last_name ?? ''} · {new Date(item.at).toLocaleDateString()}</span>
					</span>
					<span class="rounded-full px-2 py-0.5 text-xs font-medium {enumChipClass(String(item.status))}">{item.type}</span>
				</a>
			{:else}
				<p class="px-4 py-6 text-center text-sm text-steel/70">No activities yet</p>
			{/each}
		</div>
	</section>

	<section class="rounded-lg border border-rule bg-surface p-4">
		<h2 class="text-sm font-semibold">Standings</h2>
		<div class="mt-2 flex flex-col">
			{#each data.members as member, index (member.id)}
				<div class="flex items-center gap-2.5 border-t border-rule/40 py-2 first:border-0">
					<span class="w-4 text-center text-xs font-semibold text-steel">{index + 1}</span>
					<span class="min-w-0 flex-1">
						<span class="block truncate text-sm font-medium">{member.first_name} {member.last_name}</span>
						<span class="block text-xs text-steel">L{member.level} {member.level_name}</span>
					</span>
					<span class="text-xs font-semibold tabular-nums text-accent-600">{member.xp_total}</span>
				</div>
			{/each}
		</div>
	</section>
</div>
