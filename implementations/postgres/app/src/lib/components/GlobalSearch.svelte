<script lang="ts">
	type Group = { objectType: string; label: string; matches: { id: string; display: string; sub: string }[] };

	let query = $state('');
	let groups = $state<Group[]>([]);
	let open = $state(false);
	let timer: ReturnType<typeof setTimeout> | null = null;

	function onInput() {
		if (timer) clearTimeout(timer);
		timer = setTimeout(run, 200);
	}

	async function run() {
		if (query.trim().length < 2) {
			groups = [];
			open = false;
			return;
		}
		const response = await fetch(`/api/search?q=${encodeURIComponent(query.trim())}`);
		if (response.ok) {
			groups = (await response.json()).results;
			open = true;
		}
	}

	function go(group: Group, match: { id: string }) {
		open = false;
		query = '';
		window.location.href = `/${group.objectType}/${match.id}`;
	}
</script>

<div class="relative w-72">
	<input
		bind:value={query}
		oninput={onInput}
		onfocus={() => groups.length && (open = true)}
		onblur={() => setTimeout(() => (open = false), 150)}
		placeholder="Search…"
		class="w-full rounded border border-rule bg-paper px-3 py-1.5 text-sm outline-none placeholder:text-steel/70 focus:border-accent-600 focus:bg-white"
	/>
	{#if open}
		<div class="absolute left-0 right-0 z-20 mt-1 max-h-96 overflow-y-auto rounded-lg border border-rule bg-white shadow-lg">
			{#if groups.length === 0}
				<p class="px-3 py-4 text-center text-sm text-steel/70">No matches</p>
			{:else}
				{#each groups as group (group.objectType)}
					<div class="border-b border-rule/40 last:border-0">
						<p class="px-3 pt-2 text-[10px] font-medium uppercase tracking-wider text-steel/80">{group.label}</p>
						{#each group.matches as match (match.id)}
							<button onmousedown={() => go(group, match)}
								class="block w-full px-3 py-1.5 text-left text-sm hover:bg-accent-50/60">
								<span class="font-medium">{match.display}</span>
								{#if match.sub}<span class="ml-1.5 text-xs text-steel">{match.sub}</span>{/if}
							</button>
						{/each}
					</div>
				{/each}
			{/if}
		</div>
	{/if}
</div>
