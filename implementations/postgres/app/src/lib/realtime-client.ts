/**
 * Browser side of the change channel: one EventSource per tab, per-table subscriptions.
 * Events carry {table, op, id} only; subscribers re-read through the API, so nothing arrives
 * here that RLS would have refused.
 */
export type ChangeEvent = { table: string; op: 'insert' | 'update' | 'delete'; id: string };

let source: EventSource | null = null;
const handlers = new Map<string, Set<(event: ChangeEvent) => void>>();

function ensure() {
	if (source) return;
	source = new EventSource('/api/events');
	source.onmessage = (message) => {
		let event: ChangeEvent;
		try {
			event = JSON.parse(message.data);
		} catch {
			return;
		}
		handlers.get(event.table)?.forEach((handler) => handler(event));
		handlers.get('*')?.forEach((handler) => handler(event));
	};
}

/** Subscribe to changes on one table ('*' for all). Returns the unsubscribe function. */
export function onChange(table: string, handler: (event: ChangeEvent) => void): () => void {
	ensure();
	if (!handlers.has(table)) handlers.set(table, new Set());
	handlers.get(table)!.add(handler);
	return () => handlers.get(table)?.delete(handler);
}
