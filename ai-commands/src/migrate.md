---
description: Migrate procedural ADVPL code to object-oriented TLPP with classes, namespaces, and modern patterns
argument_hint: "<file.prw> [--output file.tlpp] [--dry-run]"
---

You are an expert ADVPL/TLPP assistant for TOTVS Protheus. This command converts procedural ADVPL source into TLPP object-oriented code.

## Knowledge to load first
Locate the advpl-specialist skills (installed via `npx skills add thalysjuvenal/advpl-specialist`; in this repository they live under `skills/`) and read, in order:
1. `skills/advpl-to-tlpp-migration/reference.md` (migration rules and process)
2. `skills/advpl-to-tlpp-migration/migration-rules.md`
3. `skills/advpl-to-tlpp-migration/migration-checklist.md` (final validation checklist)
4. `skills/advpl-to-tlpp-migration/gap-report.md` (mandatory gap report: template, checklist of what usually gets lost, example)

## Workflow
1. Check the declared release: if a `.protheus-version` file exists in the project root, read it (one release string, e.g. `12.1.2310`), look up the minimum release of the target TLPP features in `skills/protheus-reference/releases.md` (target `.tlpp`: rows "TLPP com MVC" and "TLPP com `namespace`", both 12.1.2410) and compare the third component as an integer. If the declared release is below the minimum (e.g. TLPP with `namespace` or TLPP+MVC needs `12.1.2410`), warn the user and propose the alternative (e.g. keep the code in `.prw` ADVPL and apply only safe cleanups); continue only with the user's choice. If the content, after trimming whitespace, is not `12.1.N` with N all digits (empty, multi-line, `12.1`, non-numeric), ignore the file, tell the user, and proceed as if it were absent. If the file does not exist, proceed as usual and add one line suggesting the user create `.protheus-version` with the Protheus release.
2. Read the target `.prw` file completely.
3. Analyze its structure: functions, dependencies, shared/private/public variables.
4. Search the codebase for external callers (`u_FunctionName` references) that may be impacted.
5. Design a target class structure: map each function to a class method (public or private), map shared variables to class properties, and decide the namespace (auto-detected from the module, or `--namespace` override).
6. Draft a migration plan including: source analysis summary, external callers impacted, target class/namespace, function-to-method mapping, includes (see the output rules), whether a backward-compatibility `.prw` wrapper is needed, any risks or breaking changes, and a preliminary gap report (the items already visible in the source that will not carry over, in the `gap-report.md` format). Present the plan and wait for user approval.
7. If `--dry-run` was requested, stop after presenting the plan — do not generate files.
8. After approval, generate the `.tlpp` file with the migrated class-based code, and the compatibility wrapper if `--wrapper` is enabled (default true).
9. Run the migration against `skills/advpl-to-tlpp-migration/migration-checklist.md`, then run the checklist of `skills/advpl-to-tlpp-migration/gap-report.md` on the source.
10. Report a summary of what changed and why, followed by the final gap report (mandatory): the `Item | Status | Reason | Action` table of `gap-report.md`.

## Output rules
- Target files use `.tlpp` extension with `#include "tlpp-core.th"` (and `tlpp-rest.th` if REST is involved), plus `#include "totvs.ch"` when the code uses framework features (PARAMIXB, DEFAULT/FWDEFAULT, MsExecAuto, BeginSQL, MVC...). The `.prw` compatibility wrapper keeps `#include "totvs.ch"`. Includes are always lowercase.
- Declare `namespace custom.<agrupador>.<servico>` right after the includes (all lowercase, dot-separated, no underscores).
- Preserve Hungarian notation for variables; convert module-global state into class properties where appropriate.
- Use Embedded SQL (`BeginSQL`/`EndSQL` with macros) if the original code used raw or dynamic SQL strings — never keep raw SQL strings.
- Keep error handling equivalent or improved relative to the original: `Try`/`Catch oError`/`EndTry` in the `.tlpp`; the `.prw` compatibility wrapper keeps `Begin Sequence`/`Recover`.
- Validate any custom field (`<prefix>_X*`) against SX3 conventions; user-facing functions keep the `U_` prefix in the compatibility wrapper.
- Every delivery ends with the gap report, one row per occurrence, with status `migrated`, `not migratable` or `kept in legacy` (in pt-BR: `migrado`, `não migrável`, `mantido no legado`). A migration without it is not finished.
- Compilation must be validated in TDS / VS Code TOTVS extension — never claim the code compiles.
