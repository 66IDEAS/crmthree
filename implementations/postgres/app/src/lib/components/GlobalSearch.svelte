<script lang="ts">
	import { t } from '$lib/i18n';
	type Group = { objectType: string; label: string; matches: { id: string; display: string; sub: string }[] };

	let query = $state('');
	let groups = $state<Group[]>([]);
	let open = $state(false);
	let timer: ReturnType<typeof setTimeout> | null = null;
	let aiResults = $state<{ type: string; id: string; name: string; reason: string }[] | null>(null);
	let asking = $state(false);

	async function askAi() {
		asking = true;
		aiResults = null;
		const response = await fetch('/api/ai', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({ operation: 'semanticSearch', params: { query } })
		});
		asking = false;
		aiResults = response.ok ? (await response.json()).results : [];
	}

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

<div class="relative w-full max-w-xl md:w-[36rem]">
	<input
		bind:value={query}
		oninput={onInput}
		onfocus={() => groups.length && (open = true)}
		onblur={() => setTimeout(() => (open = false), 150)}
		placeholder={t('search.placeholder', 'Ask AI or search across all records (Ctrl+K)')}
		class="w-full rounded border border-rule bg-paper px-3 py-1.5 text-sm outline-none placeholder:text-steel/70 focus:border-accent-600 focus:bg-surface"
	/>
	{#if open}
		<div class="absolute left-0 right-0 z-20 mt-1 max-h-96 overflow-y-auto rounded-lg border border-rule bg-surface shadow-lg">
			<button onmousedown={askAi} disabled={asking}
				class="flex w-full items-center gap-2 border-b border-rule/40 px-3 py-2 text-left text-sm text-accent-600 hover:bg-accent-50/60 disabled:opacity-60">
				<span>✦</span> {asking ? t('search.ai_searching', 'AI is searching...') : `${t('ui.ask', 'Ask')} AI: "${query.trim()}"`}
			</button>
			{#if aiResults}
				<div class="border-b border-rule/40">
					<p class="px-3 pt-2 text-[10px] font-medium uppercase tracking-wider text-accent-600">{t('search.ai_results', 'AI Search Results')}</p>
					{#each aiResults as match (match.id)}
						<button onmousedown={() => { open = false; window.location.href = `/${match.type}/${match.id}`; }}
							class="block w-full px-3 py-1.5 text-left text-sm hover:bg-accent-50/60">
							<span class="font-medium">{match.name}</span>
							<span class="ml-1.5 text-xs text-steel">{match.reason}</span>
						</button>
					{:else}
						<p class="px-3 py-2 text-xs text-steel/70">{t('search.no_results', 'No results found')}</p>
					{/each}
				</div>
			{/if}
			{#if groups.length === 0}
				<p class="px-3 py-4 text-center text-sm text-steel/70">{t('search.no_results', 'No results found')}</p>
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
