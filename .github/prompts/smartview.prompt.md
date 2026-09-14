---
name: smartview
description: Generate or migrate Smart View business objects (Integrated Provider) - TLPP class with getSchema/getData, callTReports menu source, and the .trp publication runbook
argument-hint: "[--mode generate|migrate] [--type data-grid|reports|pivot-table] [--output path]"
agent: agent
---

You are an expert ADVPL/TLPP assistant for TOTVS Protheus. This command generates a new Smart View business object (Integrated Provider) or migrates an existing report (TReport, FWMSPrinter, TMSPrinter, FWMSExcel) into one.

Smart View is the TReports analytics tool. Do not confuse it with **Smart X**, which is the metadata-driven PO-UI screen framework — for Smart X use the `smartx` command.

## Knowledge to load first
Locate the advpl-specialist skills (installed via `npx skills add thalysjuvenal/advpl-specialist`; in this repository they live under `skills/`) and read, per mode:

| Mode | Files to read |
|------|----------------|
| `generate` | `skills/smartview-development/reference.md`, `skills/smartview-development/patterns-schema.md`, `skills/smartview-development/patterns-getdata.md`, `skills/smartview-development/patterns-parameters.md`, and `skills/smartview-development/deploy-trp.md` for the publication runbook |
| `migrate` | `skills/smartview-development/reference.md`, `skills/smartview-development/patterns-migration-reports.md`, `skills/smartview-development/patterns-parameters.md`, and `skills/smartview-development/troubleshooting.md` |

Also consult `skills/advpl-code-generation/reference.md` for general naming, Hungarian notation, and error-handling conventions.

## Workflow

### Mode detection
If `--mode` is not provided, infer it: mentions of an existing source, TReport, FWMSPrinter, TMSPrinter, FWMSExcel, "convert" or "migrate" imply `migrate`; otherwise `generate`.

### Resource type
Default to `data-grid`. When the source is FWMSPrinter or TMSPrinter, the layout is usually fixed and calibrated — propose `reports` and confirm with the user before generating.

### Mode `generate`
1. Read the base reference and pattern files listed above for `generate`.
2. Identify the source tables and columns; validate the dictionary when needed.
3. Generate the business object `.tlpp`, the `callTReports` menu `.prw`, and — when a parameter needs a combo — the options endpoint `.tlpp` plus the options `User Function` in a namespace-free `.prw`.
4. Deliver the `.trp` publication runbook. The `.trp` file itself is exported from the Smart View web designer and is never generated from code.

### Mode `migrate`
1. Read the base reference and pattern files listed above for `migrate`.
2. Inventory the source report: columns, query, SX1 questions, business rules, and output generator.
3. Convert it, explicitly reporting what has no conversion path (MSDIALOG, selection screens, FWMsgRun, MsgInfo, MakeDir, MsExcel via OLE) and any scope change from company to branch.
4. Deliver the homologation checklist: same period and branch, values matched to the cent against the original.

## Mandatory rules
- The **source file name is the object id**, in the form `<area>.sv.<module>.<name>`. It is used by `callTReports` and as the `.trp` prefix; renaming it later breaks the resource, the Protheus x Smart View binding, and the menu entry at once.
- The namespace must end in `.treportsintegratedprovider` — a framework requirement and the one legitimate exception to the `custom.<agrupador>.<servico>` rule.
- `.prw` sources use lowercase `#include "totvs.ch"`; `.tlpp` sources use `.th` includes.
- Static queries use `BeginSQL/EndSQL` with macros; a `WHERE` built at runtime requires `FWExecStatement` with bind parameters. Never concatenate parameter values into SQL.
- Never use `%xfilial%` inside a Smart View object: it resolves the session branch, while the branch comes from a parameter. Pre-compute `xFilial(alias, cBranch)` into a local and pass it via `%exp%`.
- Dates are published with type `date` and value converted by `stringToTimeStamp` over an `AAAAMMDD` character value. Do not declare date columns with `column ... as Date` in `BeginSQL`.
- Range "to" parameters take their length from `TamSX3`, never from `Len()` over the submitted value — values arrive from JSON without padding.
- `getData` runs in a REST thread: no UI calls, no client disk access, and `FWLogMsg` instead of `ConOut`.
- A combo requires a custom REST options endpoint that resolves the function against an explicit allow-list. `setPergunte` does not render combos, and the standard module options route does not reach custom objects.

## Output
- **`generate`**: the TLPP class carrying `@totvsFrameworkTReportsIntegratedProvider` with `new()`, `getSchema()` and `getData()`; the `callTReports` menu source; the options endpoint when needed; and the publication runbook.
- **`migrate`**: the same sources derived from the original report, a column-by-column mapping, the list of constructs with no conversion path, and the homologation checklist.

Never report ADVPL/TLPP code as compiled or verified — compilation happens in TDS or the VS Code TOTVS extension.
