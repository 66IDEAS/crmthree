<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import CommentThread from '$lib/components/CommentThread.svelte';
	import DataService from '$lib/DataService';
	import { enumChipClass, formatValue } from '$lib/display';
	import AiBriefing from '$lib/components/AiBriefing.svelte';

	let { data } = $props();

	const currentStageIndex = $derived(
		data.stages.findIndex((s: { id: string }) => s.id === data.opportunity?.stage_id)
	);

	async function updateStage(stageId: string) {
		if (!data.opportunity) return;
		await DataService.update('Opportunity', String(data.opportunity.id), { stage_id: stageId });
		await invalidateAll();
	}

	async function closeRoom() {
		if (!confirm('Close this deal room?')) return;
		await DataService.update('DealRoom', String(data.room.id), { status: 'Closed' });
		await invalidateAll();
	}
</script>
<svelte:head>
	<title>{data.room.name} · Deal Room · CRMTHREE</title>
</svelte:head>


<div class="mx-auto max-w-5xl">
	<div class="flex items-center justify-between">
		<div>
			<a href="/DealRoom" class="text-sm text-steel hover:text-ink">← Deal Rooms</a>
			<h1 class="mt-1 flex items-center gap-2 text-xl font-semibold tracking-tight">
				{data.room.name}
				<span class="rounded-full px-2 py-0.5 text-xs font-medium {enumChipClass(String(data.room.status))}">{data.room.status}</span>
			</h1>
		</div>
		<div class="flex gap-2">
			{#if data.opportunity}
				<a href={`/Opportunity/${data.opportunity.id}`}
					class="rounded border border-rule px-4 py-1.5 text-sm hover:bg-paper">View Opportunity</a>
			{/if}
			{#if data.room.status === 'Active'}
				<button onclick={closeRoom} class="rounded border border-rule px-4 py-1.5 text-sm hover:bg-paper">Close Deal Room</button>
			{/if}
		</div>
	</div>

	<!-- Stage progress: the pipeline as a stepper, current highlighted, click to move. -->
	{#if data.opportunity}
		<div class="mt-5 flex items-center gap-1 overflow-x-auto rounded-lg border border-rule bg-surface p-4">
			{#each data.stages as stage, index (stage.id)}
				<button
					onclick={() => updateStage(stage.id)}
					title="{stage.name} ({stage.probability}%)"
					class="flex min-w-0 flex-1 flex-col items-center gap-1.5 rounded px-1 py-1 hover:bg-paper"
				>
					<span class="flex h-6 w-6 items-center justify-center rounded-full text-xs font-semibold
						{index < currentStageIndex ? 'bg-accent-100 text-accent-700'
						: index === currentStageIndex ? 'bg-accent-600 text-white'
						: 'bg-rule/40 text-steel'}">
						{index < currentStageIndex ? '✓' : index + 1}
					</span>
					<span class="w-full truncate text-center text-[11px] {index === currentStageIndex ? 'font-semibold text-ink' : 'text-steel'}">{stage.name}</span>
				</button>
				{#if index < data.stages.length - 1}<span class="h-px w-4 shrink-0 bg-rule"></span>{/if}
			{/each}
		</div>
	{/if}

	<div class="mt-4 grid grid-cols-1 gap-4 lg:grid-cols-3">
		<div class="flex flex-col gap-4 lg:col-span-2">
			{#if data.aiConfigured && data.opportunity}
				<!-- Pipeline coaching (story 24): the record briefing over the opportunity. -->
				<div class="-mt-4"><AiBriefing objectType="Opportunity" recordId={String(data.opportunity.id)} /></div>
			{/if}
			<!-- Activity timeline -->
			<section class="rounded-lg border border-rule bg-surface">
				<h2 class="border-b border-rule/50 px-4 py-2.5 text-sm font-semibold">Activity Timeline</h2>
				<div class="flex flex-col">
					{#each data.activities as activity (activity.id)}
						<a href={`/Activity/${activity.id}`} class="flex items-center gap-3 border-b border-rule/40 px-4 py-2.5 last:border-0 hover:bg-paper">
							<span class="rounded-full px-2 py-0.5 text-xs font-medium {enumChipClass(String(activity.status))}">{activity.type}</span>
							<span class="min-w-0 flex-1 truncate text-sm">{activity.subject}</span>
							<span class="text-xs text-steel">{formatValue({ type: 'date' }, activity.due_date ?? activity.start_date)}</span>
						</a>
					{:else}
						<p class="px-4 py-5 text-center text-sm text-steel/70">No activities yet</p>
					{/each}
				</div>
			</section>
			<CommentThread parentType="DealRoom" parentId={String(data.room.id)} profileId={data.profileId} />
		</div>

		<div class="flex flex-col gap-4">
			{#if data.opportunity}
				<section class="rounded-lg border border-rule bg-surface p-4">
					<h2 class="text-sm font-semibold">Deal Info</h2>
					<dl class="mt-3 flex flex-col gap-2 text-sm">
						<div class="flex justify-between"><dt class="text-steel">Amount</dt>
							<dd class="tabular-nums font-medium">{formatValue({ type: 'currency' }, data.opportunity.amount)}</dd></div>
						<div class="flex justify-between"><dt class="text-steel">Probability</dt>
							<dd>{data.opportunity.probability ?? '—'}%</dd></div>
						<div class="flex justify-between"><dt class="text-steel">Expected close</dt>
							<dd>{formatValue({ type: 'date' }, data.opportunity.expected_close_date)}</dd></div>
						<div class="flex justify-between"><dt class="text-steel">Result</dt>
							<dd><span class="rounded-full px-2 py-0.5 text-xs font-medium {enumChipClass(String(data.opportunity.result))}">{data.opportunity.result}</span></dd></div>
						{#if data.account}
							<div class="flex justify-between"><dt class="text-steel">Account</dt>
								<dd><a class="text-accent-600 hover:underline" href={`/Account/${data.account.id}`}>{data.account.name1}</a></dd></div>
						{/if}
						{#if data.owner}
							<div class="flex justify-between"><dt class="text-steel">Owner</dt>
								<dd>{data.owner.first_name} {data.owner.last_name}</dd></div>
						{/if}
					</dl>
				</section>
			{/if}
			<section class="rounded-lg border border-rule bg-surface p-4">
				<h2 class="text-sm font-semibold">Contacts</h2>
				<div class="mt-2 flex flex-col gap-2">
					{#each data.contacts as contact (contact.id)}
						<a href={`/Contact/${contact.id}`} class="flex items-baseline justify-between text-sm hover:text-accent-600">
							<span>{contact.first_name} {contact.last_name}</span>
							<span class="text-xs text-steel">{contact.role ?? ''}</span>
						</a>
					{:else}
						<p class="text-sm text-steel/70">No contacts linked</p>
					{/each}
				</div>
			</section>
		</div>
	</div>
</div>
