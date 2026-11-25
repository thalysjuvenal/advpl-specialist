# Lock Prevention Patterns

Code templates and rules for writing routines that lock records safely. Apply during `/generate`, `/refactor`, `/review`, and migration work.

## The Golden Rule

> **Every `RecLock` must be paired with an `MsUnlock` on every code path — including error paths.**

The only reliable way to enforce this in ADVPL/TLPP is to wrap the lock in `BEGIN SEQUENCE / RECOVER USING` and unlock in **both** the success and error branches.

---

## Pattern 1 — Single Record Update with Recovery

```advpl
#include "totvs.ch"

User Function FlagCust(cCustCode, cLoja, cFlag)
    Local lOk      := .F.
    Local oError
    Local aArea    := GetArea()
    Local aAreaSA1 := SA1->(GetArea())
    Local lLocked  := .F.

    DbSelectArea("SA1")
    SA1->(DbSetOrder(1))

    BEGIN SEQUENCE
        If !SA1->(DbSeek(xFilial("SA1") + cCustCode + cLoja))
            Break
        EndIf

        If !RecLock("SA1", .F.)
            Break               // Could not acquire lock
        EndIf
        lLocked := .T.

        SA1->A1_XFLAG := cFlag
        lOk := .T.
    RECOVER USING oError
        FWLogMsg("ERROR", /*cTransactionId*/, "FLAGCUST", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Error: " + oError:Description, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
    END SEQUENCE

    // Unlock runs in BOTH success and error paths
    If lLocked
        SA1->(MsUnlock())
    EndIf

    SA1->(RestArea(aAreaSA1))
    RestArea(aArea)
Return lOk
```

### Key rules

- The `lLocked` flag tracks whether `RecLock` actually succeeded — only call `MsUnlock` if it did.
- `BEGIN SEQUENCE / RECOVER USING` catches any runtime error inside the block, including from triggered SX7 or validations.
- Unlock + `RestArea` happen **outside** the `END SEQUENCE`, guaranteed to run.
- Returns `lOk` — caller knows whether the change persisted.

---

## Pattern 2 — Multi-Record Transaction

```advpl
#include "totvs.ch"

User Function ApproveOrder(cOrderNum)
    Local lOk      := .F.
    Local oError
    Local aArea    := GetArea()
    Local aAreaSC5 := SC5->(GetArea())
    Local aAreaSE1 := SE1->(GetArea())
    Local lLockedSC5 := .F.
    Local lLockedSE1 := .F.

    BeginTran()
    BEGIN SEQUENCE
        // Always lock in a consistent project-wide order. Here: SC5 before SE1.
        DbSelectArea("SC5")
        SC5->(DbSetOrder(1))
        If !SC5->(DbSeek(xFilial("SC5") + cOrderNum))
            Break
        EndIf
        If !RecLock("SC5", .F.)
            Break
        EndIf
        lLockedSC5 := .T.
        SC5->C5_XSTATUS := "AP"

        DbSelectArea("SE1")
        SE1->(DbSetOrder(1))
        If !SE1->(DbSeek(xFilial("SE1") + cOrderNum))
            Break
        EndIf
        If !RecLock("SE1", .F.)
            Break
        EndIf
        lLockedSE1 := .T.
        SE1->E1_STATUS := "B"

        lOk := .T.
    RECOVER USING oError
        FWLogMsg("ERROR", /*cTransactionId*/, "APPROVEORDER", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Error: " + oError:Description, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
    END SEQUENCE

    If lLockedSC5
        SC5->(MsUnlock())
    EndIf
    If lLockedSE1
        SE1->(MsUnlock())
    EndIf

    If lOk
        EndTran()                // Commit
    Else
        DisarmTransaction()      // Rollback
    EndIf

    SC5->(RestArea(aAreaSC5))
    SE1->(RestArea(aAreaSE1))
    RestArea(aArea)
Return lOk
```

### Key rules

- **Lock order matters.** Always lock tables in the same project-wide order. Document the convention (e.g., alphabetical by alias) and enforce in review.
- Both tables must have `X2_TTS = Sim` for the transaction to be effective.
- `BeginTran` / `EndTran` / `DisarmTransaction` form a strict triple — every `BeginTran` must be followed by **exactly one** of the other two.
- Track each lock independently with its own flag — the second lock might fail while the first succeeded.

---

## Pattern 3 — Batch with `SoftLock` (Non-Blocking)

For batch jobs that should skip locked records instead of waiting:

```advpl
#include "totvs.ch"

User Function BatchProcess()
    Local nProcessed := 0
    Local nSkipped   := 0
    Local aArea      := GetArea()

    DbSelectArea("SE1")
    SE1->(DbSetOrder(1))
    SE1->(DbGoTop())

    While !SE1->(Eof())
        If SE1->E1_FILIAL == xFilial("SE1") .And. SE1->E1_STATUS == "A"
            If SoftLock("SE1")
                SE1->E1_STATUS := "B"
                nProcessed++
                // SoftLock auto-releases when cursor moves
            Else
                nSkipped++
                // Record was locked by another user — skip and continue
            EndIf
        EndIf
        SE1->(DbSkip())
    EndDo

    FWLogMsg("INFO", /*cTransactionId*/, "BATCHPROCESS", /*cCategory*/, /*cStep*/, /*cMsgId*/, ;
        "Processed: " + cValToChar(nProcessed) + " | Skipped: " + cValToChar(nSkipped), ;
        /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

    RestArea(aArea)
Return nProcessed
```

### Key rules

- `SoftLock` returns immediately — never blocks.
- Released automatically on next `DbSkip` / `DbGoto` — no explicit `MsUnlock` needed.
- For records that were skipped, **requeue them** at the end (a second pass) or log them for manual handling. Don't silently lose work.

---

## Pattern 4 — Application-Level Mutex with `LockByName`

To ensure only one instance of a job runs at a time (regardless of record):

```advpl
#include "totvs.ch"

User Function NightlyJob()
    Local cLockName := "NIGHTLY_JOB_" + cFilAnt
    Local lOk       := .F.
    Local oError

    // .F. = exclusive lock | .T. = file scope (across all environments)
    If !LockByName(cLockName, .F., .F.)
        FWLogMsg("WARN", /*cTransactionId*/, "NIGHTLYJOB", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Already running - exiting", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
        Return .F.
    EndIf

    BEGIN SEQUENCE
        // ... main job logic ...
        lOk := .T.
    RECOVER USING oError
        FWLogMsg("ERROR", /*cTransactionId*/, "NIGHTLYJOB", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Error: " + oError:Description, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
    END SEQUENCE

    UnLockByName(cLockName, .F., .F.)
Return lOk
```

### Key rules

- `LockByName` does not lock any record — it's a named application-wide flag.
- Always pair with `UnLockByName` in the recovery path.
- Choose a stable, unique lock name (include `cFilAnt` if the job is per-branch).

---

## Pattern 5 — Insert with Sequenced Code

When inserting using `GetSxeNum()`, the sequence reservation is itself a lock that must be released:

```advpl
#include "totvs.ch"

User Function CreateOrder(cCliente, cLoja)
    Local cNum    := ""
    Local lOk     := .F.
    Local oError
    Local aArea   := GetArea()
    Local aAreaSC5 := SC5->(GetArea())
    Local lLocked := .F.
    Local lSxeOk  := .F.

    BEGIN SEQUENCE
        cNum := GetSxeNum("SC5", "C5_NUM")
        lSxeOk := .T.

        DbSelectArea("SC5")
        SC5->(DbSetOrder(1))
        If !SC5->(DbSeek(xFilial("SC5") + cNum))
            If !RecLock("SC5", .T.)            // .T. = insert
                Break
            EndIf
            lLocked := .T.

            SC5->C5_FILIAL  := xFilial("SC5")
            SC5->C5_NUM     := cNum
            SC5->C5_CLIENTE := cCliente
            SC5->C5_LOJACLI := cLoja
            SC5->C5_EMISSAO := dDataBase

            lOk := .T.
        EndIf
    RECOVER USING oError
        FWLogMsg("ERROR", /*cTransactionId*/, "CREATEORDER", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Error: " + oError:Description, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
    END SEQUENCE

    If lLocked
        SC5->(MsUnlock())
    EndIf

    If lSxeOk
        If lOk
            ConfirmSx8()              // Confirm sequence consumption
        Else
            RollBackSx8()             // Release reserved number for reuse
        EndIf
    EndIf

    SC5->(RestArea(aAreaSC5))
    RestArea(aArea)
Return If(lOk, cNum, "")
```

### Key rules

- `GetSxeNum` reserves the next number and **must** be paired with `ConfirmSx8` (success) or `RollBackSx8` (failure) — otherwise the number is leaked.
- Track separately whether `RecLock` and `GetSxeNum` succeeded.

---

## Project-Wide Conventions

### Lock Ordering

Document a single rule and stick to it. Common choices:

- **Alphabetical by alias:** `SA1` before `SE1` before `SF2`. Easy to memorize, easy to review.
- **Top-down by domain hierarchy:** master tables before detail (e.g., `SC5` header before `SC6` items).
- **Read-then-write:** acquire all read positions first, then `RecLock` only when ready to write.

Pick one. Document it in `CONTRIBUTING.md` or project guidelines. Code review must enforce it.

### Lock Scope Minimization

Hold locks for the **shortest possible time**:

- **Bad:** `RecLock`, then call external API, then `MsUnlock` → other users blocked for seconds.
- **Good:** call API, prepare data, `RecLock`, write, `MsUnlock`.

### No Locks in SX7 Triggers

SX7 trigger expressions (`X7_REGRA`) run **inside** the `RecLock` of the source field's record. Acquiring another lock from within is a deadlock waiting to happen.

- ✅ `Posicione("SA1", 1, xFilial("SA1") + M->ZA1_CLIENT, "A1_NOME")` — read-only lookup
- ❌ Calling a function that does `RecLock("SA1", .F.)`
- ❌ Calling `TCSqlExec("UPDATE ...")` from inside a trigger

### Avoid `MsUnlockAll`

`MsUnlockAll()` releases **every** lock on the current thread. If called inside a `BeginTran`, it can break the transaction's atomicity. Always prefer targeted `(cAlias)->(MsUnlock())`.

### Error Path Discipline

Every routine that locks must answer:

- What happens if the function returns mid-block?
- What happens if a called function throws?
- What happens if the user disconnects?

If the answer to any is "the lock leaks," wrap with `BEGIN SEQUENCE / RECOVER USING` and unlock in both branches.

### `MV_TIMEOUT` Tuning

- Too short (1–2 sec): healthy contention looks like errors; users see "record locked" frequently.
- Too long (60+ sec): real deadlocks make users wait a minute before getting the error.
- Default ~10 sec is usually correct. **Don't tune this to mask leaks** — fix the leak instead.

---

## Refactor Checklist

When converting legacy lock code:

- [ ] Every `RecLock` has a paired `MsUnlock` on every code path
- [ ] Wrapped with `BEGIN SEQUENCE / RECOVER USING` (or equivalent)
- [ ] Lock-acquired flag tracks success — `MsUnlock` is gated on it
- [ ] `BeginTran` / `EndTran` / `DisarmTransaction` are balanced
- [ ] Lock order matches the project convention
- [ ] No external calls (HTTP, file I/O, user prompts) between lock and unlock
- [ ] `GetSxeNum` paired with `ConfirmSx8` / `RollBackSx8`
- [ ] No `RecLock` or `TCSqlExec` inside SX7 trigger expressions
- [ ] No `MsUnlockAll` inside an active transaction
- [ ] `(cAlias)->(MsUnlock())` qualified by alias when working with multiple tables
