#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const matter = require('gray-matter');
const yaml = require('js-yaml');

const normalize = require('./normalize');

const ROOT = process.cwd();

// allow overriding the KB root directory via --root PATH or --root=PATH
function getArg(name) {
  for (let i = 2; i < process.argv.length; i++) {
    const a = process.argv[i];
    if (a === name && process.argv[i+1]) return process.argv[i+1];
    if (a.startsWith(name + '=')) return a.split('=')[1];
  }
  return null;
}
const ROOT_DIR = getArg('--root') ? path.resolve(getArg('--root')) : ROOT;
const TAGS_FILE = path.join(ROOT_DIR, 'tags.yml');
// files and directories to skip when scanning the repository for KB markdown files
const IGNORE = ['.git', 'node_modules', 'dist', 'build', '.github', '.mcp', 'backlinks', 'examples', 'docs', 'tests', '.githooks', 'SKILL.md', 'KB_OWNERS.md'];

function walk(dir) {
  const results = [];
  for (const name of fs.readdirSync(dir)) {
    const full = path.join(dir, name);
    const stat = fs.statSync(full);
    if (stat.isDirectory()) {
      if (IGNORE.includes(name)) continue;
      results.push(...walk(full));
    } else if (stat.isFile() && name.endsWith('.md')) {
      // skip known non-KB packaging or docs files
      if (IGNORE.includes(name)) continue;
      results.push(full);
    }
  }
  return results;
}

function parseFrontmatter(content) {
  // use gray-matter with js-yaml for robust YAML parsing
  try {
    const parsed = matter(content, { engines: { yaml: s => yaml.load(s) } });
    return parsed.data || {};
  } catch (e) {
    // fallback: return empty
    return {};
  }
}

// load canonical tags and build alias -> canonical mapping
let canonicalTags = {};
let tagAliasToCanonical = new Map();
try {
  const tagsRaw = fs.readFileSync(TAGS_FILE, 'utf8');
  const tagsParsed = yaml.load(tagsRaw) || {};
  canonicalTags = tagsParsed.canonical || {};
  for (const [canon, meta] of Object.entries(canonicalTags)) {
    const cnorm = normalize(canon);
    tagAliasToCanonical.set(cnorm, canon);
    if (meta && Array.isArray(meta.aliases)) {
      for (const a of meta.aliases) {
        const an = normalize(a);
        if (an) tagAliasToCanonical.set(an, canon);
      }
    }
  }
} catch (e) {
  // missing tags.yml is non-fatal; validation of tags will be skipped
}

const files = walk(ROOT_DIR);
const titleMap = new Map();
const aliasMap = new Map();
const missingFrontmatter = [];
const tagErrors = []; const tagWarnings = [];

for (const f of files) {
  const raw = fs.readFileSync(f,'utf8');
  const fm = parseFrontmatter(raw);
  const title = fm.title || null;
  if (!title) missingFrontmatter.push({file:f, reason:'missing title'});
  const norm = normalize(title);
  if (norm) {
    if (!titleMap.has(norm)) titleMap.set(norm, []);
    titleMap.get(norm).push(f);
  }
  const aliases = fm.aliases || fm.alias || [];
  if (typeof aliases === 'string') {
    const a = aliases;
    const anum = normalize(a);
    if (anum) {
      if (!aliasMap.has(anum)) aliasMap.set(anum, []);
      aliasMap.get(anum).push(f);
    }
  } else if (Array.isArray(aliases)) {
    for (const a of aliases) {
      const anum = normalize(a);
      if (!anum) continue; // skip empty/blank aliases
      if (!aliasMap.has(anum)) aliasMap.set(anum, []);
      aliasMap.get(anum).push(f);
    }
  }
  // tags validation (if tags.yml present)
  if (fm.tags && tagAliasToCanonical.size > 0) {
    const tags = Array.isArray(fm.tags) ? fm.tags : [fm.tags];
    for (const t of tags) {
      const tn = normalize(t);
      if (!tn) {
        tagErrors.push({file:f, tag:t, reason:'empty tag'});
        continue;
      }
      if (!tagAliasToCanonical.has(tn)) {
        tagErrors.push({file:f, tag:t, reason:'unknown tag'});
      } else {
        const canonical = tagAliasToCanonical.get(tn);
        // if the user used an alias different than the canonical, warn but don't fail
        if (canonical && normalize(canonical) !== tn) {
          tagWarnings.push({file:f, tag:t, reason:`use canonical tag '${canonical}'`} );
        }
      }
    }
  }

  // minimal required fields check
  const required = ['title','created','modified','type'];
  for (const r of required) {
    if (!fm[r]) missingFrontmatter.push({file:f, reason:`missing ${r}`} );
  }
}

let hasError = false;

for (const [t, list] of titleMap.entries()) {
  if (list.length > 1) {
    console.error('\nDuplicate title detected:', t);
    list.forEach(p => console.error(' -', p));
    hasError = true;
  }
}

for (const [a, list] of aliasMap.entries()) {
  if (list.length > 1) {
    console.error('\nDuplicate alias detected:', a);
    list.forEach(p => console.error(' -', p));
    hasError = true;
  }
}

if (tagErrors.length) {
  console.error('\nTag validation errors:');
  tagErrors.forEach(i => console.error(` - ${i.file}: ${i.tag} -> ${i.reason}`));
  hasError = true;
}

if (tagWarnings.length) {
  console.warn('\nTag validation warnings:');
  tagWarnings.forEach(i => console.warn(` - ${i.file}: ${i.tag} -> ${i.reason}`));
}

if (missingFrontmatter.length) {
  console.error('\nFrontmatter issues:');
  missingFrontmatter.forEach(i => console.error(` - ${i.file}: ${i.reason}`));
  hasError = true;
}

if (hasError) process.exit(2);
console.log('No duplicates or missing required frontmatter fields found.');
process.exit(0);
