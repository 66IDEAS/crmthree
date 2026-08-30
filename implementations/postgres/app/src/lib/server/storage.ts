import { mkdir, writeFile, readFile, stat } from 'node:fs/promises';
import { createReadStream } from 'node:fs';
import { Readable } from 'node:stream';
import { join, resolve } from 'node:path';
import { randomUUID } from 'node:crypto';
import { env } from '$env/dynamic/private';

/**
 * File storage (R6). A directory on disk behind an authorising route; no bucket service.
 * Files are stored under a server-generated uuid, never under a client-supplied name, so
 * path traversal has nothing to work with. The original name, type and size live in a
 * sidecar next to the payload and in the Document record that references the file.
 */
const ROOT = resolve(env.FILE_STORAGE_DIR || 'data/files');
const MAX_BYTES = 20 * 1024 * 1024;

export type StoredFile = { id: string; name: string; type: string; size: number };

function pathFor(id: string): string {
	// Defense in depth: ids are generated here, but never trust one from a URL.
	if (!/^[0-9a-f-]{36}$/.test(id)) throw new Error('Invalid file id');
	return join(ROOT, id);
}

export async function saveFile(file: File): Promise<StoredFile> {
	if (file.size > MAX_BYTES) throw new Error(`File exceeds ${MAX_BYTES / 1024 / 1024} MB`);
	await mkdir(ROOT, { recursive: true });
	const id = randomUUID();
	const meta: StoredFile = {
		id,
		name: file.name,
		type: file.type || 'application/octet-stream',
		size: file.size
	};
	await writeFile(pathFor(id), Buffer.from(await file.arrayBuffer()));
	await writeFile(pathFor(id) + '.json', JSON.stringify(meta));
	return meta;
}

export async function openFile(id: string): Promise<{ meta: StoredFile; body: ReadableStream } | null> {
	const path = pathFor(id);
	try {
		await stat(path);
	} catch {
		return null;
	}
	const meta = JSON.parse(await readFile(path + '.json', 'utf8')) as StoredFile;
	return { meta, body: Readable.toWeb(createReadStream(path)) as ReadableStream };
}
