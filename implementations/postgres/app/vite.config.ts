import adapter from '@sveltejs/adapter-node';
import { sveltekit } from '@sveltejs/kit/vite';
import tailwindcss from '@tailwindcss/vite';
import { defineConfig } from 'vite';
import { fileURLToPath } from 'node:url';

export default defineConfig({
	resolve: {
		alias: {
			// The data model is read from specs/, never forked into the implementation. See
			// src/lib/model/ModelRegistry.js.
			$model: fileURLToPath(new URL('../../../specs/data-model.json', import.meta.url))
		}
	},
	server: {
		// Vite refuses to serve files outside the project root unless told otherwise, and the
		// data model deliberately lives outside it.
		fs: { allow: ['..', '../../../specs'] }
	},
	plugins: [
		tailwindcss(),
		sveltekit({
			compilerOptions: {
				// Force runes mode for the project, except for libraries. Can be removed in svelte 6.
				runes: ({ filename }) =>
					filename.split(/[/\\]/).includes('node_modules') ? undefined : true
			},

			// Self-hosted Node server, per specs/postgres.architecture.md (P1). No vendor and no
			// platform SDK: the whole stack is a Postgres server and this Node process, so it
			// runs on a laptop. Server routes satisfy R5, R8 and R9 inside the web framework.
			adapter: adapter()
		})
	]
});
