<script lang="ts">
	import { onMount } from 'svelte';
	import DataService from '$lib/DataService';
	import { onChange } from '$lib/realtime-client';

	/**
	 * Team discussion on a record (stories 33/34). Live: the comment trigger publishes ids
	 * over the change channel, every viewer re-reads through the authorised path, so a
	 * thread updates for everyone without polling and without the push channel carrying
	 * content.
	 */
	let { parentType, parentId, profileId }: { parentType: string; parentId: string; profileId: string } = $props();

	type Comment = { id: string; content: string; author_id: string; created_at: string };
	let comments = $state<Comment[]>([]);
	let authors = $state<Record<string, string>>({});
	let draft = $state('');
	let busy = $state(false);

	async function refresh() {
		const page = await DataService.listPage<Comment>('Comment', {
			filters: [
				{ field: 'parent_type', op: 'eq', value: parentType },
				{ field: 'parent_id', op: 'eq', value: parentId }
			],
			sort: { field: 'created_at', direction: 'asc' },
			pageSize: 100
		});
		comments = page.data;
		const missing = [...new Set(comments.map((c) => c.author_id))].filter((id) => !authors[id]);
		for (const id of missing) {
			DataService.getById<{ first_name: string; last_name: string }>('UserProfile', id)
				.then((profile) => {
					authors = { ...authors, [id]: `${profile.first_name} ${profile.last_name}` };
				})
				.catch(() => {
					authors = { ...authors, [id]: 'Former user' };
				});
		}
	}

	onMount(() => {
		refresh();
		return onChange('comment', refresh);
	});

	async function post(event: SubmitEvent) {
		event.preventDefault();
		if (!draft.trim()) return;
		busy = true;
		try {
			await DataService.create('Comment', {
				parent_type: parentType,
				parent_id: parentId,
				content: draft.trim(),
				author_id: profileId
			});
			draft = '';
			await refresh();
		} finally {
			busy = false;
		}
	}
</script>

<section class="rounded-lg border border-rule bg-white">
	<h2 class="border-b border-rule/50 px-4 py-2.5 text-sm font-semibold">
		Comments <span class="ml-1 font-normal text-steel">{comments.length}</span>
	</h2>
	<div class="flex max-h-80 flex-col gap-3 overflow-y-auto px-4 py-3">
		{#each comments as comment (comment.id)}
			<div class="flex gap-2.5">
				<span class="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-accent-100 text-xs font-semibold text-accent-700">
					{(authors[comment.author_id] ?? '?').split(' ').map((w) => w[0]).join('').slice(0, 2)}
				</span>
				<div class="min-w-0">
					<p class="text-xs text-steel">
						<span class="font-medium text-ink">{authors[comment.author_id] ?? '…'}</span>
						· {new Date(comment.created_at).toLocaleString()}
					</p>
					<p class="mt-0.5 text-sm whitespace-pre-wrap">{comment.content}</p>
				</div>
			</div>
		{:else}
			<p class="py-4 text-center text-sm text-steel/70">No comments yet - start the discussion.</p>
		{/each}
	</div>
	<form onsubmit={post} class="flex gap-2 border-t border-rule/50 p-3">
		<input bind:value={draft} placeholder="Write a comment…"
			class="flex-1 rounded border border-steel/40 px-3 py-1.5 text-sm outline-none focus:border-accent-600" />
		<button type="submit" disabled={busy || !draft.trim()}
			class="rounded bg-accent-600 px-4 py-1.5 text-sm font-medium text-white hover:bg-accent-500 disabled:opacity-50">Post</button>
	</form>
</section>
