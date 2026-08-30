<script lang="ts">
	import { objectLabel } from '$lib/display';
	let { data } = $props();
</script>

<h1 class="text-xl font-semibold tracking-tight">Welcome back</h1>
<p class="mt-1 text-sm text-zinc-500">Everything below is served from local Postgres; no cloud service is involved.</p>

<div class="mt-6 grid grid-cols-2 gap-4 md:grid-cols-3 lg:grid-cols-5">
	{#each data.counts as { objectType, total }}
		<a href={`/${objectType}`}
			class="rounded-lg border border-zinc-200 bg-white p-4 transition-shadow hover:shadow-md">
			<div class="text-2xl font-semibold tabular-nums">{total}</div>
			<div class="mt-1 text-sm text-zinc-500">{objectLabel(objectType, true)}</div>
		</a>
	{/each}
</div>
