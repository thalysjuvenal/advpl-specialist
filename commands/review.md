---
description: Review ADVPL/TLPP code for best practices, performance, security, and modernization
allowed-tools: Read, Glob, Grep, Bash, Agent, WebSearch, WebFetch
argument-hint: "<file|directory> [--focus category]"
---

**IMPORTANT:** Always respond in the same language the user is writing in. If the user writes in Portuguese, respond in Portuguese. If in English, respond in English. Adapt all explanations, error descriptions, and suggestions to the user's language. Code comments may remain in English or match the user's language.

# /advpl-specialist:review

Review ADVPL/TLPP code for best practices, performance, security, and modernization opportunities.

## Usage

```bash
/advpl-specialist:review <target> [--focus category]
```

## Focus Categories

| Focus | Description |
|-------|------------|
| `boas-praticas` | Best practices: variables, locks, error handling, naming |
| `performance` | Performance: queries, loops, indexing |
| `seguranca` | Security: SQL injection, input validation, credentials |
| `modernizacao` | Modernization: ADVPL→TLPP, legacy patterns |
| `all` | All categories (default) |

## Process

1. **Parse arguments** - Identify target file(s) and optional `--focus` category
2. **Load review reference** - Read `${CLAUDE_PLUGIN_ROOT}/skills/advpl-code-review/reference.md` and read relevant rules files
3. **Delegate to code-reviewer agent** - Pass targets and focus to the code-reviewer agent for systematic analysis
4. **Present findings** - Structured report grouped by severity with actionable fix suggestions

## Examples

```bash
# Review a single source file (all categories)
/advpl-specialist:review src/FATA001.prw

# Review an entire directory focusing on performance
/advpl-specialist:review src/ --focus performance

# Review REST endpoints for security issues
/advpl-specialist:review src/REST/*.tlpp --focus seguranca

# Review current directory for modernization opportunities
/advpl-specialist:review . --focus modernizacao

# Review specific files for best practices
/advpl-specialist:review src/MATA010.prw --focus boas-praticas
```

## Output

- Findings grouped by file and severity (CRITICAL, WARNING, INFO)
- Each finding includes: rule ID, file:line reference, current code, suggested fix, and explanation
- Summary table with counts per category and severity
- Actionable recommendations prioritized by impact
