<script lang="ts">
	import { t } from '$lib/i18n';
	/**
	 * On-demand AI briefing card (story 21). Never generated on page load; the card is
	 * absent entirely when no provider is configured.
	 */
	let { objectType, recordId }: { objectType: string; recordId: string } = $props();

	let content = $state('');
	let busy = $state(false);
	let problem = $state('');
	let collapsed = $state(false);

	async function generate() {
		busy = true;
		problem = '';
		const response = await fetch('/api/ai', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({ operation: 'briefing', params: { objectType, recordId } })
		});
		busy = false;
		if (!response.ok) {
			problem = (await response.json().catch(() => null))?.message ?? 'Briefing failed';
			return;
		}
		content = (await response.json()).content;
	}
</script>

<section class="mt-4 rounded-lg border border-rule bg-surface">
	<header class="flex items-center gap-2.5 px-4 py-2.5">
		<span class="flex h-7 w-7 items-center justify-center rounded-full bg-accent-600 text-white">
			<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
				<path stroke-linecap="round" stroke-linejoin="round"
					d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09zM18.259 8.715L18 9.75l-.259-1.035a3.375 3.375 0 00-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 002.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 002.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 00-2.456 2.456z" />
			</svg>
		</span>
		<h2 class="flex-1 text-sm font-semibold">{t('ai.briefing', 'AI Briefing')}</h2>
		{#if content}
			<button onclick={generate} class="text-xs text-steel hover:text-ink" title={t('ai.regenerate', 'Regenerate')}>↻</button>
			<button onclick={() => (collapsed = !collapsed)} class="text-xs text-steel hover:text-ink">{collapsed ? '+' : '−'}</button>
		{:else}
			<button onclick={generate} disabled={busy}
				class="rounded border border-accent-600 px-3 py-1 text-xs font-medium text-accent-600 hover:bg-accent-50 disabled:opacity-50">
				{busy ? t('ai.generating', 'Generating briefing...') : t('ai.generate', 'Generate Briefing')}
			</button>
		{/if}
	</header>
	{#if problem}<p class="border-t border-rule/50 px-4 py-2 text-sm text-error">{problem}</p>{/if}
	{#if content && !collapsed}
		<p class="border-t border-rule/50 px-4 py-3 text-sm leading-relaxed whitespace-pre-wrap">{content}</p>
	{/if}
</section>
