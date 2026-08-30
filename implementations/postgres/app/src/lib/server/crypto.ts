import { createCipheriv, createDecipheriv, randomBytes } from 'node:crypto';
import { env } from '$env/dynamic/private';

/**
 * Envelope for the AI provider key (P11). AES-256-GCM; the key material comes from the
 * process environment and is never sent to Postgres, so the database holds only ciphertext
 * and a database dump alone cannot recover the provider key.
 */
function keyMaterial(): Buffer {
	const raw = env.AI_KEY_ENCRYPTION_KEY;
	if (!raw) throw new Error('AI_KEY_ENCRYPTION_KEY is not set');
	const key = Buffer.from(raw, 'base64');
	if (key.length !== 32) throw new Error('AI_KEY_ENCRYPTION_KEY must be 32 bytes, base64-encoded');
	return key;
}

export function encryptSecret(plaintext: string): string {
	const iv = randomBytes(12);
	const cipher = createCipheriv('aes-256-gcm', keyMaterial(), iv);
	const encrypted = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
	return ['v1', iv.toString('base64'), cipher.getAuthTag().toString('base64'), encrypted.toString('base64')].join('.');
}

export function decryptSecret(stored: string): string {
	const [version, iv, tag, data] = stored.split('.');
	if (version !== 'v1') throw new Error('Unknown ciphertext version');
	const decipher = createDecipheriv('aes-256-gcm', keyMaterial(), Buffer.from(iv, 'base64'));
	decipher.setAuthTag(Buffer.from(tag, 'base64'));
	return Buffer.concat([decipher.update(Buffer.from(data, 'base64')), decipher.final()]).toString('utf8');
}
