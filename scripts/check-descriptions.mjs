#!/usr/bin/env node
// Mede o tamanho das descricoes (frontmatter) de skills e comandos.
// Limites: SKILL.md 250, commands e ai-commands/src 150 (code points Unicode).
// Sai com 1 se houver qualquer infracao.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

function list(dir, filter) {
  const abs = path.join(ROOT, dir);
  if (!fs.existsSync(abs)) return [];
  return fs.readdirSync(abs).sort().map((n) => filter(n)).filter(Boolean).map((p) => path.join(dir, p));
}

const targets = [
  ...list('skills', (n) => (fs.existsSync(path.join(ROOT, 'skills', n, 'SKILL.md')) ? `${n}/SKILL.md` : null)).map((p) => [p, 250]),
  ...list('commands', (n) => (n.endsWith('.md') ? n : null)).map((p) => [p, 150]),
  ...list('ai-commands/src', (n) => (n.endsWith('.md') ? n : null)).map((p) => [p, 150]),
];

function check(rel, limit) {
  const text = fs.readFileSync(path.join(ROOT, rel), 'utf8').replace(/\r\n/g, '\n');
  const lines = text.split('\n');
  if (lines[0] !== '---') return 'sem frontmatter';
  const end = lines.indexOf('---', 1);
  if (end < 0) return 'frontmatter nao fechado';
  const line = lines.slice(1, end).find((l) => /^description:/.test(l));
  if (line === undefined) return 'description ausente';
  let value = line.replace(/^description:/, '').trim();
  if (/^[>|]/.test(value)) return 'description em bloco (> ou |) nao suportada';
  const m = value.match(/^(["'])(.*)\1$/);
  if (m) value = m[2];
  if (value.trim() === '') return 'description vazia';
  const len = [...value].length;
  return len > limit ? `${len} > ${limit}` : null;
}

let bad = 0;
for (const [rel, limit] of targets) {
  const problem = check(rel, limit);
  if (problem) {
    bad++;
    console.log(`${rel}: ${problem}`);
  }
}
console.log(`${targets.length} arquivos verificados, ${bad} com problema`);
process.exit(bad ? 1 : 0);
