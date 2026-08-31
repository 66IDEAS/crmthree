<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import DataService from '$lib/DataService';
	import { fieldLabel } from '$lib/display';

	let { data } = $props();

	let theme = $state(String(data.me.theme_preference ?? 'System'));
	let language = $state(String(data.me.language_preference ?? 'en'));
	// Unset means enabled, exactly how the notification triggers read it.
	let prefs = $state<Record<string, boolean>>({ ...(data.me.notification_preferences ?? {}) });
	let saved = $state(false);
	let narrative = $state('');
	let narrating = $state(false);

	// Story 28: a performance summary from one's own numbers.
	async function generateNarrative() {
		narrating = true;
		const response = await fetch('/api/ai', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({ operation: 'performance' })
		});
		narrating = false;
		narrative = response.ok
			? (await response.json()).content
			: (await response.json().catch(() => null))?.message ?? 'Generation failed';
	}

	async function save() {
		await DataService.update('UserProfile', String(data.me.id), {
			theme_preference: theme,
			language_preference: language,
			notification_preferences: prefs
		});
		saved = true;
		setTimeout(() => (saved = false), 1500);
		await invalidateAll();
	}

	function toggle(type: string) {
		prefs = { ...prefs, [type]: prefs[type] === false ? true : false };
	}
</script>

<div class="mx-auto max-w-2xl">
	<h1 class="text-xl font-semibold tracking-tight">Profile</h1>

	<section class="mt-5 rounded-lg border border-rule bg-surface p-6">
		<div class="flex items-center gap-4">
			<span class="flex h-14 w-14 items-center justify-center rounded-full bg-accent-100 text-lg font-semibold text-accent-700">
				{String(data.me.first_name ?? '?')[0]}{String(data.me.last_name ?? '?')[0]}
			</span>
			<div>
				<p class="text-lg font-semibold">{data.me.first_name} {data.me.last_name}</p>
				<p class="text-sm text-steel">{data.me.email} · {data.me.role_name}</p>
				<p class="mt-0.5 text-xs text-steel">
					Level {data.me.level} {data.me.level_name} · {data.me.xp_total} XP ·
					{data.me.current_streak_days}-day streak
				</p>
			</div>
			<button onclick={generateNarrative} disabled={narrating}
				class="ml-auto rounded border border-accent-600 px-3 py-1.5 text-xs font-medium text-accent-600 hover:bg-accent-50 disabled:opacity-50">
				{narrating ? 'Writing…' : '✦ Performance summary'}
			</button>
		</div>
		{#if narrative}
			<p class="mt-4 rounded bg-accent-50 p-3 text-sm leading-relaxed">{narrative}</p>
		{/if}
	</section>

	<section class="mt-4 rounded-lg border border-rule bg-surface p-6">
		<h2 class="text-sm font-semibold">Appearance & Language</h2>
		<div class="mt-3 grid grid-cols-2 gap-4 text-sm">
			<label class="flex flex-col gap-1">
				<span class="font-medium text-ink/80">Theme</span>
				<select bind:value={theme} class="rounded border border-steel/40 px-2 py-1.5">
					<option>Light</option><option>Dark</option><option>System</option>
				</select>
			</label>
			<label class="flex flex-col gap-1">
				<span class="font-medium text-ink/80">Language</span>
				<select bind:value={language} class="rounded border border-steel/40 px-2 py-1.5">
					<option value="en">English</option>
					{#each data.languages as lang (lang.code)}
						<option value={lang.code}>{lang.language_name}</option>
					{/each}
				</select>
			</label>
		</div>
	</section>

	<section class="mt-4 rounded-lg border border-rule bg-surface p-6">
		<h2 class="text-sm font-semibold">Notifications</h2>
		<p class="mt-1 text-xs text-steel">Applies at the source: a disabled type is never created for you, whoever the writer is.</p>
		<div class="mt-3 grid grid-cols-2 gap-2">
			{#each data.notificationTypes as type (type)}
				<label class="flex items-center gap-2 text-sm">
					<input type="checkbox" class="h-4 w-4 accent-accent-600"
						checked={prefs[type] !== false} onchange={() => toggle(type)} />
					{fieldLabel(type)}
				</label>
			{/each}
		</div>
	</section>

	<section class="mt-4 rounded-lg border border-rule bg-surface p-6">
		<h2 class="text-sm font-semibold">Badges</h2>
		{#if data.badges.length === 0}
			<p class="mt-2 text-sm text-steel/70">No badges earned yet.</p>
		{:else}
			<div class="mt-3 grid grid-cols-2 gap-3">
				{#each data.badges as badge (badge.name)}
					<div class="flex items-center gap-3 rounded border border-rule/60 p-3">
						<span class="flex h-9 w-9 items-center justify-center rounded-full bg-warning/15 text-warning">★</span>
						<span class="min-w-0">
							<span class="block truncate text-sm font-medium">{badge.name}</span>
							<span class="block truncate text-xs text-steel">{badge.description ?? badge.category ?? ''}</span>
						</span>
					</div>
				{/each}
			</div>
		{/if}
	</section>

	<section class="mt-4 rounded-lg border border-rule bg-surface p-6">
		<h2 class="text-sm font-semibold">Your Recent Activity</h2>
		<div class="mt-2 flex flex-col">
			{#each data.activity as entry, index (index)}
				<div class="flex items-center gap-3 border-t border-rule/40 py-1.5 text-sm first:border-0">
					<span class="w-32 shrink-0 text-xs text-steel">{new Date(entry.timestamp).toLocaleString()}</span>
					<span class="rounded-full px-2 py-0.5 text-xs font-medium
						{entry.action === 'Create' ? 'bg-success/10 text-success' : entry.action === 'Delete' ? 'bg-error/10 text-error' : 'bg-accent-50 text-accent-600'}">{entry.action}</span>
					<span class="min-w-0 flex-1 truncate">{entry.object_type}{entry.object_name ? ` · ${entry.object_name}` : ''}</span>
					<span class="hidden truncate text-xs text-steel md:block">{entry.summary ?? ''}</span>
				</div>
			{:else}
				<p class="py-3 text-sm text-steel/70">Nothing yet - your changes will show up here.</p>
			{/each}
		</div>
	</section>

	<div class="mt-4 flex items-center gap-3">
		<button onclick={save}
			class="rounded bg-accent-600 px-4 py-1.5 text-sm font-medium text-white hover:bg-accent-500">Save</button>
		{#if saved}<span class="text-sm text-success">Saved</span>{/if}
	</div>
</div>
