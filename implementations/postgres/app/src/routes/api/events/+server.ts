import { error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { subscribe, type ChangeEvent } from '$lib/server/realtime';

/**
 * Server-sent events stream (R4). Chosen over websockets because the traffic is one-way and
 * browsers reconnect automatically, so there is no protocol to maintain.
 */
export const GET: RequestHandler = async ({ locals }) => {
	if (!locals.profile) throw error(401, 'Not provisioned');

	let unsubscribe: (() => void) | null = null;
	let heartbeat: ReturnType<typeof setInterval> | null = null;

	const stream = new ReadableStream({
		async start(controller) {
			const send = (event: ChangeEvent) => {
				try {
					controller.enqueue(`data: ${JSON.stringify(event)}\n\n`);
				} catch {
					// Client vanished between the change and the write.
				}
			};
			unsubscribe = await subscribe(send);
			controller.enqueue(': connected\n\n');
			// Comment frames keep intermediaries from closing an idle stream.
			heartbeat = setInterval(() => {
				try {
					controller.enqueue(': ping\n\n');
				} catch {
					/* closed */
				}
			}, 30_000);
		},
		cancel() {
			unsubscribe?.();
			if (heartbeat) clearInterval(heartbeat);
		}
	});

	return new Response(stream, {
		headers: {
			'content-type': 'text/event-stream',
			'cache-control': 'no-store',
			connection: 'keep-alive'
		}
	});
};
