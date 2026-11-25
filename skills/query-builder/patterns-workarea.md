# Pattern: Workarea Access (DbSelectArea + DbSeek)

Use Workarea when:

- Looking up a single record by an existing SIX index key
- Iterating records sequentially in a known order
- Performing locking + a direct update with `RecLock`/`MsUnlock` (no `X3_VALID` and no SX7 triggers run)

When the write needs dictionary validations or SX7 triggers, do not write the fields yourself: use `MsExecAuto` with the routine's documented example, or the MVC model API (`FWLoadModel` + `SetValue` + `VldData` + `CommitData`).

Avoid Workarea when:

- The query requires aggregation (SUM/COUNT/AVG/MAX/MIN)
- Joining 3+ tables — nested seeks are slow and unreadable
- No suitable index exists for the access path
- Reading large result sets where SQL projection is much faster

## Pattern 1.1 — Single Record Lookup by Index

```advpl
#include "totvs.ch"

User Function GetCustomerName(cCustCode, cLoja)
    Local cName    := ""
    Local aArea    := GetArea()
    Local aAreaSA1 := SA1->(GetArea())

    DbSelectArea("SA1")
    SA1->(DbSetOrder(1))  // Index 1: A1_FILIAL + A1_COD + A1_LOJA

    If SA1->(DbSeek(xFilial("SA1") + cCustCode + cLoja))
        cName := AllTrim(SA1->A1_NOME)
    EndIf

    SA1->(RestArea(aAreaSA1))
    RestArea(aArea)
Return cName
```

### Key rules

- Always `SA1->(DbSetOrder(N))` before `DbSeek` — index 1 is the primary key by convention.
- Build the seek key **in the exact order of the index expression** (e.g., `A1_FILIAL + A1_COD + A1_LOJA`).
- Pad each component with `Space()` / `StrZero()` to the field length if you don't have the full key.
- `xFilial("SA1")` returns `''` (empty) for shared tables, so the call is safe even on non-branched dictionaries.

## Pattern 1.2 — Sequential Scan with Range Filter

```advpl
#include "totvs.ch"

User Function ListReceivablesDue(dDataIni, dDataFim)
    Local aResult  := {}
    Local aArea    := GetArea()
    Local aAreaSE1 := SE1->(GetArea())
    Local cKeyIni
    Local cKeyFim

    DbSelectArea("SE1")
    SE1->(DbSetOrder(6))  // Example: E1_FILIAL + DTOS(E1_VENCREA)

    cKeyIni := xFilial("SE1") + DtoS(dDataIni)
    cKeyFim := xFilial("SE1") + DtoS(dDataFim)

    SE1->(DbSeek(cKeyIni, .T.))   // .T. = soft seek (positions on first >= key)
    While !SE1->(Eof()) .And. ;
          xFilial("SE1") == SE1->E1_FILIAL .And. ;
          DtoS(SE1->E1_VENCREA) <= DtoS(dDataFim)

        If SE1->(!Deleted())                   // Defensive: skip deleted
            aAdd(aResult, { SE1->E1_PREFIXO, SE1->E1_NUM, SE1->E1_VALOR })
        EndIf
        SE1->(DbSkip())
    EndDo

    SE1->(RestArea(aAreaSE1))
    RestArea(aArea)
Return aResult
```

### Key rules

- `DbSeek(key, .T.)` with `.T.` does a **soft seek** — positions at the first record `>= key`.
- The stop condition must re-check `XX_FILIAL` because the index continues into the next branch.
- Always check `Deleted()` (or rely on `Set Deleted On`, configured at SetPrvt level) — `DbSkip` does not skip deleted rows unless the deletion filter is active.

## Pattern 1.3 — Locking + Update (RecLock / MsUnlock)

`RecLock` locks a single record so the code can write its fields directly. The write runs no `X3_VALID` validation and no SX7 trigger. Use it for fields the code owns (such as a custom `_X*` flag); when the dictionary rules must run, use `MsExecAuto` or the MVC model API instead.

```advpl
#include "totvs.ch"

User Function FlagCustomer(cCustCode, cLoja, cFlag)
    Local lOk      := .F.
    Local aArea    := GetArea()
    Local aAreaSA1 := SA1->(GetArea())

    DbSelectArea("SA1")
    SA1->(DbSetOrder(1))

    If SA1->(DbSeek(xFilial("SA1") + cCustCode + cLoja))
        // RecLock("SA1", .F.) = lock existing record (.T. = insert new)
        If RecLock("SA1", .F.)
            SA1->A1_XFLAG := cFlag
            SA1->(MsUnlock())
            lOk := .T.
        EndIf
    EndIf

    SA1->(RestArea(aAreaSA1))
    RestArea(aArea)
Return lOk
```

### Key rules

- `RecLock("SA1", .F.)` — `.F.` for existing record, `.T.` to insert a new one.
- Always pair every successful `RecLock` with `MsUnlock()` — even on error paths (use `BEGIN SEQUENCE / RECOVER`).
- `RecLock` does **not** run `SX7` triggers (gatilhos) or `SX3` validations (`X3_VALID`): the assignment is written as is. When those rules are needed, use `MsExecAuto` with the routine's documented example, or the MVC model API (`SetValue` + `VldData` + `CommitData`). For bulk DML, `TCSqlExec` (which also skips them) is the alternative.

## Pattern 1.4 — Insert via RecLock

```advpl
#include "totvs.ch"

User Function CreateCustomCode(cCod, cDesc)
    Local lOk     := .F.
    Local aArea   := GetArea()
    Local aAreaZZ := ZZ1->(GetArea())

    DbSelectArea("ZZ1")
    ZZ1->(DbSetOrder(1))

    If !ZZ1->(DbSeek(xFilial("ZZ1") + cCod))
        If RecLock("ZZ1", .T.)              // .T. = insert
            ZZ1->ZZ1_FILIAL := xFilial("ZZ1")
            ZZ1->ZZ1_COD    := cCod
            ZZ1->ZZ1_DESCRI := cDesc
            ZZ1->(MsUnlock())
            lOk := .T.
        EndIf
    EndIf

    ZZ1->(RestArea(aAreaZZ))
    RestArea(aArea)
Return lOk
```

### Key rules

- Always check duplicates **before** inserting (`DbSeek` first).
- Populate `XX_FILIAL` explicitly — even though the field has a default, depending on dictionary config it may not be auto-filled on direct `RecLock`.
- For sequenced codes, use `GetSxeNum()` + `ConfirmSx8()` / `RollBackSx8()`.

## Common Workarea Mistakes

| Mistake | Why It Hurts | Fix |
|---|---|---|
| Forgetting `DbSetOrder` | Uses last-set index — unpredictable | Always call before `DbSeek` |
| Building seek key with wrong field order | `DbSeek` won't find the record | Match the SIX key expression exactly |
| Not padding key with `Space()`/`StrZero()` | Partial keys may not match | Pad to the full field length |
| Not saving/restoring area | Breaks caller's cursor | `GetArea()` / `RestArea()` pair |
| `RecLock` without `MsUnlock` | Lock leak — record blocked until session ends | Always pair, including in error paths |
| Iterating without `XX_FILIAL` re-check | Bleeds into next branch's records | Re-check in `While` condition |
| Calling `DbCloseArea` on a system alias (SA1, SE1, ...) | Closes the alias for the whole session | Never close system tables — only `GetNextAlias()` ones |
