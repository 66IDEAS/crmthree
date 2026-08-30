import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import ModelRegistry from '$lib/model/ModelRegistry';

/** Proves the shared data model resolves, and gives the client its object list. */
export const GET: RequestHandler = async () =>
	json({ objectTypes: ModelRegistry.getObjectTypes(), count: ModelRegistry.getObjectTypes().length });
