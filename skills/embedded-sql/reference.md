# Embedded SQL in ADVPL/TLPP

## Overview

Embedded SQL allows writing SQL queries directly in ADVPL/TLPP code using `BeginSQL ... EndSQL` blocks with special macro expressions. It replaces error-prone string concatenation (`cQuery += "SELECT..."`) with readable, type-safe, and maintainable SQL blocks.

`%exp:` inserts a value into the SQL text — it is **not** a bind parameter. Values typed by the user or received from outside go through `FWPreparedStatement` (see [SQL Injection and User Input](#sql-injection-and-user-input)).

## When to Use

- Writing SQL queries whose text is fixed and whose values are internal to the routine (prefer over string concatenation)
- Need to query with proper filial filtering, deletion handling, and table naming
- Building reports with complex SELECT, JOIN, GROUP BY
- Replacing `TCQuery` with concatenated strings (when a value comes from the user or from outside, migrate to `FWPreparedStatement` instead)
- When readability and maintainability of SQL code matters

## BeginSQL vs TCQuery (String Concatenation)

| Aspect | BeginSQL (Modern) | TCQuery + Strings (Legacy) |
|--------|-------------------|---------------------------|
| Readability | SQL written naturally | SQL buried in string concat |
| Table names | `%table:SE2%` automatic | `RetSqlName("SE2")` manual |
| Filial filter | `%xfilial:SE2%` automatic | `xFilial("SE2")` manual |
| Deletion filter | `%notDel%` automatic | `D_E_L_E_T_ = ' '` manual |
| Variable values | `%exp:cVar%` (value inserted into the SQL text, no manual quoting) | `"'" + cVar + "'"` (manual quoting) |
| Column types | `column X as Date` | `TCSetField` manual |
| Maintenance | Easy to read and modify | Hard to find errors in strings |
| SQL injection | `%exp:` is not a bind parameter: internal values only; user/external input → `FWPreparedStatement` | Vulnerable |

**Prefer BeginSQL for new code with internal values; use `FWPreparedStatement` for user/external input.**

## Core Syntax

```advpl
BeginSQL Alias cAlias
    SELECT columns
    FROM %table:ALIAS% ALIAS
    WHERE ALIAS.%notDel%
    AND ALIAS.FIELD_FILIAL = %xfilial:ALIAS%
    AND ALIAS.FIELD = %exp:cVariable%
    ORDER BY %Order:ALIAS%
EndSQL
```

**Important:** The alias parameter can be a string literal or `GetNextAlias()`:

```advpl
Local cAlias := GetNextAlias()
Local aNomes := {}

BeginSQL Alias cAlias
    SELECT A1_COD, A1_LOJA, A1_NOME
    FROM %table:SA1% SA1
    WHERE SA1.%notDel%
    AND SA1.A1_FILIAL = %xfilial:SA1%
EndSQL

DbSelectArea(cAlias)
While !Eof()
    aAdd(aNomes, (cAlias)->A1_NOME)
    DbSkip()
EndDo
DbCloseArea()
```

## Special Macro Expressions

### %table:TABLE%

Resolves the physical table name with proper database schema/owner.

```advpl
-- Input:
FROM %table:SA1% SA1

-- Expands to (example):
FROM SA1010 SA1
-- (where 010 = company code, depends on environment)
```

### %xfilial:TABLE%

Returns the current branch (filial) value for the table.

```advpl
-- Input:
AND SA1.A1_FILIAL = %xfilial:SA1%

-- Expands to:
AND SA1.A1_FILIAL = '01'
-- (or '' if table is not branch-filtered)
```

### %notDel%

Filters out logically deleted records.

```advpl
-- Input:
WHERE SA1.%notDel%

-- Expands to (TDN):
WHERE SA1.D_E_L_E_T_ = ' '
```

**Always include this.** Protheus uses logical deletion, not physical.

### %exp:EXPRESSION%

Inserts the value of an ADVPL variable, expression, or function result into the SQL text. Accepted value types are C, D, N, and L; any other type aborts with `Query Argument Error: Invalid Value Type` (TDN).

```advpl
// Internal values (literals and a date built by the routine).
// Text typed by the user or received from outside goes through FWPreparedStatement.
Local cCodCli := "000001"
Local cLoja   := "01"
Local dDataIni := CtoD("01/01/2026")

BeginSQL Alias cAlias
    SELECT E2_PREFIXO, E2_NUM, E2_VALOR, E2_EMISSAO
    FROM %table:SE2% SE2
    WHERE SE2.%notDel%
    AND SE2.E2_FILIAL  = %xfilial:SE2%
    AND SE2.E2_FORNECE = %exp:cCodCli%
    AND SE2.E2_LOJA    = %exp:cLoja%
    AND SE2.E2_EMISSAO >= %exp:DtoS(dDataIni)%
EndSQL
```

**`%exp:` is not a bind parameter.** The precompiler turns `%exp:cVar%` into `'+___SQLGetValue(CVAR)+'`: the value is concatenated into the statement text at run time (precompiled code shown on the TDN "Embedded SQL" page). Character values come out delimited by `___SQLGetValue()` (the precompiled code adds no quotes around it), so the examples write no quotes; how a `'` inside the value is treated is not documented (a confirmar no TDS). TDN sources also wrap a raw SQL fragment as `"%" + cFragmento + "%"`, which suggests that a value starting and ending with `%` (such as a LIKE pattern) reaches the SQL unquoted (a confirmar no TDS).

Use `%exp:` only with values the routine itself controls (literals, `DtoS()` of a date, numbers it computes, `xFilial()`); user/external input goes through `FWPreparedStatement` — see [SQL Injection and User Input](#sql-injection-and-user-input). For dates, use `DtoS()` to convert.

### %Order:TABLE%

Returns the primary key ordering for the table.

```advpl
-- Input:
ORDER BY %Order:SE2%

-- Expands to the primary key columns of SE2
```

## Column Type Declaration

Declare result column types to avoid manual `TCSetField` calls:

```advpl
Local cAlias   := GetNextAlias()
Local dEmissao := CtoD("")
Local nValor   := 0

BeginSQL Alias cAlias
    column E2_EMISSAO as Date
    column E2_VENCTO  as Date
    column E2_VALOR   as Numeric(16,2)

    SELECT E2_PREFIXO, E2_NUM, E2_EMISSAO, E2_VENCTO, E2_VALOR
    FROM %table:SE2% SE2
    WHERE SE2.%notDel%
    AND SE2.E2_FILIAL = %xfilial:SE2%
EndSQL

// Columns are automatically typed - no TCSetField needed
DbSelectArea(cAlias)
While !Eof()
    dEmissao := (cAlias)->E2_EMISSAO   // Already Date type
    nValor   := (cAlias)->E2_VALOR     // Already Numeric
    DbSkip()
EndDo
```

**Without `column` declaration**, all fields return as Character and need manual conversion.

## JOIN Patterns

### INNER JOIN

```advpl
BeginSQL Alias cAlias
    SELECT SE2.E2_PREFIXO, SE2.E2_NUM, SE2.E2_VALOR,
           SA2.A2_NOME, SA2.A2_CGC
    FROM %table:SE2% SE2
    INNER JOIN %table:SA2% SA2
        ON SE2.E2_FORNECE = SA2.A2_COD
        AND SE2.E2_LOJA   = SA2.A2_LOJA
        AND SA2.A2_FILIAL = %xfilial:SA2%
        AND SA2.%notDel%
    WHERE SE2.%notDel%
    AND SE2.E2_FILIAL = %xfilial:SE2%
    AND SE2.E2_EMISSAO >= %exp:DtoS(dDataIni)%
    ORDER BY SE2.E2_EMISSAO
EndSQL
```

### LEFT JOIN

```advpl
BeginSQL Alias cAlias
    SELECT SC5.C5_NUM, SC5.C5_CLIENTE, SC5.C5_LOJACLI,
           SA1.A1_NOME
    FROM %table:SC5% SC5
    LEFT JOIN %table:SA1% SA1
        ON SC5.C5_CLIENTE = SA1.A1_COD
        AND SC5.C5_LOJACLI = SA1.A1_LOJA
        AND SA1.A1_FILIAL = %xfilial:SA1%
        AND SA1.%notDel%
    WHERE SC5.%notDel%
    AND SC5.C5_FILIAL = %xfilial:SC5%
EndSQL
```

**Best practice:** Always use explicit JOIN syntax, not comma-separated FROM.

## Aggregation Patterns

### SUM / COUNT / AVG

```advpl
BeginSQL Alias cAlias
    column TOTAL as Numeric(16,2)
    column QTD   as Numeric(10,0)

    SELECT SE2.E2_FORNECE, SE2.E2_LOJA,
           SUM(SE2.E2_VALOR) AS TOTAL,
           COUNT(*) AS QTD
    FROM %table:SE2% SE2
    WHERE SE2.%notDel%
    AND SE2.E2_FILIAL = %xfilial:SE2%
    AND SE2.E2_EMISSAO BETWEEN %exp:DtoS(dDataIni)% AND %exp:DtoS(dDataFim)%
    GROUP BY SE2.E2_FORNECE, SE2.E2_LOJA
    HAVING SUM(SE2.E2_VALOR) > 0
    ORDER BY TOTAL DESC
EndSQL
```

### Subquery

```advpl
BeginSQL Alias cAlias
    SELECT SA1.A1_COD, SA1.A1_NOME
    FROM %table:SA1% SA1
    WHERE SA1.%notDel%
    AND SA1.A1_FILIAL = %xfilial:SA1%
    AND SA1.A1_COD IN (
        SELECT SC5.C5_CLIENTE
        FROM %table:SC5% SC5
        WHERE SC5.%notDel%
        AND SC5.C5_FILIAL = %xfilial:SC5%
        AND SC5.C5_EMISSAO >= %exp:DtoS(dDataIni)%
    )
EndSQL
```

## Complete Pattern: Query with Cursor Iteration

```advpl
#include "totvs.ch"
#include "topconn.ch"

User Function QueryEx()
    Local cAlias := GetNextAlias()
    Local aArea  := GetArea()
    Local aResult := {}
    Local dDataIni := Date() - 30

    BeginSQL Alias cAlias
        column E2_EMISSAO as Date
        column E2_VENCTO  as Date
        column E2_VALOR   as Numeric(16,2)
        column SALDO      as Numeric(16,2)

        SELECT SE2.E2_PREFIXO, SE2.E2_NUM, SE2.E2_PARCELA,
               SE2.E2_FORNECE, SE2.E2_LOJA,
               SE2.E2_EMISSAO, SE2.E2_VENCTO,
               SE2.E2_VALOR,
               SE2.E2_SALDO AS SALDO,
               SA2.A2_NOME
        FROM %table:SE2% SE2
        INNER JOIN %table:SA2% SA2
            ON SE2.E2_FORNECE = SA2.A2_COD
            AND SE2.E2_LOJA   = SA2.A2_LOJA
            AND SA2.A2_FILIAL = %xfilial:SA2%
            AND SA2.%notDel%
        WHERE SE2.%notDel%
        AND SE2.E2_FILIAL = %xfilial:SE2%
        AND SE2.E2_EMISSAO >= %exp:DtoS(dDataIni)%
        AND SE2.E2_SALDO > 0
        ORDER BY SE2.E2_VENCTO
    EndSQL

    DbSelectArea(cAlias)
    While !(cAlias)->(Eof())
        aAdd(aResult, {;
            (cAlias)->E2_PREFIXO,;
            (cAlias)->E2_NUM,;
            (cAlias)->E2_VALOR,;
            (cAlias)->SALDO,;
            (cAlias)->A2_NOME;
        })
        (cAlias)->(DbSkip())
    EndDo
    (cAlias)->(DbCloseArea())

    RestArea(aArea)
Return aResult
```

## Restrictions and Gotchas

| Rule | Why |
|------|-----|
| Do NOT start a line with `*` inside BeginSQL | ADVPL pre-compiler treats `*` at line start as comment |
| Always include `%notDel%` | Protheus uses logical deletion, never rely on physical |
| Always include `%xfilial%` or filial filter | Multi-branch environments will return wrong data |
| Use `GetNextAlias()` for the alias | Avoids alias name conflicts with open work areas |
| Always `DbCloseArea()` after done | Prevents work area leaks (limited number of aliases) |
| Do NOT use `SELECT *` | Specify columns explicitly for performance and clarity |
| Date values must use `DtoS()` | Database stores dates as YYYYMMDD strings |
| `column` declarations go BEFORE the SELECT | They define result types, not query columns |
| `%exp:` only with internal values | It is not a bind parameter; user/external input goes through `FWPreparedStatement` |
| Do NOT use `?` in the query text or in `%exp:` values | `?` is reserved by Embedded SQL (TDN); in that case the TDN recommends `FWPreparedStatement` or `FWExecStatement` |

## SQL Injection and User Input

Embedded SQL removes manual quoting and the `RetSqlName`/`xFilial`/`D_E_L_E_T_` boilerplate, but `%exp:` still inserts each value into the SQL text (see `%exp:EXPRESSION%` above). Choose by the origin of each value:

| Value | Use |
|---|---|
| Fixed text, `xFilial()`, `DtoS()` of a date, numbers computed by the routine | `BeginSQL` + `%exp:` |
| Typed by the user (screen field, `Pergunte` answers in `MV_PAR*`), received from outside (REST/SOAP payload, file, integration), or any free text | `FWPreparedStatement` with `?` parameters |
| A raw SQL fragment received from the caller or built from user text | Never — build the clause from fixed text in the routine and pass only the values as `?` parameters |

> The TDN "Embedded SQL" examples pass `MV_PAR*` answers through `%exp:`. Since the escaping done by `___SQLGetValue()` is not documented (a confirmar no TDS), this plugin treats `Pergunte` answers as user input.

```advpl
// cNome is typed by the user: it goes as a ? parameter, never through %exp:
Local cAlias := GetNextAlias()
Local oStmt  := FWPreparedStatement():New()
Local cQuery := ""

cQuery := "SELECT A1_COD, A1_LOJA, A1_NOME FROM " + RetSqlName("SA1") + " SA1 "
cQuery += "WHERE SA1.D_E_L_E_T_ = ' ' AND SA1.A1_FILIAL = ? AND SA1.A1_NOME LIKE ? "

oStmt:SetQuery(cQuery)
oStmt:SetString(1, xFilial("SA1"))
oStmt:SetString(2, AllTrim(cNome) + "%")   // a ' typed in cNome stays part of the value (TDN)
DbUseArea(.T., "TOPCONN", TCGenQry(,, oStmt:GetFixQuery()), cAlias, .F., .T.)
// ... read (cAlias)->A1_COD, (cAlias)->A1_NOME ...
(cAlias)->(DbCloseArea())
oStmt:Destroy()
```

Full patterns (JOIN, DML, LIKE, IN-list): `skills/query-builder/patterns-fwpreparedstatement.md` (query-builder skill).

## DML Operations

**BeginSQL is for SELECT only.** For UPDATE/DELETE use `TCSqlExec`, with the values passed as `FWPreparedStatement` parameters:

```advpl
// UPDATE: values go as ? parameters
Local oStmt := FWPreparedStatement():New()
Local cSql  := ""
Local nRet  := 0

cSql := "UPDATE " + RetSqlName("ZZ1") + " SET ZZ1_DESCRI = ? "
cSql += "WHERE ZZ1_FILIAL = ? AND ZZ1_CODIGO = ? AND D_E_L_E_T_ = ' '"

oStmt:SetQuery(cSql)
oStmt:SetString(1, cDescri)
oStmt:SetString(2, xFilial("ZZ1"))
oStmt:SetString(3, cCodigo)
nRet := TCSqlExec(oStmt:GetFixQuery())
oStmt:Destroy()

If nRet < 0
    FWLogMsg("ERROR", /*cTransactionId*/, "EMBEDDEDSQL", "DML", /*cStep*/, /*cMsgId*/, "SQL Error: " + TCSqlError())
EndIf
```

To insert a record, do not build an `INSERT` by hand: use the work area (`RecLock(cAlias, .T.)` + `MsUnlock()`, see `skills/query-builder/patterns-workarea.md`, Pattern 1.4). More `TCSqlExec` patterns: `skills/query-builder/patterns-fwpreparedstatement.md`.

## Performance Tips

1. **Use `column` declarations** to avoid post-query type conversions
2. **Use JOINs** instead of subqueries when possible
3. **Filter early** with WHERE, not after reading all rows in ADVPL
4. **No locking hints**: do not hard-code `WITH(NOLOCK)` — it exists only on SQL Server and allows dirty reads. `ChangeQuery()`, which Embedded SQL applies unless `%noparser%` is used, removes `NOLOCK`/`(NOLOCK)` from the query, and the TDN documents no `%nolock%` macro
5. **Use TOP N** when you only need limited results
6. **Close aliases** immediately after use to free work areas
7. **Avoid loops with BeginSQL inside** - build one query that returns all needed data

## Migration from TCQuery to BeginSQL

**Before (string concatenation):**

<!-- advpl-lint: anti-exemplo -->
```advpl
Local cQuery := ""
cQuery += "SELECT A1_COD, A1_NOME "
cQuery += "FROM " + RetSqlName("SA1") + " SA1 "
cQuery += "WHERE SA1.D_E_L_E_T_ = ' ' "
cQuery += "AND A1_FILIAL = '" + xFilial("SA1") + "' "
cQuery += "AND A1_TIPO = '" + cTipo + "'"
TCQuery cQuery New Alias "QRY_CLI"
```

**After (Embedded SQL) — `cTipo` is an internal value of the routine:**

```advpl
Local cAlias := GetNextAlias()
Local cTipo  := "F"   // set by the routine, not typed by the user

BeginSQL Alias cAlias
    SELECT A1_COD, A1_NOME
    FROM %table:SA1% SA1
    WHERE SA1.%notDel%
    AND SA1.A1_FILIAL = %xfilial:SA1%
    AND SA1.A1_TIPO = %exp:cTipo%
EndSQL
```

If `cTipo` comes from the user or from outside, migrate to `FWPreparedStatement` instead (see [SQL Injection and User Input](#sql-injection-and-user-input)).

Benefits: no manual `RetSqlName`, no `D_E_L_E_T_`, no `xFilial()`, no manual quoting. `%exp:` does not make the query injection-proof — it is not a bind parameter.
