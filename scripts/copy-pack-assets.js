#!/usr/bin/env node
/**
 * Copies non-TS pack assets (pack.json, capability.json, skill.json, README.md)
 * from src/packs/<id>/ into dist/packs/<id>/ so the built CLI can find them.
 *
 * Run automatically after `tsc` via `npm run build`.
 */
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const srcDir = path.join(root, 'src', 'packs');
const destDir = path.join(root, 'dist', 'packs');

if (!fs.existsSync(srcDir)) {
  console.error('copy-pack-assets: no src/packs directory; nothing to do.');
  process.exit(0);
}

fs.mkdirSync(destDir, { recursive: true });

const entries = fs.readdirSync(srcDir, { withFileTypes: true });
for (const entry of entries) {
  if (!entry.isDirectory()) continue;
  const srcPack = path.join(srcDir, entry.name);
  const destPack = path.join(destDir, entry.name);
  fs.mkdirSync(destPack, { recursive: true });

  for (const file of fs.readdirSync(srcPack)) {
    if (file.endsWith('.js') || file.endsWith('.d.ts') || file.endsWith('.map')) continue;
    fs.copyFileSync(path.join(srcPack, file), path.join(destPack, file));
    console.log(`copy-pack-assets: ${path.relative(root, path.join(srcPack, file))} -> ${path.relative(root, path.join(destPack, file))}`);
  }
}
