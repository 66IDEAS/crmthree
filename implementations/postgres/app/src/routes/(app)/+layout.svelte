<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/state';
	import { NAV_OBJECTS, objectLabel, monogram } from '$lib/display';
	import NotificationBell from '$lib/components/NotificationBell.svelte';

	let { data, children } = $props();

	// Collapsed is the shared UX default; the choice persists per browser.
	let collapsed = $state(true);
	onMount(() => {
		try {
			collapsed = localStorage.getItem('crmthree-nav') !== 'expanded';
		} catch {
			/* keep default */
		}
	});
	function toggle() {
		collapsed = !collapsed;
		try {
			localStorage.setItem('crmthree-nav', collapsed ? 'collapsed' : 'expanded');
		} catch {
			/* non-fatal */
		}
	}

	async function signOut() {
		await fetch('/api/auth/sign-out', { method: 'POST' });
		window.location.href = '/login';
	}
</script>

<div class="flex min-h-screen">
	<!-- Navigation rail. Deep-ink ground; the toggle is the rail's first item, per the
	     shared UX: expanded shows labels, collapsed shows monogram tiles. -->
	<aside class="shrink-0 bg-rail text-warm/70 transition-[width] duration-150 {collapsed ? 'w-14' : 'w-56'}">
		<a href="/" class="flex h-16 items-center px-3" aria-label="Home">
			{#if collapsed}
				<img src="/logo.svg" alt="CRMTHREE" class="mx-auto h-8 w-8" />
			{:else}
				<img src="/crmthree-dark.svg" alt="CRMTHREE" class="ml-1 h-5 w-auto" />
				<span class="mt-3 ml-2 rounded bg-white/10 px-1.5 py-0.5 text-[9px] font-medium uppercase tracking-wider text-warm/50">postgres</span>
			{/if}
		</a>

		<button onclick={toggle} aria-label="Toggle navigation"
			class="flex w-full items-center gap-3 px-3 py-2 text-warm/80 hover:bg-white/5 hover:text-warm">
			<span class="flex h-8 w-8 shrink-0 items-center justify-center">
				<svg class="h-5 w-5 text-accent-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
					<path stroke-linecap="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
				</svg>
			</span>
			{#if !collapsed}<span class="text-sm font-semibold">Navigation</span>{/if}
		</button>
		<div class="mx-3 my-1 border-t border-white/10"></div>

		<nav class="flex flex-col gap-0.5 px-2 pb-6">
			{#each NAV_OBJECTS as objectType}
				{@const active = page.url.pathname.startsWith(`/${objectType}`)}
				<a
					href={`/${objectType}`}
					title={objectLabel(objectType, true)}
					class="flex items-center gap-3 rounded px-1.5 py-1.5 text-sm transition-colors
						{active ? 'bg-white/10 text-white' : 'hover:bg-white/5 hover:text-warm'}"
				>
					<span
						class="flex h-7 w-7 shrink-0 items-center justify-center rounded text-[10px] font-semibold tracking-wide
							{active ? 'bg-accent-400/20 text-accent-400' : 'bg-white/5 text-warm/60'}"
					>
						{monogram(objectType)}
					</span>
					{#if !collapsed}<span class="truncate">{objectLabel(objectType, true)}</span>{/if}
				</a>
			{/each}
		</nav>
	</aside>

	<div class="flex min-w-0 flex-1 flex-col">
		<header class="flex items-center justify-end gap-4 border-b border-rule bg-white px-6 py-3">
			<NotificationBell />
			<div class="text-sm">
				<span class="font-medium">{data.profile.first_name} {data.profile.last_name}</span>
				<span class="ml-1.5 rounded bg-rule/40 px-1.5 py-0.5 text-xs text-steel">{data.profile.role_name}</span>
			</div>
			<button onclick={signOut} class="text-sm text-steel hover:text-ink">Sign out</button>
		</header>
		<main class="flex-1 p-6">
			{@render children()}
		</main>
	</div>
</div>
