---
name: smartview-development
description: Create, migrate or publish Smart View (TReports) business objects - IntegratedProvider, getSchema/getData, .trp. NOT Smart X. "objeto de negocio Smart View", "migrar relatorio para Smart View", "callTReports".
---

# Smart View

This skill covers building custom Smart View business objects on TOTVS Protheus: the TLPP class that inherits from `totvs.framework.treports.integratedprovider.IntegratedProvider`, declares the `@totvsFrameworkTReportsIntegratedProvider` annotation, and implements `new()`, `getSchema()` and `getData()`. It documents the schema contract (`addProperty`, column types, dates), the parameter contract (`addParameter`, `setPergunte`, advanced search via `setCustomURL`, and the custom REST endpoint a combo requires), the query patterns inside `getData`, the `callTReports` menu source, and the full `.trp` resource publication cycle that makes the object reachable from the Protheus menu.

Activate this skill when the user is creating a new Smart View report or data view from scratch, migrating an existing TReport/FWMSPrinter/TMSPrinter/FWMSExcel report into a Smart View business object, wiring parameters with advanced search or combo values, or diagnosing why an object does not appear in the tool, returns no rows, or fails to import its resource. It does not cover Smart X (see `smartx-development`), automated testing of Smart View objects (see `advpr-test-automation`, which has `UTSchemaSmartView`/`UTGetDataSmartView`), nor SX dictionary scripts for the tables being read (see `sx-configuration`).

The referenced files are written in Brazilian Portuguese.

| Reference file | Read when |
|---|---|
| reference.md | Always -- Smart View vs Smart X, environment prerequisites, minimum contract, annotation, REST routes, object identity, end-to-end example |
| patterns-schema.md | Defining columns with `addProperty`: types, dates, calculated columns, discriminator column, page size |
| patterns-parameters.md | Defining parameters: `addParameter`, `setPergunte`, advanced search (lookup), combo values and the custom options endpoint |
| patterns-getdata.md | Writing the query and feeding rows: BeginSQL vs FWExecStatement, multi-branch, currency, workarea rules |
| patterns-migration-reports.md | Converting an existing TReport, FWMSPrinter, TMSPrinter or FWMSExcel report into a Smart View business object |
| deploy-trp.md | Publishing: prerequisites, `.trp` naming, TDS extension allowance, compile/restart cycle, Protheus x Smart View binding |
| troubleshooting.md | Diagnosing errors: object missing from the list, resource not found, parameter screen 500, empty combo, zero rows |

## After writing the source (Depois de gravar o fonte)

AIs without hooks (Copilot, Cursor, Gemini CLI and others) must verify the file themselves, in this order, before delivering. Paths are relative to this skill folder; the scripts belong to the named skills.

1. Lint the whole file with the `advpl-code-review` skill's `scripts/advpl-lint.sh` (`../advpl-code-review/scripts/advpl-lint.sh --scope all <file>`). Exit 1 means errors.
2. Fix the errors and re-run the lint until there are none. Evaluate warnings and mention any you keep. A false positive can be suppressed in the project's `.advpl-specialist-ignore` (`rule <ID>`, `path <glob>`, `field <FIELD>`, `function <NAME>`).
3. As the last step, convert to Windows-1252 with the `advpl-code-generation` skill's `scripts/convert-encoding.sh` (`../advpl-code-generation/scripts/convert-encoding.sh <file>`, strict). On `failed: ... (incompatible char)`, remove or replace the character; or re-run with `--translit` and tell the user which characters became `?`. Do not edit the file after converting: a tool that assumes UTF-8 corrupts the accents. If it needs another edit, convert it back with `--to-utf8` first and repeat steps 1 to 3.
4. On Windows without bash, run the `.ps1` twins with `pwsh -NoProfile -ExecutionPolicy Bypass -File` (or `powershell -NoProfile -ExecutionPolicy Bypass -File` on Windows PowerShell 5.1).
5. In Claude Code, the plugin hooks lint on every write and convert at the end of the turn; use `/advpl-specialist:validate` to lint whole files on demand.
6. Never say the code compiled: compilation and validation in TDS / the VS Code TOTVS extension remain pending.
