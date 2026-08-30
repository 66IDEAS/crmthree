<script lang="ts">
	import { page } from '$app/state';
	import { NAV_OBJECTS, objectLabel } from '$lib/display';
	import NotificationBell from '$lib/components/NotificationBell.svelte';

	let { data, children } = $props();

	async function signOut() {
		await fetch('/api/auth/sign-out', { method: 'POST' });
		window.location.href = '/login';
	}
</script>

<div class="flex min-h-screen">
	<!-- Rail. Dark slate, teal accent: deliberately not the reference app's light ribbon. -->
	<aside class="w-56 shrink-0 bg-slate-900 text-slate-300">
		<a href="/" class="flex items-baseline gap-1 px-5 py-5 text-lg font-semibold tracking-tight text-white">
			CRM<span class="text-accent-500">THREE</span>
			<span class="ml-1 self-center rounded bg-slate-800 px-1.5 py-0.5 text-[10px] font-medium uppercase tracking-wider text-slate-400">postgres</span>
		</a>
		<nav class="mt-2 flex flex-col gap-0.5 px-2 pb-6">
			{#each NAV_OBJECTS as objectType}
				{@const active = page.url.pathname.startsWith(`/${objectType}`)}
				<a
					href={`/${objectType}`}
					class="rounded px-3 py-1.5 text-sm transition-colors
						{active ? 'bg-accent-700 font-medium text-white' : 'hover:bg-slate-800 hover:text-white'}"
				>
					{objectLabel(objectType, true)}
				</a>
			{/each}
		</nav>
	</aside>

	<div class="flex min-w-0 flex-1 flex-col">
		<header class="flex items-center justify-end gap-4 border-b border-zinc-200 bg-white px-6 py-3">
			<NotificationBell />
			<div class="text-sm">
				<span class="font-medium">{data.profile.first_name} {data.profile.last_name}</span>
				<span class="ml-1.5 rounded bg-zinc-100 px-1.5 py-0.5 text-xs text-zinc-500">{data.profile.role_name}</span>
			</div>
			<button onclick={signOut} class="text-sm text-zinc-500 hover:text-zinc-900">Sign out</button>
		</header>
		<main class="flex-1 p-6">
			{@render children()}
		</main>
	</div>
</div>
