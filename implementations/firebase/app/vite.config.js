import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { fileURLToPath } from 'node:url';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      // The data model is read from specs/, not forked into the implementation. This folder
      // previously kept its own copy, which drifted: it gained DealRoom and a dozen field
      // changes the specification never learned about.
      $model: fileURLToPath(new URL('../../../specs/data-model.json', import.meta.url)),
    },
  },
  server: {
    port: 5173,
    open: false,
    // The data model deliberately lives outside the project root.
    fs: { allow: ['..', '../../../specs'] },
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
  },
});
