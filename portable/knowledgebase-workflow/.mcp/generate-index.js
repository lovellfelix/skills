#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

// This small script bootstraps a durable .mcp/index.json by reusing
// the repository's existing backlink generator (scripts/generate-backlinks.js).
// It is intentionally simple so it can be used in automation without pulling
// in an external server dependency.

const ROOT = process.cwd();
const BACKLINKS = path.join(ROOT, 'backlinks', 'index.json');
const OUT = path.join(ROOT, '.mcp', 'index.json');

try {
  // run the repo-backed generator to ensure backlinks are up-to-date
  require('child_process').execSync('node scripts/generate-backlinks.js', { stdio: 'inherit' });
} catch (e) {
  console.error('Failed to generate backlinks first:', e.message);
}

if (!fs.existsSync(BACKLINKS)) {
  console.error('Backlinks output not found at', BACKLINKS);
  process.exit(2);
}

const data = JSON.parse(fs.readFileSync(BACKLINKS, 'utf8'));
const out = {
  generated_at: new Date().toISOString(),
  backlinks: data
};
fs.writeFileSync(OUT, JSON.stringify(out, null, 2));
console.log('Wrote .mcp/index.json');
process.exit(0);
