/**
 * Translation singleton (story 60), the reference implementation's hybrid pattern: a
 * module-level t() callable from pure functions like fieldLabel, loaded once per session.
 *
 * SSR note: the label map is set synchronously at the top of the layout render, and Svelte
 * renders the tree synchronously after loads resolve, so per-request state does not bleed
 * between concurrently loading sessions.
 */
let labels: Record<string, string> = {};

export function setLabels(map: Record<string, string> | null | undefined): void {
	labels = map ?? {};
}

export function t(key: string, fallback: string): string {
	return labels[key] ?? fallback;
}
