---
description: Validate or lint ADVPL/TLPP files (validar fonte, validar codigo) - whole-file advpl-lint, then semantic checks S1-S6, in one report
allowed-tools: Read, Glob, Grep, Bash, WebSearch, WebFetch
argument-hint: "<arquivo|glob> [--errors-only]"
---

**IMPORTANT:** Always respond in the same language the user is writing in. If the user writes in Portuguese, respond in Portuguese. If in English, respond in English. Adapt all explanations and suggestions to the user's language. Lines copied from the lint engine stay verbatim.

# /advpl-specialist:validate

Validate ADVPL/TLPP sources on demand: first the deterministic lint engine over the whole file (`--scope all`, including the file-scope rules ADV019-ADV021 that the PostToolUse hook skips on edits), then a semantic pass (S1-S6) done by you with the plugin's reference skills. The command is read-only: it reports, it never edits the files.

## Usage

```bash
/advpl-specialist:validate <file|glob|directory>... [--errors-only]
```

## Options

| Flag | Description |
|------|------------|
| `--errors-only` | Omit the lint warnings section from the report (the summary still shows the warning count) |

## Process

### 1. Resolve the targets

1. Parse the arguments: one or more files, globs or directories, plus the optional `--errors-only`. With no target, ask the user which files to validate; never scan the project on your own.
2. Expand globs with `Glob`. For a directory, list the lint extensions in any case: `find <dir> -type f \( -iname '*.prw' -o -iname '*.prx' -o -iname '*.tlpp' -o -iname '*.th' \) | sort` (or `Glob` with the same extensions where `bash` is not available).
3. Keep the paths exactly as resolved: the engine prints each FILE as it was received. Files with other extensions (e.g. `.ch`) are skipped by the engine; mention them as not linted.
4. If nothing matches, say so and stop.

### 2. Run the lint engine

Run from the project root, so the engine picks up `./.advpl-specialist-ignore` when it exists:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/advpl-code-review/scripts/advpl-lint.sh" --scope all "<file1>" "<file2>" ...
```

- Windows without `bash`: run the PowerShell twin with the same arguments, `pwsh -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/skills/advpl-code-review/scripts/advpl-lint.ps1" --scope all ...` (or `powershell -NoProfile -ExecutionPolicy Bypass -File ...` on Windows PowerShell 5.1). Output and exit codes are identical.
- Output: one line per finding, `FILE:LINE: error|warning ID MESSAGE [REF]`, then the summary `advpl-lint: N error(s), M warning(s), K suppressed`.
- Exit code: `0` no errors (warnings may exist), `1` errors found, `2` usage or IO error (unreadable file, invalid option, unreadable rules or ignore file). **On `2`, report the engine's stderr message and stop** - no report, no semantic pass.
- If the file list is too long for one command line, run it in batches and add up N, M and K from each summary line.
- If `K > 0`, list what was suppressed: run the same command again with `--ignore-file` pointing to an empty temporary file (`mktemp`, removed afterwards); the finding lines present only in that second run are the suppressed ones.
- The rule IDs, messages and references are documented in `${CLAUDE_PLUGIN_ROOT}/skills/advpl-code-review/scripts/advpl-lint.rules`.

### 3. Semantic pass (S1-S6)

Read each target file in full, then apply the checks below. If the targets expand to more than 20 files, ask the user which ones the semantic pass should cover (the lint still covers all of them).

- Read only the target files and the plugin references named here; do not scan the rest of the project.
- Respect `./.advpl-specialist-ignore`: skip files matched by a `path` directive, do not raise S2 for a field listed in a `field` directive (the user already confirmed it), and do not raise S1 for a name listed in a `function` directive.
- Do not restate a lint finding: if the engine already reported the same problem on the same line, leave it out. Exception: S6 always reports `FWMVCRotAuto`, because it names the alternative.
- Never invent a signature, field or PARAMIXB. What no source confirms is reported as **a confirmar**, never as a fact.

| ID | Check | Sources |
|----|-------|---------|
| **S1** | Native function signature: number and type of parameters in each call. Skip functions defined in the file and `U_` calls | `${CLAUDE_PLUGIN_ROOT}/skills/protheus-reference/native-functions.md`; when the local reference is incomplete, TDN via `${CLAUDE_PLUGIN_ROOT}/skills/tdn-lookup/reference.md` |
| **S2** | SX3 fields (`ALIAS_CAMPO`) of tables outside the coverage of `sx3-common-fields.md` (fields of covered tables are lint rule ADV018). Confirm with the Field Name Validation layers of `critical-rules.md`, then TDN; never invent a field. Custom `_X*` fields cannot be checked externally: always list them for the user to confirm | `${CLAUDE_PLUGIN_ROOT}/skills/protheus-reference/sx3-common-fields.md`, `${CLAUDE_PLUGIN_ROOT}/skills/advpl-code-generation/critical-rules.md` (Field Name Validation), `${CLAUDE_PLUGIN_ROOT}/skills/tdn-lookup/reference.md` |
| **S3** | Entry point (ponto de entrada) using context that is not available to it: PARAMIXB positions or types that differ from the documented ones, wrong return type, variables of the calling routine that do not exist at that moment, UI in automatic execution. For MVC entry points, check `cIdPonto`/`cIdModel` handling and the return expected per event | `${CLAUDE_PLUGIN_ROOT}/skills/advpl-code-generation/catalogo-top-50-pes.md`, `${CLAUDE_PLUGIN_ROOT}/skills/advpl-code-generation/patterns-pontos-entrada.md`, `${CLAUDE_PLUGIN_ROOT}/skills/advpl-code-generation/patterns-pontos-entrada-mvc.md`, then TDN |
| **S4** | MVC coherence: `ModelDef` and `ViewDef` point to the same table and structure (`FWFormStruct(1, ...)` and `FWFormStruct(2, ...)` with the same alias), the View loads this source's model (`FWLoadModel`), and the View component IDs match the Model component IDs | `${CLAUDE_PLUGIN_ROOT}/skills/advpl-code-generation/patterns-mvc.md` (sections 3 ModelDef and 4 ViewDef) |
| **S5** | ADVPL/TLPP mixed incorrectly, as defined in `critical-rules.md`: bare `Function` in customer code (outside the documented exceptions); `.tlpp` customer source without `namespace` or with a malformed one (not lowercase `custom.<agrupador>.<servico>`, underscores, dotted name in the function declaration); `using namespace tlpp.*` other than `tlpp.probat`; identifier longer than the limit (`User Function` in `.prw` > 8, `Static Function` > 10, TLPP without `namespace` > 10). Lowercase `user function` in `.tlpp` is valid: never report it | `${CLAUDE_PLUGIN_ROOT}/skills/advpl-code-generation/critical-rules.md` |
| **S6** | Automation. (a) Any `FWMVCRotAuto` use: it is restricted (TOTVS internal use); point to `MsExecAuto` following the routine's documented example, or, for MVC routines, the model API (`FWLoadModel` + `SetOperation` + `Activate` + `SetValue` + `VldData` + `CommitData` + `DeActivate`). (b) `MsExecAuto` and model API operation codes are the documented ones: `3` include, `4` alter, `5` delete (`MODEL_OPERATION_INSERT`/`_UPDATE`/`_DELETE`) | `${CLAUDE_PLUGIN_ROOT}/skills/advpl-code-generation/patterns-mvc.md` (section 6), `${CLAUDE_PLUGIN_ROOT}/skills/advpl-code-generation/patterns-workflow.md` (section 2), `${CLAUDE_PLUGIN_ROOT}/skills/protheus-reference/restricted-functions.md` |

Semantic findings are never lint errors: they are not added to N, M or K and never change the engine's verdict.

### 4. Report

In this order:

1. **Summary** - one line with the file count, the engine summary copied verbatim and the semantic count, e.g. `1 arquivo | advpl-lint: 2 error(s), 1 warning(s), 0 suppressed | 1 achado semântico`. With several batches, use the summed N, M and K in the engine's format.
2. **Errors** - the engine's `error` lines, verbatim, in the engine's order.
3. **Warnings** - the engine's `warning` lines, verbatim. Omitted with `--errors-only`.
4. **Suppressed by `.advpl-specialist-ignore`** - the lines found in step 2 (or "none").
5. **Semantic findings** - labeled `semântico` and kept apart from the lint lines, one per line: `S<n> (semântico) FILE:LINE - finding - suggested fix - source (reference file or TDN URL) - confirmado | a confirmar`.
6. **Pending** - always close by saying that compilation and validation in TDS / the VS Code TOTVS extension are still pending. A clean report does not mean the code compiles; never claim it does.

If a section has more than 100 lines, show the first 100 and say how many were left out; the counts always come from the engine.

## Examples

```bash
# Validate one source
/advpl-specialist:validate src/FATA001.prw

# Validate every .prw/.prx/.tlpp/.th under a directory, errors only
/advpl-specialist:validate src/ --errors-only

# Validate a glob of TLPP sources
/advpl-specialist:validate "src/REST/*.tlpp"
```

## Output

```text
1 arquivo | advpl-lint: 2 error(s), 1 warning(s), 0 suppressed | 1 achado semântico

Erros
src/FATA001.prw:3: error ADV001 <engine message>
src/FATA001.prw:40: error ADV003 <engine message> [CA1004]

Avisos
src/FATA001.prw:52: warning ADV009 <engine message> [CA4000]

Suprimidos pelo .advpl-specialist-ignore
nenhum

Achados semânticos
S2 (semântico) src/FATA001.prw:61 - campo ZZ1_XPROJ não confirmado - confirmar no dicionário da base - critical-rules.md (Field Name Validation) - a confirmar

Pendente: compilação e validação no TDS / extensão TOTVS do VS Code.
```
