<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import DataService from '$lib/DataService';
	import { NAV_OBJECTS, objectLabel } from '$lib/display';

	let { data } = $props();

	// ── User management (story 62) ──────────────────────────────────────────────
	let open = $state<'users' | 'roles' | null>('users');
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
	<section class="mt-5 rounded-lg border border-rule bg-white">
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
	<section class="mt-4 rounded-lg border border-rule bg-white">
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
							<button onclick={() => (editingRole = null)} class="rounded border border-rule px-3 py-1.5 text-xs hover:bg-white">Cancel</button>
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
{/if}
