<script lang="ts">
	let { data } = $props();

	const money = (value: unknown) =>
		new Intl.NumberFormat(undefined, { maximumFractionDigits: 0 }).format(Number(value ?? 0));

	const tiles = $derived([
		{ label: 'Pipeline value', value: money(data.kpis.pipeline_value), unit: '€' },
		{ label: 'Open opportunities', value: String(data.kpis.open_opportunities) },
		{ label: 'Open tickets', value: String(data.kpis.open_tickets) },
		{ label: 'Open leads', value: String(data.kpis.open_leads) },
		{ label: 'Activities this week', value: String(data.kpis.activities_this_week) }
	]);

	const maxStage = $derived(Math.max(1, ...data.pipeline.map((s) => Number(s.value))));
	const maxTrend = $derived(Math.max(1, ...data.trend.map((m) => m.total)));
	const maxPriority = $derived(Math.max(1, ...data.priorities.map((p) => p.tickets)));

	// Sequential ramp for the ordered priority scale, light to dark, validated for lightness
	// monotonicity and CVD separation; the pale step's contrast relief is the direct label
	// every bar carries. Identity comes from the axis, not the hue.
	const PRIORITY_RAMP: Record<string, string> = {
		Low: '#8FA9FA', Medium: '#5A80EF', High: '#2450C4', Critical: '#132466'
	};
</script>
<svelte:head>
	<title>Dashboard · CRMTHREE</title>
</svelte:head>


<h1 class="text-xl font-semibold tracking-tight">Welcome back</h1>
<p class="mt-1 text-sm text-steel">Everything below is aggregated in Postgres under your permissions.</p>

<!-- Stat tiles: headline numbers are not charts. Colour lives on the numbers. -->
<div class="mt-6 grid grid-cols-2 gap-4 md:grid-cols-5">
	{#each tiles as tile (tile.label)}
		<div class="rounded-lg border border-rule bg-surface p-4">
			<div class="text-2xl font-semibold tabular-nums text-accent-600">
				{#if tile.unit}<span class="mr-0.5 text-base font-normal text-steel">{tile.unit}</span>{/if}{tile.value}
			</div>
			<div class="mt-1 text-sm text-steel">{tile.label}</div>
		</div>
	{/each}
</div>

<div class="mt-6 grid grid-cols-1 gap-4 lg:grid-cols-2">
	<!-- Pipeline by stage: single-series magnitude comparison, one hue, one axis. -->
	<section class="rounded-lg border border-rule bg-surface p-5">
		<h2 class="text-sm font-semibold">Open pipeline by stage</h2>
		<div class="mt-4 flex flex-col gap-2">
			{#each data.pipeline as stage (stage.name)}
				<div class="group relative flex items-center gap-3">
					<span class="w-36 shrink-0 truncate text-right text-xs text-steel">{stage.name}</span>
					<div class="relative h-6 flex-1">
						<div class="absolute inset-y-0 left-0 rounded-r bg-accent-600 transition-opacity group-hover:opacity-80"
							style="width: {Math.max(Number(stage.value) / maxStage * 100, stage.deals ? 1.5 : 0)}%"></div>
						<span class="absolute inset-y-0 flex items-center pl-2 text-xs tabular-nums text-ink"
							style="left: {Math.max(Number(stage.value) / maxStage * 100, stage.deals ? 1.5 : 0)}%">
							{#if stage.deals}€{money(stage.value)}{/if}
						</span>
					</div>
					<div class="pointer-events-none absolute -top-8 left-40 z-10 hidden rounded bg-ink px-2 py-1 text-xs text-paper group-hover:block">
						{stage.name}: €{money(stage.value)} across {stage.deals} deal{stage.deals === 1 ? '' : 's'}
					</div>
				</div>
			{/each}
		</div>
	</section>

	<!-- Tickets by priority: ordered severity, sequential ramp light to dark. -->
	<section class="rounded-lg border border-rule bg-surface p-5">
		<h2 class="text-sm font-semibold">Tickets by priority</h2>
		<div class="mt-4 flex flex-col gap-2">
			{#each data.priorities as row (row.priority)}
				<div class="group relative flex items-center gap-3">
					<span class="w-36 shrink-0 truncate text-right text-xs text-steel">{row.priority}</span>
					<div class="relative h-6 flex-1">
						<div class="absolute inset-y-0 left-0 rounded-r transition-opacity group-hover:opacity-80"
							style="width: {Math.max(row.tickets / maxPriority * 100, 1.5)}%; background: {PRIORITY_RAMP[row.priority] ?? '#2E62E8'}"></div>
						<span class="absolute inset-y-0 flex items-center pl-2 text-xs tabular-nums text-ink"
							style="left: {Math.max(row.tickets / maxPriority * 100, 1.5)}%">{row.tickets}</span>
					</div>
					<div class="pointer-events-none absolute -top-8 left-40 z-10 hidden rounded bg-ink px-2 py-1 text-xs text-paper group-hover:block">
						{row.priority}: {row.tickets} ticket{row.tickets === 1 ? '' : 's'}
					</div>
				</div>
			{/each}
		</div>
	</section>
</div>

<div class="mt-4 grid grid-cols-1 gap-4 lg:grid-cols-2">
	<!-- Leaderboard (UX53): identity by name, colour only on the numbers. -->
	<section class="rounded-lg border border-rule bg-surface p-5">
		<h2 class="text-sm font-semibold">Leaderboard</h2>
		<div class="mt-3 flex flex-col">
			{#each data.leaders as leader, index (leader.id)}
				<div class="flex items-center gap-3 border-t border-rule/40 py-2 first:border-0">
					<span class="w-5 text-center text-sm font-semibold text-steel">{index + 1}</span>
					<span class="flex h-8 w-8 items-center justify-center rounded-full bg-accent-100 text-xs font-semibold text-accent-700">
						{String(leader.first_name ?? '?')[0]}{String(leader.last_name ?? '?')[0]}
					</span>
					<span class="min-w-0 flex-1">
						<span class="block truncate text-sm font-medium">{leader.first_name} {leader.last_name}</span>
						<span class="block text-xs text-steel">Level {leader.level} · {leader.level_name}
							{#if leader.current_streak_days > 1}· {leader.current_streak_days}-day streak{/if}</span>
					</span>
					<span class="text-sm font-semibold tabular-nums text-accent-600">{leader.xp_total} XP</span>
				</div>
			{/each}
		</div>
	</section>

	<!-- Active challenges (story 42), when any are assigned. -->
	<section class="rounded-lg border border-rule bg-surface p-5">
		<h2 class="text-sm font-semibold">Your Challenges</h2>
		{#if data.challenges.length === 0}
			<p class="mt-3 text-sm text-steel/70">No active challenges this month.</p>
		{:else}
			<div class="mt-3 flex flex-col gap-3">
				{#each data.challenges as challenge (challenge.title)}
					{@const pct = Math.min(100, Math.round((Number(challenge.current_value ?? 0) / Math.max(1, Number(challenge.target_value))) * 100))}
					<div>
						<div class="flex items-baseline justify-between text-sm">
							<span class="font-medium">{challenge.title}</span>
							<span class="text-xs tabular-nums text-steel">{challenge.current_value ?? 0} / {challenge.target_value}</span>
						</div>
						<div class="mt-1 h-2 rounded-full bg-rule/40">
							<div class="h-2 rounded-full bg-accent-600" style="width: {pct}%"></div>
						</div>
					</div>
				{/each}
			</div>
		{/if}
	</section>
</div>

<!-- Trend (story 54): one series, one axis, columns anchored to the baseline. -->
<section class="mt-4 rounded-lg border border-rule bg-surface p-5">
	<h2 class="text-sm font-semibold">New records per month</h2>
	<div class="mt-4 flex h-36 items-end gap-2">
		{#each data.trend as month (month.key)}
			<div class="group relative flex h-full flex-1 flex-col items-center justify-end gap-1">
				<span class="text-xs tabular-nums text-ink">{month.total || ''}</span>
				<div class="w-full max-w-10 rounded-t bg-accent-600 transition-opacity group-hover:opacity-80"
					style="height: {Math.max((month.total / maxTrend) * 100, month.total ? 2 : 0.5)}%"></div>
				<span class="text-[10px] text-steel">{month.label}</span>
				<div class="pointer-events-none absolute -top-6 z-10 hidden rounded bg-ink px-2 py-1 text-xs whitespace-nowrap text-paper group-hover:block">
					{month.key}: {month.total} new record{month.total === 1 ? '' : 's'}
				</div>
			</div>
		{/each}
	</div>
</section>

