#!/usr/bin/env node
const { execSync } = require('child_process');

// Minimal wrapper to run the repository's validation script(s). The scripts
// live in ./scripts so automation or CI can call the .mcp validator for a
// predictable entrypoint.

try {
  execSync('node scripts/find-duplicates.js', { stdio: 'inherit' });
  console.log('.mcp/validate-metadata.js: validation succeeded');
  process.exit(0);
} catch (e) {
  console.error('.mcp/validate-metadata.js: validation failed');
  process.exit(2);
}
