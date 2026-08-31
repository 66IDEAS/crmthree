<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import DataService from '$lib/DataService';
	import { NAV_OBJECTS, objectLabel } from '$lib/display';

	let { data } = $props();

	// ── User management (story 62) ──────────────────────────────────────────────
	let open = $state<'users' | 'roles' | 'statuses' | 'whitelist' | 'ai' | 'audit' | 'languages' | 'sources' | 'replication' | null>('users');
	let showInvite = $state(false);
	let invite = $state({ email: '', password: '', firstName: '', lastName: '', roleName: 'User' });
	let problem = $state('');

	async function createUser(event: SubmitEvent) {
		event.preventDefault();
		problem = '';
		const response = await fetch('/api/users', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify(invite)
		});
		if (!response.ok) {
			problem = (await response.json().catch(() => null))?.message ?? 'Failed';
			return;
		}
		showInvite = false;
		invite = { email: '', password: '', firstName: '', lastName: '', roleName: 'User' };
		await invalidateAll();
	}

	async function setActive(user: { id: string }, active: boolean) {
		await DataService.update('UserProfile', user.id, { active });
		await invalidateAll();
	}

	async function setRole(user: { id: string }, roleId: string) {
		await DataService.update('UserProfile', user.id, { role_id: roleId });
		await invalidateAll();
	}

	async function removeUser(user: { id: string; first_name: string; last_name: string }) {
		if (!confirm(`Delete ${user.first_name} ${user.last_name}? Their records remain.`)) return;
		problem = '';
		try {
			await DataService.remove('UserProfile', user.id);
			await invalidateAll();
		} catch (e) {
			problem = (e as Error).message;
		}
	}

	// ── Role management (story 18) ──────────────────────────────────────────────
	const ACTIONS = ['read', 'read_all', 'create', 'update', 'delete'] as const;
	let editingRole = $state<null | { id: string; name: string; description: string; is_system_role: boolean; permissions: Record<string, Record<string, boolean>> }>(null);

	function editRole(role: (typeof data.roles)[number]) {
		editingRole = structuredClone({ ...role, permissions: role.permissions ?? {} });
	}

	function toggle(objectType: string, action: string) {
		if (!editingRole) return;
		const map = { ...(editingRole.permissions[objectType] ?? {}) };
		map[action] = !map[action];
		editingRole.permissions = { ...editingRole.permissions, [objectType]: map };
	}

	// ── Ticket statuses ────────────────────────────────────────────────────────
	let newStatus = $state({ name: '', is_closed: false, is_resolved: false });
	async function addStatus(event: SubmitEvent) {
		event.preventDefault();
		problem = '';
		try {
			await DataService.create('TicketStatus', {
				...newStatus,
				sort_order: data.statuses.length + 1,
				active: true
			});
			newStatus = { name: '', is_closed: false, is_resolved: false };
			await invalidateAll();
		} catch (e) { problem = (e as Error).message; }
	}
	async function toggleStatusActive(status: { id: string; active: boolean }) {
		await DataService.update('TicketStatus', status.id, { active: !status.active });
		await invalidateAll();
	}

	// ── Whitelist ──────────────────────────────────────────────────────────────
	let newEntry = $state({ kind: 'domain', value: '' });
	async function addEntry(event: SubmitEvent) {
		event.preventDefault();
		problem = '';
		const response = await fetch('/api/whitelist', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify(newEntry)
		});
		if (!response.ok) { problem = (await response.json().catch(() => null))?.message ?? 'Failed'; return; }
		newEntry = { kind: 'domain', value: '' };
		await invalidateAll();
	}
	async function removeEntry(id: string) {
		await fetch(`/api/whitelist/${id}`, { method: 'DELETE' });
		await invalidateAll();
	}

	// ── AI provider ────────────────────────────────────────────────────────────
	let ai = $state({ provider: 'Anthropic', model: '', api_key: '', endpoint_url: '' });
	async function saveAi(event: SubmitEvent) {
		event.preventDefault();
		problem = '';
		const response = await fetch('/api/ai/config', {
			method: 'PUT',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({ ...ai, endpoint_url: ai.endpoint_url || null, is_active: true })
		});
		if (!response.ok) { problem = (await response.json().catch(() => null))?.message ?? 'Failed'; return; }
		ai = { provider: 'Anthropic', model: '', api_key: '', endpoint_url: '' };
		await invalidateAll();
	}

	// ── Languages ──────────────────────────────────────────────────────────────
	let newLang = $state({ code: '', language_name: '' });
	let translating = $state(false);
	async function addLanguage(event: SubmitEvent, translate: boolean) {
		event.preventDefault();
		problem = '';
		translating = translate;
		const response = await fetch('/api/translations', {
			method: 'PUT',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({ ...newLang, translate })
		});
		translating = false;
		if (!response.ok) { problem = (await response.json().catch(() => null))?.message ?? 'Failed'; return; }
		newLang = { code: '', language_name: '' };
		await invalidateAll();
	}
	async function removeLanguage(code: string) {
		await fetch(`/api/translations?code=${encodeURIComponent(code)}`, { method: 'DELETE' });
		await invalidateAll();
	}

	// ── Integration ────────────────────────────────────────────────────────────
	let runResult = $state('');
	async function runReplication(id: string) {
		runResult = 'Running…';
		const response = await fetch('/api/replication', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({ id })
		});
		const result = await response.json().catch(() => null);
		runResult = response.ok
			? `Received ${result.received}: ${result.created} created, ${result.updated} updated, ${result.skipped} skipped`
			: (result?.message ?? 'Run failed');
		await invalidateAll();
	}
	async function toggleSource(source: { id: string; active: boolean }) {
		await DataService.update('DataSourceConfig', source.id, { active: !source.active });
		await invalidateAll();
	}
	async function removeReplication(id: string) {
		await fetch(`/api/replication?id=${id}`, { method: 'DELETE' });
		await invalidateAll();
	}

	async function saveRole() {
		if (!editingRole) return;
		problem = '';
		try {
			await DataService.update('Role', editingRole.id, {
				name: editingRole.name,
				description: editingRole.description,
				permissions: editingRole.permissions
			});
			editingRole = null;
			await invalidateAll();
		} catch (e) {
			problem = (e as Error).message;
		}
	}
</script>

<h1 class="text-xl font-semibold tracking-tight">Settings</h1>

{#if !data.isAdmin}
	<p class="mt-4 rounded bg-rule/30 p-4 text-sm text-steel">Administrator settings are not available for your role.</p>
{:else}
	{#if problem}<p class="mt-3 rounded bg-error/10 p-2 text-sm text-error">{problem}</p>{/if}

	<!-- Users -->
	<section class="mt-5 rounded-lg border border-rule bg-surface">
		<button class="flex w-full items-center justify-between px-4 py-3 text-left" onclick={() => (open = open === 'users' ? null : 'users')}>
			<span class="text-sm font-semibold">User Management <span class="ml-1 font-normal text-steel">{data.users.length}</span></span>
			<span class="text-steel">{open === 'users' ? '−' : '+'}</span>
		</button>
		{#if open === 'users'}
			<div class="border-t border-rule/50 px-4 pb-4">
				<div class="py-2 text-right">
					<button onclick={() => (showInvite = !showInvite)}
						class="rounded bg-accent-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-accent-500">New User</button>
				</div>
				{#if showInvite}
					<form onsubmit={createUser} class="mb-3 grid grid-cols-2 gap-3 rounded border border-rule bg-paper p-3 text-sm">
						<input required placeholder="First name" bind:value={invite.firstName} class="rounded border border-steel/40 px-2 py-1.5" />
						<input required placeholder="Last name" bind:value={invite.lastName} class="rounded border border-steel/40 px-2 py-1.5" />
						<input required type="email" placeholder="Email" bind:value={invite.email} class="rounded border border-steel/40 px-2 py-1.5" />
						<input required type="password" placeholder="Initial password" minlength="12" bind:value={invite.password} class="rounded border border-steel/40 px-2 py-1.5" />
						<select bind:value={invite.roleName} class="rounded border border-steel/40 px-2 py-1.5">
							{#each data.roles as role (role.id)}<option value={role.name}>{role.name}</option>{/each}
						</select>
						<button type="submit" class="rounded bg-accent-600 py-1.5 font-medium text-white hover:bg-accent-500">Create</button>
					</form>
				{/if}
				<table class="w-full text-sm">
					<thead><tr class="text-left text-[11px] uppercase tracking-wider text-steel/80">
						<th class="py-1.5 pr-4 font-medium">Name</th><th class="py-1.5 pr-4 font-medium">Email</th>
						<th class="py-1.5 pr-4 font-medium">Role</th><th class="py-1.5 pr-4 font-medium">Status</th><th></th>
					</tr></thead>
					<tbody>
						{#each data.users as user (user.id)}
							<tr class="border-t border-rule/40">
								<td class="py-2 pr-4 font-medium">{user.first_name} {user.last_name}</td>
								<td class="py-2 pr-4">{user.email}</td>
								<td class="py-2 pr-4">
									<select value={user.role_id} onchange={(e) => setRole(user, e.currentTarget.value)}
										class="rounded border border-steel/40 px-1.5 py-1 text-xs">
										{#each data.roles as role (role.id)}<option value={role.id}>{role.name}</option>{/each}
									</select>
								</td>
								<td class="py-2 pr-4">
									<span class="rounded-full px-2 py-0.5 text-xs font-medium {user.active ? 'bg-success/10 text-success' : 'bg-error/10 text-error'}">
										{user.active ? 'Active' : 'Deactivated'}</span>
									{#if !user.claimed}<span class="ml-1 rounded-full bg-warning/10 px-2 py-0.5 text-xs font-medium text-warning">Pending</span>{/if}
								</td>
								<td class="py-2 text-right text-xs">
									<button onclick={() => setActive(user, !user.active)} class="text-steel hover:text-ink">
										{user.active ? 'Deactivate' : 'Reactivate'}</button>
									<button onclick={() => removeUser(user)} class="ml-2 text-steel hover:text-error">Delete</button>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		{/if}
	</section>

	<!-- Roles -->
	<section class="mt-4 rounded-lg border border-rule bg-surface">
		<button class="flex w-full items-center justify-between px-4 py-3 text-left" onclick={() => (open = open === 'roles' ? null : 'roles')}>
			<span class="text-sm font-semibold">Role Management <span class="ml-1 font-normal text-steel">{data.roles.length}</span></span>
			<span class="text-steel">{open === 'roles' ? '−' : '+'}</span>
		</button>
		{#if open === 'roles'}
			<div class="border-t border-rule/50 px-4 pb-4">
				{#if editingRole}
					<div class="mt-3 rounded border border-rule bg-paper p-3">
						<div class="flex items-center gap-3">
							<input bind:value={editingRole.name} disabled={editingRole.is_system_role}
								class="rounded border border-steel/40 px-2 py-1.5 text-sm font-medium disabled:bg-rule/30" />
							<input bind:value={editingRole.description} placeholder="Description"
								class="flex-1 rounded border border-steel/40 px-2 py-1.5 text-sm" />
						</div>
						<div class="mt-3 overflow-x-auto">
							<table class="w-full text-xs">
								<thead><tr class="text-left uppercase tracking-wider text-steel/80">
									<th class="py-1 pr-3 font-medium">Object</th>
									{#each ACTIONS as action}<th class="px-2 py-1 text-center font-medium">{action}</th>{/each}
								</tr></thead>
								<tbody>
									{#each NAV_OBJECTS as objectType (objectType)}
										<tr class="border-t border-rule/40">
											<td class="py-1.5 pr-3">{objectLabel(objectType, true)}</td>
											{#each ACTIONS as action}
												<td class="px-2 py-1.5 text-center">
													<input type="checkbox" class="h-3.5 w-3.5 accent-accent-600"
														checked={editingRole.permissions[objectType]?.[action] ?? false}
														onchange={() => toggle(objectType, action)} />
												</td>
											{/each}
										</tr>
									{/each}
								</tbody>
							</table>
						</div>
						<div class="mt-3 flex justify-end gap-2">
							<button onclick={() => (editingRole = null)} class="rounded border border-rule px-3 py-1.5 text-xs hover:bg-paper">Cancel</button>
							<button onclick={saveRole} class="rounded bg-accent-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-accent-500">Save Role</button>
						</div>
					</div>
				{:else}
					<table class="mt-2 w-full text-sm">
						<tbody>
							{#each data.roles as role (role.id)}
								<tr class="border-t border-rule/40 first:border-0">
									<td class="py-2 pr-4 font-medium">{role.name}
										{#if role.is_system_role}<span class="ml-1.5 rounded bg-rule/40 px-1.5 py-0.5 text-[10px] uppercase tracking-wider text-steel">system</span>{/if}
									</td>
									<td class="py-2 pr-4 text-steel">{role.description ?? ''}</td>
									<td class="py-2 text-right">
										<button onclick={() => editRole(role)} class="text-xs text-accent-600 hover:underline">Edit permissions</button>
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
					<p class="mt-2 text-xs text-steel/80">Admins bypass the permission map entirely. These settings apply to every other role, and they are enforced in the database, not the browser.</p>
				{/if}
			</div>
		{/if}
	</section>

	<!-- Ticket statuses -->
	<section class="mt-4 rounded-lg border border-rule bg-surface">
		<button class="flex w-full items-center justify-between px-4 py-3 text-left" onclick={() => (open = open === 'statuses' ? null : 'statuses')}>
			<span class="text-sm font-semibold">Ticket Statuses <span class="ml-1 font-normal text-steel">{data.statuses.length}</span></span>
			<span class="text-steel">{open === 'statuses' ? '−' : '+'}</span>
		</button>
		{#if open === 'statuses'}
			<div class="border-t border-rule/50 px-4 pb-4">
				<table class="mt-2 w-full text-sm">
					<tbody>
						{#each data.statuses as status (status.id)}
							<tr class="border-t border-rule/40 first:border-0">
								<td class="py-2 pr-4 font-medium">{status.name}</td>
								<td class="py-2 pr-4 text-xs text-steel">
									{status.is_closed ? 'closes the ticket' : status.is_resolved ? 'resolves' : 'open state'}</td>
								<td class="py-2 text-right">
									<button onclick={() => toggleStatusActive(status)} class="text-xs text-steel hover:text-ink">
										{status.active ? 'Disable' : 'Enable'}</button>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
				<form onsubmit={addStatus} class="mt-3 flex items-center gap-2 text-sm">
					<input required placeholder="New status name" bind:value={newStatus.name}
						class="flex-1 rounded border border-steel/40 px-2 py-1.5" />
					<label class="flex items-center gap-1 text-xs"><input type="checkbox" bind:checked={newStatus.is_resolved} class="accent-accent-600" /> resolves</label>
					<label class="flex items-center gap-1 text-xs"><input type="checkbox" bind:checked={newStatus.is_closed} class="accent-accent-600" /> closes</label>
					<button type="submit" class="rounded bg-accent-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-accent-500">Add</button>
				</form>
			</div>
		{/if}
	</section>

	<!-- Email whitelist -->
	<section class="mt-4 rounded-lg border border-rule bg-surface">
		<button class="flex w-full items-center justify-between px-4 py-3 text-left" onclick={() => (open = open === 'whitelist' ? null : 'whitelist')}>
			<span class="text-sm font-semibold">Access Whitelist <span class="ml-1 font-normal text-steel">{data.whitelist.length}</span></span>
			<span class="text-steel">{open === 'whitelist' ? '−' : '+'}</span>
		</button>
		{#if open === 'whitelist'}
			<div class="border-t border-rule/50 px-4 pb-4">
				<p class="mt-2 text-xs text-steel">An empty list allows everyone. Entries apply on every sign-in, including users who already hold a profile.</p>
				<table class="mt-2 w-full text-sm">
					<tbody>
						{#each data.whitelist as entry (entry.id)}
							<tr class="border-t border-rule/40 first:border-0">
								<td class="py-2 pr-4"><span class="rounded bg-rule/40 px-1.5 py-0.5 text-xs">{entry.kind}</span></td>
								<td class="py-2 pr-4 font-medium">{entry.value}</td>
								<td class="py-2 text-right"><button onclick={() => removeEntry(entry.id)} class="text-xs text-steel hover:text-error">Remove</button></td>
							</tr>
						{/each}
					</tbody>
				</table>
				<form onsubmit={addEntry} class="mt-3 flex items-center gap-2 text-sm">
					<select bind:value={newEntry.kind} class="rounded border border-steel/40 px-2 py-1.5">
						<option value="domain">Domain</option><option value="email">Email</option>
					</select>
					<input required placeholder={newEntry.kind === 'domain' ? 'example.com' : 'person@example.com'}
						bind:value={newEntry.value} class="flex-1 rounded border border-steel/40 px-2 py-1.5" />
					<button type="submit" class="rounded bg-accent-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-accent-500">Add</button>
				</form>
			</div>
		{/if}
	</section>

	<!-- AI provider -->
	<section class="mt-4 rounded-lg border border-rule bg-surface">
		<button class="flex w-full items-center justify-between px-4 py-3 text-left" onclick={() => (open = open === 'ai' ? null : 'ai')}>
			<span class="text-sm font-semibold">AI Provider <span class="ml-1 font-normal text-steel">{data.aiConfigs.filter((c) => c.is_active).length ? 'active' : 'not configured'}</span></span>
			<span class="text-steel">{open === 'ai' ? '−' : '+'}</span>
		</button>
		{#if open === 'ai'}
			<div class="border-t border-rule/50 px-4 pb-4">
				{#if data.aiConfigs.length}
					<table class="mt-2 w-full text-sm">
						<tbody>
							{#each data.aiConfigs as config (config.id)}
								<tr class="border-t border-rule/40 first:border-0">
									<td class="py-2 pr-4 font-medium">{config.provider}</td>
									<td class="py-2 pr-4">{config.model}</td>
									<td class="py-2 pr-4 text-xs text-steel">{config.has_key ? 'key stored (write-only)' : 'no key'}</td>
									<td class="py-2 text-right">
										{#if config.is_active}<span class="rounded-full bg-success/10 px-2 py-0.5 text-xs font-medium text-success">Active</span>{/if}
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
				{/if}
				<form onsubmit={saveAi} class="mt-3 grid grid-cols-2 gap-2 text-sm">
					<select bind:value={ai.provider} class="rounded border border-steel/40 px-2 py-1.5">
						<option>Anthropic</option><option>OpenAI</option><option>Google</option><option>Moonshot</option>
					</select>
					<input required placeholder="Model (e.g. claude-sonnet-5)" bind:value={ai.model} class="rounded border border-steel/40 px-2 py-1.5" />
					<input type="password" placeholder="API key (encrypted at rest, never shown again)" bind:value={ai.api_key} class="rounded border border-steel/40 px-2 py-1.5" />
					<input placeholder="Endpoint URL (optional)" bind:value={ai.endpoint_url} class="rounded border border-steel/40 px-2 py-1.5" />
					<button type="submit" class="col-span-2 rounded bg-accent-600 py-1.5 font-medium text-white hover:bg-accent-500">Save & Activate</button>
				</form>
			</div>
		{/if}
	</section>

	<!-- Audit trail -->
	<section class="mt-4 rounded-lg border border-rule bg-surface">
		<button class="flex w-full items-center justify-between px-4 py-3 text-left" onclick={() => (open = open === 'audit' ? null : 'audit')}>
			<span class="text-sm font-semibold">Audit Log <span class="ml-1 font-normal text-steel">last {data.audit.length}</span></span>
			<span class="text-steel">{open === 'audit' ? '−' : '+'}</span>
		</button>
		{#if open === 'audit'}
			<div class="max-h-96 overflow-y-auto border-t border-rule/50 px-4 pb-3">
				<table class="mt-2 w-full text-sm">
					<tbody>
						{#each data.audit as entry (entry.id)}
							<tr class="border-t border-rule/40 first:border-0">
								<td class="py-1.5 pr-3 text-xs whitespace-nowrap text-steel">{new Date(entry.timestamp).toLocaleString()}</td>
								<td class="py-1.5 pr-3 text-xs">{entry.first_name ?? '?'} {entry.last_name ?? ''}</td>
								<td class="py-1.5 pr-3">
									<span class="rounded-full px-2 py-0.5 text-xs font-medium
										{entry.action === 'Create' ? 'bg-success/10 text-success' : entry.action === 'Delete' ? 'bg-error/10 text-error' : 'bg-accent-50 text-accent-600'}">
										{entry.action}</span>
								</td>
								<td class="py-1.5 pr-3 text-xs">{entry.object_type}</td>
								<td class="py-1.5 pr-3 text-xs font-medium">{entry.object_name ?? ''}</td>
								<td class="py-1.5 text-xs text-steel">{entry.summary ?? ''}</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		{/if}
	</section>

	<!-- Languages -->
	<section class="mt-4 rounded-lg border border-rule bg-surface">
		<button class="flex w-full items-center justify-between px-4 py-3 text-left" onclick={() => (open = open === 'languages' ? null : 'languages')}>
			<span class="text-sm font-semibold">Languages <span class="ml-1 font-normal text-steel">{data.languages.length + 1}</span></span>
			<span class="text-steel">{open === 'languages' ? '−' : '+'}</span>
		</button>
		{#if open === 'languages'}
			<div class="border-t border-rule/50 px-4 pb-4">
				<table class="mt-2 w-full text-sm">
					<tbody>
						<tr><td class="py-2 pr-4 font-medium">English</td><td class="py-2 pr-4 text-xs text-steel">en · built-in default</td><td></td></tr>
						{#each data.languages as language (language.code)}
							<tr class="border-t border-rule/40">
								<td class="py-2 pr-4 font-medium">{language.language_name}</td>
								<td class="py-2 pr-4 text-xs text-steel">{language.code}</td>
								<td class="py-2 text-right"><button onclick={() => removeLanguage(language.code)} class="text-xs text-steel hover:text-error">Remove</button></td>
							</tr>
						{/each}
					</tbody>
				</table>
				<form onsubmit={(e) => addLanguage(e, true)} class="mt-3 flex items-center gap-2 text-sm">
					<input required placeholder="Code (de)" maxlength="5" bind:value={newLang.code} class="w-24 rounded border border-steel/40 px-2 py-1.5" />
					<input required placeholder="Language name (Deutsch)" bind:value={newLang.language_name} class="flex-1 rounded border border-steel/40 px-2 py-1.5" />
					<button type="submit" disabled={translating}
						class="rounded bg-accent-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-accent-500 disabled:opacity-50">
						{translating ? 'Translating…' : 'Add & AI-translate'}</button>
				</form>
				<p class="mt-2 text-xs text-steel">Translation runs the full label catalog through the configured AI provider in batches; users pick their language on the profile page.</p>
			</div>
		{/if}
	</section>

	<!-- Data sources -->
	<section class="mt-4 rounded-lg border border-rule bg-surface">
		<button class="flex w-full items-center justify-between px-4 py-3 text-left" onclick={() => (open = open === 'sources' ? null : 'sources')}>
			<span class="text-sm font-semibold">Data Sources <span class="ml-1 font-normal text-steel">{data.sources.filter((s) => s.active).length} active</span></span>
			<span class="text-steel">{open === 'sources' ? '−' : '+'}</span>
		</button>
		{#if open === 'sources'}
			<div class="border-t border-rule/50 px-4 pb-4">
				<p class="mt-2 text-xs text-steel">An active external source serves its object type live from the external system - list, detail, create, update and delete all pass through. Configure new sources via the Data Source Config records; this list toggles them.</p>
				<table class="mt-2 w-full text-sm">
					<tbody>
						{#each data.sources as source (source.id)}
							<tr class="border-t border-rule/40 first:border-0">
								<td class="py-2 pr-4 font-medium">{source.object_type}</td>
								<td class="py-2 pr-4 text-xs text-steel">{source.endpoint_url}</td>
								<td class="py-2 pr-4"><span class="rounded-full px-2 py-0.5 text-xs font-medium {source.active ? 'bg-success/10 text-success' : 'bg-rule/40 text-steel'}">{source.active ? 'External' : 'Inactive'}</span></td>
								<td class="py-2 text-right"><button onclick={() => toggleSource(source)} class="text-xs text-steel hover:text-ink">{source.active ? 'Deactivate' : 'Activate'}</button></td>
							</tr>
						{:else}
							<tr><td class="py-3 text-sm text-steel/70">All object types serve from the local database.</td></tr>
						{/each}
					</tbody>
				</table>
			</div>
		{/if}
	</section>

	<!-- Replication -->
	<section class="mt-4 rounded-lg border border-rule bg-surface">
		<button class="flex w-full items-center justify-between px-4 py-3 text-left" onclick={() => (open = open === 'replication' ? null : 'replication')}>
			<span class="text-sm font-semibold">Replication <span class="ml-1 font-normal text-steel">{data.replications.length}</span></span>
			<span class="text-steel">{open === 'replication' ? '−' : '+'}</span>
		</button>
		{#if open === 'replication'}
			<div class="border-t border-rule/50 px-4 pb-4">
				{#if runResult}<p class="mt-2 rounded bg-accent-50 px-3 py-2 text-sm">{runResult}</p>{/if}
				<table class="mt-2 w-full text-sm">
					<tbody>
						{#each data.replications as replication (replication.id)}
							<tr class="border-t border-rule/40 first:border-0">
								<td class="py-2 pr-4 font-medium">{replication.name}</td>
								<td class="py-2 pr-4 text-xs text-steel">{replication.object_type} · key {replication.key_field}</td>
								<td class="py-2 pr-4 text-xs text-steel">
									{replication.last_run_at ? `${new Date(replication.last_run_at).toLocaleString()}: ${replication.last_result}` : 'never run'}</td>
								<td class="py-2 text-right whitespace-nowrap">
									<button onclick={() => runReplication(replication.id)}
										class="rounded bg-accent-600 px-2.5 py-1 text-xs font-medium text-white hover:bg-accent-500">Run now</button>
									<button onclick={() => removeReplication(replication.id)} class="ml-2 text-xs text-steel hover:text-error">Remove</button>
								</td>
							</tr>
						{:else}
							<tr><td class="py-3 text-sm text-steel/70">No replication configurations. Create one via the API: PUT /api/replication.</td></tr>
						{/each}
					</tbody>
				</table>
			</div>
		{/if}
	</section>
{/if}
