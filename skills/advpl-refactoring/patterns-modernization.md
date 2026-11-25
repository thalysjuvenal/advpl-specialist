# Modernization Refactoring Patterns (RF-007 to RF-012)

Behavior-preserving replacements for legacy APIs that the TOTVS SonarQube catalog flags (`skills/advpl-code-review/sonarqube-rules-catalog.md`) and the plugin lint engine detects. The Refactoring Process and Safety Rules in [`reference.md`](reference.md) still apply: present a before/after plan, wait for approval, apply one change at a time, keep the function signature. Never claim the result compiles; compilation and validation in TDS / the VS Code TOTVS extension remain pending.

## Finding candidates

Run the lint engine of the `advpl-code-review` skill over the whole file, from the project root so it picks up `./.advpl-specialist-ignore`. Below, `<review-skill>` is that skill's folder (`../advpl-code-review` from this skill folder). On Windows without bash, run the `.ps1` twin with the same arguments.

```bash
bash <review-skill>/scripts/advpl-lint.sh --scope all <file>
```

Each finding is printed as `FILE:LINE: error|warning ID MESSAGE [REF]`. Map the IDs to the patterns:

| Lint ID (severity) | Catalog | Pattern | Applies to |
|---|---|---|---|
| ADV015 (warn) | CA2050; CA2051 is in the catalog with no lint rule | RF-007 concatenated `TCQuery` → `FWPreparedStatement` / `BeginSQL` | `.prw`, `.tlpp` |
| none: search `ErrorBlock(` with Grep | BG1200 | RF-008 `ErrorBlock` + `Begin Sequence` → `Try`/`Catch` | `.tlpp` only |
| ADV003 (error) | CA1004 | RF-009 `ConOut`/`OutErr`/`?` → `FWLogMsg` | all |
| ADV010 (error) `DbCreate`/`MsCreate`, ADV011 (warn) `CriaTrab` | CA1000 | RF-010 → `FWTemporaryTable` | all |
| ADV009 (warn) | CA4000 | RF-011 `IIf` → `If`/`Else`/`EndIf` | all, outside code blocks and dictionary expressions |
| ADV008 (error) | CA2000–CA2013 | RF-012 direct SX access → framework API | all |

Other IDs (includes, restricted functions, `WITH(NOLOCK)`, read-only variables...) are fixes, not refactorings: list them apart. Apply the low-risk patterns first (RF-009, RF-011), then RF-012, RF-010, RF-007 and RF-008.

## Rules for every modernization pattern

- One pattern in one function at a time. Re-run the lint on the file after each change: the finding must disappear and no new error may appear.
- Keep what callers see: return value and its type, records written, log lines, restored work area, signature.
- When an item of "Do not apply when" matches, leave the code as it is and report the reason; a warning kept on purpose is reported, not hidden.
- Anything no reference confirms is written "(a confirmar no TDS)", never as a fact.
- Tests: ProBat for TLPP (`skills/probat-testing/`); for `.prw`, run the routine in a test environment with the inputs listed under "Same behavior" and compare the results with the original version.

## RF-007: Concatenated TCQuery → FWPreparedStatement or BeginSQL (Complexity: MEDIUM)

**Detect:** SQL text built by concatenation (`cQuery += "... '" + cVar + "'"`) and opened with `TCQuery`/`TCGenQry`.
**Lint:** ADV015 (warn, CA2050). CA2051 (user input inside Embedded SQL, e.g. through `%exp:`) has no lint rule: check each `%exp:` by hand.
**Action:** choose by the origin of each concatenated value, as in `skills/embedded-sql/reference.md` ("SQL Injection and User Input"): typed by the user or received from outside → `FWPreparedStatement` with `?` parameters (After A, style of `skills/query-builder/patterns-fwpreparedstatement.md`); only internal values → `BeginSQL` with macros (After B). `%exp:` is not a bind parameter: it inserts the value into the SQL text (TDN "Embedded SQL").

Before:

<!-- advpl-lint: anti-exemplo -->
```advpl
#include "totvs.ch"
#include "topconn.ch"

User Function ZTITVENC(cCliente, cLoja)
    Local aArea  := GetArea()
    Local nSaldo := 0
    Local cQuery := ""

    cQuery := "SELECT SUM(E1_SALDO) AS SALDO FROM " + RetSqlName("SE1") + " SE1 "
    cQuery += "WHERE SE1.D_E_L_E_T_ = ' ' "
    cQuery += "AND SE1.E1_FILIAL = '" + xFilial("SE1") + "' "
    cQuery += "AND SE1.E1_CLIENTE = '" + cCliente + "' "
    cQuery += "AND SE1.E1_LOJA = '" + cLoja + "' "
    cQuery += "AND SE1.E1_VENCREA < '" + DtoS(dDataBase) + "' "
    cQuery += "AND SE1.E1_SALDO > 0 "
    cQuery := ChangeQuery(cQuery)
    TCQuery cQuery New Alias "QRYTIT"

    If !QRYTIT->(Eof())
        nSaldo := QRYTIT->SALDO
    EndIf
    QRYTIT->(DbCloseArea())
    RestArea(aArea)
Return nSaldo
```

After A — `cCliente`/`cLoja` come from the user or from outside (screen field, `MV_PAR*`, REST/SOAP payload). Each `cQuery +=` line adds either fixed text or `RetSqlName()`, so it is easy to audit that no value is concatenated:

```advpl
#include "totvs.ch"
#include "topconn.ch"

User Function ZTITVENC(cCliente, cLoja)
    Local aArea  := GetArea()
    Local nSaldo := 0
    Local cAlias := GetNextAlias()
    Local oStmt  := FWPreparedStatement():New()
    Local cQuery := ""

    cQuery := "SELECT SUM(E1_SALDO) AS SALDO FROM "
    cQuery += RetSqlName("SE1")
    cQuery += " SE1 WHERE SE1.D_E_L_E_T_ = ' ' "
    cQuery += "AND SE1.E1_FILIAL = ? "
    cQuery += "AND SE1.E1_CLIENTE = ? "
    cQuery += "AND SE1.E1_LOJA = ? "
    cQuery += "AND SE1.E1_VENCREA < ? "
    cQuery += "AND SE1.E1_SALDO > 0 "

    oStmt:SetQuery(cQuery)
    oStmt:SetString(1, xFilial("SE1"))
    oStmt:SetString(2, cCliente)
    oStmt:SetString(3, cLoja)
    oStmt:SetString(4, DtoS(dDataBase))
    DbUseArea(.T., "TOPCONN", TCGenQry(,, oStmt:GetFixQuery()), cAlias, .F., .T.)

    If !(cAlias)->(Eof())
        nSaldo := (cAlias)->SALDO
    EndIf
    (cAlias)->(DbCloseArea())
    oStmt:Destroy()
    RestArea(aArea)
Return nSaldo
```

After B — every caller (checked with Grep) passes codes the routine controls, such as `SA1->A1_COD` of a positioned record, never typed text:

```advpl
#include "totvs.ch"
#include "topconn.ch"

User Function ZTITVENC(cCliente, cLoja)
    Local aArea  := GetArea()
    Local nSaldo := 0
    Local cAlias := GetNextAlias()

    BeginSQL Alias cAlias
        SELECT SUM(E1_SALDO) AS SALDO
        FROM %table:SE1% SE1
        WHERE SE1.%notDel%
        AND SE1.E1_FILIAL = %xfilial:SE1%
        AND SE1.E1_CLIENTE = %exp:cCliente%
        AND SE1.E1_LOJA = %exp:cLoja%
        AND SE1.E1_VENCREA < %exp:DtoS(dDataBase)%
        AND SE1.E1_SALDO > 0
EndSQL

    If !(cAlias)->(Eof())
        nSaldo := (cAlias)->SALDO
    EndIf
    (cAlias)->(DbCloseArea())
    RestArea(aArea)
Return nSaldo
```

**Risk:**

- `ChangeQuery()`: the original passed the text through it. `BeginSQL` applies it automatically unless `%noparser%` is used (TDN "Embedded SQL"). Whether `GetFixQuery()` applies it is not documented (a confirmar no TDS).
- Column types: `TCQuery`/`TCGenQry` return dates as `YYYYMMDD` text unless `TCSetField` is called. Port each `TCSetField` to a `column ... as` declaration in `BeginSQL` (or keep it after `DbUseArea`), and do not add type declarations the original did not have, or code that reads the column as text breaks.
- Values: bind exactly what the original concatenated (same `AllTrim`/padding, `DtoS()` for dates compared as text). The number of `?` must match the number of `Set*` calls.
- Alias: the original used the fixed alias `QRYTIT`. If a called function reads that alias by name, keep the name or pass `cAlias` to it.
- A `'` inside the value broke or altered the original SQL; now it is part of the value (TDN "FWPreparedStatement"). That change is the purpose of the pattern; for ordinary values the result must be identical.

**Same behavior — compare and test:**

- In a test environment, log the final SQL of both versions (original: `cQuery` after `ChangeQuery`; After A: `oStmt:GetFixQuery()`) with `FWLogMsg` and compare tables, filters and values.
- Run both versions against the same company and branch with: an existing customer, a non-existent one, blank codes and a value containing `'`. Compare the returned values and their `ValType()`.
- Re-run the lint: ADV015 must be gone. ADV015 is heuristic and flags any concatenation into `cQuery`/`cSql`/`cQry`, including `+ RetSqlName()`; a hit on a line that concatenates only the physical table name is expected.

**Do not apply when:**

- The SQL is static and every value is internal (literals, `xFilial()`, `DtoS()` of a date, numbers the routine computes): `FWPreparedStatement` is not required. Use After B (`BeginSQL` with `%exp:`) or leave the warning with that justification.
- A fragment of SQL (column list, `ORDER BY`, table, a whole `WHERE` clause) comes from the caller: it cannot become a `?` parameter. Building the clause from fixed text in the routine changes the design; report it instead of refactoring.
- The SQL text contains a literal `?`: `BeginSQL` reserves `?` (TDN "Embedded SQL"), so After B is not an option.

## RF-008: ErrorBlock + Begin Sequence → Try/Catch, TLPP only (Complexity: MEDIUM)

**Detect:** `.tlpp` source with `ErrorBlock({|e| Break(e)})` + `Begin Sequence` / `Recover Using oError` / `End Sequence`.
**Lint:** no rule. Catalog BG1200 (`ErrorBlock` override, INFO, replacement `Try-Catch` in TLPP). Find candidates with Grep `ErrorBlock(` in `.tlpp` files.
**Action:** replace the sequence with `Try` / `Catch oError` / `EndTry` (TDN "Try...Catch", <https://tdn.totvs.com/display/tec/Try...Catch>, Application Server 20.3.0.0 or later). `Finally` is optional and always runs. The caught object is an `ErrorClass`; the TDN example reads `description` and `genCode`, other properties are a confirmar no TDS.

Before:

<!-- advpl-lint: anti-exemplo -->
```tlpp
#include "tlpp-core.th"
#include "totvs.ch"

namespace custom.fat.pedidos

user function gravaPed(cPedido as character) as logical
    local lRet      := .T.
    local aArea     := GetArea()
    local oError
    local bOldError := ErrorBlock({|e| Break(e)})

    Begin Sequence
        // gravacao do pedido cPedido (pode gerar erro de execucao)
    Recover Using oError
        lRet := .F.
        FWLogMsg("ERROR", /*cTransactionId*/, "PEDIDOS", "gravaPed", /*cStep*/, /*cMsgId*/, "Erro no pedido " + cPedido + ": " + oError:Description)
    End Sequence

    ErrorBlock(bOldError)
    RestArea(aArea)
return lRet
```

After:

```tlpp
#include "tlpp-core.th"
#include "totvs.ch"

namespace custom.fat.pedidos

user function gravaPed(cPedido as character) as logical
    local lRet  := .T.
    local aArea := GetArea()

    Try
        // gravacao do pedido cPedido (pode gerar erro de execucao)
    Catch oError
        lRet := .F.
        FWLogMsg("ERROR", /*cTransactionId*/, "PEDIDOS", "gravaPed", /*cStep*/, /*cMsgId*/, "Erro no pedido " + cPedido + ": " + oError:description)
    EndTry

    RestArea(aArea)
return lRet
```

`RestArea()` stays after `EndTry`, in the same place as after `End Sequence`. Move it to `Finally` only when the `Try` block has a `Return`.

**Risk:**

- A custom handler (`ErrorBlock` that logs, shows a screen or returns a value before `Break`) is not reproduced by `Try`/`Catch`: move that behavior into `Catch` or keep the sequence.
- `Break` used as flow control (`Break(xValue)` without an error, `Recover Using` receiving a non-error value) has no direct equivalent: the migration rules of `skills/advpl-to-tlpp-migration/` restructure that flow with `If`/`Else`, which is a logic change, not this pattern.
- Error properties: the original reads `oError:Description` (and maybe others). Only `description` and `genCode` are shown on the TDN page; any other property read in `Recover` is a confirmar no TDS.
- `DisarmTransaction()` or any cleanup inside `Recover` must move to `Catch` unchanged.

**Same behavior — compare and test:**

- Happy path: same return value and the same records written.
- Error path: force a runtime error inside the protected block, also in a function it calls (the TDN example raises one with `UserException("...")`). Compare the return value, the log line (severity, group, text), the restored work area and the transaction state.
- Write both paths as ProBat tests (`skills/probat-testing/`).

**Do not apply when:**

- The source is `.prw`: `Try`/`Catch` exists only in TLPP (TDN "Try...Catch"). ADVPL keeps `ErrorBlock` + `Begin Sequence` / `Recover Using` + `ErrorBlock(bOldError)`, as in the "Error Handling Pattern" of `skills/advpl-code-generation/reference.md`.
- The sequence uses `Break` for flow control, or the custom `ErrorBlock` has side effects that `Catch` cannot reproduce.
- The AppServer of the environment is older than 20.3.0.0.

## RF-009: ConOut → FWLogMsg (Complexity: LOW)

**Detect:** `ConOut(`, `OutErr(` or the `?` / `??` console statement.
**Lint:** ADV003 (error, CA1004).
**Action:** replace each call with `FWLogMsg(cSeverity, [cTransactionId], cGroup, [cCategory], [cStep], [cMsgId], [cMessage], [nMensure], [nElapseTime], [aMessage])` (TDN "FWLogMsg", <https://tdn.totvs.com/display/framework/FWLogMsg>). `cSeverity` and `cGroup` are mandatory; `cSeverity` is `INFO`, `WARN`, `ERROR`, `FATAL` or `DEBUG` (never `"WARNING"`). Use `INFO` on the normal path and `WARN`/`ERROR` on failure paths. Keep the message text so whoever reads the log still finds it.

Before:

<!-- advpl-lint: anti-exemplo -->
```advpl
#include "totvs.ch"

User Function ZPROCNF(cDoc)
    Local lOk := .T.

    ConOut("ZPROCNF - inicio da nota " + cDoc + " " + DtoC(Date()) + " " + Time())
    // ... processamento da nota ...
    If !lOk
        ConOut("ZPROCNF - erro ao processar a nota " + cDoc)
    EndIf
    ConOut("ZPROCNF - fim da nota " + cDoc)
Return lOk
```

After:

```advpl
#include "totvs.ch"

User Function ZPROCNF(cDoc)
    Local lOk := .T.

    FWLogMsg("INFO", /*cTransactionId*/, "ZPROCNF", "NOTA", /*cStep*/, /*cMsgId*/, "ZPROCNF - inicio da nota " + cDoc + " " + DtoC(Date()) + " " + Time())
    // ... processamento da nota ...
    If !lOk
        FWLogMsg("ERROR", /*cTransactionId*/, "ZPROCNF", "NOTA", /*cStep*/, /*cMsgId*/, "ZPROCNF - erro ao processar a nota " + cDoc)
    EndIf
    FWLogMsg("INFO", /*cTransactionId*/, "ZPROCNF", "NOTA", /*cStep*/, /*cMsgId*/, "ZPROCNF - fim da nota " + cDoc)
Return lOk
```

**Risk:**

- Format: `ConOut` writes the bare text to the AppServer console; `FWLogMsg` writes a structured entry (severity, group, transaction id...). Monitoring scripts that search `console.log` for the exact text may stop matching.
- Severity: `DEBUG` is only written when the environment has `FWLOGMSG_DEBUG=1` (TDN). Turning a trace into `DEBUG` makes it disappear by default.
- Size: `cMessage` is limited to 10K (TDN). Large dumps (payloads, `VarInfo` of arrays) are cut: log a summary.
- `cMessage` is character: convert numbers and dates with `cValToChar()`/`DtoC()` as the original text did. When `aMessage` is informed, the console omits `cMessage` (TDN).
- Each call without `cTransactionId` gets a new id (default `FWUUIDV1()`); `"LAST"` reuses the previous one (TDN). Only use it when no other call can log in between.

**Same behavior — compare and test:**

- Run the routine in a test environment on the normal path and on each failure path. Every former `ConOut` line must have one `FWLogMsg` entry with the same text and a severity that matches the path.
- Check with whoever runs the monitoring that the new format is still found.
- Re-run the lint: no ADV003 may remain (it is an error with no legitimate use).

**Do not apply when:**

- An external process parses the `ConOut` text and cannot be adjusted in the same delivery: plan both changes together.
- The code runs before the environment is prepared (a job before `RpcSetEnv`): whether `FWLogMsg` works at that point is not documented (a confirmar no TDS).
- The call is a user message (`MsgInfo`, `Help`, `MsgAlert`): it is not a log, so this pattern does not apply.

## RF-010: CriaTrab / DbCreate → FWTemporaryTable (Complexity: MEDIUM)

**Detect:** temporary work file created with `CriaTrab(aStru, .T.)`, or `CriaTrab(NIL, .F.)` + `DbCreate()`/`MsCreate()`, then opened with `DbUseArea()` and indexed with `IndRegua()`.
**Lint:** ADV010 (error: `DbCreate`, `MsCreate`) and ADV011 (warn: `CriaTrab`), both CA1000.
**Action:** create the table with `FWTemporaryTable` in relational mode with the same alias, the same fields and an equivalent index. Methods used in the plugin references: `New(cAlias[, aFields])`, `SetFields()`, `AddIndex()`, `Create()`, `GetRealName()`, `Delete()` (drops the table and closes the alias). See also `skills/advpl-debugging/performance-tips.md` and `skills/query-builder/cross-database.md`.

Before:

<!-- advpl-lint: anti-exemplo -->
```advpl
#include "totvs.ch"

User Function ZTOTPED(aItens)
    Local aArea   := GetArea()
    Local aStru   := {}
    Local cArqTrb := ""
    Local nI      := 0

    aAdd(aStru, {"PEDIDO", "C", 6, 0})
    aAdd(aStru, {"ITEM", "C", 2, 0})
    aAdd(aStru, {"TOTAL", "N", 14, 2})

    cArqTrb := CriaTrab(NIL, .F.)
    DbCreate(cArqTrb, aStru)
    DbUseArea(.T., , cArqTrb, "TRB", .F., .F.)
    IndRegua("TRB", cArqTrb, "PEDIDO+ITEM", , , "Criando indice...")

    For nI := 1 To Len(aItens)
        RecLock("TRB", .T.)
        TRB->PEDIDO := aItens[nI][1]
        TRB->ITEM   := aItens[nI][2]
        TRB->TOTAL  := aItens[nI][3]
        MsUnlock()
    Next

    // ... TRB->(DbSeek(cPedido + cItem)) e leitura ...

    TRB->(DbCloseArea())
    RestArea(aArea)
Return
```

After:

```advpl
#include "totvs.ch"

User Function ZTOTPED(aItens)
    Local aArea   := GetArea()
    Local aFields := {}
    Local oTmp    := FWTemporaryTable():New("TRB")
    Local nI      := 0

    aAdd(aFields, {"PEDIDO", "C", 6, 0})
    aAdd(aFields, {"ITEM", "C", 2, 0})
    aAdd(aFields, {"TOTAL", "N", 14, 2})

    oTmp:SetFields(aFields)
    oTmp:AddIndex("01", {"PEDIDO", "ITEM"})
    oTmp:Create()

    For nI := 1 To Len(aItens)
        RecLock("TRB", .T.)
        TRB->PEDIDO := aItens[nI][1]
        TRB->ITEM   := aItens[nI][2]
        TRB->TOTAL  := aItens[nI][3]
        MsUnlock()
    Next

    // ... TRB->(DbSetOrder(1)), TRB->(DbSeek(cPedido + cItem)) e leitura ...

    oTmp:Delete()
    RestArea(aArea)
Return
```

**Risk:**

- Location: the data moves from an ISAM work file, outside the database, to a table in the database. Code that uses the file name (`cArqTrb` in `FErase`, `COPY TO`, file copies, or passed to another routine) must change; in SQL use `oTmp:GetRealName()`.
- Index: `IndRegua` takes a key expression; `AddIndex` takes a list of fields. Keys with functions (`DtoS(DATA)`, `Upper(NOME)`) have no direct equivalent in that list (a confirmar no TDS) and need a redesign.
- Active order and area: `DbUseArea(.T., ...)` selected `TRB` and `IndRegua` activated the index. Whether `Create()` selects the alias and activates index 1 is not documented in the plugin references (a confirmar no TDS): call `TRB->(DbSetOrder(1))`, and `DbSelectArea("TRB")` when the following code uses commands without an alias.
- Cleanup: `oTmp:Delete()` must run on every path, including errors (`Recover` in `.prw`, `Finally` in TLPP). Otherwise the table is left in the database.
- Structure: keep the same field names, types, sizes and decimals, so reads return the same values.
- Performance: every `RecLock` is now a database write. For large volumes, consider a set-based `INSERT ... SELECT` into `oTmp:GetRealName()`; that is a separate change.

**Same behavior — compare and test:**

- With the same input, compare the record count, the totals, the reading order after `DbSetOrder(1)` + `DbGoTop()`, and `DbSeek` results for existing and missing keys.
- Force an error after `Create()` and confirm that the error path calls `oTmp:Delete()`.

**Do not apply when:**

- `CriaTrab(NIL, .F.)` only produces a unique name for something that is not a temporary table, such as a temporary index file on a real table or a text file. There is no table to replace, which is why ADV011 is only a warning.
- The work file is itself the deliverable (a file copied to the user or to another system): moving it to the database changes the output. Report it as a functional change.

## RF-011: IIf → If/Else/EndIf outside code blocks (Complexity: LOW)

**Detect:** `IIf(` in ordinary statements.
**Lint:** ADV009 (warn, CA4000).
**Action:** replace the assignment with an `If`/`Else`/`EndIf` block that assigns the same variable in every branch. Turn nested `IIf` into `Do Case`. When the `IIf` sits inside an argument, compute the value in a variable first.

Before:

<!-- advpl-lint: anti-exemplo -->
```advpl
cSituac := IIf(SA1->A1_MSBLQL == "1", "Bloqueado", "Ativo")
cFaixa  := IIf(nTotal >= 10000, "A", IIf(nTotal >= 1000, "B", "C"))
```

After:

```advpl
If SA1->A1_MSBLQL == "1"
    cSituac := "Bloqueado"
Else
    cSituac := "Ativo"
EndIf

Do Case
Case nTotal >= 10000
    cFaixa := "A"
Case nTotal >= 1000
    cFaixa := "B"
Otherwise
    cFaixa := "C"
EndCase
```

**Risk:**

- A branch that does not assign the variable leaves it with its previous value (or `NIL`): every branch must assign it.
- If a branch of the `IIf` calls a function with side effects (writes a record, increments a counter, moves the record pointer), `If`/`Else` runs only the chosen branch. The plugin's `Iif` reference does not state whether `IIf` evaluates only the chosen argument (a confirmar no TDS): when side effects exist, check it before converting.

**Same behavior — compare and test:**

- For each converted `IIf`, test both values of the condition and the boundary (in the example: `nTotal` equal to 10000 and 1000). Compare the value and the `ValType()` of the result.

**Do not apply when:**

- The `IIf` is inside a code block (`{|| IIf(lOk, "S", "N")}`): a code block holds an expression, and `If`/`Else` is a statement. The lint only warns there; keep it.
- The `IIf` is in a dictionary expression or another expression evaluated as text: field validation, initializer or trigger rule, `bValid`/`SetValid`, browse legend or filter, a string run with `&`. Keep it.

## RF-012: Direct SX access → framework API (Complexity: MEDIUM)

**Detect:** `DbSelectArea("SX?")`, `DbSelectArea("SM0")` or `DbSelectArea("SIX")` followed by `DbSeek` and field reads.
**Lint:** ADV008 (error, CA2000–CA2013).
**Action:** read the same information through the framework API (`skills/protheus-reference/sx-dictionary.md`, catalog G4):

| Table | Catalog | Use instead |
|---|---|---|
| SX1 | CA2002 | `Pergunte()`, `FWSX1Util` |
| SX2 | CA2003 | `RetSqlName()`, `X2Nome()`, `FWSX2Util` |
| SX3 | CA2004 | `FWSX3Util`, `GetSX3Cache()`, `FWFormStruct()` in MVC |
| SX5 | CA2009 | `FWGetSX5()`, `X5Descri()`, `FwPutSX5()` |
| SX6 | CA2010 | `SuperGetMV()`, `GetMV()`, `PutMV()`, `FWSX6Util` |
| SIX | CA2001 | `FWSIXUtil` |
| SX9 | CA2006 | `FWSX9Util` |
| SXG | CA2011 | `FWSXGUtil` |
| SM0 | CA2000 | `FWSM0Util` |
| SXD | CA2012 | `SchedDef` |
| SX7, SXA, SXB, other SX* | CA2005, CA2007, CA2008, CA2013 | The catalog only says "standard APIs"; the plugin references name no function (a confirmar no TDS) |

Before:

<!-- advpl-lint: anti-exemplo -->
```advpl
#include "totvs.ch"

User Function ZTAMDOC()
    Local aArea := GetArea()
    Local nTam  := 0
    Local nDias := 0

    DbSelectArea("SX3")
    DbSetOrder(2)
    If DbSeek("E1_NUM")
        nTam := SX3->X3_TAMANHO
    EndIf

    DbSelectArea("SX6")
    DbSetOrder(1)
    If DbSeek(xFilial("SX6") + "MV_XDIASVC")
        nDias := Val(SX6->X6_CONTEUD)
    EndIf

    RestArea(aArea)
Return {nTam, nDias}
```

After (`MV_XDIASVC` is a custom numeric parameter):

```advpl
#include "totvs.ch"

User Function ZTAMDOC()
    Local nTam  := 0
    Local nDias := 0

    If FWSX3Util():SeekX3File("E1_NUM")
        nTam := GetSX3Cache("E1_NUM", "X3_TAMANHO")
    EndIf
    nDias := SuperGetMV("MV_XDIASVC", .F., 0)
Return {nTam, nDias}
```

**Risk:**

- Type: the original converted the parameter with `Val(SX6->X6_CONTEUD)`. `SuperGetMV`/`GetMV` return a value whose type depends on the parameter definition (`X6_TIPO`). If the parameter is character, keep the `Val()`.
- Missing entries: the original returned `0` silently. `SuperGetMV` shows a help when the parameter is missing unless `lHelp` is `.F.`, and returns the default. What `GetSX3Cache` returns for a missing field is not documented in the plugin references (a confirmar no TDS), so keep a guard such as `SeekX3File` when the field may not exist (custom `_X*` fields).
- Branch: the original searched only the key `xFilial("SX6") + name`. Compare the value returned in each branch you use.
- Cache: `SuperGetMV` caches values. If the routine writes the parameter with `PutMV` and reads it again, check the value it gets (a confirmar no TDS).
- Positioning: code after the original may read other fields of the positioned SX record (`SX3->X3_TITULO`...). Map every field read, not only the first one.
- `DbSeek` without padding matches the first key that starts with the text searched; the API looks up the exact name. Compare the result for the names actually used.
- The original changed and restored the work area. Remove `GetArea`/`RestArea` only if nothing else in the function changes the area.

**Same behavior — compare and test:**

- In the same company and in each branch used, log every value read in both versions and compare value and `ValType()`. Include a missing field or parameter.

**Do not apply when:**

- The code creates or updates dictionary entries (SX3 fields, SX6 parameters) instead of reading them: that is dictionary configuration, see `skills/sx-configuration/`.
- No API in the plugin references covers what the code reads (see the last row of the table): do not invent one. Keep the code, report the ADV008 finding as open and confirm the API on TDN.
