# SonarQube Rules Catalog — AdvPL/TLPP

Complete catalog of the official TOTVS static-analysis rules for AdvPL/TLPP, used by the
Protheus quality gate. Use this catalog to tag code-review findings with the canonical rule
code so reviews speak the same language as the official SonarQube analysis.

- **Attribution:** derived from the TOTVS EngPro "agent-skills" repository (MIT License, Copyright (c) 2026 TOTVS) — see `NOTICE` at the repository root.
- **Source ruleset:** `https://sonar-rules.engpro.totvs.com.br`
- **Rule code families:** `CA####` (code analysis), `BG####` (best-practice guideline),
  `CS####` (cloud/SmartERP).
- **Severity levels (SonarQube):** CRITICAL, MAJOR, MINOR, INFO.

> A `-2` suffix (e.g. `CA2001-2`) marks a lower-severity variant of the same rule (typically
> the indirect-access or "under review" case).

## Severity Legend

| Level | Meaning | Action |
|-------|---------|--------|
| **CRITICAL** | Data corruption, security breach, or prohibited API | Must fix before deploy |
| **MAJOR** | Performance, transaction safety, or legacy-driver risk | Should fix in current sprint |
| **MINOR** | Style, console output, naming, encoding | Fix when touching the code |
| **INFO** | Modernization hint or low-impact convention | Optional |

> Note: `CA2050`, `CA2051`, `CA2052` are classified INFO in SonarQube but represent
> high-impact vulnerabilities — treat them as CRITICAL during review.

---

## G1 — Security

| Rule | Title | Severity | Prohibited API / Pattern | Required Alternative |
|------|-------|----------|--------------------------|----------------------|
| BG1000 | Environment context switch in REST/SOAP services | MAJOR | `RpcSetEnv`, `RpcSetType` inside REST/SOAP functions | Configure REST Server `PrepareIn` and Webservice environments |
| CA2022 | Restricted function: StaticCall | CRITICAL | `StaticCall()` | `FWLoadModel()`, `FWLoadMenuDef()`, direct namespace calls |
| CA2023 | Restricted function: PTInternal | CRITICAL | `PTInternal()` | Prohibited without exception |
| CA2024 | Prohibited assignment: __cUserID | CRITICAL | `__cUserID := ...` | Never assign — read-only system variable |
| CA2025 | Prohibited assignment: cEmpAnt | CRITICAL | `cEmpAnt := ...` | Never assign — use environment APIs |
| CA2050 | SQL Injection | INFO* | Concatenating user input in SQL strings | `FWPreparedStatement` |
| CA2051 | SQL Injection (Embedded SQL) | INFO* | Concatenating user input in Embedded SQL | `FWPreparedStatement` |
| CA2052 | Exposed password in source code | INFO* | Hardcoded credentials | Environment variables or AppServer configuration |
| CA2053 | Procedure created directly in source | CRITICAL | `CREATE PROCEDURE` in AdvPL/TLPP source | Manage procedures via SPManager |
| BG1200 | ErrorBlock override | INFO | `ErrorBlock({...})` | `Try-Catch` (TLPP) |

---

## G2 — Performance and Loops

| Rule | Title | Severity | Prohibited API / Pattern | Required Alternative |
|------|-------|----------|--------------------------|----------------------|
| CA1002 | UI API inside a transaction | MAJOR | `MsgAlert()`, `MsgYesNo()`, `MsgInfo()`, `Aviso()`, `Help()`, `Pergunte()`, `ParamBox()` inside `Begin Transaction`/`End Transaction` or MVC commit handlers | Move UI calls outside the transaction scope |
| CA1003 | Prohibited API inside a loop | MAJOR | `GetMV()`, `SuperGetMV()`, `ExistBlock()`, `AllUsers()` inside `While`/`For`/`Do While` | Cache the result before the loop |
| CA1003-2 | API in loop (under review) | MAJOR | `Type()`, `Pergunte()` inside loops | Cache the result before the loop |
| CS1000 | Direct query in AdvPL/TLPP | MAJOR | Raw SQL queries without evaluation | Evaluate Cloud impact; prefer framework APIs / `ChangeQuery()` / `BeginSQL` |

---

## G3 — Legacy and Deprecated Code

| Rule | Title | Severity | Prohibited API / Pattern | Required Alternative |
|------|-------|----------|--------------------------|----------------------|
| CA1000 | ISAM driver access | MAJOR | `MSCREATE()`, `DBCREATE()`, `CRIATRAB(.T.)`, `COPY TO` | `FWTemporaryTable` with relational mode |
| CA1001 | Disk exclusive lock | MAJOR | File-based semaphores, exclusive file lock | `LockByName()` |
| CA1001-2 | SmartERP shared-filesystem offender | MAJOR | Shared-filesystem operations | Database or network semaphores |
| CA1004 | Console API prohibited | MINOR | `ConOut()`, `CONOUT()`, `OutErr()`, `?` statement | `FWLogMsg()` |
| CA1006 / CA2020 | Deprecated function/class | MINOR | `AllUsers()` | `FWSFALLUSERS()` |
| CA2014 | PutSX1 deprecated | INFO | `PutSX1()` | Standard SX1 API |
| CA2015 | FormCommit override | INFO | Overriding the `FormCommit` method directly | `FWModelEvent` for commit interception; `FWFormCommit(oModel)` for the standard commit |
| CA2017–CA2019 | Prohibited SPF/binary APIs | CRITICAL | SPF table access, binary read/write functions | Framework APIs |
| BG1100 | Deprecated functions (generic) | INFO | Various deprecated functions | See function-specific documentation |
| CA3001 | Include must be lowercase | MINOR | `#INCLUDE "TOTVS.CH"` | `#include "totvs.ch"` |
| CA3002 | Incorrect inheritance naming | MINOR | `LongClassName` in class inheritance | `LongNameClass` |
| CA4000 | IIF prohibited (clean code) | INFO | `IIF()` / `IF()` inline ternary | `If/Else/EndIf` block |

### Obsolete Include Directives (flag and replace)

| Obsolete Include | Replacement Include | Modern Class/API |
|------------------|---------------------|------------------|
| `Ap5Mail.ch` | `totvs.ch` | `TMailMessage()` |
| `ApWizard.ch` | `totvs.ch` | `FWWizardControl()` |
| `FileIO.ch` | `totvs.ch` | `FWFileWriter()` / `FWFileReader()` |
| `Font.ch` | `totvs.ch` | `TFont()` |
| `ParmType.ch` | `totvs.ch` | `Default` prefix for parameter handling |
| `protheus.ch` | `totvs.ch` | — |
| `RWMake.ch` | `totvs.ch` | — |

---

## G4 — Metadata (Direct SX* Access Prohibited)

Direct access to Protheus system tables (SX*) via `DbSelectArea` is prohibited. Always use the
framework APIs. The `-2` variant flags the lower-severity indirect-access case.

| Rule | Table | Severity | Required API |
|------|-------|----------|--------------|
| CA2000 | SM0 (Companies) | CRITICAL | Standard company APIs |
| CA2001 / CA2001-2 | SIX (Indexes) | CRITICAL / MINOR | Standard index APIs (indirect access) |
| CA2002 / CA2002-2 | SX1 (Parameters / Pergunte) | CRITICAL / MINOR | `Pergunte()` |
| CA2003 / CA2003-2 | SX2 (Tables) | CRITICAL / MINOR | `RetSqlName()`, `X2Nome()` |
| CA2004 / CA2004-2 | SX3 (Fields) | CRITICAL / MINOR | `FWSX3Util()`, `FWFormStruct()` |
| CA2005 / CA2005-2 | SX7 (Triggers) | CRITICAL / MINOR | Standard trigger APIs (indirect) |
| CA2006 / CA2006-2 | SX9 (Relationships) | CRITICAL / MINOR | Standard relationship APIs (indirect) |
| CA2007 | SXA (Folders) | CRITICAL | Standard folder APIs (indirect) |
| CA2008 / CA2008-2 | SXB (Validations) | CRITICAL / MINOR | Standard validation APIs (indirect) |
| CA2009 / CA2009-2 | SX5 (Lookup Tables) | MAJOR / MINOR | Standard SX5 APIs |
| CA2010 / CA2010-2 | SX6 (System Parameters) | MAJOR / MINOR | `GetMV()` / `SuperGetMV()` |
| CA2011 / CA2011-2 | SXG (Sequences) | CRITICAL / MINOR | Standard sequence APIs |
| CA2012 / CA2012-2 | SXD (Scheduler) | MAJOR / MINOR | `SchedDef` |
| CA2013 | SX8–SXZ, XX?, SPF | CRITICAL | Framework APIs |
| CA2021 | SE5 (Cash Movements) | MAJOR | `FKx` family + `ExecAuto` |

---

## G5 — Compilation / Clean Code

| Rule | Title | Severity | Description |
|------|-------|----------|-------------|
| CA0000 | Compilation error | MAJOR | Invalid syntax, wrong charset (use Windows-1252), invalid block closure |
| CA1005 | INI references (SmartERP) | MINOR | References to INI files need evaluation for Cloud compatibility |
| CA2016 | Log/error without I18N | MINOR | Error messages and logs should use internationalization strings |

---

## Rule Groups — Quick Index

| Group | Focus | Rules |
|-------|-------|-------|
| G1 — Security | Injection, credentials, restricted APIs | BG1000, BG1200, CA2022, CA2023, CA2024, CA2025, CA2050, CA2051, CA2052, CA2053 |
| G2 — Performance | Loops, transactions, queries | CA1002, CA1003, CA1003-2, CS1000 |
| G3 — Legacy | Deprecated APIs, ISAM, console, includes | CA1000, CA1001, CA1001-2, CA1004, CA1006/CA2020, CA2014, CA2015, CA2017–CA2019, BG1100, CA3001, CA3002, CA4000 |
| G4 — Metadata | Direct SX* table access | CA2000–CA2013, CA2021 (+ `-2` variants) |
| G5 — Compilation | Syntax, encoding, I18N | CA0000, CA1005, CA2016 |

## Mapping to Internal Review IDs

This skill's native rule IDs map to the SonarQube codes as follows:

| Internal Category | Internal Prefix | SonarQube Group | Representative SonarQube Rules |
|-------------------|-----------------|-----------------|-------------------------------|
| Security | `SEC` | G1 | CA2050, CA2051, CA2052, CA2022–CA2025, BG1000 |
| Performance | `PERF` | G2 | CA1002, CA1003, CS1000 |
| Best Practices | `BP` | G3, G4, G5 | CA1000, CA1001, CA1004, CA2000–CA2021, CA0000, CA2016 |
| Modernization | `MOD` | G3 (INFO) | BG1200, CA2014, CA2015, CA4000, CA3001 |

When reporting a finding, cite both IDs where possible, e.g.
`[SEC-001 / CA2051] CRITICAL: SQL injection in Embedded SQL`.
