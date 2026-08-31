<script lang="ts">
	import { goto } from '$app/navigation';
	import { t } from '$lib/i18n';

	let { lead, onclose }: { lead: Record<string, unknown>; onclose: () => void } = $props();

	const fullName = [lead.first_name, lead.last_name].filter(Boolean).join(' ');
	let accountName = $state(String(lead.company ?? fullName));
	let createOpportunity = $state(false);
	let opportunityName = $state(fullName);
	let problem = $state('');
	let busy = $state(false);

	async function convert() {
		busy = true;
		problem = '';
		const response = await fetch('/api/conversions', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({ kind: 'lead', leadId: lead.id, accountName, createOpportunity, opportunityName })
		});
		busy = false;
		if (!response.ok) {
			problem = (await response.json().catch(() => null))?.message ?? t('dialog.conversion_failed', 'Conversion failed. Please try again.');
			return;
		}
		const result = await response.json();
		await goto(`/Contact/${result.contactId}`, { invalidateAll: true });
	}
</script>

<div class="fixed inset-0 z-30 flex items-center justify-center bg-ink/40" role="presentation" onclick={onclose}>
	<div class="w-full max-w-md rounded-lg bg-surface p-6 shadow-xl" role="dialog" onclick={(e) => e.stopPropagation()}>
		<h2 class="text-lg font-semibold">{t('dialog.convert_lead', 'Convert Lead')}</h2>
		<p class="mt-1 text-sm text-steel">{t('dialog.convert_description', 'Converting this lead will create the following records:')} {t('dialog.account', 'Account')}, {t('dialog.contact', 'Contact')}{createOpportunity ? `, ${t('dialog.opportunity', 'Opportunity')}` : ''}</p>

		<label class="mt-4 flex flex-col gap-1 text-sm">
			<span class="font-medium">{t('dialog.account_name', 'Account Name')}</span>
			<input bind:value={accountName} class="rounded border border-steel/40 px-3 py-1.5 outline-none focus:border-accent-600" />
		</label>
		<label class="mt-3 flex items-center gap-2 text-sm">
			<input type="checkbox" bind:checked={createOpportunity} class="h-4 w-4 accent-accent-600" />
			{t('dialog.create_opportunity', 'Create an opportunity')}
		</label>
		{#if createOpportunity}
			<label class="mt-2 flex flex-col gap-1 text-sm">
				<span class="font-medium">{t('dialog.opportunity_name', 'Opportunity Name')}</span>
				<input bind:value={opportunityName} class="rounded border border-steel/40 px-3 py-1.5 outline-none focus:border-accent-600" />
			</label>
		{/if}
		{#if problem}<p class="mt-3 rounded bg-error/10 p-2 text-sm text-error">{problem}</p>{/if}
		<div class="mt-5 flex justify-end gap-2">
			<button onclick={onclose} class="rounded border border-rule px-4 py-1.5 text-sm hover:bg-paper">{t('ui.cancel', 'Cancel')}</button>
			<button onclick={convert} disabled={busy || !accountName.trim()}
				class="rounded bg-accent-600 px-4 py-1.5 text-sm font-medium text-white hover:bg-accent-500 disabled:opacity-50">
				{busy ? t('ui.converting', 'Converting...') : t('ui.convert', 'Convert')}
			</button>
		</div>
	</div>
</div>
