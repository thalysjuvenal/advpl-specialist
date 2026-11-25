# Post-Migration Gap Report

Every migration ends with a gap report: a table of what did **not** carry over, delivered together with the generated sources. Without it, a lost access check, entry point or parameter only shows up in production. A migration delivered without this report is not finished.

The same format serves the three migration paths of this plugin:

| Path | Path-specific gaps |
|---|---|
| ADVPL (`.prw`) → TLPP (`.tlpp`) | The checklist in this file and `migration-checklist.md` |
| Legacy routine → Smart X | Skill `smartx-development`, `patterns-migration.md` ("Passo 8 — O que NÃO migra" and the Faz/Não-Faz checklist) |
| Legacy report → Smart View | Skill `smartview-development`, `patterns-migration-reports.md` ("Relatório de lacunas") |

Run the checklist below on every source being migrated, whatever the path, then add the path-specific rows.

## Template

```markdown
**Gap report — <routine>** (`<source file>` → `<target files>`)

| Item | Status | Reason | Action |
|---|---|---|---|
| <token + where it was found> | migrated / not migratable / kept in legacy | <why> | <what the user must do, or "None"> |

Searched, not found: <checklist items with no hit>.
Totals: <n> migrated, <n> not migratable, <n> kept in legacy.
Compilation and validation in TDS / the VS Code TOTVS extension: pending.
```

Status values (use exactly these):

| Status | Meaning | Action column |
|---|---|---|
| `migrated` | Carried over with the same behaviour | Where it lives now (method, file); "None" or the test to run |
| `not migratable` | No equivalent in the target; the behaviour is lost unless someone acts | Required: what replaces it, or who must decide |
| `kept in legacy` | Deliberately left in the legacy source (compatibility wrapper, `ModelDef` kept for ExecAuto, original report until sign-off) | When it can be retired, if ever |

Rules for filling it in:

- One row per occurrence that matters — per parameter name, entry point name, trigger, filter, legend — never one row per category.
- The **Item** column carries the grep-able token and where it was found (function or line), e.g. `ExecBlock("ZFAT01GR")` in `ZFATA01()`.
- A behaviour that moved but changed (a parameter read in another place, an entry point with new `PARAMIXB` positions) is `migrated`; the change goes in **Reason**, and anything the user must do goes in **Action**.
- Items searched with no hit stay out of the table and are listed in the "Searched, not found" line, so an empty report can be told apart from a skipped one.
- In a pt-BR delivery, use the headers `Item | Situação | Motivo | Ação` and the values `migrado` / `não migrável` / `mantido no legado`. The meaning does not change.
- Never write that the code compiled.

## When to produce it

- **At plan time** (including `--dry-run`): a preliminary report with the gaps already visible in the source, so the user approves the plan knowing what will not carry over.
- **At delivery**: the final report, after the migration checklist, with every row resolved.

## Checklist — what usually gets lost

For each item: what to search for in the source, why it gets lost, and what goes in the report. Search ignoring case: the same call appears as `SuperGetMV`, `SuperGetMv` or `SUPERGETMV`. Behaviour that is not in the plugin's references or in the TDN is marked "(a confirmar no TDS)": confirm it in TDS before stating it to the user.

### 1. `VerifyAccess`

- **Look for:** `VerifyAccess(`.
- **Why it gets lost:** neither the plugin's references nor the TDN document `VerifyAccess`: whether it exists as a framework function, what it checks, its signature and its return value are all "a confirmar no TDS". Whatever it verifies, a call found in the source is tied to the routine's original flow. When the logic moves into a class and the class gains new callers (job, REST endpoint, Smart X action, another routine), the call stays on the old screen path or disappears, and the new caller runs without it.
- **Report:** one row per call, saying where the call is now. If it stayed only in the `.prw` wrapper, the row is `kept in legacy` and the action is to confirm in TDS what it checks and to repeat it before every new direct caller of the class.

### 2. `SuperGetMv` / `GetMV` / `MV_` parameters

- **Look for:** `SuperGetMV(`, `GetMV(`, `"MV_`.
- **Why it gets lost:** the value lives in SX6, keyed by branch (`X6_FIL` + `X6_VAR`), not in the source. Hardcoding the value seen in the test environment, or dropping the default (third parameter of `SuperGetMV`), silently stops honouring the customer's configuration. A custom parameter must also exist in the SX6 of the target environment. Moving the read inside a loop breaks rule CA1003 (cache the value before the loop).
- **Report:** one row per parameter name: default value, where it is read now, and whether it exists in the target SX6 (to create one, see the `sx-configuration` skill).

### 3. `FwAliasInDic`

- **Look for:** `FwAliasInDic(`.
- **Why it gets lost:** the guard protects code that uses a table that may not exist in every environment (a custom `Z*` table, a table created by an update). Migrating the body without the guard, or leaving the guard in a function that is no longer on the path, makes the new code fail where the table is missing. The plugin's references describe `FwAliasInDic` as the framework check for SX2 registration (a confirmar no TDS).
- **Report:** one row per alias, saying whether the guard moved together with the code that depends on it.

### 4. `cPaisLoc`

- **Look for:** `cPaisLoc`, `FwExecLocaliz(`.
- **Why it gets lost:** these are country-specific branches. A migration tested only in the Brazilian environment drops or breaks the other branches without anyone noticing. `FwExecLocaliz` finds the localized function by its country suffix (e.g. `ExecTesBRA`), so localized function names must not change. The values of `cPaisLoc` and its availability in every execution context of the new code (job, REST, Smart X) are not in the plugin's references (a confirmar no TDS).
- **Report:** one row per country branch and per localized function, with the environments where it was tested.

### 5. Entry points called by the routine

- **Look for:** `ExecBlock("` (the string is the entry point name) and `PARAMIXB`.
- **Why it gets lost:** the entry point is a separate customer function that runs in the caller's context: it reads `PARAMIXB` by position and may read `Private` variables of the routine. After the migration those `Private` variables become `data` properties or `Local` variables, and the entry point no longer sees them; a reordered parameter array shifts `PARAMIXB`; a dropped call removes the customization with no error.
- **Report:** one row per entry point name: whether the call moved, whether the `PARAMIXB` positions are unchanged, and which `Private` variables it read. Action: test with the entry point compiled.

### 6. `ExistBlock`

- **Look for:** `ExistBlock("`.
- **Why it gets lost:** it is the guard that makes the entry point optional. Dropping the whole `If ExistBlock(...)` block removes the hook silently. Keeping `ExecBlock` without the guard makes the routine depend on the entry point being compiled (behaviour when it is missing: a confirmar no TDS). Moving the check inside a loop breaks CA1003. In Smart X, MVC entry points without a native equivalent only keep running while the legacy `ModelDef`/`ViewDef`/`MenuDef` stay in the source.
- **Report:** one row per guarded entry point (it may share the row of item 5): guard kept, moved or dropped.

### 7. SX7 triggers

- **Look for:** the fields the routine edits (`M->` memory variables, `SetValue(` on an MVC model, `Enchoice(`), then the SX7 rows whose `X7_CAMPO` is one of them.
- **Why it gets lost:** triggers live in the dictionary, not in the source: when the source field (`X7_CAMPO`) changes, they fill the target field (`X7_CDOMIN`). A migrated class that writes the record directly with `RecLock`, instead of going through the screen or the model, may not fire them and leave the target field empty (a confirmar no TDS). In Smart X the framework loads the dictionary triggers automatically, and the Model can turn them off with `disableDefaultTriggers()` (`patterns-model.md` of the `smartx-development` skill); that skill recommends describing triggers in the dictionary (SX7) whenever possible instead of building the action by hand (`patterns-interface.md`).
- **Report:** one row per trigger (`X7_CAMPO` + `X7_SEQUENC` → `X7_CDOMIN`): still fired, reproduced in the code, or lost.

### 8. Filters

- **Look for:** `SetFilterDefault(`, `DbSetFilter(`, and the filter expressions passed to the browse (in the plugin's `mBrowse` example, an assignment to a variable named `cFilterDefault`; other sources use other names).
- **Why it gets lost:** a browse filter is an ADVPL expression evaluated on the browse's work area. If the browse setup is rebuilt, the filter is easy to leave behind. In Smart X it must become SQL with the `@` prefix: expressions with `Date()` or `U_Func()` stop working, `DbSetFilter` on the browse work area is ignored, and filters that users saved (Papel de Trabalho) are lost.
- **Report:** one row per filter expression: carried over as is, converted (show the new form) or lost. For Smart X, add a row reminding the users to recreate their saved filters.

### 9. Legends

- **Look for:** `AddLegend(`, the legend array of `MBrowse`, `.BMP` image names and colour names.
- **Why it gets lost:** each legend is an expression plus a colour. The expressions often call `Static Function`s or read `Private` variables of the routine, and both change scope in the migration. In Smart X there are no `.BMP` images or arbitrary RGB colours: each legend needs a PO-UI colour, and a legacy colour outside the compatibility table, without the new parameter, raises an exception.
- **Report:** one row per legend: expression, old colour, and new colour or form.

### 10. Permissions

- **Look for:** `ACCESS` in `ADD OPTION`, the access position of the `aRotina` items (a confirmar no TDS), `RetCodUsr()` compared with a list of users (often kept in an `MV_` parameter), and the menu item that opens the routine.
- **Why it gets lost:** permissions live partly outside the source (menu, user and group setup in the Configurador, Papel de Trabalho) and partly in hand-written checks. A new entry point (job, REST endpoint, new menu item, Smart X action) does not inherit them. In Smart X, the Papel de Trabalho button restrictions stop being applied.
- **Report:** one row per check, saying where it is enforced now. Action: test with a user who must be denied.

## Example — fictitious customer routine

`ZFATA01.prw` is a fictitious customer routine that computes the sales commission of an order and records it in the custom table `ZA1`. It was migrated to the class `ComissaoService` in `custom.faturamento.comissao.tlpp`, and `ZFATA01.prw` was kept as the compatibility wrapper. All names are illustrative.

**Gap report — ZFATA01** (`ZFATA01.prw` → `custom.faturamento.comissao.tlpp`)

| Item | Status | Reason | Action |
|---|---|---|---|
| `U_ZFATA01` (menu) | kept in legacy | The wrapper in `ZFATA01.prw` delegates to `ComissaoService` | None: the menu still calls the wrapper |
| `VerifyAccess` in `ZFATA01()`, before the edit screen | kept in legacy | Stays on the wrapper's screen path; `ComissaoService:calcular()` has no `VerifyAccess` call | Confirm in TDS what it checks; repeat it before any new direct caller of `ComissaoService` (job, REST endpoint, Smart X action) |
| `SuperGetMV("MV_ZPCOMI", .F., 5)` | migrated | Read in `calcular()`, same default | Check that `MV_ZPCOMI` exists in the SX6 of every branch |
| `ExistBlock("ZFAT01GR")` + `ExecBlock("ZFAT01GR", .F., .F., {cNumPed})` | migrated | Guard and call moved to `gravar()`; `PARAMIXB` unchanged | Test with `ZFAT01GR` compiled |
| `Private cZTpCom`, read by the entry point `ZFAT01GR` | not migratable | Became `data cTipoCom`; the entry point no longer sees it | Pass it as `PARAMIXB[2]` and adapt `ZFAT01GR` (customer's decision) |
| SX7 trigger `ZA1_XVEND` → `ZA1_XNOMVE` | not migratable | `gravar()` writes with `RecLock`; the screen trigger does not run (a confirmar no TDS) | Fill `ZA1_XNOMVE` in `gravar()` or keep the screen path; test both |

Searched, not found: `FwAliasInDic`, `cPaisLoc`, filters, legends, other permission checks.
Totals: 2 migrated, 2 not migratable, 2 kept in legacy.
Compilation and validation in TDS / the VS Code TOTVS extension: pending.
