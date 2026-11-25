---
description: Refactor ADVPL/TLPP code - extract functions, simplify logic, remove dead code, improve naming
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, WebSearch, WebFetch
argument-hint: "<file> [--dry-run]"
---

**IMPORTANT:** Always respond in the same language the user is writing in. If the user writes in Portuguese, respond in Portuguese. If in English, respond in English.

# /advpl-specialist:refactor

Analyze and refactor ADVPL/TLPP code to improve structure without changing behavior.

## Usage

```bash
/advpl-specialist:refactor <target> [options]
```

## Options

| Flag | Description | Default |
|------|------------|---------|
| `--dry-run` | Show suggestions without applying changes | false |

## Refactoring Patterns

| ID | Pattern | Risk |
|----|---------|------|
| RF-001 | Extract Function (>100 lines) | Low |
| RF-002 | Simplify Conditionals (>3 levels) | Low |
| RF-003 | Remove Dead Code | Low |
| RF-004 | Improve Naming (Hungarian notation) | Low |
| RF-005 | Eliminate Duplication | Medium |
| RF-006 | Reduce Parameters (>5 params) | Medium |

## Process

**MANDATORY: Always enter planning mode before applying changes. Never refactor without approval.**

1. **Parse arguments** — Identify target file(s) and flags
2. **Load refactoring reference** — Read `${CLAUDE_PLUGIN_ROOT}/skills/advpl-refactoring/reference.md`
3. **Delegate to refactorer agent** — Pass target and options to the refactorer agent
4. **Present plan** — Structured list of refactorings with before/after for each
5. **Wait for approval** — User must approve before changes are applied
6. **Apply changes** — One refactoring at a time (unless --dry-run)
7. **Report** — Summary of changes applied

## Examples

```bash
# Refactor a source file (interactive, with approval)
/advpl-specialist:refactor src/FATA001.prw

# Show suggestions without applying
/advpl-specialist:refactor src/FATA001.prw --dry-run

# Refactor all files in a directory
/advpl-specialist:refactor src/
```

## Output

- List of refactoring opportunities found, ordered by priority
- Before/after code for each suggestion
- Summary of improvements (function count, max length, naming compliance)
