#!/usr/bin/env node
// Regenerates the GENERATED block of skills/advpl-code-review/scripts/advpl-lint.rules
// (rules ADV017 and ADV018) from the reference files in skills/protheus-reference/.
//   node scripts/sync-lint-rules.mjs          rewrite the block
//   node scripts/sync-lint-rules.mjs --check  exit 1 if the block is out of date
// Generated block — do not edit it by hand; edit the references and re-run.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const RULES_FILE = path.join(ROOT, 'skills', 'advpl-code-review', 'scripts', 'advpl-lint.rules');
const RESTRICTED_FILE = path.join(ROOT, 'skills', 'protheus-reference', 'restricted-functions.md');
const SX3_FILE = path.join(ROOT, 'skills', 'protheus-reference', 'sx3-common-fields.md');
const BEGIN = '# BEGIN GENERATED';
const END = '# END GENERATED';
const BOUNDARY = '(^|[^a-z0-9_])';

// Native functions whose names look like a field of a covered table (prefix_name),
// so ADV018 would flag them. The SFT prefix "ft" collides with the text-file API
// FT_F*. Added to ADV018's exception list; do NOT exclude whole prefixes (real SFT
// fields such as FT_FILIAL must stay recognized). Add future collisions here.
// Only FT_FUSE is cited in the local references; the rest are the standard
// text-file API family (TDN), kept here as exact names.
const NATIVE_FUNCTIONS_COLLIDING_WITH_PREFIXES = [
  'FT_FUSE', 'FT_FGOTOP', 'FT_FGOTO', 'FT_FGOBOTTOM', 'FT_FEOF',
  'FT_FREADLN', 'FT_FSKIP', 'FT_FLASTREC', 'FT_FRECNO', 'FT_FERROR',
];

function readText(file) {
  if (!fs.existsSync(file)) {
    throw new Error(`file not found: ${path.relative(ROOT, file)}`);
  }
  // Normalize CRLF so autocrlf checkouts don't produce spurious drift
  return fs.readFileSync(file, 'utf8').replace(/\r\n/g, '\n');
}

// Longest alternative first (C22: awk picks the longest, .NET the first),
// then alphabetical so the output is deterministic.
function sortAlternatives(names) {
  return [...new Set(names)].sort((a, b) => b.length - a.length || (a < b ? -1 : a > b ? 1 : 0));
}

function escapeRegex(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function assertAscii(s, what) {
  if (/[^\x20-\x7e\t\n]/.test(s)) throw new Error(`non-ASCII output in ${what}`);
}

// Names from the "Restricted Functions (NOT supported ...)" table; rows are "| N | NAME | Category |".
function readRestrictedNames() {
  const lines = readText(RESTRICTED_FILE).split('\n');
  const start = lines.findIndex((l) => /^## Restricted Functions \(NOT supported/.test(l));
  if (start === -1) throw new Error('restricted-functions.md: "Restricted Functions" section not found');
  const names = [];
  for (let i = start + 1; i < lines.length; i++) {
    if (/^## /.test(lines[i])) break;
    const m = /^\|\s*\d+\s*\|\s*([^|]+?)\s*\|/.exec(lines[i]);
    if (!m) continue;
    // "CALCEST/CALCESTL" lists two names; "__SaveParam()" carries the call parens.
    for (let raw of m[1].split('/')) {
      raw = raw.trim().replace(/\(\)$/, '');
      if (!raw) continue;
      // Methods ("oObj:GetData") are not plain calls; skip anything outside identifier syntax.
      if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(raw)) continue;
      names.push(escapeRegex(raw.toLowerCase()));
    }
  }
  if (names.length === 0) throw new Error('restricted-functions.md: no function names extracted');
  return names;
}

// Aliases ("## SA1 — Clientes") and the field names of each table.
function readSx3() {
  const lines = readText(SX3_FILE).split('\n');
  const prefixes = [];
  const fields = [];
  let alias = null;
  for (const line of lines) {
    const h = /^## ([A-Z0-9]{3}) — /.exec(line);
    if (h) {
      alias = h[1];
      const prefix = (alias[0] === 'S' ? alias.slice(1) : alias).toLowerCase();
      prefixes.push(prefix);
      continue;
    }
    if (/^## /.test(line)) {
      alias = null;
      continue;
    }
    const f = /^\|\s*([A-Z0-9]+_[A-Z0-9]+)\s*\|/.exec(line);
    if (f && alias) {
      const name = f[1].toLowerCase();
      const prefix = (alias[0] === 'S' ? alias.slice(1) : alias).toLowerCase();
      if (!name.startsWith(`${prefix}_`)) {
        throw new Error(`sx3-common-fields.md: field ${f[1]} does not start with the prefix of ${alias}`);
      }
      fields.push(name);
    }
  }
  if (prefixes.length === 0 || fields.length === 0) throw new Error('sx3-common-fields.md: no aliases/fields extracted');
  return { prefixes, fields };
}

function buildBlock() {
  const names = sortAlternatives(readRestrictedNames());
  const { prefixes, fields } = readSx3();
  const sortedPrefixes = sortAlternatives(prefixes);
  const sortedFields = sortAlternatives([...fields, ...NATIVE_FUNCTIONS_COLLIDING_WITH_PREFIXES.map((n) => n.toLowerCase())]);

  const adv017 = [
    'ADV017', 'warn', 'line', 'forbid', 'code', 'i', 'prw,prx,tlpp,th',
    `${BOUNDARY}(${names.join('|')})[ \\t]*\\(`,
    '-',
    'funcao sem suporte TOTVS (restricted-functions.md); pode mudar sem aviso, prefira a alternativa documentada',
    '-',
  ];
  const adv018 = [
    'ADV018', 'warn', 'line', 'forbid', 'code', 'i', 'prw,prx,tlpp,th',
    `${BOUNDARY}(${sortedPrefixes.join('|')})_[a-z0-9]+`,
    `^(${sortedFields.join('|')})$|^[a-z0-9]+_x`,
    'campo ausente de sx3-common-fields.md; confirme no SX3 (campos customizados _X* sao aceitos)',
    '-',
  ];
  const rows = [adv017, adv018].map((r) => r.join('\t'));
  const block = [
    BEGIN,
    `# Generated by scripts/sync-lint-rules.mjs from protheus-reference/restricted-functions.md (${names.length} names)`,
    `# and protheus-reference/sx3-common-fields.md (${sortedPrefixes.length} tables, ${fields.length} fields + ${NATIVE_FUNCTIONS_COLLIDING_WITH_PREFIXES.length} colliding native functions). Do not edit by hand.`,
    ...rows,
    END,
  ].join('\n');
  assertAscii(block, 'generated block');
  return block;
}

function main() {
  const check = process.argv.includes('--check');
  const current = readText(RULES_FILE);
  const b = current.indexOf(`${BEGIN}\n`);
  const e = current.indexOf(`\n${END}`);
  if (b === -1 || e === -1 || e < b) {
    throw new Error(`${path.relative(ROOT, RULES_FILE)}: missing "${BEGIN}" / "${END}" markers`);
  }
  const eEnd = e + 1 + END.length;
  const next = current.slice(0, b) + buildBlock() + current.slice(eEnd);

  if (check) {
    if (next !== current) {
      console.error('advpl-lint.rules: generated block is out of date; run: node scripts/sync-lint-rules.mjs');
      process.exit(1);
    }
    console.log('advpl-lint.rules: generated block is up to date');
    return;
  }
  if (next !== current) fs.writeFileSync(RULES_FILE, next);
  console.log(next !== current ? 'advpl-lint.rules: generated block updated' : 'advpl-lint.rules: already up to date');
}

try {
  main();
} catch (err) {
  console.error(`sync-lint-rules: ${err.message}`);
  process.exit(1);
}
