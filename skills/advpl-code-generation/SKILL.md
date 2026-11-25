---
name: advpl-code-generation
description: Generate or scaffold ADVPL/TLPP code - User Functions, TLPP classes, MVC, REST, SOAP, entry points, reports, jobs. "gerar codigo", "criar rotina", "novo ponto de entrada", "criar classe tlpp", "gerar api rest".
---

# ADVPL/TLPP Code Generation

This skill provides patterns, templates, and mandatory structural rules for generating new ADVPL (`.prw`) and TLPP (`.tlpp`) code for TOTVS Protheus. It covers naming conventions (module prefixes, Hungarian notation), the mandatory User Function skeleton with Protheus.doc headers and error handling, variable scope rules, TLPP namespace conventions (`custom.<agrupador>.<servico>`), and the 8/10/255-character identifier length limits per construct type.

Activate this skill whenever the user requests new code creation: a new function, a TLPP class, an MVC screen, a REST endpoint, a SOAP web service, an entry point, a report, a batch job, or any new `.prw`/`.tlpp` file. It does not cover reviewing existing code (see `advpl-code-review`), fixing errors in existing code (see `advpl-debugging`), improving existing code structure without adding features (see `advpl-refactoring`), or converting legacy `.prw` to `.tlpp` (see `advpl-to-tlpp-migration`).

The reference and pattern files below hold the concrete templates -- read the specific pattern file that matches the type of code being generated instead of relying on memory.

| Reference file | Read when |
|---|---|
| critical-rules.md | Always, before generating any code -- `User Function` vs bare `Function`, TLPP namespace declaration, identifier length limits (8/10/255), valid `JsonObject`/`TWsdlManager`/`FWFormView` methods, `ALIAS_CAMPO` field-name validation |
| reference.md | Always -- overview, naming conventions, mandatory User Function structure, variable scope, error handling, common mistakes |
| templates-classes.md | Generating a TLPP class (data, methods, constructor) |
| patterns-mvc.md | Generating an MVC screen (ModelDef/ViewDef/MenuDef) |
| patterns-rest.md | Generating a REST API endpoint (WsRestFul or TLPP `@Get/@Post` annotations) |
| patterns-soap.md | Generating a SOAP Web Service |
| patterns-treport.md | Generating a TReport-based report with embedded SQL |
| patterns-pontos-entrada.md | Generating a legacy (non-MVC) entry point (ponto de entrada) |
| patterns-pontos-entrada-mvc.md | Generating an MVC-based entry point |
| patterns-workflow.md | Generating a Protheus workflow routine |
| patterns-jobs.md | Generating a scheduled/background job |
| patterns-fwmsprinter.md | Generating a coordinate-based PDF report with FWMsPrinter |
| patterns-fwformbrowse.md | Generating a browse screen with FWFormBrowse |
| catalogo-top-50-pes.md | Looking up existing well-known entry points before creating a duplicate |

## After writing the source (Depois de gravar o fonte)

AIs without hooks (Copilot, Cursor, Gemini CLI and others) must verify the file themselves, in this order, before delivering. Paths are relative to this skill folder; the scripts belong to the named skills.

1. Convert to Windows-1252 with this skill's `scripts/convert-encoding.sh` (`scripts/convert-encoding.sh <file>`, strict). On `failed: ... (incompatible char)`, remove or replace the character; or re-run with `--translit` and tell the user which characters became `?`.
2. Lint the whole file with the `advpl-code-review` skill's `scripts/advpl-lint.sh` (`../advpl-code-review/scripts/advpl-lint.sh --scope all <file>`). Exit 1 means errors: fix them and re-run until there are none. Evaluate warnings and mention any you keep. A false positive can be suppressed in the project's `.advpl-specialist-ignore` (`rule <ID>`, `path <glob>`, `field <FIELD>`, `function <NAME>`).
3. On Windows without bash, run the `.ps1` twins with `pwsh -File` or `powershell -File`.
4. In Claude Code the plugin hooks do this automatically on every write; use `/advpl-specialist:validate` to lint whole files on demand.
5. Never say the code compiled: compilation and validation in TDS / the VS Code TOTVS extension remain pending.
