# ADVPL/TLPP Debugging

## Overview

Systematic methodology for diagnosing and resolving errors in ADVPL/TLPP on TOTVS Protheus. This skill covers compilation errors, runtime failures, performance bottlenecks, database locks, log analysis, and AppServer troubleshooting.

## When to Use

- Compilation errors (syntax, missing includes, undeclared variables)
- Runtime errors (NIL access, type mismatch, array bounds)
- Performance issues (slow queries, memory leaks, excessive loops)
- Database locks (RecLock timeouts, deadlocks, exclusive access failures)
- Log analysis (Protheus console, AppServer logs, SmartClient logs)
- AppServer issues (crash, high memory, thread exhaustion, connection problems)

## Debug Methodology

```dot
digraph debug_flow {
    rankdir=TB;
    node [shape=box, style=rounded];

    A [label="Error Reported"];
    B [label="Compilation Error?" shape=diamond];
    C [label="Check common-errors.md\nFix syntax/includes/declarations"];
    D [label="Add Logging\n(Conout / FWLogMsg)"];
    E [label="Reproduce Error"];
    F [label="Analyze Stack Trace\n& Log Output"];
    G [label="Identify Root Cause"];
    H [label="Apply Fix"];
    I [label="Validate Fix\n& Remove Debug Logging"];

    A -> B;
    B -> C [label="Yes"];
    B -> D [label="No (Runtime)"];
    C -> I [label="Fixed"];
    D -> E;
    E -> F;
    F -> G;
    G -> H;
    H -> I;
}
```

**Steps:**

1. **Error reported** - Collect the error message, stack trace, and reproduction steps
2. **Compilation?** - If yes, consult `common-errors.md` for immediate fix
3. **Add logging** - Insert Conout/FWLogMsg at strategic points around the failure
4. **Reproduce** - Recreate the error in a controlled environment
5. **Analyze stack** - Read the full stack trace, identify the failing line and function
6. **Identify root cause** - Determine why the error occurs (data, logic, environment)
7. **Fix** - Apply the correction, validate, and remove debug logging

## Quick Diagnosis by Error Type

| Symptom | Likely Cause | First Check |
|---------|-------------|-------------|
| Variable does not exist | Undeclared Local or typo in name | Verify variable declaration matches usage (case-sensitive) |
| Array access out of bounds | Index exceeds `Len(aArray)` or index <= 0 | Add `Conout(Len(aArray))` before the access line |
| Type mismatch on operation | Operating on NIL or wrong type | Check `ValType()` of both operands before the line |
| File not found / Include error | Missing .ch file or wrong RPO | Verify `#Include` paths and RPO compilation |
| Lock timeout (RecLock) | Record locked by another user/thread | Check `RecLock(cAlias, .F.)` with timeout, use SM0/SMA lock monitor |
| Memory allocation error | Array growing unbounded or object leak | Check loops for `aAdd` without limit, verify `FreeObj()` calls |
| Invalid alias XXXX | WorkArea not opened or closed prematurely | Verify `DbSelectArea()` precedes the alias usage, check `Select(cAlias) > 0` |

## Logging Tools

### Conout (Console Output) - legacy, avoid

`Conout` is the legacy console output (appears in the AppServer console). New code must use `FWLogMsg` (next section); the block below only illustrates what to look for when reading old sources.

<!-- advpl-lint: anti-exemplo -->
```advpl
// Basic variable inspection
Conout(">>> [FATA001] cCodCli: " + cValToChar(cCodCli))
Conout(">>> [FATA001] nTotal: " + cValToChar(nTotal))
Conout(">>> [FATA001] ValType(xRet): " + ValType(xRet))

// Array inspection
Conout(">>> aItens length: " + cValToChar(Len(aItens)))
If Len(aItens) > 0
    Conout(">>> aItens[1]: " + cValToChar(aItens[1]))
EndIf

// Flow tracing
Conout(">>> Entering FATA001 at " + Time())
// ... code ...
Conout(">>> Leaving FATA001 at " + Time())
```

### FWLogMsg (Structured Logging - Preferred)

Structured logging with severity levels. Logs are stored in the Protheus log system and can be queried.

Signature (TDN): `FWLogMsg(cSeverity, [cTransactionId], cGroup, [cCategory], [cStep], [cMsgId], [cMessage], [nMensure], [nElapseTime], [aMessage])`. Only `cSeverity` and `cGroup` are required.

```advpl
// Severity levels: "INFO", "WARN", "ERROR", "FATAL", "DEBUG"
FWLogMsg("INFO", /*cTransactionId*/, "FATA001", "MyModule", /*cStep*/, /*cMsgId*/, ;
    "Processing started for client: " + cCodCli)

FWLogMsg("ERROR", /*cTransactionId*/, "FATA001", "MyModule", /*cStep*/, /*cMsgId*/, ;
    "Failed to lock record SA1. Alias: " + cAlias + ;
    " RecNo: " + cValToChar(RecNo()))

FWLogMsg("WARN", /*cTransactionId*/, "FATA001", "MyModule", /*cStep*/, /*cMsgId*/, ;
    "Slow query detected. Elapsed: " + cValToChar(nElapsed) + "s")
```

### ErrorBlock for Custom Stack Trace Capture

Capture and log full error details including the call stack.

```advpl
Local oError
Local bOldError := ErrorBlock({|e| oError := e, Break(e)})

Begin Sequence

    // Code that may fail
    DbSelectArea("SA1")
    DbSetOrder(1)
    DbSeek(xFilial("SA1") + cCodCli)
    cNome := SA1->A1_NOME

Recover Using oError
    FWLogMsg("ERROR", /*cTransactionId*/, "ADVPLDBG", /*cCategory*/, /*cStep*/, /*cMsgId*/, "=== ERROR CAPTURED ===")
    FWLogMsg("ERROR", /*cTransactionId*/, "ADVPLDBG", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Description: " + oError:Description)
    FWLogMsg("ERROR", /*cTransactionId*/, "ADVPLDBG", /*cCategory*/, /*cStep*/, /*cMsgId*/, "GenCode:     " + cValToChar(oError:GenCode))
    FWLogMsg("ERROR", /*cTransactionId*/, "ADVPLDBG", /*cCategory*/, /*cStep*/, /*cMsgId*/, "SubCode:     " + cValToChar(oError:SubCode))
    FWLogMsg("ERROR", /*cTransactionId*/, "ADVPLDBG", /*cCategory*/, /*cStep*/, /*cMsgId*/, "OsCode:      " + cValToChar(oError:OsCode))
    FWLogMsg("ERROR", /*cTransactionId*/, "ADVPLDBG", /*cCategory*/, /*cStep*/, /*cMsgId*/, "FileName:    " + cValToChar(oError:FileName))
    FWLogMsg("ERROR", /*cTransactionId*/, "ADVPLDBG", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Operation:   " + oError:Operation)
    FWLogMsg("ERROR", /*cTransactionId*/, "ADVPLDBG", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Args:        " + cValToChar(oError:Args))
    FWLogMsg("INFO", /*cTransactionId*/, "ADVPLDBG", /*cCategory*/, /*cStep*/, /*cMsgId*/, "======================")

End Sequence

ErrorBlock(bOldError)
```

## Database Lock Diagnosis

### RecLock with Timeout Check

Always use `.F.` (non-exclusive wait) and check the return value:

```advpl
DbSelectArea("SD1")
DbSetOrder(1)

If DbSeek(xFilial("SD1") + cDoc + cSerie)
    // Try to lock with .F. (non-blocking)
    If RecLock("SD1", .F.)
        SD1->D1_TOTAL := nNewTotal
        MsUnlock()
        FWLogMsg("INFO", /*cTransactionId*/, "ADVPLDBG", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Record updated successfully")
    Else
        FWLogMsg("ERROR", /*cTransactionId*/, "ADVPLDBG", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Could not lock SD1 RecNo " + cValToChar(RecNo()))
        FWLogMsg("INFO", /*cTransactionId*/, "ADVPLDBG", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Another user/thread may be editing this record")
        // Check who is locking:
        // Use Protheus Monitor (SIGAMNT) or AppServer console
    EndIf
EndIf
```

### Common Lock Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| RecLock hangs indefinitely | Using `RecLock(cAlias, .T.)` - blocks forever | Use `RecLock(cAlias, .F.)` and check return |
| Lock not released | Missing `MsUnlock()` after RecLock | Always call `MsUnlock()` after writing |
| Deadlock between threads | Two threads locking records in different order | Lock records in a consistent order, keep locks short |
| Exclusive lock failure | Another process has shared lock | Schedule exclusive operations during off-hours |

## Performance Quick Checks

### Wrong Index (DbSetOrder)

Using the wrong index forces a full table scan:

```advpl
// WRONG - may use wrong index or full scan
DbSelectArea("SA1")
DbSetOrder(3) // Index 3 may not match your search key
DbSeek(xFilial("SA1") + cCodCli)

// RIGHT - verify the index matches your key
// Check SIX table for SA1 index composition
// Index 1 typically: A1_FILIAL + A1_COD + A1_LOJA
DbSelectArea("SA1")
DbSetOrder(1)
DbSeek(xFilial("SA1") + cCodCli + cLoja)
```

### Array Growth in Loops

Pre-allocate arrays when the size is known:

```advpl
// SLOW - aAdd reallocates memory on every iteration
Local aResult := {}
While !Eof()
    aAdd(aResult, {ALIAS->FIELD1, ALIAS->FIELD2})
    DbSkip()
EndDo

// FAST - pre-allocate with aSize
Local nCount := RecCount() // or known count
Local aResult := Array(nCount)
Local nIdx := 0
While !Eof()
    nIdx++
    aResult[nIdx] := {ALIAS->FIELD1, ALIAS->FIELD2}
    DbSkip()
EndDo
aSize(aResult, nIdx) // trim unused slots
```

### Embedded SQL vs ISAM

Use embedded SQL for complex queries; use ISAM for simple key lookups:

```advpl
// ISAM - good for single-record lookup by key
DbSelectArea("SA1")
DbSetOrder(1)
If DbSeek(xFilial("SA1") + cCodCli + cLoja)
    cNome := SA1->A1_NOME
EndIf

// Embedded SQL - good for filtered/aggregated queries
// (%exp: inserts the value in the SQL text; for external input use FWPreparedStatement)
BeginSQL Alias "QRY_TMP"
    SELECT D1_DOC, D1_SERIE, SUM(D1_TOTAL) AS TOTAL
    FROM %table:SD1% SD1
    WHERE D1_FILIAL = %xFilial:SD1%
      AND D1_EMISSAO >= %exp:DtoS(dDataIni)%
      AND SD1.%notDel%
    GROUP BY D1_DOC, D1_SERIE
EndSQL
```

See `performance-tips.md` for comprehensive optimization techniques.

## Common Mistakes When Debugging

| Mistake | Why It Is Wrong | Better Approach |
|---------|----------------|-----------------|
| Leaving Conout in production | Floods console, impacts performance | Use FWLogMsg with severity, remove debug Conouts before deploy |
| Not saving ErrorBlock | Overwrites global error handler | Always save with `bOld := ErrorBlock(...)` and restore after |
| Using MsgAlert for debug | Blocks execution, not visible on server | Use Conout or FWLogMsg for non-interactive debugging |
| Ignoring RecLock return value | Writes to unlocked record - data corruption | Always check `If RecLock(cAlias, .F.)` |
| Not checking ValType before operations | Misses NIL values that cause runtime errors | Add `ValType(xVar) == "C"` checks before string operations |
| Debugging on production environment | Risk of data corruption or downtime | Reproduce on development/QA environment first |
| Not reading the full stack trace | Fixes symptom, not root cause | Read from bottom to top: the root cause is usually deepest in the stack |
| Hardcoding file paths in debug | Works on your machine only | Use `GetSrvProfString()` or system paths |

## References

- `common-errors.md` - Top 50 ADVPL/TLPP errors with causes and solutions
- `performance-tips.md` - Performance optimization techniques with code examples
