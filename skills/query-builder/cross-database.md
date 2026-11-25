# Cross-Database Compatibility

Protheus officially supports **PostgreSQL**, **Microsoft SQL Server**, and **Oracle**. Generated code must run unmodified across all three. Use the framework tools below — `ChangeQuery()`, `TCGetDB()`, Embedded SQL macros — to abstract differences. When no portable alternative exists, branch with `Do Case` on `TCGetDB()`.

## ChangeQuery() — Dialect Translation

`ChangeQuery(cQuery)` translates a SQL string to the active database dialect before execution. It rewrites syntax such as `TOP n` → `LIMIT n` (PG) / `FETCH FIRST n ROWS ONLY` (Oracle), some date functions, and string operations.

```advpl
#include "totvs.ch"
#include "topconn.ch"

Local cQuery := ""
cQuery += "SELECT TOP 10 A1_COD, A1_NOME "
cQuery += "FROM " + RetSqlName("SA1") + " SA1 "
cQuery += "WHERE SA1.D_E_L_E_T_ = ' ' AND SA1.A1_FILIAL = '" + xFilial("SA1") + "'"

cQuery := ChangeQuery(cQuery)   // TOP 10 → LIMIT 10 (PG) or FETCH FIRST 10 ROWS ONLY (Oracle)
TCQuery cQuery New Alias "QRY1"
```

> **`BeginSQL/EndSQL` calls `ChangeQuery()` automatically** unless `%noparser%` is specified. For raw `TCQuery`/`TCGenQry`, call it explicitly.

## TCGetDB() — Runtime Database Detection

Use `TCGetDB()` when `ChangeQuery()` cannot bridge the gap (DB-specific functions, hints, system tables):

```advpl
Local cDB := TCGetDB()   // "MSSQL" | "ORACLE" | "POSTGRES"

Do Case
    Case cDB == "MSSQL"
        cExpr := "ISNULL(A1_NOME, '')"
    Case cDB == "ORACLE"
        cExpr := "NVL(A1_NOME, '')"
    Case cDB == "POSTGRES"
        cExpr := "COALESCE(A1_NOME, '')"
EndCase
```

> Prefer ANSI alternatives (`COALESCE`) over branching whenever possible — keeps code shorter and easier to test.

## Embedded SQL Macros (BeginSQL/EndSQL)

The TDN documents these `%...%` expressions for Embedded SQL (`BeginSQL`/`EndSQL`), where they are replaced by framework calls — the same on every database. In a raw SQL string (`TCQuery`, `TCGenQry`, `FWPreparedStatement`) use the equivalent functions (`RetSqlName()`, `xFilial()`, `D_E_L_E_T_ = ' '`).

| Macro | Replaced by (TDN) | Purpose |
|---|---|---|
| `%notDel%` | `D_E_L_E_T_ = ' '` | Soft-delete filter |
| `%table:XXX%` | `RetSqlName('XXX')` | Physical table name |
| `%xfilial:XXX%` | `xFilial('XXX')`, as a quoted literal | Branch filter |
| `%Order:XXX%` | `SqlOrder(XXX->(IndexKey()))` | Index-ordered column list |
| `%exp:cVar%` | the value, inserted into the SQL text (`___SQLGetValue()`) | Internal values only — not a bind parameter; user/external input goes through `FWPreparedStatement` ([`patterns-fwpreparedstatement.md`](patterns-fwpreparedstatement.md)) |
| `%noparser%` | — | Skips `ChangeQuery()`: the query reaches the database without dialect translation |

> The TDN documents no `%nolock%` macro (a confirmar no TDS) — see the locking-hint row in [Anti-Patterns](#anti-patterns).

## Cross-Database Function Equivalents

| Operation | ANSI / Cross-DB | MSSQL | PostgreSQL | Oracle |
|---|---|---|---|---|
| Null coalescing | `COALESCE(a, b)` | `ISNULL(a, b)` | `COALESCE(a, b)` | `NVL(a, b)` |
| String concat | `CONCAT(a, b)` | `a + b` | `a \|\| b` | `a \|\| b` |
| Current date | — | `GETDATE()` | `CURRENT_DATE` | `SYSDATE` |
| Current timestamp | — | `GETUTCDATE()` | `NOW()` | `SYSTIMESTAMP` |
| Row limiting | `FETCH FIRST n ROWS ONLY` | `TOP n` | `LIMIT n` | `FETCH FIRST n ROWS ONLY` |
| Pagination | `OFFSET x ROWS FETCH FIRST n ROWS ONLY` | `OFFSET x ROWS FETCH NEXT n ROWS ONLY` | `LIMIT n OFFSET x` | `OFFSET x ROWS FETCH FIRST n ROWS ONLY` |
| Substring | `SUBSTRING(s FROM start FOR len)` | `SUBSTRING(s, start, len)` | `SUBSTRING(s FROM start FOR len)` | `SUBSTR(s, start, len)` |
| Conditional | `CASE WHEN ... THEN ... END` | same | same | same |
| Type cast | `CAST(x AS type)` | same | same | same |
| Temp tables | use `FWTemporaryTable` | `#temp_name` | `CREATE TEMPORARY TABLE` | `CREATE GLOBAL TEMPORARY TABLE` |

## Date Handling

- Protheus stores dates in the database as **strings in `YYYYMMDD` format** (e.g., `'20260131'`).
- Convert AdvPL `Date` values with `DtoS(dDate)` before binding/comparing.
- Never use DB date functions to extract Y/M/D from these stored strings — use `SUBSTRING` or AdvPL post-processing.

```advpl
oStmt:SetString(1, DtoS(dDataIni))
oStmt:SetString(2, DtoS(dDataFim))

cQuery += "AND SE1.E1_EMISSAO BETWEEN ? AND ? "
```

## Pagination Pattern

```advpl
Local nPage     := 2
Local nPageSize := 50
Local nOffset   := (nPage - 1) * nPageSize
Local cQuery    := ""

cQuery += "SELECT A1_COD, A1_NOME "
cQuery += "FROM " + RetSqlName("SA1") + " SA1 "
cQuery += "WHERE SA1.D_E_L_E_T_ = ' ' "
cQuery +=   "AND SA1.A1_FILIAL = '" + xFilial("SA1") + "' "
cQuery += "ORDER BY SA1.A1_COD "
cQuery += "OFFSET " + cValToChar(nOffset) + " ROWS "
cQuery += "FETCH NEXT " + cValToChar(nPageSize) + " ROWS ONLY "

cQuery := ChangeQuery(cQuery)   // Translates to LIMIT/OFFSET on PG
```

> `OFFSET ... FETCH NEXT ... ROWS ONLY` is ANSI-compatible (SQL:2008). `ChangeQuery()` adapts it for PG (`LIMIT/OFFSET`).
>
> The raw strings on this page concatenate only framework values (`RetSqlName()`, `xFilial()`) and numbers computed by the routine. Text typed by the user or received in a request goes as a `?` parameter of `FWPreparedStatement` — see [`patterns-fwpreparedstatement.md`](patterns-fwpreparedstatement.md).

## Temporary Tables

Avoid raw DB-specific temp tables (`#tmp` on MSSQL, `CREATE TEMP TABLE` on PG). Use the framework class **`FWTemporaryTable`** — it abstracts naming, scoping, and cleanup:

```advpl
Local oTmp := FWTemporaryTable():New("XTMP1")
oTmp:SetFields( { ;
    { "X1_COD",  "C", 6, 0 }, ;
    { "X1_NAME", "C", 40, 0 } ;
} )
oTmp:Create()
// ... INSERT/SELECT against RetSqlName(oTmp:GetRealName()) ...
oTmp:Delete()
```

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| Raw `GETDATE()` in SQL | Breaks PG/Oracle | Use ANSI `CURRENT_DATE` or branch on `TCGetDB()` |
| `+` for string concat in SQL | Breaks PG/Oracle (need `\|\|`) | Use `CONCAT()` or build on AdvPL side |
| Hardcoded `WITH (NOLOCK)` | SQL Server-only hint: breaks PG/Oracle when the query skips `ChangeQuery()`, and allows dirty reads | Do not hard-code locking hints. `ChangeQuery()` removes `NOLOCK`/`(NOLOCK)` from the query (TDN), and the TDN documents no `%nolock%` macro |
| `ISNULL` outside MSSQL branch | Breaks PG/Oracle | Use `COALESCE` |
| `LIMIT n` without `ChangeQuery()` | Breaks MSSQL | Either `ChangeQuery()` or use `FETCH FIRST` |
| Building SQL strings dialect-aware by hand | Maintenance burden, easy to miss a path | Always run through `ChangeQuery()` and use macros |
| Non-ANSI date functions on `YYYYMMDD` strings | Wrong on every DB | Compare as strings or convert to date in AdvPL |
