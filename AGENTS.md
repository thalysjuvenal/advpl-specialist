# AGENTS.md — ADVPL/TLPP (TOTVS Protheus)

> This file doubles as a distributable template: copy it to the root of your Protheus source repository so any AI agent follows these standards.

## Project context

**In this repository** (`advpl-specialist`): this is a knowledge plugin for AI coding agents working with TOTVS Protheus. It ships 15 slash commands (`commands/`), 4 specialized agents (`agents/`), and 19 reference skills (`skills/<name>/SKILL.md` + companion reference files) covering code generation, review, debugging, refactoring, TLPP migration, documentation, SQL, testing, locks, business processes, Smart X, Smart View, and SX dictionary configuration. There is no application runtime here — the "code" is markdown reference material and prompt instructions.

**In a Protheus source repository** where this file is copied: the project contains `.prw` (ADVPL) and/or `.tlpp` (TLPP) source files that run inside a Protheus AppServer, plus SX dictionary scripts and possibly REST/SOAP services. Apply the standards below to any file with those extensions.

## Coding standards

- **Includes:** `.prw` files always use `#include "totvs.ch"` (lowercase). Never use `"protheus.ch"` — it is obsolete. `.tlpp` files use dedicated `.th` includes (`tlpp-core.th`, `tlpp-rest.th`, `tlpp-object.th`, `tlpp-probat.th`, etc.). Do not add `using namespace tlpp.*` — the `.th` includes already bring what is needed.
- **Naming:** Hungarian notation for variables — `c` (character), `n` (numeric), `d` (date), `l` (logical), `a` (array), `o` (object), `b` (code block), `x` (indefinite). User Functions use a module prefix + descriptive name (e.g. `FATA001`, `COMA100`); TLPP classes are PascalCase, methods camelCase.
- **Variable scope:** Always prefer `Local`. Pass data via parameters, never via `Private`/`Public`. All `Local` declarations must appear at the top of the function, before any executable statement.
- **Database access:** Use Embedded SQL (`BeginSQL ... EndSQL`) with macros — `%table:TABLE%`, `%xFilial:TABLE%`, `%notDel%`, `%exp:EXPRESSION%`, `%Order:TABLE%` — instead of raw SQL strings or `TCQuery` concatenation. Use `TCSqlExec` for DML. Every function that changes the current WorkArea (`DbSelectArea`, `DbSetOrder`, `DbSeek`) must save/restore it with `GetArea()`/`RestArea()`.
- **Locking:** Every `RecLock` must have a corresponding `MsUnlock`, including on error paths.
- **Automation:** Prefer `FWMVCRotAuto` to automate MVC routines; use `MsExecAuto` only for legacy non-MVC routines.
- **TLPP namespaces:** `custom.<agrupador>.<servico>` for customizations, `totvs.protheus.<segmento>.<agrupador>` for standard TOTVS namespaces — lowercase, dot-separated, no underscores.
- **Custom fields:** Validate existence in SX3 before referencing any custom field. Custom fields follow `<table-prefix>_X*` (e.g. `A1_XCODIGO`). Custom user functions use the `U_` prefix.
- **Error handling:** Use `BEGIN SEQUENCE ... RECOVER ... END SEQUENCE` (ADVPL) or `Try/Catch` (TLPP), never leave error paths silently swallowed.
- **Encoding:** ADVPL/TLPP source files use Windows-1252 (not UTF-8).
- **Documentation:** Public functions, methods, and REST endpoints get a Protheus.doc header block (`@type`, `@param`, `@return`, `@author`, `@since`, `@version`, `@history`).

## Prohibited patterns

Sourced from the SonarQube-aligned rule catalog (`skills/advpl-code-review/sonarqube-rules-catalog.md`):

- `StaticCall()` / `PTInternal()` — restricted, use `FWLoadModel()`/`FWLoadMenuDef()` or direct namespace calls instead.
- Assigning to `__cUserID` or `cEmpAnt` — these are read-only system variables.
- Direct `DbSelectArea` on SX* / SM0 / SIX system tables — use the framework APIs instead (`FWSX3Util`, `GetMV`/`SuperGetMV`, `RetSqlName`, `Pergunte`, `X2Nome`, etc.).
- `ConOut()` / `?` for logging — use `FWLogMsg()`.
- `IIF()` / `IF()` inline ternaries — use `If/Else/EndIf` blocks.
- SQL injection via string concatenation (raw `TCQuery`, concatenated Embedded SQL) — use `FWPreparedStatement` for parameterized queries.
- Hardcoded credentials in source code — use environment variables or AppServer configuration.
- `#INCLUDE "TOTVS.CH"` uppercase — includes must be lowercase (`#include "totvs.ch"`).
- ISAM-era APIs (`MSCREATE`, `DBCREATE`, `CRIATRAB(.T.)`, `COPY TO`) — use `FWTemporaryTable` in relational mode.
- UI calls (`MsgAlert`, `MsgYesNo`, `Aviso`, `ParamBox`, etc.) inside `Begin Transaction`/`End Transaction` blocks.
- `GetMV()`/`SuperGetMV()`/`ExistBlock()` inside loops without caching the result before the loop.

## Skill map

| Task | Read |
|---|---|
| Generate new ADVPL/TLPP code, MVC, REST, entry points, reports | `skills/advpl-code-generation/` |
| Review/audit existing code for quality, security, performance | `skills/advpl-code-review/` |
| Diagnose a compilation/runtime error, lock timeout, crash | `skills/advpl-debugging/` |
| Restructure working code without changing behavior | `skills/advpl-refactoring/` |
| Convert procedural `.prw` to object-oriented `.tlpp` | `skills/advpl-to-tlpp-migration/` |
| Generate a changelog/release notes from code changes | `skills/changelog-patterns/` |
| Explain existing code in plain language (junior/senior/functional) | `skills/code-explanation/` |
| Generate Protheus.doc headers, routine docs, or REST API docs | `skills/documentation-patterns/` |
| Write, review, or migrate Embedded SQL (`BeginSQL`/`EndSQL`) | `skills/embedded-sql/` |
| Write/run ProBat unit/functional tests for TLPP | `skills/probat-testing/` |
| Understand an ERP business process (Compras, Estoque, Fiscal, etc.) | `skills/protheus-business/` |
| Look up a native function, SX dictionary, or REST API pattern | `skills/protheus-reference/` |
| Write or troubleshoot ADVPR (Advanced Protheus Robot) regression tests | `skills/advpr-test-automation/` |
| Diagnose or prevent record locks and deadlocks | `skills/protheus-locks-deadlocks/` |
| Build, choose the pattern for, or optimize a SQL query | `skills/query-builder/` |
| Build/migrate/troubleshoot a Smart X (metadata-driven PO-UI) routine | `skills/smartx-development/` |
| Build/migrate/publish a Smart View business object (Integrated Provider, `.trp`) | `skills/smartview-development/` |
| Generate/validate SX2/SX3/SIX/SXG/SXA/SX1/SX5/SXB/SX7 dictionary scripts | `skills/sx-configuration/` |
| Escalate to TDN when local reference lacks an answer | `skills/tdn-lookup/` |

## For AI agents

- These skills are portable and installable in any agent-compatible project via `npx skills add thalysjuvenal/advpl-specialist`.
- There is no ADVPL/TLPP compiler or linter available in CI. Compilation and validation must be performed in TDS or the VS Code TOTVS extension — never report ADVPL/TLPP code as "compiled" or "verified" without that step.
