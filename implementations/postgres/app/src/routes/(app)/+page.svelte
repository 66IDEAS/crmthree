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
	const maxPriority = $derived(Math.max(1, ...data.priorities.map((p) => p.tickets)));

	// Sequential ramp for the ordered priority scale, light to dark, validated for lightness
	// monotonicity and CVD separation; the pale step's contrast relief is the direct label
	// every bar carries. Identity comes from the axis, not the hue.
	const PRIORITY_RAMP: Record<string, string> = {
		Low: '#8FA9FA', Medium: '#5A80EF', High: '#2450C4', Critical: '#132466'
	};
</script>

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
