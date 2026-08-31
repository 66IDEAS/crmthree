<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/state';
	import { NAV_OBJECTS, objectLabel } from '$lib/display';
	import NavIcon from '$lib/components/NavIcon.svelte';
	import NotificationBell from '$lib/components/NotificationBell.svelte';
	import { setLabels, t } from '$lib/i18n';
	import GlobalSearch from '$lib/components/GlobalSearch.svelte';

	let { data, children } = $props();

	// Role-adaptive navigation (story 48): a role listing ribbon items sees only those;
	// an empty list means everything. Admins always see everything.
	const navItems = $derived.by(() => {
		const allowed = data.prefs?.ribbon_items;
		if (data.profile.role_name === 'Admin' || !Array.isArray(allowed) || allowed.length === 0) {
			return NAV_OBJECTS;
		}
		return NAV_OBJECTS.filter((item) => allowed.includes(item));
	});

	// Mobile (story 49): the rail hides behind a hamburger overlay and closes on navigation.
	let mobileOpen = $state(false);

	// Installed before anything below renders; SSR renders the tree synchronously after
	// loads resolve, so per-request labels do not bleed between sessions.
	setLabels(data.labels);
	$effect(() => setLabels(data.labels));

	// Theme: the stored preference wins; System follows the OS. Applied as a class on the
	// root element so the dark token set takes over; mirrored to localStorage so the early
	// inline script in app.html can avoid a light flash on the next load.
	$effect(() => {
		const pref = data.prefs?.theme_preference ?? 'System';
		const dark =
			pref === 'Dark' || (pref === 'System' && window.matchMedia('(prefers-color-scheme: dark)').matches);
		document.documentElement.classList.toggle('dark', dark);
		try {
			localStorage.setItem('crmthree-theme', dark ? 'dark' : 'light');
		} catch {
			/* fine */
		}
	});

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

<div class="flex h-screen overflow-hidden">
	<!-- Navigation rail. Deep-ink ground; the toggle is the rail's first item, per the
	     shared UX: expanded shows labels, collapsed shows monogram tiles. -->
	<aside class="{mobileOpen ? 'fixed inset-y-0 left-0 z-40 flex' : 'hidden'} shrink-0 flex-col bg-rail md:static md:flex text-warm/70 transition-[width] duration-150 {collapsed ? 'w-14' : 'w-56'}">
		<a href="/" class="flex h-16 shrink-0 items-center px-3" aria-label="Home">
			{#if collapsed}
				<img src="/logo.svg" alt="CRMTHREE" class="mx-auto h-8 w-8" />
			{:else}
				<img src="/crmthree-dark.svg" alt="CRMTHREE" class="ml-1 h-5 w-auto" />
			{/if}
		</a>

		<button onclick={toggle} aria-label="Toggle navigation"
			class="flex w-full shrink-0 items-center gap-3 px-3 py-2 text-warm/80 hover:bg-white/5 hover:text-warm">
			<span class="flex h-8 w-8 shrink-0 items-center justify-center">
				<svg class="h-5 w-5 text-accent-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
					<path stroke-linecap="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
				</svg>
			</span>
			{#if !collapsed}<span class="text-sm font-semibold">{t('ui.navigation', 'Navigation')}</span>{/if}
		</button>
		<div class="mx-3 my-1 border-t border-white/10"></div>

		<nav class="rail-scroll flex flex-1 flex-col gap-0.5 overflow-y-auto px-2 pb-2">
			{#each navItems as objectType}
				{@const active = page.url.pathname.startsWith(`/${objectType}`)}
				<a
					href={`/${objectType}`}
					title={objectLabel(objectType, true)}
					onclick={() => (mobileOpen = false)}
					class="flex items-center gap-3 rounded px-1.5 py-1.5 text-sm transition-colors
						{active ? 'bg-white/10 text-white' : 'hover:bg-white/5 hover:text-warm'}"
				>
					<NavIcon {objectType} {active} />
					{#if !collapsed}<span class="truncate">{objectLabel(objectType, true)}</span>{/if}
				</a>
			{/each}
		</nav>
		<div class="mx-3 my-1 border-t border-white/10"></div>
		<a href="/settings" title="Settings"
			class="mx-2 mb-3 flex shrink-0 items-center gap-3 rounded px-1.5 py-1.5 text-sm
				{page.url.pathname.startsWith('/settings') ? 'bg-white/10 text-white' : 'hover:bg-white/5 hover:text-warm'}">
			<span class="flex h-7 w-7 shrink-0 items-center justify-center {page.url.pathname.startsWith('/settings') ? 'text-accent-400' : 'text-warm/60'}">
				<svg class="h-[18px] w-[18px]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
					<path stroke-linecap="round" stroke-linejoin="round" d="M10.343 3.94c.09-.542.56-.94 1.11-.94h1.093c.55 0 1.02.398 1.11.94l.149.894c.07.424.384.764.78.93.398.164.855.142 1.205-.108l.737-.527a1.125 1.125 0 011.45.12l.773.774c.39.389.44 1.002.12 1.45l-.527.737c-.25.35-.272.806-.107 1.204.165.397.505.71.93.78l.893.15c.543.09.94.56.94 1.109v1.094c0 .55-.397 1.02-.94 1.11l-.893.149c-.425.07-.765.383-.93.78-.165.398-.143.854.107 1.204l.527.738c.32.447.269 1.06-.12 1.45l-.774.773a1.125 1.125 0 01-1.449.12l-.738-.527c-.35-.25-.806-.272-1.203-.107-.397.165-.71.505-.781.929l-.149.894c-.09.542-.56.94-1.11.94h-1.094c-.55 0-1.019-.398-1.11-.94l-.148-.894c-.071-.424-.384-.764-.781-.93-.398-.164-.854-.142-1.204.108l-.738.527c-.447.32-1.06.269-1.45-.12l-.773-.774a1.125 1.125 0 01-.12-1.45l.527-.737c.25-.35.273-.806.108-1.204-.165-.397-.506-.71-.93-.78l-.894-.15c-.542-.09-.94-.56-.94-1.109v-1.094c0-.55.398-1.02.94-1.11l.894-.149c.424-.07.765-.383.93-.78.165-.398.143-.854-.108-1.204l-.526-.738a1.125 1.125 0 01.12-1.45l.773-.773a1.125 1.125 0 011.45-.12l.737.527c.35.25.807.272 1.204.107.397-.165.71-.505.78-.929l.15-.894z M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
				</svg>
			</span>
			{#if !collapsed}<span>{t('ui.settings', 'Settings')}</span>{/if}
		</a>
	</aside>

	<div class="flex min-w-0 flex-1 flex-col">
		<header class="flex shrink-0 items-center justify-between gap-4 border-b border-rule bg-surface px-4 py-3 md:px-6">
			<div class="flex min-w-0 items-center gap-3">
				<button onclick={() => (mobileOpen = !mobileOpen)} aria-label="Menu"
					class="rounded p-1.5 text-steel hover:bg-rule/30 md:hidden">
					<svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
						<path stroke-linecap="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
					</svg>
				</button>
				<GlobalSearch />
			</div>
			<div class="flex items-center gap-4">
			<NotificationBell />
			<a href="/profile" class="text-sm hover:text-accent-600">
				<span class="font-medium">{data.profile.first_name} {data.profile.last_name}</span>
				<span class="ml-1.5 rounded bg-rule/40 px-1.5 py-0.5 text-xs text-steel">{data.profile.role_name}</span>
			</a>
			<button onclick={signOut} class="text-sm text-steel hover:text-ink">{t('ui.sign_out', 'Sign Out')}</button>
			</div>
		</header>
		{#if mobileOpen}
			<button class="fixed inset-0 z-30 bg-ink/40 md:hidden" aria-label="Close menu"
				onclick={() => (mobileOpen = false)}></button>
		{/if}
		<main class="flex-1 overflow-y-auto p-6">
			{@render children()}
		</main>
	</div>
</div>
