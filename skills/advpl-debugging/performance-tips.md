# ADVPL/TLPP Performance Optimization Tips

Practical techniques for improving performance in ADVPL/TLPP code on TOTVS Protheus. Each tip includes a before (slow) and after (optimized) code example.

> Note: `EndSQL` must always be in column 1 — with a space or tab before it, the compiler reports C2001 (TDN Embedded SQL, "Erros de compilação").

---

## 1. Index Optimization

### Choosing the Right DbSetOrder

Using the wrong index forces a sequential scan instead of an indexed seek. Always match `DbSetOrder` to the key you are searching.

**Before (slow):**
```advpl
// Using index 1 (A1_FILIAL+A1_COD+A1_LOJA) but searching by name
DbSelectArea("SA1")
DbSetOrder(1)
DbGoTop()
While !Eof()
    If Alltrim(SA1->A1_NOME) == cNomeBusca  // full table scan
        // found
        Exit
    EndIf
    DbSkip()
EndDo
```

**After (optimized):**
```advpl
// Use the index that matches the search key (e.g., index 5 = A1_FILIAL+A1_NOME)
DbSelectArea("SA1")
DbSetOrder(5) // index on A1_FILIAL + A1_NOME
If DbSeek(xFilial("SA1") + PadR(cNomeBusca, TamSX3("A1_NOME")[1]))
    // found via indexed seek - much faster
EndIf
```

### Understanding Index Composition

Before choosing an index, check SIX for the table:

```advpl
// Inspect the available indexes of SA1 through the work area, not by opening SIX
// (direct access to SX*/SIX tables is blocked by the SonarQube rules)
Local nOrd := 0

DbSelectArea("SA1")
For nOrd := 1 To 3
    FWLogMsg("INFO", /*cTransactionId*/, "ADVPLPERF", /*cCategory*/, /*cStep*/, /*cMsgId*/, ;
        "Order: " + cValToChar(nOrd) + " Key: " + Alltrim(SA1->(IndexKey(nOrd))))
Next
// Output (example):
// Order: 1 Key: A1_FILIAL+A1_COD+A1_LOJA
// Order: 2 Key: A1_FILIAL+A1_CGC
// Order: 3 Key: A1_FILIAL+A1_NOME
```

### When to Create Custom Indexes

Create custom indexes when your frequent queries do not match any existing index:

```advpl
// Creating a temporary index for a specific report
Local cIdxFile := CriaTrab(NIL, .F.)
Local cIdxKey  := "D1_FILIAL+D1_FORNECE+D1_EMISSAO"

DbSelectArea("SD1")
IndRegua("SD1", cIdxFile, cIdxKey, , , "Creating index...")
DbSetIndex(cIdxFile + OrdBagExt())
DbSetOrder(IndexOrd())

// Use the index
DbGoTop()
While !Eof()
    // process in order of FORNECE+EMISSAO
    DbSkip()
EndDo

// Clean up temporary index
DbClearIndex()
FErase(cIdxFile + OrdBagExt())
```

---

## 2. Query Optimization

### Embedded SQL vs ISAM Access

Use ISAM (`DbSeek`) for single-record lookups by key. Use embedded SQL for filtered, aggregated, or multi-table queries.

**Before (slow) - ISAM for aggregation:**
```advpl
// Summing values using ISAM loop - very slow for large tables
DbSelectArea("SD1")
DbSetOrder(1)
DbSeek(xFilial("SD1") + cDoc)
nTotal := 0
While !Eof() .And. SD1->D1_FILIAL == xFilial("SD1") .And. SD1->D1_DOC == cDoc
    nTotal += SD1->D1_TOTAL
    DbSkip()
EndDo
```

**After (optimized) - SQL for aggregation:**
```advpl
// SQL aggregation is handled by the database engine - much faster
// (%exp: inserts the value in the SQL text; for external input use FWPreparedStatement)
BeginSQL Alias "QRY_SUM"
    SELECT SUM(D1_TOTAL) AS TOTAL
    FROM %table:SD1% SD1
    WHERE D1_FILIAL = %xFilial:SD1%
      AND D1_DOC = %exp:cDoc%
      AND SD1.%notDel%
EndSQL
nTotal := QRY_SUM->TOTAL
DbSelectArea("QRY_SUM")
DbCloseArea()
```

### SELECT Optimization Tips

<!-- advpl-lint: anti-exemplo -->
```advpl
// TIP 1 - WRONG: SELECT * returns every column
cQuery := "SELECT * FROM " + RetSqlName("SA1") + " SA1 "
```

```advpl
// TIP 1 - RIGHT: select only needed columns
// TIP 2: always filter by D_E_L_E_T_ (%notDel%)
// TIP 3: always filter by branch (%xFilial:%)
BeginSQL Alias "QRY_TIP"
    SELECT A1_COD, A1_LOJA, A1_NOME
    FROM %table:SA1% SA1
    WHERE A1_FILIAL = %xFilial:SA1%
      AND A1_CGC = %exp:cCGC%
      AND SA1.%notDel%
EndSQL
// TIP 4: when only checking existence, limit the result. The row-limit syntax
// (TOP / FETCH FIRST / LIMIT) differs per database; Embedded SQL already passes
// the query through ChangeQuery() (confirm the translation in TDS).
```

> **Locking hints are not portable.** Do not add database-specific hints such as `WITH(NOLOCK)` to queries: they only exist on SQL Server (PostgreSQL and Oracle reject or ignore them) and allow dirty reads. The TDN documents no portable macro for them, and `ChangeQuery()` removes `NOLOCK`/`(NOLOCK)` from the query it returns. Let the framework and the DBAccess handle read consistency.

---

## 3. Memory Management

### Array Pre-allocation with aSize

**Before (slow):**
```advpl
// aAdd reallocates memory on every call
Local aResult := {}
Local nCount := 5000

For nI := 1 To nCount
    aAdd(aResult, {"", 0, .F.})
Next
```

**After (optimized):**
```advpl
// Pre-allocate the array to the known size
Local nCount := 5000
Local aResult := Array(nCount)

For nI := 1 To nCount
    aResult[nI] := {"", 0, .F.}
Next
```

### Object Destruction with FreeObj

**Before (slow) - memory leak:**
```advpl
// Objects never freed - accumulate in memory
While !Eof()
    Local oItem := ItemClass():New()
    oItem:Load(ALIAS->CODE)
    aAdd(aItems, oItem)
    DbSkip()
EndDo
// oItem objects stay in memory even after aItems goes out of scope
```

**After (optimized):**
```advpl
// Free objects when done
While !Eof()
    Local oItem := ItemClass():New()
    oItem:Load(ALIAS->CODE)
    aAdd(aItems, oItem:Export()) // export data, not object
    FreeObj(oItem) // release object memory
    DbSkip()
EndDo

// If you must keep objects in array, free them at the end:
For nI := 1 To Len(aItems)
    If ValType(aItems[nI]) == "O"
        FreeObj(aItems[nI])
    EndIf
Next
aSize(aItems, 0)
```

### Avoiding Memory Leaks in Loops

**Before (slow):**

<!-- advpl-lint: anti-exemplo -->
```advpl
// TCQuery opens alias but never closes it - each iteration leaks a workarea
For nI := 1 To Len(aDocs)
    cQuery := "SELECT D1_TOTAL FROM " + RetSqlName("SD1") + " WHERE D1_DOC = '" + aDocs[nI] + "'"
    TCQuery cQuery New Alias "QRY_TMP"
    nTotal += QRY_TMP->D1_TOTAL
    // Missing: DbCloseArea()
Next
```

**After (optimized):**
```advpl
// Always close temporary aliases inside loops
For nI := 1 To Len(aDocs)
    BeginSQL Alias "QRY_TMP"
        SELECT D1_TOTAL
        FROM %table:SD1% SD1
        WHERE D1_DOC = %exp:aDocs[nI]%
          AND SD1.%notDel%
EndSQL
    If Select("QRY_TMP") > 0
        nTotal += QRY_TMP->D1_TOTAL
        DbSelectArea("QRY_TMP")
        DbCloseArea()
    EndIf
Next

// Even better - use a single query with IN clause
// (values come from internal data; for external input bind them with FWPreparedStatement)
cInList := ""
For nI := 1 To Len(aDocs)
    If !Empty(cInList)
        cInList += ","
    EndIf
    cInList += "'" + aDocs[nI] + "'"
Next
BeginSQL Alias "QRY_BATCH"
    SELECT D1_DOC, D1_TOTAL
    FROM %table:SD1% SD1
    WHERE D1_DOC IN (%exp:cInList%)
      AND SD1.%notDel%
EndSQL
```

---

## 4. Network Optimization

### Batch vs Individual Operations

**Before (slow):**
```advpl
// One HTTP call per item - N round trips
For nI := 1 To Len(aOrders)
    oRest := FWRest():New(cBaseUrl)
    oRest:SetPostParams(aOrders[nI]:ToJson())
    oRest:Post("/api/orders")
    FreeObj(oRest)
Next
```

**After (optimized):**
```advpl
// Single HTTP call with batch payload - 1 round trip
Local oJson := JsonObject():New()
oJson:SetJsonObject("orders", aOrders)

oRest := FWRest():New(cBaseUrl)
oRest:SetPostParams(oJson:ToJson())
oRest:Post("/api/orders/batch")

FreeObj(oJson)
FreeObj(oRest)
```

### Payload Size Reduction

**Before (slow):**
```advpl
// Sending entire record with all fields
oJson := JsonObject():New()
While !Eof()
    oItem := JsonObject():New()
    // Adding all 50+ fields when only 5 are needed
    For nI := 1 To FCount()
        oItem:SetJsonText(FieldName(nI), FieldGet(nI))
    Next
    oJson:Append(oItem)
    DbSkip()
EndDo
```

**After (optimized):**
```advpl
// Send only the required fields
oJson := JsonObject():New()
While !Eof()
    oItem := JsonObject():New()
    oItem:SetJsonText("code", Alltrim(SA1->A1_COD))
    oItem:SetJsonText("name", Alltrim(SA1->A1_NOME))
    oItem:SetJsonText("cgc", Alltrim(SA1->A1_CGC))
    oJson:Append(oItem)
    FreeObj(oItem)
    DbSkip()
EndDo
```

---

## 5. UI Performance

### Lazy Loading in Browses

**Before (slow):**
```advpl
// Loading all records into array before displaying
Local aData := {}
DbSelectArea("SC5")
DbGoTop()
While !Eof()
    aAdd(aData, {SC5->C5_NUM, SC5->C5_EMISSAO, SC5->C5_CLIENTE})
    DbSkip()
EndDo
// Display array - slow if SC5 has millions of records
```

**After (optimized):**
```advpl
// Use MsBrowse with database-backed browsing (no pre-load)
DbSelectArea("SC5")
DbSetOrder(1)
DbGoTop()

oBrowse := MsBrowse():New(01, 01, 20, 75, , , , , , , , "SC5")
oBrowse:AddColumn("C5_NUM", , "Pedido", , 15)
oBrowse:AddColumn("C5_EMISSAO", , "Emissao", , 10)
oBrowse:AddColumn("C5_CLIENTE", , "Cliente", , 20)
// Records are loaded on demand as user scrolls
```

### Reducing UI Refreshes

**Before (slow):**
```advpl
// Refreshing dialog on every iteration
For nI := 1 To Len(aItems)
    ProcessItem(aItems[nI])
    oDialog:Refresh()  // forces UI repaint on every item
    ProcRegua(nI)
Next
```

**After (optimized):**
```advpl
// Refresh only at intervals
Local nRefreshInterval := Max(1, Int(Len(aItems) / 20)) // ~20 refreshes total
For nI := 1 To Len(aItems)
    ProcessItem(aItems[nI])
    If nI % nRefreshInterval == 0
        ProcRegua(nI)
    EndIf
Next
oDialog:Refresh() // single refresh at end
```

---

## 6. Temporary Tables (TRB)

### When to Use Temp Tables

Use temporary tables (TRB) for intermediate processing when you need indexed access to computed data.

**Before (slow):**
```advpl
// Processing with nested loops - O(n*m) complexity
For nI := 1 To Len(aPedidos)
    For nJ := 1 To Len(aItens)
        If aItens[nJ][1] == aPedidos[nI][1]
            // match found
        EndIf
    Next
Next
```

**After (optimized):**
```advpl
// Create the temporary table with FWTemporaryTable (relational mode)
Local oTmp := FWTemporaryTable():New("TMP_ITENS")

oTmp:SetFields({ ;
    {"PEDIDO", "C", 15, 0}, ;
    {"ITEM",   "C", 6,  0}, ;
    {"TOTAL",  "N", 14, 2} ;
})
oTmp:AddIndex("01", {"PEDIDO", "ITEM"})
oTmp:Create()

// Populate the temporary table
For nI := 1 To Len(aItens)
    RecLock("TMP_ITENS", .T.)
    TMP_ITENS->PEDIDO := aItens[nI][1]
    TMP_ITENS->ITEM   := aItens[nI][2]
    TMP_ITENS->TOTAL  := aItens[nI][3]
    MsUnlock()
Next

// Now use indexed seek instead of nested loops
DbSelectArea("TMP_ITENS")
DbSetOrder(1)
For nI := 1 To Len(aPedidos)
    If DbSeek(aPedidos[nI][1])
        While !Eof() .And. TMP_ITENS->PEDIDO == aPedidos[nI][1]
            // process matching items
            DbSkip()
        EndDo
    EndIf
Next

// Cleanup - Delete() drops the temporary table and closes its alias
oTmp:Delete()
```

> `CriaTrab(NIL, .F.)` + `DbCreate()` (ISAM-era temporary files) is no longer the recommended approach; use `FWTemporaryTable` in relational mode. Validation of this example in TDS is pending (a confirmar).

---

## 7. Cache Patterns

### Caching GetMV Results

**Before (slow):**
```advpl
// Calling GetMV on every loop iteration - hits SX6 table each time
While !Eof()
    If SA1->A1_TIPO == GetMV("MV_TIPOCLI")  // DB lookup on every iteration
        // process
    EndIf
    DbSkip()
EndDo
```

**After (optimized):**
```advpl
// Cache the parameter value before the loop
Local cTipoCli := SuperGetMV("MV_TIPOCLI", .F., "F")  // with default value

While !Eof()
    If SA1->A1_TIPO == cTipoCli  // uses cached value
        // process
    EndIf
    DbSkip()
EndDo
```

### Caching Repeated Database Lookups

**Before (slow):**
```advpl
// Looking up client name for every invoice line
DbSelectArea("SD2")
DbSetOrder(1)
DbGoTop()
While !Eof()
    // Opens SA1 seek on every line - even if same client repeats
    DbSelectArea("SA1")
    DbSetOrder(1)
    If DbSeek(xFilial("SA1") + SD2->D2_CLIENTE + SD2->D2_LOJA)
        cNome := SA1->A1_NOME
    EndIf
    DbSelectArea("SD2")
    DbSkip()
EndDo
```

**After (optimized):**
```advpl
// Cache lookups in a hash-like array
Local aCache := {}
Local cKey := ""
Local cNome := ""
Local nPos := 0

DbSelectArea("SD2")
DbSetOrder(1)
DbGoTop()
While !Eof()
    cKey := SD2->D2_CLIENTE + SD2->D2_LOJA

    nPos := aScan(aCache, {|x| x[1] == cKey})
    If nPos > 0
        cNome := aCache[nPos][2]  // from cache
    Else
        DbSelectArea("SA1")
        DbSetOrder(1)
        If DbSeek(xFilial("SA1") + cKey)
            cNome := SA1->A1_NOME
        Else
            cNome := ""
        EndIf
        aAdd(aCache, {cKey, cNome})
    EndIf

    // use cNome
    DbSelectArea("SD2")
    DbSkip()
EndDo
```

### Static Variables for Caching

```advpl
// Use Static to cache data that does not change during execution
Static cCompanyName := NIL

Static Function GetCompanyName()
    If cCompanyName == NIL
        // Only queries once, caches for entire session
        cCompanyName := Alltrim(GetMV("MV_NOMEMP"))
    EndIf
Return cCompanyName
```

---

## 8. Transaction Scope

### Keeping Transactions Short

**Before (slow):**
```advpl
// Transaction wraps everything including validation and logging
Begin Transaction
    // Validation queries (read-only - do not need transaction)
    DbSelectArea("SA1")
    DbSetOrder(1)
    If !DbSeek(xFilial("SA1") + cCodCli)
        DisarmTransaction()
    EndIf

    // Heavy logging
    FWLogMsg("INFO", /*cTransactionId*/, "ADVPLPERF", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Starting process...")

    // The actual write (this is what needs the transaction)
    RecLock("SC5", .T.)
    SC5->C5_NUM := cNumPed
    SC5->C5_CLIENTE := cCodCli
    MsUnlock()

    // More logging
    FWLogMsg("INFO", /*cTransactionId*/, "ADVPLPERF", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Process complete")
End Transaction
```

**After (optimized):**
```advpl
// Validate first, outside the transaction
DbSelectArea("SA1")
DbSetOrder(1)
If !DbSeek(xFilial("SA1") + cCodCli)
    FWLogMsg("ERROR", /*cTransactionId*/, "ADVPLPERF", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Client not found: " + cCodCli)
    Return .F.
EndIf

FWLogMsg("INFO", /*cTransactionId*/, "ADVPLPERF", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Starting process...")

// Transaction wraps only the writes - minimal scope
Begin Transaction
    RecLock("SC5", .T.)
    SC5->C5_NUM := cNumPed
    SC5->C5_CLIENTE := cCodCli
    MsUnlock()
End Transaction

FWLogMsg("INFO", /*cTransactionId*/, "ADVPLPERF", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Process complete")
```

### What to Include/Exclude from Transactions

| Include in Transaction | Exclude from Transaction |
|----------------------|------------------------|
| RecLock / MsUnlock (writes) | Read-only queries (DbSeek for validation) |
| Multiple related writes that must be atomic | Logging (Conout, FWLogMsg) |
| TCSqlExec for DML statements | User interaction (MsgInfo, MsgYesNo) |
| | Network calls (REST APIs) |
| | File I/O operations |

---

## 9. String Concatenation

### Using Arrays Instead of Repeated Concatenation

**Before (slow):**
```advpl
// String concatenation in loop - each += creates a new string copy
Local cReport := ""
Local nLines := 10000

DbSelectArea("SD1")
DbGoTop()
While !Eof()
    cReport += SD1->D1_DOC + " | "
    cReport += SD1->D1_SERIE + " | "
    cReport += cValToChar(SD1->D1_TOTAL) + CRLF
    DbSkip()
EndDo
// Performance degrades exponentially as cReport grows
```

**After (optimized):**
```advpl
// Build with array, join at the end
Local aReport := {}

DbSelectArea("SD1")
DbGoTop()
While !Eof()
    aAdd(aReport, SD1->D1_DOC + " | " + ;
                  SD1->D1_SERIE + " | " + ;
                  cValToChar(SD1->D1_TOTAL))
    DbSkip()
EndDo

// Single join at the end
Local cReport := ""
For nI := 1 To Len(aReport)
    cReport += aReport[nI] + CRLF
Next

// Or for file output, write line by line instead of building full string:
Local nHandle := FCreate(cFilePath)
For nI := 1 To Len(aReport)
    FWrite(nHandle, aReport[nI] + CRLF)
Next
FClose(nHandle)
```

---

## 10. Loop Optimization

### Moving Invariants Outside Loops

**Before (slow):**
```advpl
// xFilial, TamSX3, and GetMV called on every iteration - wasteful
DbSelectArea("SA1")
DbGoTop()
While !Eof()
    If SA1->A1_FILIAL == xFilial("SA1")                           // recalculates every time
        If SA1->A1_TIPO == GetMV("MV_TIPOCLI")                    // DB lookup every time
            cNome := PadR(Alltrim(SA1->A1_NOME), TamSX3("A1_NOME")[1])  // TamSX3 every time
        EndIf
    EndIf
    DbSkip()
EndDo
```

**After (optimized):**
```advpl
// Calculate invariants once before the loop
Local cFilSA1  := xFilial("SA1")
Local cTipoCli := SuperGetMV("MV_TIPOCLI", .F., "F")
Local nTamNome := TamSX3("A1_NOME")[1]

DbSelectArea("SA1")
DbGoTop()
While !Eof()
    If SA1->A1_FILIAL == cFilSA1
        If SA1->A1_TIPO == cTipoCli
            cNome := PadR(Alltrim(SA1->A1_NOME), nTamNome)
        EndIf
    EndIf
    DbSkip()
EndDo
```

### Proper Loop Termination

**Before (slow):**
```advpl
// Scans entire table even after passing the relevant records
DbSelectArea("SD1")
DbSetOrder(1) // D1_FILIAL+D1_DOC+D1_SERIE+D1_ITEM
DbSeek(xFilial("SD1") + cDoc + cSerie)
While !Eof()
    If SD1->D1_DOC == cDoc .And. SD1->D1_SERIE == cSerie
        nTotal += SD1->D1_TOTAL
    EndIf  // continues to end of table even when D1_DOC changes
    DbSkip()
EndDo
```

**After (optimized):**
```advpl
// Break out of the loop when the key changes
Local cFilSD1 := xFilial("SD1")

DbSelectArea("SD1")
DbSetOrder(1)
DbSeek(cFilSD1 + cDoc + cSerie)
While !Eof() .And. SD1->D1_FILIAL == cFilSD1 ;
              .And. SD1->D1_DOC == cDoc ;
              .And. SD1->D1_SERIE == cSerie
    nTotal += SD1->D1_TOTAL
    DbSkip()
EndDo
```

### Avoiding Unnecessary Processing Inside Loops

**Before (slow):**
```advpl
// Formatting and string operations done even when not needed
While !Eof()
    cLine := PadR(ALIAS->FIELD1, 20) + " | " + ;
             Transform(ALIAS->FIELD2, "@E 999,999,999.99") + " | " + ;
             DtoC(ALIAS->FIELD3)

    If ALIAS->FIELD2 > nMinValue  // only some records matter
        aAdd(aResult, cLine)
    EndIf
    DbSkip()
EndDo
```

**After (optimized):**
```advpl
// Filter first, format only matching records
While !Eof()
    If ALIAS->FIELD2 > nMinValue
        cLine := PadR(ALIAS->FIELD1, 20) + " | " + ;
                 Transform(ALIAS->FIELD2, "@E 999,999,999.99") + " | " + ;
                 DtoC(ALIAS->FIELD3)
        aAdd(aResult, cLine)
    EndIf
    DbSkip()
EndDo
```

---

## Performance Checklist

Use this checklist when reviewing ADVPL code for performance:

| # | Check | Impact |
|---|-------|--------|
| 1 | Is the correct index selected with DbSetOrder? | High |
| 2 | Are SQL queries selecting only needed columns? | Medium |
| 3 | Is D_E_L_E_T_ filter included in SQL queries? | Medium |
| 4 | Are arrays pre-allocated when size is known? | Medium |
| 5 | Are objects freed with FreeObj when no longer needed? | Medium |
| 6 | Are temporary workareas (TCQuery aliases) closed after use? | High |
| 7 | Are loop invariants calculated outside the loop? | Medium |
| 8 | Do loops terminate as soon as the key changes? | High |
| 9 | Is GetMV/SuperGetMV cached before loops? | Medium |
| 10 | Are transactions scoped to only the necessary writes? | High |
| 11 | Is string concatenation avoided inside large loops? | Medium |
| 12 | Are REST/network calls batched instead of per-record? | High |
| 13 | Is the UI refreshed only at intervals, not every iteration? | Low |
| 14 | Are repeated DB lookups cached in arrays or static variables? | Medium |
| 15 | Is embedded SQL used for aggregations instead of ISAM loops? | High |
