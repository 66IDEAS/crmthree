<script lang="ts">
	import '../app.css';
	let { children } = $props();
</script>

<svelte:head>
	<title>CRMTHREE</title>
	<link rel="icon" href="/logo.svg" />
</svelte:head>

{@render children()}
