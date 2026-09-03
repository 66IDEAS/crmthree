/**
 * Release packaging (Phase 8 golfing pass): produces index.min.html - the same single
 * file with the embedded script and styles minified and every internal identifier
 * shortened. index.html stays the readable, authoritative source; the minified file is a
 * deterministic build output, regenerated with:
 *   node scripts/minify.mjs
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
// esbuild comes from the reference implementation's dev dependencies - a dev tool, not a runtime dependency.
const esbuild = require(new URL('../../firebase/app/node_modules/esbuild', import.meta.url).pathname);

const src = readFileSync(new URL('../index.html', import.meta.url), 'utf8');
const styleStart = src.indexOf('<style>') + 7;
const styleEnd = src.indexOf('</style>');
const scriptStart = src.indexOf('  <script>\n') + 11;
const scriptEnd = src.lastIndexOf('  </script>');

const css = (await esbuild.transform(src.slice(styleStart, styleEnd), { loader: 'css', minify: true })).code;
const js = (await esbuild.transform(src.slice(scriptStart, scriptEnd), { loader: 'js', minify: true, target: 'es2020' })).code;

let out = src.slice(0, styleStart) + css + src.slice(styleEnd, scriptStart) + js + src.slice(scriptEnd);
out = out.replace(/^\s+</gm, '<');
writeFileSync(new URL('../index.min.html', import.meta.url), out);
const kb = (b) => (b / 1024).toFixed(0) + ' KB';
const { gzipSync } = require('node:zlib');
console.log(`source: ${kb(src.length)} (gzip ${kb(gzipSync(src).length)})  min: ${kb(out.length)} (gzip ${kb(gzipSync(out).length)})`);
