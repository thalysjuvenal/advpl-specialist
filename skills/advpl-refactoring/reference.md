# ADVPL/TLPP Refactoring

## Overview

Patterns and rules for safe refactoring of ADVPL/TLPP code on TOTVS Protheus. Focuses on improving code structure without changing behavior. RF-001 to RF-006 (structure) are in this file; RF-007 to RF-012 (modernization of legacy APIs, guided by the lint engine) are in [`patterns-modernization.md`](patterns-modernization.md).

## When to Use

- Functions too long (>100 lines)
- Duplicated code across files or functions
- Complex nested conditionals (>3 levels deep)
- Variables with unclear names
- Dead code (unreachable blocks, unused variables/functions)
- God functions that do too many things
- Legacy APIs flagged by the lint engine (`TCQuery` with concatenation, `ConOut`, `CriaTrab`/`DbCreate`, `IIf`, direct SX access) or `ErrorBlock` + `Begin Sequence` in TLPP: see RF-007 to RF-012

## Refactoring Patterns

### RF-001: Extract Function (Complexity: LOW)

**Detect:** Function body > 100 lines with identifiable logical blocks
**Action:** Extract logical block into a new Static Function
**Rule:** The extracted function must receive all needed data as parameters (no shared Private/Public)

Before:
```advpl
User Function ProcessaPedido()
    // ... 40 lines validating data ...
    // ... 30 lines calculating totals ...
    // ... 50 lines saving to database ...
Return
```

After:
```advpl
User Function ProcessaPedido()
    If !fValidaDados(cCodPed)
        Return .F.
    EndIf
    nTotal := fCalculaTotais(cCodPed)
    lOk := fGravaPedido(cCodPed, nTotal)
Return lOk

Static Function fValidaDados(cCodPed)
    // 40 lines
Return lValido

Static Function fCalculaTotais(cCodPed)
    // 30 lines
Return nTotal

Static Function fGravaPedido(cCodPed, nTotal)
    // 50 lines
Return lOk
```

### RF-002: Simplify Conditionals (Complexity: LOW)

**Detect:** Nested If > 3 levels deep, or long If/ElseIf chains
**Action:** Use early return, guard clauses, or Do Case

Before:
```advpl
If lCondicao1
    If lCondicao2
        If lCondicao3
            // codigo principal
        EndIf
    EndIf
EndIf
```

After:
```advpl
If !lCondicao1
    Return
EndIf
If !lCondicao2
    Return
EndIf
If !lCondicao3
    Return
EndIf
// codigo principal
```

### RF-003: Remove Dead Code (Complexity: LOW)

**Detect:** Variables declared but never used, unreachable code after Return, commented-out blocks
**Action:** Remove the dead code entirely
**Rule:** Use Grep to verify the variable/function is not called from other files before removing

### RF-004: Improve Naming (Complexity: LOW)

**Detect:** Variables without Hungarian notation, single-letter names (except loop counters), unclear names
**Action:** Rename following Hungarian notation convention

| Type | Prefix | Example |
|------|--------|---------|
| Character | c | cNomeCli, cCodProd |
| Numeric | n | nValor, nQtde |
| Logical | l | lOk, lContinua |
| Date | d | dDataIni, dEmissao |
| Array | a | aDados, aItens |
| Object | o | oModel, oReport |
| Block | b | bBloco, bFiltro |

### RF-005: Eliminate Duplication (Complexity: MEDIUM)

**Detect:** Two or more code blocks with >5 similar lines
**Action:** Extract common logic into a shared function
**Rule:** Only extract if the logic is truly identical, not just visually similar

Before:
```advpl
Static Function fValPed(cCliente, cLoja)
    Local lOk   := .T.
    Local aArea := GetArea()

    DbSelectArea("SA1")
    DbSetOrder(1)
    If !DbSeek(xFilial("SA1") + cCliente + cLoja)
        lOk := .F.
    ElseIf SA1->A1_MSBLQL == "1"
        lOk := .F.
    EndIf
    RestArea(aArea)
    // ... validacoes do pedido ...
Return lOk

Static Function fValTit(cCliente, cLoja)
    Local lOk   := .T.
    Local aArea := GetArea()

    DbSelectArea("SA1")
    DbSetOrder(1)
    If !DbSeek(xFilial("SA1") + cCliente + cLoja)
        lOk := .F.
    ElseIf SA1->A1_MSBLQL == "1"
        lOk := .F.
    EndIf
    RestArea(aArea)
    // ... validacoes do titulo ...
Return lOk
```

After:
```advpl
Static Function fValPed(cCliente, cLoja)
    Local lOk := fCliAtivo(cCliente, cLoja)

    // ... validacoes do pedido ...
Return lOk

Static Function fValTit(cCliente, cLoja)
    Local lOk := fCliAtivo(cCliente, cLoja)

    // ... validacoes do titulo ...
Return lOk

Static Function fCliAtivo(cCliente, cLoja)
    Local lOk   := .T.
    Local aArea := GetArea()

    DbSelectArea("SA1")
    DbSetOrder(1)
    If !DbSeek(xFilial("SA1") + cCliente + cLoja)
        lOk := .F.
    ElseIf SA1->A1_MSBLQL == "1"
        lOk := .F.
    EndIf
    RestArea(aArea)
Return lOk
```

**Check:** compare the copies line by line: same index order, same messages, same side effects (here both versions leave SA1 positioned on the customer). A copy that differs in any of these is not a duplicate: pass the difference as a parameter or keep it separate. The new name must respect the identifier limit (`Static Function` up to 10 characters in `.prw`) and must not exist yet in the file (Grep).

### RF-006: Reduce Function Parameters (Complexity: MEDIUM)

**Detect:** Functions with >5 parameters
**Action:** Group related parameters into a JSON object or array
**Rule:** Only apply if parameters are logically related

Before:
```advpl
// chamada
fGrvLog("FATA001", SC5->C5_NUM, SC5->C5_CLIENTE, SC5->C5_LOJACLI, nTotal, nQtde, cUserName)

Static Function fGrvLog(cRotina, cPedido, cCliente, cLoja, nValor, nQtde, cUsuario)
    // ... grava o log com os 7 valores ...
Return .T.
```

After (only the order data is grouped; `cRotina` and `cUsuario` stay as parameters):
```advpl
// chamada
Local jPed := JsonObject():New()

jPed["pedido"]  := SC5->C5_NUM
jPed["cliente"] := SC5->C5_CLIENTE
jPed["loja"]    := SC5->C5_LOJACLI
jPed["valor"]   := nTotal
jPed["qtde"]    := nQtde
fGrvLog("FATA001", jPed, cUserName)
FreeObj(jPed)

Static Function fGrvLog(cRotina, jPed, cUsuario)
    // ... le jPed["pedido"], jPed["cliente"], jPed["loja"], jPed["valor"], jPed["qtde"] ...
Return .T.
```

**Check:**
- RF-006 changes the signature, which the Safety Rules otherwise forbid: apply it to `Static Function`s, or to functions whose callers are all found with Grep and changed in the same step. A `User Function` called from other sources, entry points or `ExecBlock` keeps its old signature as a wrapper that builds the JSON and calls the new function.
- The JSON object is shared with the caller (object reference). If the original function assigned values to its parameters (`cCliente := AllTrim(cCliente)`), assign to a `Local` instead, or the caller's object changes.
- Use the same key names on both sides: a misspelled key is not caught at compile time (check with `jPed:HasProperty("pedido")` when a key may be missing). An array is an option, but positions are easier to break than names. For values other than character, numeric and logical (dates, objects), confirm the type read back from the JSON (a confirmar no TDS) or keep them as separate parameters.

### RF-007 to RF-012: Modernization (Complexity: LOW to MEDIUM)

Legacy APIs found by the lint engine of the `advpl-code-review` skill (`--scope all`). Each pattern in [`patterns-modernization.md`](patterns-modernization.md) has before/after code, the risk, how to prove the behavior is the same, the lint rule and catalog code, and when not to apply it.

| ID | Pattern | Lint (severity) / catalog | Complexity |
|----|---------|---------------------------|------------|
| RF-007 | Concatenated `TCQuery` → `FWPreparedStatement` / `BeginSQL` | ADV015 (warn) / CA2050, CA2051 | MEDIUM |
| RF-008 | `ErrorBlock` + `Begin Sequence` → `Try`/`Catch`, `.tlpp` only | no rule / BG1200 | MEDIUM |
| RF-009 | `ConOut` → `FWLogMsg` | ADV003 (error) / CA1004 | LOW |
| RF-010 | `CriaTrab`/`DbCreate` → `FWTemporaryTable` | ADV010 (error), ADV011 (warn) / CA1000 | MEDIUM |
| RF-011 | `IIf` → `If`/`Else`/`EndIf` outside code blocks | ADV009 (warn) / CA4000 | LOW |
| RF-012 | Direct SX access → `FWSX3Util`, `GetMV`/`SuperGetMV`, `RetSqlName`... | ADV008 (error) / CA2000–CA2013 | MEDIUM |

## Refactoring Process

1. **Analyze** — Read the file, identify refactoring opportunities (for RF-007 to RF-012, start from the lint findings, see `patterns-modernization.md`)
2. **Prioritize** — Order by impact: dead code removal first, then naming, then extraction
3. **Present plan** — Show each refactoring with before/after
4. **Wait for approval** — User must approve before changes are applied
5. **Apply changes** — One refactoring at a time
6. **Verify** — Ensure the code structure is correct after each change

## Safety Rules

- NEVER change business logic during refactoring
- NEVER rename Public/Private variables that might be used externally
- ALWAYS check for external callers before removing functions (use Grep)
- ALWAYS preserve the function signature (parameters and return type)
- If unsure whether behavior will change, DO NOT refactor — flag it as a suggestion only
