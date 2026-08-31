<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import CommentThread from '$lib/components/CommentThread.svelte';
	import DataService from '$lib/DataService';
	import { t } from '$lib/i18n';
	import { enumChipClass, enumLabel, fieldLabel, objectLabel, formatValue } from '$lib/display';
	import { goto } from '$app/navigation';

	let { data } = $props();
	let drafting = $state(false);
	let draftProblem = $state('');

	// Stories 25/51: the case becomes a draft knowledge article, AI-written and linked.
	async function draftArticle() {
		drafting = true;
		draftProblem = '';
		const response = await fetch('/api/ai', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({ operation: 'caseToArticle', params: { ticketId: data.ticket.id } })
		});
		drafting = false;
		if (!response.ok) {
			draftProblem = (await response.json().catch(() => null))?.message ?? 'Drafting failed';
			return;
		}
		const result = await response.json();
		await goto(`/KnowledgeArticle/${result.id}`);
	}

	async function updateStatus(statusId: string) {
		const status = data.statuses.find((s: { id: string }) => s.id === statusId);
		const stamps: Record<string, unknown> = { status_id: statusId };
		// Milestone timestamps follow the status semantics.
		if (status?.is_resolved && !data.ticket.resolved_at) stamps.resolved_at = new Date().toISOString();
		if (status?.is_closed && !data.ticket.closed_at) stamps.closed_at = new Date().toISOString();
		await DataService.update('Ticket', String(data.ticket.id), stamps);
		await invalidateAll();
	}

	const slaState = (deadline: unknown): string => {
		if (!deadline) return '';
		return new Date(String(deadline)) < new Date() ? 'text-error font-medium' : 'text-success';
	};
</script>
<svelte:head>
	<title>{data.ticket.subject} · Case Room · CRMTHREE</title>
</svelte:head>


<div class="mx-auto max-w-5xl">
	<div class="flex items-center justify-between">
		<div>
			<a href="/CaseRoom" class="text-sm text-steel hover:text-ink">← {objectLabel('CaseRoom', true)}</a>
			<h1 class="mt-1 flex items-center gap-2 text-xl font-semibold tracking-tight">
				{data.ticket.subject}
				<span class="rounded-full px-2 py-0.5 text-xs font-medium {enumChipClass(String(data.ticket.priority))}">{enumLabel(String(data.ticket.priority))}</span>
			</h1>
		</div>
		<div class="flex items-center gap-2">
			<select value={data.ticket.status_id} onchange={(e) => updateStatus(e.currentTarget.value)}
				class="rounded border border-steel/40 bg-surface px-2 py-1.5 text-sm">
				{#each data.statuses as status (status.id)}<option value={status.id}>{status.name}</option>{/each}
			</select>
			{#if data.aiConfigured}
				<button onclick={draftArticle} disabled={drafting}
					class="rounded border border-accent-600 px-4 py-1.5 text-sm font-medium text-accent-600 hover:bg-accent-50 disabled:opacity-50">
					{drafting ? 'Drafting…' : 'Draft KB Article'}
				</button>
			{/if}
			<a href={`/Ticket/${data.ticket.id}`} class="rounded border border-rule px-4 py-1.5 text-sm hover:bg-paper">View Ticket</a>
		</div>
	</div>

	{#if draftProblem}<p class="mt-3 rounded bg-error/10 p-2 text-sm text-error">{draftProblem}</p>{/if}
	<div class="mt-4 grid grid-cols-1 gap-4 lg:grid-cols-3">
		<div class="flex flex-col gap-4 lg:col-span-2">
			{#if data.ticket.description}
				<section class="rounded-lg border border-rule bg-surface p-4 text-sm whitespace-pre-wrap">{data.ticket.description}</section>
			{/if}
			<section class="rounded-lg border border-rule bg-surface">
				<h2 class="border-b border-rule/50 px-4 py-2.5 text-sm font-semibold">Activity Timeline</h2>
				<div class="flex flex-col">
					{#each data.activities as activity (activity.id)}
						<a href={`/Activity/${activity.id}`} class="flex items-center gap-3 border-b border-rule/40 px-4 py-2.5 last:border-0 hover:bg-paper">
							<span class="rounded-full px-2 py-0.5 text-xs font-medium {enumChipClass(String(activity.status))}">{enumLabel(String(activity.type))}</span>
							<span class="min-w-0 flex-1 truncate text-sm">{activity.subject}</span>
							<span class="text-xs text-steel">{formatValue({ type: 'date' }, activity.due_date ?? activity.start_date)}</span>
						</a>
					{:else}
						<p class="px-4 py-5 text-center text-sm text-steel/70">No activities yet</p>
					{/each}
				</div>
			</section>
			<CommentThread parentType="Ticket" parentId={String(data.ticket.id)} profileId={data.profileId} />
		</div>

		<div class="flex flex-col gap-4">
			<section class="rounded-lg border border-rule bg-surface p-4">
				<h2 class="text-sm font-semibold">Case Info</h2>
				<dl class="mt-3 flex flex-col gap-2 text-sm">
					<div class="flex justify-between"><dt class="text-steel">{fieldLabel('ticket_number', 'Ticket')}</dt>
						<dd class="tabular-nums">#{Number(data.ticket.ticket_number) || data.ticket.ticket_number}</dd></div>
					{#if data.account}
						<div class="flex justify-between"><dt class="text-steel">{t('dialog.account', 'Account')}</dt>
							<dd><a class="text-accent-600 hover:underline" href={`/Account/${data.account.id}`}>{data.account.name1}</a></dd></div>
					{/if}
					{#if data.contact}
						<div class="flex justify-between"><dt class="text-steel">{t('dialog.contact', 'Contact')}</dt>
							<dd><a class="text-accent-600 hover:underline" href={`/Contact/${data.contact.id}`}>{data.contact.first_name} {data.contact.last_name}</a></dd></div>
					{/if}
					{#if data.assignee}
						<div class="flex justify-between"><dt class="text-steel">Assigned to</dt>
							<dd>{data.assignee.first_name} {data.assignee.last_name}</dd></div>
					{/if}
					<div class="flex justify-between"><dt class="text-steel">{fieldLabel('category', 'Ticket')}</dt><dd>{data.ticket.category ?? '—'}</dd></div>
				</dl>
			</section>
			<section class="rounded-lg border border-rule bg-surface p-4">
				<h2 class="text-sm font-semibold">SLA</h2>
				<dl class="mt-3 flex flex-col gap-2 text-sm">
					<div class="flex justify-between"><dt class="text-steel">Response due</dt>
						<dd class={slaState(data.ticket.sla_response_deadline)}>{formatValue({ type: 'datetime' }, data.ticket.sla_response_deadline)}</dd></div>
					<div class="flex justify-between"><dt class="text-steel">Resolution due</dt>
						<dd class={slaState(data.ticket.sla_resolution_deadline)}>{formatValue({ type: 'datetime' }, data.ticket.sla_resolution_deadline)}</dd></div>
					<div class="flex justify-between"><dt class="text-steel">First response</dt>
						<dd>{formatValue({ type: 'datetime' }, data.ticket.first_response_at)}</dd></div>
					<div class="flex justify-between"><dt class="text-steel">Resolved</dt>
						<dd>{formatValue({ type: 'datetime' }, data.ticket.resolved_at)}</dd></div>
				</dl>
			</section>
			<section class="rounded-lg border border-rule bg-surface p-4">
				<h2 class="text-sm font-semibold">{objectLabel('KnowledgeArticle', true)}</h2>
				<div class="mt-2 flex flex-col gap-2">
					{#each data.articles as article (article.id)}
						<a href={`/KnowledgeArticle/${article.id}`} class="flex items-baseline justify-between text-sm hover:text-accent-600">
							<span class="min-w-0 truncate">{article.title}</span>
							<span class="ml-2 shrink-0 rounded-full px-2 py-0.5 text-xs {enumChipClass(String(article.status))}">{enumLabel(String(article.status))}</span>
						</a>
					{:else}
						<p class="text-sm text-steel/70">{t('misc.no_linked_records', 'No linked records.')}</p>
					{/each}
				</div>
			</section>
		</div>
	</div>
</div>
