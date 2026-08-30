<script lang="ts">
	import { onMount } from 'svelte';
	import DataService from '$lib/DataService';
	import { onChange } from '$lib/realtime-client';

	type Notification = {
		id: string; type: string; title: string; message: string | null;
		read: boolean; link_type: string | null; link_id: string | null; created_at: string;
	};

	let open = $state(false);
	let items = $state<Notification[]>([]);
	let unread = $derived(items.filter((n) => !n.read).length);

	async function refresh() {
		const page = await DataService.listPage<Notification>('Notification', {
			sort: { field: 'created_at', direction: 'desc' },
			pageSize: 10
		});
		items = page.data;
	}

	onMount(() => {
		refresh();
		// RLS scopes the re-read, so reacting to every notification event is safe: rows that
		// are not ours simply do not come back.
		return onChange('notification', refresh);
	});

	async function openItem(item: Notification) {
		if (!item.read) await DataService.update('Notification', item.id, { read: true });
		open = false;
		if (item.link_type && item.link_id) window.location.href = `/${item.link_type}/${item.link_id}`;
		else refresh();
	}
</script>

<div class="relative">
	<button onclick={() => (open = !open)} aria-label="Notifications"
		class="relative rounded p-1.5 text-steel hover:bg-rule/30 hover:text-ink">
		<svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
			<path stroke-linecap="round" stroke-linejoin="round"
				d="M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0" />
		</svg>
		{#if unread > 0}
			<span class="absolute -top-0.5 -right-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-error px-1 text-[10px] font-semibold text-white">{unread}</span>
		{/if}
	</button>

	{#if open}
		<div class="absolute right-0 z-20 mt-2 w-80 rounded-lg border border-rule bg-white shadow-lg">
			<div class="border-b border-rule/50 px-4 py-2 text-sm font-semibold">Notifications</div>
			{#if items.length === 0}
				<p class="px-4 py-6 text-center text-sm text-steel/70">No notifications</p>
			{:else}
				<ul class="max-h-96 overflow-y-auto">
					{#each items as item (item.id)}
						<li>
							<button onclick={() => openItem(item)}
								class="flex w-full items-start gap-2 px-4 py-2.5 text-left hover:bg-paper">
								<span class="mt-1.5 h-2 w-2 shrink-0 rounded-full {item.read ? 'bg-transparent' : 'bg-accent-500'}"></span>
								<span class="min-w-0">
									<span class="block truncate text-sm {item.read ? '' : 'font-semibold'}">{item.title}</span>
									{#if item.message}<span class="block truncate text-xs text-steel">{item.message}</span>{/if}
								</span>
							</button>
						</li>
					{/each}
				</ul>
			{/if}
		</div>
	{/if}
</div>
