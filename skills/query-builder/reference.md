# Protheus Query Builder

## Overview

Build correct, safe, and optimized SQL queries for Protheus ERP tables. Protheus has unique database conventions — mandatory soft-delete filters, multi-branch filtering, Hungarian-notation field names, dictionary-driven physical schemas, and specific SIX index patterns — that every query must respect. This skill helps the agent **choose the right pattern** (Workarea vs Embedded SQL vs TCSqlExec), **enforce mandatory filters**, **align WHERE order to indexes**, and **parameterize all dynamic values** to prevent SQL injection.

> **Companion skill:** `embedded-sql` covers `BeginSQL/EndSQL` macros (`%table%`, `%notDel%`, `%xfilial%`, `%exp%`). This skill covers everything *around* the query: pattern choice, indexes, security, cross-database concerns.

## When to Use

- Building any SQL query against Protheus tables (SA1, SE1, SF2, custom Z*)
- Choosing between Workarea (`DbSelectArea`/`DbSeek`) and Embedded SQL
- Enforcing mandatory filters (`D_E_L_E_T_`, `XX_FILIAL`) on existing code
- Adding `FWPreparedStatement` to eliminate SQL injection risks
- Optimizing slow queries by aligning WHERE clauses to SIX indexes
- Writing cross-database code (PostgreSQL / MSSQL / Oracle)
- During code review, refactoring, or migration when SQL hygiene must be verified

## Bundled References

| File | Read When |
|---|---|
| [`patterns-workarea.md`](patterns-workarea.md) | Generating record-by-record code with `DbSelectArea` + `DbSeek` + `RecLock` |
| [`patterns-fwpreparedstatement.md`](patterns-fwpreparedstatement.md) | Building parameterized `TCQuery`/`TCSqlExec`, LIKE clauses, INSERT/UPDATE/DELETE |
| [`index-awareness.md`](index-awareness.md) | Choosing/validating index, ordering WHERE clauses, common SIX key expressions |
| [`cross-database.md`](cross-database.md) | Using `ChangeQuery()`, `TCGetDB()`, DBAccess macros, MSSQL ⇄ PG ⇄ Oracle equivalents |
| `../embedded-sql/reference.md` | Using `BeginSQL/EndSQL` macros (`%table%`, `%notDel%`, `%xfilial%`, `%exp%`) |
| `../protheus-reference/sx-dictionary.md` | Looking up table prefixes, field naming, dictionary tables |

## Protheus Database Conventions

### Table Naming

Protheus aliases follow `XXN` where `XX` is the module prefix and `N` is a sequence digit:

| Prefix | Module | Example Tables |
|---|---|---|
| SA | Customers/Vendors | SA1 (Clients), SA2 (Vendors), SA3 (Salespeople) |
| SB | Products | SB1 (Products), SB2 (Stock Balances), SB5 (Supplements) |
| SC | Orders | SC1 (Purchase Requests), SC5 (Sales Orders Header), SC6 (Sales Orders Items), SC7 (POs) |
| SD | Documents | SD1 (Inbound Items), SD2 (Outbound Items), SD3 (Internal Movements) |
| SE | Financial | SE1 (Receivables), SE2 (Payables), SE5 (Cash Movements) |
| SF | Invoices | SF1 (Inbound Headers), SF2 (Outbound Headers) |
| SX/SI | Data Dictionary | SX1, SX2, SX3, SX5, SX6, SX7, SIX |
| Z* / ZZ* | Custom | Customer-created tables (Z01–Z99, ZA0–ZAZ, ZZ1–ZZZ) |

### Physical Table Names

The physical table name in the database appends company code + branch padding. **Never hardcode** physical names — always resolve via `RetSqlName()`:

```advpl
Local cTbl := RetSqlName("SA1")  // Returns "SA1010" or env-specific name
```

| Alias | Typical Physical Name | Rule |
|---|---|---|
| SA1 | SA1010 | Alias + Company ("01") + Padding ("0") |
| SE1 | SE1010 | Same pattern |

### Field Naming

Fields follow `XX_FIELD` matching the table prefix:

| Table | Field | Meaning |
|---|---|---|
| SA1 | A1_COD | Customer code |
| SA1 | A1_NOME | Customer name |
| SE1 | E1_VALOR | Receivable amount |
| SF2 | F2_DOC | Outbound invoice number |

### Mandatory System Fields

**Every Protheus query MUST include both filters:**

| Field | Filter | Purpose |
|---|---|---|
| `D_E_L_E_T_` | `= ' '` (single space) | Soft-delete flag. `'*'` = logically deleted |
| `XX_FILIAL` | `= xFilial("XXX")` or `FWxFilial("XXX")` | Multi-branch filter |

```sql
SELECT A1_COD, A1_NOME
FROM SA1010 SA1
WHERE SA1.D_E_L_E_T_ = ' '
  AND SA1.A1_FILIAL = '01'
```

> **Warning:** Omitting `D_E_L_E_T_` returns deleted records. Omitting the branch filter leaks data across branches — usually wrong, often a security issue.

## Decision Matrix: Workarea vs Embedded SQL vs TCSqlExec

| Criterion | Workarea (DbSeek) | Embedded SQL (TCQuery) | TCSqlExec (DML) |
|---|---|---|---|
| Single record lookup by key | **Best** | Acceptable | — |
| Sequential scan by index | **Best** | Acceptable | — |
| Multi-table joins | Poor (nested seeks) | **Best** | — |
| Aggregations (SUM/COUNT/AVG) | Very poor | **Best** | — |
| Large result sets | Good (memory control) | Good (mind alias cleanup) | — |
| Record locking for update | **Required** (`RecLock`) | — | Bypasses locks |
| Performance (key-based) | **Fastest** | Slight overhead | Fastest write |
| Dictionary triggers (SX7) fire | **Yes** | No | **No** |
| Index requirement | Must have suitable SIX | Any column | Any column |
| Code readability for joins | Poor | **Best** | — |

### Rules of Thumb

- **CRUD on a single record:** Workarea + `RecLock`/`MsUnlock` (triggers fire automatically).
- **Reporting / aggregation / joins:** Embedded SQL via `BeginSQL/EndSQL` (preferred) or `FWPreparedStatement` + `TCGenQry`.
- **Bulk DML (UPDATE/DELETE/INSERT) bypassing triggers:** `TCSqlExec` with `FWPreparedStatement` — only when triggers and validations are explicitly not desired.

> **Default to BeginSQL/EndSQL** for SELECT queries. Use raw `FWPreparedStatement` + `TCGenQry` only when BeginSQL macros do not fit (e.g., dynamic table names, optional WHERE blocks).

## SQL Injection Prevention — The Hard Rule

**Never concatenate user input directly into SQL strings.** Always use `FWPreparedStatement` with `?` placeholders for any value that comes from outside the function (form fields, REST payloads, `MV_*` parameters, table fields read at runtime).

```advpl
// DANGEROUS — vulnerable to SQL injection
cQuery += "AND A1_COD = '" + cUserInput + "'"

// SAFE — parameterized
oStmt := FWPreparedStatement():New()
oStmt:SetQuery("SELECT A1_COD, A1_NOME FROM " + RetSqlName("SA1") + " " + ;
               "WHERE D_E_L_E_T_ = ' ' AND A1_FILIAL = ? AND A1_COD = ?")
oStmt:SetString(1, xFilial("SA1"))
oStmt:SetString(2, cUserInput)
```

See [`patterns-fwpreparedstatement.md`](patterns-fwpreparedstatement.md) for full templates including LIKE, IN-lists, and TCSqlExec.

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| Missing `D_E_L_E_T_` filter | Returns deleted records | Always `WHERE D_E_L_E_T_ = ' '` (every joined table too) |
| Missing branch filter | Leaks data across branches | `AND XX_FILIAL = xFilial('XXX')` |
| `SELECT *` | Returns dozens of system fields, slow | List only required columns |
| Hardcoded `SA1010` | Breaks across environments | `RetSqlName("SA1")` |
| Hardcoded `'01'` for branch | Breaks multi-branch envs | `xFilial("SA1")` / `FWxFilial("SA1")` |
| String concat for user input | SQL injection | `FWPreparedStatement` + `?` placeholders |
| Macro execution `&cExpr` in SQL | SQL injection | Never use `&` to build SQL |
| `IIF()` inside SQL string | Banned by SonarQube ADVPL ruleset | Use SQL `CASE WHEN` or AdvPL `If/Else` |
| `D_E_L_E_T_` filter missing on JOINed table | Returns deleted joined rows | Add `D_E_L_E_T_ = ' '` to every JOIN |
| Hard-coded `WITH (NOLOCK)` hint | DB-specific; no documented portable `%nolock%` macro (TDN) | Do not hard-code locking hints; keep queries selective and write transactions short |
| Forgetting `(cAlias)->(DBCloseArea())` | Alias leak (limited pool) | Always close, even on error paths |
| `GetMV()` / `ExistBlock()` inside loops | Re-evaluated every iteration | Cache to a local before the loop |
| `CREATE PROCEDURE` in source | Banned by TOTVS standards | Use SPManager for procedures |
| `DbSelectArea("SX2")` / `("SX3")` / `("SIX")` | Direct dictionary access banned | Use `RetSqlName()`, `FWSX3Util()`, dictionary APIs |

## Mandatory Checklist

### Correctness
- [ ] `D_E_L_E_T_ = ' '` for **every** table referenced (FROM and every JOIN)
- [ ] `XX_FILIAL` filter for **every** table (use `xFilial()` / `FWxFilial()`)
- [ ] Physical name resolved via `RetSqlName("XXX")` — never hardcoded
- [ ] No hardcoded company/branch codes
- [ ] Alias created with `GetNextAlias()`
- [ ] `(cAlias)->(DBCloseArea())` called in all paths (success + error)

### Security
- [ ] All dynamic values bound via `FWPreparedStatement` `?` placeholders
- [ ] No `&` macro execution to build SQL strings
- [ ] No `IIF()` in SQL — use `CASE WHEN` or `If/Else`
- [ ] No `CREATE PROCEDURE` in source

### Performance
- [ ] Only required fields in `SELECT` (no `SELECT *`)
- [ ] WHERE clause column order matches the SIX index key expression — see [`index-awareness.md`](index-awareness.md)
- [ ] No hard-coded locking hints (`WITH (NOLOCK)`) — not portable across databases
- [ ] `JOIN` columns are indexed
- [ ] Pagination (`FETCH FIRST` / `LIMIT`) for large result sets
- [ ] `GetMV()` / `ExistBlock()` cached before loops

### Cross-Database
- [ ] ANSI-compatible SQL where possible (`COALESCE`, `CASE WHEN`, `CONCAT`, `FETCH FIRST`)
- [ ] `ChangeQuery()` applied when raw SQL uses dialect-specific syntax (TCQuery only — BeginSQL applies it automatically)
- [ ] DB-specific branches wrapped in `Do Case` on `TCGetDB()` when no portable alternative exists

## Workarea Save/Restore Pattern

Always preserve and restore the calling area when manipulating workareas — the caller may be iterating its own cursor:

```advpl
Local aArea     := GetArea()              // Save current area + indices
Local aAreaSA1  := SA1->(GetArea())       // Save target table area too

DbSelectArea("SA1")
SA1->(DbSetOrder(1))
// ...

SA1->(RestArea(aAreaSA1))
RestArea(aArea)
```

For Embedded SQL queries that don't open a workarea on a Protheus table (only on the result alias), `GetArea()`/`RestArea()` is still recommended around the function entry/exit.

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| Query returns deleted records | Missing `D_E_L_E_T_ = ' '` | Add to every table including JOINs |
| Query returns rows from other branches | Missing `XX_FILIAL` filter | Add `xFilial()` filter |
| `Object Not Found` on `(cAlias)->FIELD` | Alias not opened or already closed | Check `DBUseArea` return; verify ordering |
| Wrong physical table in another env | Hardcoded name like `SA1010` | Replace with `RetSqlName("SA1")` |
| Query slow on SD1/SD2 | Full table scan, no index match | Reorder WHERE to match SIX key — see `index-awareness.md` |
| Deadlocks on read queries (MSSQL) | Long writer transactions / lock ordering | Shorten transactions and fix lock order; do not hard-code `NOLOCK` (see `protheus-locks-deadlocks`) |
| `Invalid column name` on PostgreSQL/Oracle | MSSQL-specific function | Use ANSI alternative or `ChangeQuery()` |
| `Cannot open more files` | Alias leak (forgot `DBCloseArea`) | Audit all error paths |

## Attribution

Patterns and reference tables in this skill are derived from TOTVS Engenharia Protheus public skill `query-builder` (MIT license) and adapted to the `advpl-specialist` plugin conventions.
