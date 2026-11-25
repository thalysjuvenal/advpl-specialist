---
name: advpl-refactoring
description: Refactor or clean up ADVPL/TLPP without changing behavior - extract functions, simplify conditionals, remove dead code. "refatorar rotina", "extrair funcao", "remover codigo morto", "God function".
---

# ADVPL/TLPP Refactoring

This skill defines safe refactoring patterns for improving ADVPL/TLPP code without altering behavior. RF-001 through RF-006 cover structure: extract function, simplify conditionals with guard clauses, remove dead code, improve naming to Hungarian notation, eliminate duplication, and reduce function parameter count. RF-007 through RF-012 modernize legacy APIs found by the `advpl-code-review` lint engine: concatenated `TCQuery` to `FWPreparedStatement`/`BeginSQL`, `ErrorBlock` + `Begin Sequence` to `Try`/`Catch` (TLPP only), `ConOut` to `FWLogMsg`, `CriaTrab`/`DbCreate` to `FWTemporaryTable`, `IIf` to `If`/`Else`, and direct SX access to framework APIs. It also defines the mandatory process -- analyze, prioritize, present a before/after plan, wait for user approval, apply one change at a time, verify -- and hard safety rules (never change business logic, never rename externally-used symbols without a caller check).

Activate this skill when the user wants existing, working code restructured for readability or maintainability: long functions, deep nesting, unclear names, copy-pasted blocks, functions with excessive parameters, or legacy APIs to be replaced by their modern equivalents without changing behavior. It does not cover fixing bugs or errors (see `advpl-debugging`), generating brand-new functionality (see `advpl-code-generation`), a formal quality/security audit (see `advpl-code-review`), or converting procedural `.prw` to object-oriented `.tlpp` (see `advpl-to-tlpp-migration`, which is a structural paradigm change rather than a behavior-preserving cleanup).

| Reference file | Read when |
|---|---|
| reference.md | Always -- structural patterns RF-001 to RF-006 with before/after, the index of RF-007 to RF-012, the refactoring process, and safety rules |
| patterns-modernization.md | Replacing legacy APIs flagged by the lint engine (ADV003, ADV008, ADV009, ADV010, ADV011, ADV015) or `ErrorBlock` + `Begin Sequence` in `.tlpp` -- RF-007 to RF-012 with before/after, risk, how to prove the same behavior, lint rule and CA code, and when not to apply |

## After writing the source (Depois de gravar o fonte)

AIs without hooks (Copilot, Cursor, Gemini CLI and others) must verify the file themselves, in this order, before delivering. Paths are relative to this skill folder; the scripts belong to the named skills.

1. Convert to Windows-1252 with the `advpl-code-generation` skill's `scripts/convert-encoding.sh` (`../advpl-code-generation/scripts/convert-encoding.sh <file>`, strict). On `failed: ... (incompatible char)`, remove or replace the character; or re-run with `--translit` and tell the user which characters became `?`.
2. Lint the whole file with the `advpl-code-review` skill's `scripts/advpl-lint.sh` (`../advpl-code-review/scripts/advpl-lint.sh --scope all <file>`). Exit 1 means errors: fix them and re-run until there are none. Evaluate warnings and mention any you keep. A false positive can be suppressed in the project's `.advpl-specialist-ignore` (`rule <ID>`, `path <glob>`, `field <FIELD>`, `function <NAME>`).
3. On Windows without bash, run the `.ps1` twins with `pwsh -File` or `powershell -File`.
4. In Claude Code the plugin hooks do this automatically on every write; use `/advpl-specialist:validate` to lint whole files on demand.
5. Never say the code compiled: compilation and validation in TDS / the VS Code TOTVS extension remain pending.
