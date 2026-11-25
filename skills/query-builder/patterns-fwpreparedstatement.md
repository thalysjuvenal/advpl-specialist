# Pattern: FWPreparedStatement (SQL Injection Prevention)

`FWPreparedStatement` is the Protheus framework's parameterized-query API. `:GetFixQuery()` returns the query with the `?` parameters already handled and substituted, ready for the database (TDN), and the result can be passed to `TCGenQry()` (SELECT) or `TCSqlExec()` (DML).

**Always use `FWPreparedStatement` when any value in the query comes from outside the function:**

- Form fields, `Pergunte` answers (`MV_PAR*`), REST payloads, SOAP arguments
- `MV_*` parameters (`GetMV()` results)
- Field values read from other tables at runtime
- Anything the operator can influence

> **BeginSQL/EndSQL fits static queries whose values are internal to the routine** (literals, `xFilial()`, `DtoS()` of a date, numbers it computes) and applies `ChangeQuery()` automatically. Its `%exp:` is **not** a bind parameter: the value is inserted into the SQL text (TDN "Embedded SQL", precompiled code with `___SQLGetValue`), so it does not replace this class for the values listed above — see `skills/embedded-sql/reference.md`. `FWPreparedStatement` is also the tool for what BeginSQL does not handle: optional WHERE blocks built at runtime and DML.

## API Quick Reference

| Method | Purpose |
|---|---|
| `:New()` | Create instance |
| `:SetQuery(cQuery)` | Set query template with `?` placeholders |
| `:SetString(n, cValue)` | Set 1-based parameter `n` to a string — a `'` inside `cValue` stays part of the value, not a delimiter (TDN) |
| `:SetNumeric(n, nValue)` | Set to numeric |
| `:SetDate(n, dValue)` | Set to date (Protheus date) |
| `:SetIn(n, aValues)` | Set an IN parameter from an array (see Pattern 2.6) |
| `:SetUnsafe(n, xValue)` | Insert the value without treatment — TDN: never with values received from a request; only for trusted values such as a dynamic table name |
| `:GetFixQuery()` | Return the query with the parameters handled and substituted |
| `:Destroy()` | Destroy the object when done |

## Pattern 2.1 — SELECT with FWPreparedStatement

```advpl
#include "totvs.ch"
#include "topconn.ch"

User Function GetCustBalance(cCustCode, cLoja)
    Local nBalance := 0
    Local cAlias   := GetNextAlias()
    Local oStmt    := FWPreparedStatement():New()
    Local cQuery   := ""

    cQuery := "SELECT SUM(E1_SALDO) AS BALANCE "
    cQuery += "FROM " + RetSqlName("SE1") + " SE1 "
    cQuery += "WHERE SE1.D_E_L_E_T_ = ' ' "
    cQuery +=   "AND SE1.E1_FILIAL = ? "
    cQuery +=   "AND SE1.E1_CLIENTE = ? "
    cQuery +=   "AND SE1.E1_LOJA = ? "
    cQuery +=   "AND SE1.E1_SALDO > 0 "

    oStmt:SetQuery(cQuery)
    oStmt:SetString(1, xFilial("SE1"))
    oStmt:SetString(2, cCustCode)
    oStmt:SetString(3, cLoja)

    DBUseArea(.T., "TOPCONN", TCGenQry(,, oStmt:GetFixQuery()), cAlias, .F., .T.)

    If !(cAlias)->(Eof())
        nBalance := (cAlias)->BALANCE
    EndIf

    (cAlias)->(DBCloseArea())
    oStmt:Destroy()
Return nBalance
```

### Key rules

- `?` placeholders are 1-based, in order of appearance.
- Bind **every** dynamic value — including `xFilial()`, even though it's framework-generated, to keep the pattern uniform.
- Only the physical table name (`RetSqlName()`, a framework value) is concatenated into the template; values never are.
- The result is read via `(cAlias)->FIELD`, never via `&` macro.
- Always close the alias and call `oStmt:Destroy()`.

## Pattern 2.2 — Multi-Table JOIN

```advpl
#include "totvs.ch"
#include "topconn.ch"

User Function InvoiceDetails(cInvDoc, cSerie)
    Local aResult := {}
    Local cAlias  := GetNextAlias()
    Local oStmt   := FWPreparedStatement():New()
    Local cQuery  := ""

    cQuery := "SELECT SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_EMISSAO, "
    cQuery +=        "SD2.D2_COD, SD2.D2_QUANT, SD2.D2_TOTAL, "
    cQuery +=        "SB1.B1_DESC "
    cQuery += "FROM " + RetSqlName("SF2") + " SF2 "
    cQuery += "INNER JOIN " + RetSqlName("SD2") + " SD2 "
    cQuery +=   "ON SD2.D_E_L_E_T_ = ' ' "
    cQuery +=  "AND SD2.D2_FILIAL = SF2.F2_FILIAL "
    cQuery +=  "AND SD2.D2_DOC    = SF2.F2_DOC "
    cQuery +=  "AND SD2.D2_SERIE  = SF2.F2_SERIE "
    cQuery += "INNER JOIN " + RetSqlName("SB1") + " SB1 "
    cQuery +=   "ON SB1.D_E_L_E_T_ = ' ' "
    cQuery +=  "AND SB1.B1_FILIAL = ? "
    cQuery +=  "AND SB1.B1_COD    = SD2.D2_COD "
    cQuery += "WHERE SF2.D_E_L_E_T_ = ' ' "
    cQuery +=   "AND SF2.F2_FILIAL = ? "
    cQuery +=   "AND SF2.F2_DOC    = ? "
    cQuery +=   "AND SF2.F2_SERIE  = ? "

    oStmt:SetQuery(cQuery)
    oStmt:SetString(1, xFilial("SB1"))
    oStmt:SetString(2, xFilial("SF2"))
    oStmt:SetString(3, cInvDoc)
    oStmt:SetString(4, cSerie)

    DBUseArea(.T., "TOPCONN", TCGenQry(,, oStmt:GetFixQuery()), cAlias, .F., .T.)

    While !(cAlias)->(Eof())
        aAdd(aResult, { ;
            AllTrim((cAlias)->F2_DOC), ;
            AllTrim((cAlias)->D2_COD), ;
            (cAlias)->D2_QUANT, ;
            (cAlias)->D2_TOTAL, ;
            AllTrim((cAlias)->B1_DESC) ;
        })
        (cAlias)->(DBSkip())
    EndDo

    (cAlias)->(DBCloseArea())
    oStmt:Destroy()
Return aResult
```

### JOIN Rules

- `D_E_L_E_T_ = ' '` and `XX_FILIAL` filters are required on **every** joined table.
- Filters that depend on the joined row should sit in the `ON` clause; filters on the driving table go in `WHERE`.
- Always JOIN on indexed columns when possible — see [`index-awareness.md`](index-awareness.md).

## Pattern 2.3 — UPDATE / DELETE / INSERT (TCSqlExec)

`TCSqlExec` writes in the database directly: no dictionary validations (`X3_VALID`) and no SX7 triggers run, and neither do they with Workarea + `RecLock`/`MsUnlock`. Use `TCSqlExec` for bulk operations and system-level fixes; for a single-record write, prefer Workarea + `RecLock`/`MsUnlock`. When the dictionary rules must run, use `MsExecAuto` with the routine's documented example, or the MVC model API.

```advpl
#include "totvs.ch"
#include "topconn.ch"

User Function UpdateCustFlag(cCustCode, cLoja, cFlag)
    Local nResult := 0
    Local oStmt   := FWPreparedStatement():New()
    Local cQuery  := ""

    cQuery := "UPDATE " + RetSqlName("SA1") + " "
    cQuery +=    "SET A1_XFLAG = ? "
    cQuery +=  "WHERE D_E_L_E_T_ = ' ' "
    cQuery +=    "AND A1_FILIAL = ? "
    cQuery +=    "AND A1_COD    = ? "
    cQuery +=    "AND A1_LOJA   = ? "

    oStmt:SetQuery(cQuery)
    oStmt:SetString(1, cFlag)
    oStmt:SetString(2, xFilial("SA1"))
    oStmt:SetString(3, cCustCode)
    oStmt:SetString(4, cLoja)

    nResult := TCSqlExec(oStmt:GetFixQuery())
    oStmt:Destroy()

    If nResult < 0
        FWLogMsg("ERROR", /*cTransactionId*/, "QUERYBUILDER", "UpdateCustFlag", /*cStep*/, /*cMsgId*/, "SQL error: " + TCSqlError())
    EndIf
Return (nResult == 0)
```

### TCSqlExec Rules

- Returns `0` on success, negative on error. Always check.
- On error, `TCSqlError()` returns the DBAccess message.
- Wrap in `BEGIN SEQUENCE / RECOVER USING / END SEQUENCE` for production code.
- **Do not** use `TCSqlExec` for `CREATE PROCEDURE`/`CREATE FUNCTION` — banned by TOTVS standards. Use SPManager.

## Pattern 2.4 — LIKE with Safe Wildcards

Build the `%` wildcards on the AdvPL side and bind the whole string. This avoids cross-DB concat operator differences (`+` vs `||` vs `CONCAT`).

```advpl
Local cSearchParam := "%" + AllTrim(cSearch) + "%"

cQuery := "SELECT A1_COD, A1_NOME "
cQuery += "FROM " + RetSqlName("SA1") + " SA1 "
cQuery += "WHERE SA1.D_E_L_E_T_ = ' ' "
cQuery +=   "AND SA1.A1_FILIAL = ? "
cQuery +=   "AND SA1.A1_NOME LIKE ? "

oStmt:SetQuery(cQuery)
oStmt:SetString(1, xFilial("SA1"))
oStmt:SetString(2, cSearchParam)
```

> Sanitize `cSearch` if needed — escape `%` and `_` if those characters should be matched literally.

## Pattern 2.5 — COUNT

```advpl
User Function CountActiveCust()
    Local nCount := 0
    Local cAlias := GetNextAlias()
    Local oStmt  := FWPreparedStatement():New()
    Local cQuery := ""

    cQuery := "SELECT COUNT(*) AS TOTAL "
    cQuery += "FROM " + RetSqlName("SA1") + " SA1 "
    cQuery += "WHERE SA1.D_E_L_E_T_ = ' ' "
    cQuery +=   "AND SA1.A1_FILIAL = ? "
    cQuery +=   "AND SA1.A1_MSBLQL <> '1' "

    oStmt:SetQuery(cQuery)
    oStmt:SetString(1, xFilial("SA1"))

    DBUseArea(.T., "TOPCONN", TCGenQry(,, oStmt:GetFixQuery()), cAlias, .F., .T.)

    If !(cAlias)->(Eof())
        nCount := (cAlias)->TOTAL
    EndIf

    (cAlias)->(DBCloseArea())
    oStmt:Destroy()
Return nCount
```

## Pattern 2.6 — IN-List with Dynamic Length

The TDN documents `SetIn(nParam, aValues)` for an IN parameter, but does not show whether the `?` must be written inside parentheses (a confirmar no TDS). The pattern below uses only `SetString`: build one `?` per item and bind them one by one:

```advpl
Local aCodes      := { "000001", "000002", "000003" }
Local cPlacehld   := ""
Local nI

For nI := 1 To Len(aCodes)
    If nI > 1
        cPlacehld += ","
    EndIf
    cPlacehld += "?"
Next

cQuery := "SELECT A1_COD, A1_NOME "
cQuery += "FROM " + RetSqlName("SA1") + " SA1 "
cQuery += "WHERE SA1.D_E_L_E_T_ = ' ' "
cQuery +=   "AND SA1.A1_FILIAL = ? "
cQuery +=   "AND SA1.A1_COD IN (" + cPlacehld + ") "

oStmt:SetQuery(cQuery)
oStmt:SetString(1, xFilial("SA1"))
For nI := 1 To Len(aCodes)
    oStmt:SetString(nI + 1, aCodes[nI])
Next
```

> Validate `Len(aCodes) > 0` before building — an empty IN-list (`IN ()`) is a syntax error in all dialects.

## Common FWPreparedStatement Mistakes

| Mistake | Problem | Fix |
|---|---|---|
| Mixing `?` with `'" + cVar + "'"` | Defeats the purpose — injection still possible | Bind every dynamic value |
| Passing user/external input through BeginSQL `%exp:` | `%exp:` is not a bind parameter — the value is inserted into the SQL text (TDN "Embedded SQL") | Use `?` + `Set*` in `FWPreparedStatement` |
| `SetUnsafe` with a value from the user or a request | The value goes in without treatment (TDN) — injection | `SetString`/`SetNumeric`/`SetDate`; `SetUnsafe` only for trusted values such as a table name |
| Wrong placeholder count vs `SetString` calls | Runtime error or silent wrong binding | Count `?` and `Set*` calls match |
| Using `SetString` for numeric/date | Wrong type — silent or runtime error | Use `SetNumeric` / `SetDate` |
| Forgetting `:GetFixQuery()` | Passing the raw template to `TCGenQry` — placeholders not substituted | Always call `:GetFixQuery()` |
| Not closing the alias | Alias leak | `(cAlias)->(DBCloseArea())` in all paths |
| Not destroying the statement | Object kept alive after use | `oStmt:Destroy()` when done (TDN) |
| `TCSqlExec` or `RecLock` for a write that needs the dictionary rules | Neither runs SX7 triggers nor `X3_VALID` | `MsExecAuto` with the routine's documented example, or the MVC model API (`SetValue` + `VldData` + `CommitData`) |
