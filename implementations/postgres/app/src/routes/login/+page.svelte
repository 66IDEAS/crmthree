<script lang="ts">
	import { t } from '$lib/i18n';

	let { data } = $props();
	let email = $state('');
	let password = $state('');
	let error = $state('');
	let busy = $state(false);

	async function signIn(event: SubmitEvent) {
		event.preventDefault();
		busy = true;
		error = '';
		const response = await fetch('/api/auth/sign-in/email', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({ email, password })
		});
		busy = false;
		if (response.ok) {
			window.location.href = '/';
		} else {
			const body = await response.json().catch(() => null);
			error = body?.message ?? t('login.error.generic', 'An error occurred during sign-in.');
		}
	}
</script>
<svelte:head>
	<title>Sign in · CRMTHREE</title>
</svelte:head>


<div class="flex min-h-screen items-center justify-center bg-rail">
	<div class="w-full max-w-sm rounded-lg bg-surface p-8 shadow-xl">
		<img src="/crmthree-by-light.svg" alt="CRMTHREE by 66IDEAS" class="mx-auto h-14 w-auto" />
		<p class="mt-3 text-center text-sm text-steel">{t('login.subtitle', 'Sign in to continue')}</p>

		{#if data.unprovisioned}
			<p class="mt-4 rounded bg-warning/10 p-3 text-sm text-warning">
				{t('app.not_provisioned', 'Your account has not been provisioned yet. Please contact an administrator to set up your user profile.')}
			</p>
		{/if}

		<form onsubmit={signIn} class="mt-6 flex flex-col gap-4">
			<label class="flex flex-col gap-1 text-sm">
				<span class="font-medium">{t('login.email', 'Email')}</span>
				<input type="email" bind:value={email} required autocomplete="email"
					class="rounded border border-rule px-3 py-2 outline-none focus:border-accent-600 focus:ring-1 focus:ring-accent-600" />
			</label>
			<label class="flex flex-col gap-1 text-sm">
				<span class="font-medium">{t('login.password', 'Password')}</span>
				<input type="password" bind:value={password} required autocomplete="current-password"
					class="rounded border border-rule px-3 py-2 outline-none focus:border-accent-600 focus:ring-1 focus:ring-accent-600" />
			</label>
			{#if error}
				<p class="rounded bg-error/10 p-2 text-sm text-error">{error}</p>
			{/if}
			<button type="submit" disabled={busy}
				class="rounded bg-accent-600 py-2 font-medium text-white transition-colors hover:bg-accent-500 disabled:opacity-50">
				{busy ? t('ui.loading', 'Loading...') : t('ui.sign_in', 'Sign In')}
			</button>
		</form>
	</div>
</div>
