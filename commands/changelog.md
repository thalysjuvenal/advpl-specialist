---
description: Generate changelog from ADVPL/TLPP code changes - analyzes diffs and produces structured release notes
allowed-tools: Read, Glob, Grep, Bash, Agent
argument-hint: "[--since commit|date] [--format markdown|txt] [--output path]"
---

**IMPORTANT:** Always respond in the same language the user is writing in. If the user writes in Portuguese, respond in Portuguese. If in English, respond in English.

# /advpl-specialist:changelog

Generate a structured changelog from code changes in ADVPL/TLPP files.

## Usage

```bash
/advpl-specialist:changelog [options]
```

## Options

| Flag | Description | Default |
|------|------------|---------|
| `--since` | Starting point: commit hash, tag, or date (YYYY-MM-DD) | Last commit (HEAD~1) |
| `--format` | Output format: `markdown`, `txt` | `markdown` |
| `--output` | Save to file path | Display in chat |
| `--group-by` | Group entries by: `file`, `type`, `module` | `type` |

## Process

1. **Parse arguments** — Identify scope, format, and output options
2. **Load changelog reference** — Read `${CLAUDE_PLUGIN_ROOT}/skills/changelog-patterns/reference.md`
3. **Delegate to changelog-generator agent** — Pass scope and options
4. **Identify changed files** — Use git diff or provided file list
5. **Analyze each file** — Classify change type, detect tables, assess impact
6. **Generate changelog** — Apply format template with grouped entries
7. **Deliver** — Display or save to output file

## Examples

```bash
# Changelog from last commit
/advpl-specialist:changelog

# Changelog since a specific commit
/advpl-specialist:changelog --since abc1234

# Changelog since a date
/advpl-specialist:changelog --since 2026-03-01

# Changelog in plain text format
/advpl-specialist:changelog --since v1.0.0 --format txt

# Save changelog to a file
/advpl-specialist:changelog --since v1.0.0 --output CHANGELOG.md

# Group by module instead of type
/advpl-specialist:changelog --since v1.0.0 --group-by module
```

## Output

Structured changelog with:
- Date and version (if available)
- Summary of changes
- Entries grouped by type (NEW, FIX, CHANGE, REMOVE, REFACTOR)
- Each entry: description, file, impact level, tables affected
