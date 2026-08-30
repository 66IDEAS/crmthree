import pg from 'pg';
import { env } from '$env/dynamic/private';

/**
 * Change notification (R4, P8) using nothing but Postgres.
 *
 * One dedicated connection holds LISTEN, because a pooled connection cannot: LISTEN is
 * session state, and a pooled client is handed to someone else between queries. Subscribers
 * are in-process callbacks, fanned out to browsers by the server-sent events endpoint.
 *
 * Events carry an id and an operation, never row data. A subscriber learns that something
 * changed and re-reads it through the authorised path, so this channel cannot leak a row the
 * reader's policies would refuse.
 */
export type ChangeEvent = { table: string; op: 'insert' | 'update' | 'delete'; id: string };

const subscribers = new Set<(event: ChangeEvent) => void>();
let client: pg.Client | null = null;
let connecting: Promise<void> | null = null;

async function ensureListening(): Promise<void> {
	if (client) return;
	if (connecting) return connecting;

	connecting = (async () => {
		const listener = new pg.Client({ connectionString: env.DATABASE_URL });
		listener.on('notification', (message) => {
			if (!message.payload) return;
			let event: ChangeEvent;
			try {
				event = JSON.parse(message.payload);
			} catch {
				return;
			}
			for (const subscriber of subscribers) subscriber(event);
		});
		listener.on('error', () => {
			// Drop the connection so the next subscriber reconnects. Browsers reconnect on
			// their own, since server-sent events retry by default.
			client = null;
			connecting = null;
		});
		await listener.connect();
		await listener.query('listen crm_change');
		client = listener;
	})();

	try {
		await connecting;
	} finally {
		connecting = null;
	}
}

export async function subscribe(handler: (event: ChangeEvent) => void): Promise<() => void> {
	await ensureListening();
	subscribers.add(handler);
	return () => subscribers.delete(handler);
}
