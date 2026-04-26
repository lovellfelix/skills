const { spawnSync } = require('child_process');
const path = require('path');

const FIXTURE = path.join(__dirname, '..', 'tests', 'fixtures', 'kb-root');
const SCRIPTS = path.join(__dirname);

function run(name) {
  console.log('\nRunning', name);
  const res = spawnSync(process.execPath, [path.join(SCRIPTS, name)], { cwd: FIXTURE, encoding: 'utf8' });
  console.log('stdout:\n', res.stdout || '');
  console.error('stderr:\n', res.stderr || '');
  return res.status || 0;
}

let code = 0;
code = run('find-duplicates.js') || code;
code = run('generate-backlinks.js') || code;

process.exit(code);
