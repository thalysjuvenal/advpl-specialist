---
name: advpl-to-tlpp-migration
description: Migrate or modernize procedural ADVPL (.prw) to TLPP classes with namespaces, keeping compatible wrappers. "migrar para tlpp", "converter prw para tlpp", "compatibilizar fonte", "transformar em classe".
---

# ADVPL to TLPP Migration

This skill guides the conversion of legacy `.prw` procedural code (User Functions, Static Functions, Private/Public variables) into modern `.tlpp` classes with `namespace` declarations, `data` properties, and `public`/`private` methods -- following the official TOTVS naming conventions (lowercase dot-separated namespaces, PascalCase classes, camelCase methods, no underscores). It defines the migration workflow (analyze -> identify -> map to class design -> user approval -> generate -> checklist -> validate) and mandates keeping the original `.prw` User Function as a thin backward-compatible wrapper delegating to the new class.

Activate this skill when the user wants an existing procedural routine converted to TLPP, needs help deciding a namespace, or is modernizing multiple `#Include` directives to `.th` includes. It does not cover generating brand-new TLPP code that has no ADVPL predecessor (see `advpl-code-generation`), behavior-preserving cleanup of code that stays in ADVPL (see `advpl-refactoring`), auditing code quality before migration (see `advpl-code-review`), or fixing errors encountered during or after migration (see `advpl-debugging`).

| Reference file | Read when |
|---|---|
| reference.md | Always -- overview, migration strategy flow, core conversion rules table, TLPP naming conventions, full before/after example, key migration decisions, common mistakes |
| migration-rules.md | Needing the complete mapping of every ADVPL construct (preprocessor directives, database operations, error handling, UI elements) to its TLPP equivalent |
| migration-checklist.md | Verifying a completed migration is thorough before declaring it done |
| gap-report.md | Planning or delivering any migration (ADVPL to TLPP, Smart X, Smart View) -- mandatory gap report template, checklist of what usually gets lost, filled example |

## After writing the source (Depois de gravar o fonte)

AIs without hooks (Copilot, Cursor, Gemini CLI and others) must verify the file themselves, in this order, before delivering. Paths are relative to this skill folder; the scripts belong to the named skills.

1. Convert to Windows-1252 with the `advpl-code-generation` skill's `scripts/convert-encoding.sh` (`../advpl-code-generation/scripts/convert-encoding.sh <file>`, strict). On `failed: ... (incompatible char)`, remove or replace the character; or re-run with `--translit` and tell the user which characters became `?`.
2. Lint the whole file with the `advpl-code-review` skill's `scripts/advpl-lint.sh` (`../advpl-code-review/scripts/advpl-lint.sh --scope all <file>`). Exit 1 means errors: fix them and re-run until there are none. Evaluate warnings and mention any you keep. A false positive can be suppressed in the project's `.advpl-specialist-ignore` (`rule <ID>`, `path <glob>`, `field <FIELD>`, `function <NAME>`).
3. On Windows without bash, run the `.ps1` twins with `pwsh -File` or `powershell -File`.
4. In Claude Code the plugin hooks do this automatically on every write; use `/advpl-specialist:validate` to lint whole files on demand.
5. Never say the code compiled: compilation and validation in TDS / the VS Code TOTVS extension remain pending.
