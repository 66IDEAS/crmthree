/**
 * Emits the app's complete runtime label catalog (getAllLabels) as JSON on stdout.
 * labels.js reaches the data model through the vite `$model` alias and navigation
 * through MUI icon modules, so it cannot be imported by plain Node - this script
 * bundles it with the app's own esbuild and imports the bundle from a data: URL.
 *
 *   node scripts/export-label-catalog.mjs > catalog.json
 */
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const here = path.dirname(fileURLToPath(import.meta.url));
const appDir = path.join(here, '..', 'app');
const require = createRequire(path.join(appDir, 'package.json'));
const esbuild = require('esbuild');

const result = await esbuild.build({
  stdin: {
    contents: `export { getAllLabels } from ${JSON.stringify(path.join(appDir, 'src/config/labels.js'))};`,
    resolveDir: appDir,
    loader: 'js',
  },
  bundle: true,
  write: false,
  platform: 'node',
  format: 'esm',
  logLevel: 'silent',
  loader: { '.js': 'jsx' },
  resolveExtensions: ['.js', '.jsx', '.json'],
  alias: { $model: path.join(here, '../../../specs/data-model.json') },
});

const mod = await import(
  'data:text/javascript;base64,' + Buffer.from(result.outputFiles[0].contents).toString('base64')
);
process.stdout.write(JSON.stringify(mod.getAllLabels(), null, 1) + '\n');
