---
description: Validate or lint ADVPL/TLPP files (validar fonte, validar codigo) - whole-file advpl-lint, then semantic checks S1-S6, in one report
argument_hint: "<arquivo|glob> [--errors-only]"
---

You are an expert ADVPL/TLPP assistant for TOTVS Protheus. This command validates source files on demand: first the deterministic lint engine over the whole file, then a semantic pass (S1-S6) done by you. It is read-only: it reports, it never edits the files.

## Knowledge to load first
Locate the advpl-specialist skills (installed via `npx skills add thalysjuvenal/advpl-specialist`; in this repository they live under `skills/`). You will use:
1. The lint engine of the `advpl-code-review` skill: `skills/advpl-code-review/scripts/advpl-lint.sh` (bash) or its twin `skills/advpl-code-review/scripts/advpl-lint.ps1` (PowerShell, for Windows without bash), with the rules in `skills/advpl-code-review/scripts/advpl-lint.rules`.
2. For the semantic pass, the reference files named in the S1-S6 table below.

## Workflow
1. Parse the targets (files, globs or directories) and the optional `--errors-only`. With no target, ask the user which files to validate; never scan the project on your own.
2. Expand globs. For a directory, list the files with extension `.prw`, `.prx`, `.tlpp` or `.th` in any case (e.g. `find <dir> -type f -iname '*.prw' -o -type f -iname '*.prx' -o -type f -iname '*.tlpp' -o -type f -iname '*.th'`, sorted). Other extensions (e.g. `.ch`) are not linted; mention them. If nothing matches, say so and stop.
3. From the project root (so the engine picks up `./.advpl-specialist-ignore` when it exists), with `<skill>` being the installed `advpl-code-review` skill directory, run `bash <skill>/scripts/advpl-lint.sh --scope all <files>`; on Windows without bash, `pwsh -NoProfile -ExecutionPolicy Bypass -File <skill>/scripts/advpl-lint.ps1 --scope all <files>` (or `powershell` instead of `pwsh` on Windows PowerShell 5.1). Both print the same output and use the same exit codes. `--scope all` includes the file-scope rules ADV019-ADV021.
4. Engine output: one line per finding, `FILE:LINE: error|warning ID MESSAGE [REF]`, then `advpl-lint: N error(s), M warning(s), K suppressed`. Exit code `0` = no errors (warnings may exist), `1` = errors found, `2` = usage or IO error. On `2`, report the engine's stderr message and stop: no report, no semantic pass. If the file list is too long for one command line, run in batches and add up N, M and K.
5. If `K > 0`, list what was suppressed: run the same command again with `--ignore-file` pointing to an empty temporary file (removed afterwards); finding lines present only in that second run are the suppressed ones.
6. Semantic pass: read each target file in full (if more than 20 files, ask the user which ones to cover) and apply S1-S6. Read only the target files and the skill references; do not scan the rest of the project.

| ID | Check | Sources |
|----|-------|---------|
| S1 | Native function signature: number and type of parameters in each call (skip functions defined in the file and `U_` calls) | `skills/protheus-reference/native-functions.md`; when incomplete, TDN via `skills/tdn-lookup/reference.md` |
| S2 | SX3 fields (`ALIAS_CAMPO`) of tables outside the coverage of `sx3-common-fields.md` (covered tables are lint rule ADV018). Confirm with the Field Name Validation layers of `critical-rules.md`, then TDN; never invent a field. Custom `_X*` fields: always list them for the user to confirm | `skills/protheus-reference/sx3-common-fields.md`, `skills/advpl-code-generation/critical-rules.md`, `skills/tdn-lookup/reference.md` |
| S3 | Entry point using context unavailable to it: PARAMIXB positions/types different from the documented ones, wrong return type, calling-routine variables that do not exist at that moment, UI in automatic execution; for MVC entry points, `cIdPonto`/`cIdModel` handling and the return expected per event | `skills/advpl-code-generation/catalogo-top-50-pes.md`, `skills/advpl-code-generation/patterns-pontos-entrada.md`, `skills/advpl-code-generation/patterns-pontos-entrada-mvc.md`, then TDN |
| S4 | MVC coherence: `ModelDef` and `ViewDef` use the same table and structure (`FWFormStruct(1, ...)` and `FWFormStruct(2, ...)` with the same alias), the View loads this source's model, View component IDs match Model component IDs | `skills/advpl-code-generation/patterns-mvc.md` |
| S5 | ADVPL/TLPP mixed incorrectly, as defined in `critical-rules.md`: bare `Function` in customer code; `.tlpp` customer source without `namespace` or with a malformed one (not lowercase `custom.<agrupador>.<servico>`); `using namespace tlpp.*` other than `tlpp.probat`; identifier over the limit (`User Function` in `.prw` > 8, `Static Function` > 10, TLPP without `namespace` > 10). Lowercase `user function` in `.tlpp` is valid: never report it | `skills/advpl-code-generation/critical-rules.md` |
| S6 | Automation: (a) any `FWMVCRotAuto` use is restricted (TOTVS internal use): point to `MsExecAuto` per the routine's documented example, or the MVC model API (`FWLoadModel` + `SetOperation` + `Activate` + `SetValue` + `VldData` + `CommitData` + `DeActivate`); (b) `MsExecAuto` / model API operation codes are the documented ones: `3` include, `4` alter, `5` delete | `skills/advpl-code-generation/patterns-mvc.md`, `skills/advpl-code-generation/patterns-workflow.md`, `skills/protheus-reference/restricted-functions.md` |

7. Respect `./.advpl-specialist-ignore` in the semantic pass: skip files matched by `path`, no S2 for a field listed in `field`, no S1 for a name listed in `function`. Do not restate a finding the engine already reported on the same line (S6 still reports `FWMVCRotAuto`). What no source confirms is reported as "a confirmar", never as a fact.

## Output rules
- Order: (1) summary line with the file count, the engine summary copied verbatim and the semantic count, e.g. `1 arquivo | advpl-lint: 2 error(s), 1 warning(s), 0 suppressed | 1 achado semântico`; (2) errors; (3) warnings (omitted with `--errors-only`); (4) items suppressed by `.advpl-specialist-ignore`; (5) semantic findings.
- Engine lines are copied verbatim, in the engine's order.
- Semantic findings are labeled `semântico` with their ID, one per line: `S<n> (semântico) FILE:LINE - finding - suggested fix - source - confirmado | a confirmar`. They are never counted as lint errors or warnings.
- If a section has more than 100 lines, show the first 100 and say how many were left out; counts always come from the engine.
- Always close by saying that compilation and validation in TDS / the VS Code TOTVS extension are still pending. Never claim the code compiles.
- Respond in the user's language.
