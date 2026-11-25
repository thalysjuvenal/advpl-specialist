---
description: Refactor ADVPL/TLPP code - extract functions, simplify logic, remove dead code, improve naming
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, WebSearch, WebFetch
argument-hint: "<file> [--dry-run] [--focus modernize]"
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
| `--focus modernize` | Only the modernization patterns RF-007 to RF-012, with candidates found by the lint engine (see "With `--focus modernize`") | structural patterns RF-001 to RF-006 |

## Refactoring Patterns

| ID | Pattern | Risk |
|----|---------|------|
| RF-001 | Extract Function (>100 lines) | Low |
| RF-002 | Simplify Conditionals (>3 levels) | Low |
| RF-003 | Remove Dead Code | Low |
| RF-004 | Improve Naming (Hungarian notation) | Low |
| RF-005 | Eliminate Duplication | Medium |
| RF-006 | Reduce Parameters (>5 params) | Medium |
| RF-007 | Concatenated `TCQuery` → `FWPreparedStatement` / `BeginSQL` (lint ADV015) | Medium |
| RF-008 | `ErrorBlock` + `Begin Sequence` → `Try`/`Catch`, `.tlpp` only (no lint rule, BG1200) | Medium |
| RF-009 | `ConOut` → `FWLogMsg` (lint ADV003) | Low |
| RF-010 | `CriaTrab`/`DbCreate` → `FWTemporaryTable` (lint ADV010, ADV011) | Medium |
| RF-011 | `IIf` → `If`/`Else`/`EndIf` outside code blocks (lint ADV009) | Low |
| RF-012 | Direct SX access → framework API (lint ADV008) | Medium |

RF-007 to RF-012 run only with `--focus modernize`.

## Process

**MANDATORY: Always enter planning mode before applying changes. Never refactor without approval.**

1. **Parse arguments** — Identify target file(s) and flags
2. **Load refactoring reference** — Read `${CLAUDE_PLUGIN_ROOT}/skills/advpl-refactoring/reference.md`
3. **Delegate to refactorer agent** — Pass target and options to the refactorer agent
4. **Present plan** — Structured list of refactorings with before/after for each
5. **Wait for approval** — User must approve before changes are applied
6. **Prepare Windows-1252 sources** — Unless `--dry-run`. Claude Code's Edit refuses a file that is not valid UTF-8, and the refactorer agent has no Bash to convert it. After approval, for each existing target with extension `.prw`, `.prx`, `.tlpp` or `.th` that the agent will edit, in the same turn as the edits:
   1. Read the file before converting it, even if its content is already known: the plugin's hook then puts it on the list converted back at the end of the turn, edited or not, and shows the conversion hint.
   2. Convert it to UTF-8:

      ```bash
      bash "${CLAUDE_PLUGIN_ROOT}/skills/advpl-code-generation/scripts/convert-encoding.sh" --to-utf8 "<file>"
      ```

   3. On `converted:` or `already-utf8:`, go on. On `failed: <file> (undefined byte)`, tell the user and do not delegate the editing of that file.

   The plugin lints each edit the agent makes and converts the file back to Windows-1252 at the end of the turn, so an edit left for a later turn needs this step again. If the user cancels before any edit, run the same script without `--to-utf8` on those targets to return them to Windows-1252.
7. **Apply changes** — One refactoring at a time (unless --dry-run)
8. **Report** — Summary of changes applied

### With `--focus modernize`

Only RF-007 to RF-012. The lint engine finds the candidates; the approval, one-change-at-a-time and behavior-preserving rules above still apply.

1. **Load the patterns** — Read `${CLAUDE_PLUGIN_ROOT}/skills/advpl-refactoring/patterns-modernization.md` as well as `${CLAUDE_PLUGIN_ROOT}/skills/advpl-refactoring/reference.md`.
2. **Run the lint engine** — From the project root, so `./.advpl-specialist-ignore` is honored, over the target files with extension `.prw`, `.prx`, `.tlpp` or `.th`:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/advpl-code-review/scripts/advpl-lint.sh" --scope all "<file1>" "<file2>" ...
   ```

   Windows without `bash`: `pwsh -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/skills/advpl-code-review/scripts/advpl-lint.ps1" --scope all ...` (or `powershell` on Windows PowerShell 5.1). Each finding is `FILE:LINE: error|warning ID MESSAGE [REF]`. On exit code `2` (usage or IO error), report the engine's stderr message and stop.
3. **Map findings to patterns** — Use the table in "Finding candidates" of `${CLAUDE_PLUGIN_ROOT}/skills/advpl-refactoring/patterns-modernization.md`: ADV015 → RF-007, ADV003 → RF-009, ADV010/ADV011 → RF-010, ADV009 → RF-011, ADV008 → RF-012. RF-008 has no lint rule: in `.tlpp` targets, search `ErrorBlock(` with Grep; never propose RF-008 for `.prw`. Findings with other IDs are fixes, not refactorings: list them apart as outside this focus.
4. **Filter** — Check each candidate against the pattern's "Do not apply when" list (for example `IIf` inside a code block or dictionary expression, static SQL with internal values only, `CriaTrab(NIL, .F.)` used only for a file name). Report excluded candidates with the reason; do not change them.
5. **Plan** — Delegate to the refactorer agent, passing the target, `--focus modernize` and the engine's finding lines verbatim. The agent has no Bash: this command runs the lint engine, and the agent classifies and filters the findings (steps 3 and 4) with the patterns file. For each candidate the plan shows `FILE:LINE`, the engine line verbatim, the RF ID, before/after, the risk, and the "Same behavior" checks of the pattern. Wait for approval.
6. **Prepare Windows-1252 sources** — Unless `--dry-run`: after approval, convert the targets the agent will edit as in step 6 "Prepare Windows-1252 sources" above. The lint engine already ran in step 2, on the original bytes; its re-runs in step 7 read the converted file, with the same line numbers.
7. **Apply** — One pattern in one function at a time (unless `--dry-run`). After each change, this command re-runs the lint engine on the changed file: the finding must be gone and no new error may appear; otherwise the change goes back to the plan.
8. **Report** — The engine summary line before and after, the warnings kept and why, the "Same behavior" tests the user must run, and that compilation and validation in TDS / the VS Code TOTVS extension are still pending. Never claim the code compiles.

## Examples

```bash
# Refactor a source file (interactive, with approval)
/advpl-specialist:refactor src/FATA001.prw

# Show suggestions without applying
/advpl-specialist:refactor src/FATA001.prw --dry-run

# Refactor all files in a directory
/advpl-specialist:refactor src/

# Plan the modernization of legacy APIs flagged by the lint, without applying
/advpl-specialist:refactor src/FATA001.prw --focus modernize --dry-run
```

## Output

- List of refactoring opportunities found, ordered by priority
- Before/after code for each suggestion
- Summary of improvements (function count, max length, naming compliance)
- With `--focus modernize`: the engine summary line before and after, each candidate with its lint line and RF ID, and the candidates kept with the reason
