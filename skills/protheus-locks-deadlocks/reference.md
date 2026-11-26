# Protheus Locks & Deadlocks

## Overview

Protheus uses a hybrid locking model: record-level Workarea locks (`RecLock`/`MsUnlock`) coordinated by **DBAccess** on top of the underlying database (PostgreSQL / MSSQL / Oracle). Lock leaks, deadlocks, and contention are among the most common production issues. This skill documents lock semantics, leak patterns, prevention rules (`BEGIN SEQUENCE / RECOVER`, `SoftLock`, transaction scoping), and diagnostic procedures.

> **Companion skills:** `query-builder` (query design), `advpl-debugging` (general performance and errors), `embedded-sql` (BeginSQL with macros).

## When to Use

- Investigating "Record locked by user XYZ" errors in production
- Diagnosing performance degradation under concurrent load
- Reviewing code that uses `RecLock`, `TCSqlExec`, or `BeginTran`
- Designing batch jobs that update large data sets
- Suspected lock leaks (locks persisting after the user disconnected)
- Suspected deadlocks (two operations blocking each other)
- Hardening a routine before promoting to production

## Bundled References

| File | Read When |
|---|---|
| [`patterns-prevention.md`](patterns-prevention.md) | Writing/refactoring code that locks records — `BEGIN SEQUENCE / RECOVER`, `SoftLock`, transaction scoping, lock ordering |
| [`diagnostics.md`](diagnostics.md) | Investigating live lock contention — `TopMemoStatus`, MonitorActiveLocks, DBAccess monitor, SQL Server / PG / Oracle queries |

## Lock Types in Protheus

| API | Granularity | Blocks Other Users? | Released By | Typical Use |
|---|---|---|---|---|
| `RecLock(alias, lInsert)` | Single record | **Yes** (until `MsUnlock`) | `MsUnlock()` / `MsUnlockAll()` / process exit | Direct single-record write; runs no `X3_VALID` and no SX7 triggers |
| `SoftLock(alias)` | Single record (optimistic) | **No** — returns `.F.` if already locked | Automatically when next record is read | Read-modify-write patterns where waiting is unwanted |
| `LockByName(cName, lShared, lFile)` | Named global lock (no record) | **Yes** (other callers wait) | `UnLockByName()` | Application-level coordination (only one job at a time) |
| `TCSqlExec(cQuery)` (DML) | Database transaction lock | **Yes** during DB transaction | DB commit/rollback | Bulk DML in the database; like `RecLock`, no dictionary validations or triggers |
| `BeginTran` / `EndTran` | Multi-record transaction scope | **Yes** for all records touched | `EndTran` (commit) / `DisarmTransaction` (rollback) | Transactional consistency across multiple `RecLock`s |

## Core APIs

### `RecLock(cAlias, lInsert)`

```advpl
If RecLock("SA1", .F.)         // .F. = lock existing record (.T. = insert new)
    SA1->A1_XFLAG := "1"
    SA1->(MsUnlock())          // ALWAYS pair with unlock
EndIf
```

- Returns `.T.` on success, `.F.` if another user holds the lock.
- **Blocks the caller** until `MV_TIMEOUT` (default ~10s) expires; then returns `.F.`.
- Writes directly: assigning a field after `RecLock` runs **no** `X3_VALID` validation and **no** SX7 trigger (gatilho). When those dictionary rules are needed, use `MsExecAuto` with the routine's documented example, or the MVC model API (`FWLoadModel` + `SetValue` + `VldData` + `CommitData`).
- **Must be paired with `MsUnlock()`** on every code path — including error paths.

### `MsUnlock()` / `MsUnlockAll()`

- `MsUnlock()` — releases the **current** record lock on the active alias.
- `MsUnlockAll()` — releases **all** record locks held by the current thread (use with caution; can break in-progress transactions).

### `SoftLock(cAlias)`

```advpl
If SoftLock("SA1")
    // Got the lock — proceed with optimistic update
    SA1->A1_XFLAG := "1"
Else
    // Another user has it — handle gracefully (skip, requeue, log)
EndIf
```

- Non-blocking — returns immediately.
- Released automatically when the cursor moves to the next record (no explicit unlock).
- Use for batch jobs where blocking would degrade throughput.

### `BeginTran` / `EndTran` / `DisarmTransaction`

```advpl
BeginTran()
BEGIN SEQUENCE
    If RecLock("SA1", .F.)
        SA1->A1_XFLAG := "1"
        SA1->(MsUnlock())
    Else
        Break
    EndIf

    If RecLock("SE1", .F.)
        SE1->E1_STATUS := "B"
        SE1->(MsUnlock())
    Else
        Break
    EndIf
RECOVER USING oError
    DisarmTransaction()
    FWLogMsg("ERROR", /*cTransactionId*/, "LOCKDIAG", /*cCategory*/, /*cStep*/, /*cMsgId*/, "[MyRoutine] Rolled back: " + oError:Description)
END SEQUENCE
EndTran()
```

- `BeginTran()` opens a transaction scope. All `RecLock` operations inside become part of one DB transaction.
- `EndTran()` commits.
- `DisarmTransaction()` rolls back — typically called inside a `RECOVER` block.
- The table must have `X2_TTS = Sim` (transaction-enabled) for transactions to work correctly.

## Common Lock Leak Patterns

| Pattern | Why It Leaks | Fix |
|---|---|---|
| `RecLock` without `MsUnlock` | Lock held until session terminates | Always pair, in **every** code path including errors |
| `Return` between `RecLock` and `MsUnlock` | Skips unlock | Restructure or use `BEGIN SEQUENCE / RECOVER USING` to guarantee unlock |
| Exception thrown after `RecLock` | Default error handler bypasses unlock | Wrap with `BEGIN SEQUENCE / RECOVER` and unlock in both branches |
| `DBCloseArea()` while record is locked | Closes alias but lock state can remain inconsistent | Unlock first, then close |
| Job/Schedule crash mid-transaction | Locks persist until DBAccess detects dead session (minutes/hours) | Use `BeginTran/EndTran` with proper recovery + monitor `MV_TIMEOUT` |
| `RecLock` inside a long loop without unlocking each iteration | Locks accumulate | Unlock per iteration, OR use `SoftLock` for batch reads |
| Calling user-defined function between lock and unlock that itself errors | Function error path doesn't know about outer lock | Make functions lock-aware OR isolate lock to smallest scope |

## Common Deadlock Patterns

A **deadlock** occurs when two threads each hold a lock the other needs. Protheus + DBAccess detect most deadlocks and abort one of the operations with an error, but at the cost of failed transactions.

### Pattern 1 — Inverse Lock Order

```
Thread A: locks SA1, then tries SE1
Thread B: locks SE1, then tries SA1
→ DEADLOCK
```

**Fix:** establish a project-wide **lock-ordering convention** (e.g., always lock tables alphabetically by alias). Document it and enforce in code review.

### Pattern 2 — Workarea Lock + DML on Same Table

```
Thread A: RecLock("SA1", .F.) on customer 000001
Thread B: TCSqlExec("UPDATE SA1010 SET A1_XFLAG = '1'")
→ B blocks until A releases; or B times out
```

**Fix:** never mix `TCSqlExec` writes with active Workarea locks on the same table in the same workflow. Choose one model.

### Pattern 3 — Trigger Cascading Lock

```
Thread A: fills an SC5 field through the screen, MsExecAuto or the MVC model (SetValue)
  → the SX7 trigger of that field calls a function that does RecLock("SA1", .F.)
Thread B: holds that SA1 record
→ A blocks on B inside the trigger
```

**Fix:** keep SX7 trigger expressions read-only and short. Avoid `RecLock` or expensive lookups inside triggers. A direct `RecLock` followed by field assignments never fires SX7 nor `X3_VALID` (see Lock Types): triggers and validations run only through the screen, `MsExecAuto` or the MVC model API, so that is where this cascade happens.

### Pattern 4 — Long-Running Lock

```
Thread A: RecLock("SE1", .F.); ... 5 minutes of computation ... ; MsUnlock()
Thread B-Z: all blocked on SE1 record
```

**Fix:** never hold a `RecLock` across user interaction or long computation. Compute first, then lock+update+unlock as fast as possible.

## Lock-Related System Parameters

| Parameter | Default | Purpose |
|---|---|---|
| `MV_TIMEOUT` | `~10` (seconds) | How long `RecLock` waits before returning `.F.` |
| `MV_LOCKMSG` | (system msg) | Custom message shown to the user when a lock is denied |
| `MV_TRYLOCK` | `.F.` | If `.T.`, retries failed locks N times automatically |
| `MV_TLOCKR` | `3` | Number of retries when `MV_TRYLOCK = .T.` |

## Lock Hierarchy & RetSqlName Considerations

When a query joins multiple physical tables (different `RetSqlName` results), the DB's lock manager — not Protheus — coordinates blocking. Implications:

- A `RecLock("SA1")` on customer X **does not** block a `TCQuery` selecting from `SF2010` joined to `SA1010` (different rows).
- A `TCSqlExec("UPDATE SF2010 ... WHERE F2_DOC = 'X'")` **will block** any concurrent `RecLock("SF2", .F.)` on document `'X'` until the DB transaction commits.
- Read-consistency behavior differs per database (SQL Server locking vs. MVCC on PostgreSQL/Oracle). A portable `%nolock%` macro is not documented in the TDN (a confirmar no TDS), and `ChangeQuery()` removes `NOLOCK` hints — see `query-builder/cross-database.md`.

## Quick Diagnostic Checklist

When a lock-related issue is reported:

- [ ] Confirm: lock leak (lock persists with no active user) vs contention (multiple users genuinely competing)
- [ ] Identify the routine via `TopMemoStatus()` or DBAccess monitor (see [`diagnostics.md`](diagnostics.md))
- [ ] Check the routine for `RecLock` without paired `MsUnlock` on all code paths
- [ ] Check for `BeginTran` without matching `EndTran`/`DisarmTransaction` in error paths
- [ ] Check for `RecLock` held across user input or long computation
- [ ] Check for trigger SX7 expressions that themselves acquire locks
- [ ] Check `MV_TIMEOUT` — if too short, healthy contention looks like errors; if too long, deadlocks take forever to resolve
- [ ] If recurring at the same time/day: review scheduled jobs (`SCHEDDEF`) for overlapping windows
- [ ] If after a recent deploy: diff the routine for new `TCSqlExec` calls or removed `MsUnlock`
- [ ] If across DB engines: do not hard-code database-specific locking hints (`WITH(NOLOCK)`) on read queries

See [`patterns-prevention.md`](patterns-prevention.md) for the full prevention rules and [`diagnostics.md`](diagnostics.md) for live diagnostic procedures.

## Anti-Patterns Quick Reference

| Anti-Pattern | Risk | Fix |
|---|---|---|
| `RecLock` without `MsUnlock` on every path | Lock leak | `BEGIN SEQUENCE / RECOVER` + unlock in both |
| `Return` between lock and unlock | Lock leak | Restructure |
| Long computation inside `RecLock` | Contention | Compute first, lock+write+unlock fast |
| Lock multiple tables in inconsistent order | Deadlock | Project-wide lock-ordering convention |
| Mixing Workarea `RecLock` and `TCSqlExec` on same table | Deadlock | Pick one model per workflow |
| `RecLock` inside SX7 trigger expression | Cascading deadlock | Keep triggers read-only |
| `MsUnlockAll()` mid-transaction | Breaks in-flight `BeginTran` | Use targeted `MsUnlock()` |
| No `BEGIN SEQUENCE / RECOVER` around lock block | Lock leak on error | Always wrap |
| Read query blocked by a long writer (MSSQL) | Read blocks on writer | Shorten the writer transaction; do not hard-code `WITH(NOLOCK)` (not portable; `%nolock%` a confirmar no TDS) |
| `BeginTran` without matching `EndTran` in all paths | Open transaction → DB-wide impact | Wrap with recovery |
| Closing alias while locked | Inconsistent state | Unlock first, close after |
| Trusting `MV_TIMEOUT` to "auto-fix" leaks | Just hides the leak; users still see errors | Fix the leak |
