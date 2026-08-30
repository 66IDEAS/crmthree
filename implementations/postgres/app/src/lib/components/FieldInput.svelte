<script lang="ts">
	import type { FieldDefinition } from '$model';
	import type { ReferenceOption } from '$lib/server/references';

	let {
		field,
		value = $bindable(),
		options = []
	}: { field: FieldDefinition; value: unknown; options?: ReferenceOption[] } = $props();

	const base =
		'w-full rounded border border-steel/40 px-3 py-1.5 text-sm outline-none focus:border-accent-600 focus:ring-1 focus:ring-accent-600';
</script>

{#if field.type === 'enum'}
	<select bind:value class={base}>
		{#if !field.required}<option value={null}>—</option>{/if}
		{#each field.values ?? [] as option}<option value={option}>{option}</option>{/each}
	</select>
{:else if field.type === 'reference'}
	<select bind:value class={base}>
		{#if !field.required}<option value={null}>—</option>{/if}
		{#each options as option (option.id)}<option value={option.id}>{option.label}</option>{/each}
	</select>
{:else if field.type === 'boolean'}
	<input type="checkbox" bind:checked={value as boolean} class="h-4 w-4 accent-accent-600" />
{:else if field.type === 'text'}
	<textarea bind:value rows="3" class={base}></textarea>
{:else if field.type === 'integer' || field.type === 'decimal' || field.type === 'currency'}
	<input type="number" step={field.type === 'integer' ? '1' : 'any'} bind:value class={base} />
{:else if field.type === 'date'}
	<input type="date" bind:value class={base} />
{:else if field.type === 'datetime'}
	<input type="datetime-local" bind:value class={base} />
{:else}
	<input type="text" maxlength={field.length} bind:value class={base} />
{/if}
