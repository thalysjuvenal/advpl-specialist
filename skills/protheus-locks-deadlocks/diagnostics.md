# Lock Diagnostics

Procedures for investigating live lock contention and leaks. Use during `/diagnose` workflows or production incident response.

## Decision Tree

```
Lock-related symptom reported
│
├── User sees "record locked" once → Healthy contention. No action.
│
├── User sees "record locked" repeatedly on same record → Likely leak.
│   → Run "Protheus-side diagnostics" below
│
├── Multiple users blocked on different records same routine → Slow lock holder.
│   → Profile the routine; minimize lock scope
│
├── Errors come in pairs ("transaction aborted") → Likely deadlock.
│   → Run "DB-side deadlock analysis" below
│
└── All users frozen / system unresponsive → DBAccess pool exhaustion or DB-level lock.
    → Run "DBAccess monitor" and DB-specific queries below
```

## Protheus-Side Diagnostics

### `TopMemoStatus()`

Returns a memo string describing all currently active DBAccess sessions, including which records each session has locked. Best entry point for live investigation.

```advpl
User Function DiagLocks()
    MemoWrite("\\dba_locks.txt", TopMemoStatus())
    FWLogMsg("INFO", /*cTransactionId*/, "LOCKDIAG", /*cCategory*/, /*cStep*/, /*cMsgId*/, "[DiagLocks] Wrote DBAccess status snapshot")
Return Nil
```

What to look for:
- Sessions with locks but no recent activity → likely leaks
- Sessions holding multiple table locks → potential deadlock candidates
- Long-held locks (timestamp far in the past) → routine running too long inside lock scope

### MonitorActiveLocks (DBAccess Monitor)

The DBAccess monitor (graphical tool shipped with TopConnect) shows active locks per session in real time. Useful for production oncall.

- Connect to the DBAccess instance the Protheus environment uses.
- Filter by user / station / table.
- Look for locks held longer than `MV_TIMEOUT` — those are leaks.
- Force-disconnect orphaned sessions (with caution; will roll back any in-flight transaction).

### `LogReg` and SemHib Logs

For routines that misbehave under specific conditions, raise log verbosity:

- `MV_LOGSEM` parameter controls semaphore/lock log emission.
- DBAccess `dbaccess.log` records lock contention events when configured with `LogLevel=2` or higher in `dbaccess.ini`.
- Look for `MsgRun: Aguardando Liberação` and `Lock Timeout Expired` patterns.

### Identifying the Holding User

When a lock-blocked error appears, Protheus typically shows: `Registro bloqueado por: USERXYZ - WORKSTATION01`. Cross-reference:

- `MV_LOCKMSG` parameter customizes this message format.
- `cUserName` at runtime gives the current logged user.
- TopMemoStatus output includes session ID + station name.

### Tracing a Leaking Routine

When you've identified the routine but not the leaking line:

```advpl
Static lDebug := .T.

User Function MyRoutine()
    // ... existing code ...

    If lDebug
        FWLogMsg("INFO", /*cTransactionId*/, "LOCKDIAG", /*cCategory*/, /*cStep*/, /*cMsgId*/, "[MyRoutine] Pre-RecLock @ " + Time())
    EndIf
    RecLock("SA1", .F.)
    If lDebug
        FWLogMsg("INFO", /*cTransactionId*/, "LOCKDIAG", /*cCategory*/, /*cStep*/, /*cMsgId*/, "[MyRoutine] RecLock acquired @ " + Time())
    EndIf

    // ... business logic ...

    SA1->(MsUnlock())
    If lDebug
        FWLogMsg("INFO", /*cTransactionId*/, "LOCKDIAG", /*cCategory*/, /*cStep*/, /*cMsgId*/, "[MyRoutine] MsUnlock done @ " + Time())
    EndIf
Return Nil
```

If the log shows `RecLock acquired` without a matching `MsUnlock done`, you've found the leak path.

---

## DB-Side Deadlock Analysis

When a deadlock is suspected (DBAccess reported `chosen as deadlock victim` or transaction aborted unexpectedly), drop to the database to confirm and identify the participants.

### SQL Server

```sql
-- Currently blocking sessions
EXEC sp_who2

-- Lock details
EXEC sp_lock

-- Deadlock graph (last 5 deadlocks)
SELECT TOP 5
    xed.value('@timestamp', 'datetime2(3)')   AS deadlock_time,
    xed.query('.')                            AS deadlock_xml
FROM (
    SELECT CAST(target_data AS XML) AS target_data
    FROM sys.dm_xe_session_targets st
    JOIN sys.dm_xe_sessions s ON s.address = st.event_session_address
    WHERE s.name = 'system_health'
      AND st.target_name = 'ring_buffer'
) AS data
CROSS APPLY target_data.nodes('//RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEventData(xed)
ORDER BY deadlock_time DESC;
```

Look for:
- The two SPIDs involved
- The objects (tables) and resources (pages, keys) contended
- The two queries that deadlocked

### PostgreSQL

```sql
-- Current blocking sessions
SELECT
    blocked.pid          AS blocked_pid,
    blocked.usename      AS blocked_user,
    blocked.query        AS blocked_query,
    blocking.pid         AS blocking_pid,
    blocking.usename     AS blocking_user,
    blocking.query       AS blocking_query
FROM pg_stat_activity blocked
JOIN pg_stat_activity blocking
  ON blocking.pid = ANY(pg_blocking_pids(blocked.pid));

-- All current locks
SELECT
    pid,
    locktype,
    relation::regclass AS table_name,
    mode,
    granted
FROM pg_locks
WHERE granted = false
   OR pid IN (
       SELECT unnest(pg_blocking_pids(pid)) FROM pg_stat_activity
   );
```

Look for `granted = false` rows — those are sessions waiting on a lock.

### Oracle

```sql
-- Current blocking sessions
SELECT
    blocking.sid          AS blocking_sid,
    blocking.username     AS blocking_user,
    blocking.osuser       AS blocking_os_user,
    blocked.sid           AS blocked_sid,
    blocked.username      AS blocked_user
FROM v$lock l1
JOIN v$session blocking ON blocking.sid = l1.sid
JOIN v$lock l2 ON l1.id1 = l2.id1 AND l1.id2 = l2.id2
JOIN v$session blocked ON blocked.sid = l2.sid
WHERE l1.block = 1
  AND l2.request > 0;

-- Current locks held by a session
SELECT s.sid, s.serial#, s.username, l.type, l.lmode, l.request, o.object_name
FROM v$lock l
JOIN v$session s ON s.sid = l.sid
LEFT JOIN dba_objects o ON o.object_id = l.id1
WHERE s.username = 'PROTHEUS_USER';

-- Deadlock alert log entries are in $ORACLE_BASE/diag/rdbms/.../trace/alert_*.log
```

### Killing a Session (Last Resort)

If a leaked lock is blocking production and you need immediate relief:

- **MSSQL:** `KILL <spid>` — verify the SPID first via `sp_who2`
- **PostgreSQL:** `SELECT pg_terminate_backend(<pid>);`
- **Oracle:** `ALTER SYSTEM KILL SESSION '<sid>,<serial#>' IMMEDIATE;`

⚠️ Always investigate the root cause **first**. Killing the session releases the lock but loses any in-flight transaction. Document the kill, the routine involved, and the timestamp for post-mortem.

---

## DBAccess Configuration Checks

Lock issues are sometimes configuration, not code:

| Setting | Where | Symptom If Misconfigured |
|---|---|---|
| `MV_TIMEOUT` | SX6 | Too short → false "lock denied"; too long → real deadlocks frozen for minutes |
| `MV_TRYLOCK` / `MV_TLOCKR` | SX6 | Auto-retries can mask real contention |
| DBAccess pool size | `dbaccess.ini` | Too small → users wait for connections; looks like a lock |
| `Server Lock Mode` (MSSQL) | DBAccess config | Page-level locks cause false contention; row-level usually best |
| `idle_in_transaction_session_timeout` (PG) | postgresql.conf | If too high, leaked transactions linger; if too low, legit long jobs aborted |
| Statement timeout | DB-level | Mid-routine timeouts leave Protheus state inconsistent |

---

## Recurring Patterns to Watch For

| Symptom | Likely Cause |
|---|---|
| Lock leaks always in the same routine | Missing `MsUnlock` on one code path |
| Lock leaks every Monday morning | Weekend job that crashed mid-transaction |
| Deadlocks during peak hour only | Healthy contention, but lock scope too wide |
| Errors shortly after deploy | New `TCSqlExec` mixed with existing Workarea code |
| Lock denied messages with no holder | DBAccess session orphaned; restart DBAccess if needed |
| All locks released only at user logoff | Routine never reaches `MsUnlock`; check for `Return` between lock and unlock |
| Job blocks on its own previous run | Missing `LockByName` / `UnLockByName` cleanup |

---

## Post-Incident Checklist

After resolving a lock incident:

- [ ] Captured `TopMemoStatus()` snapshot at incident time
- [ ] Captured DB-side blocking-session output
- [ ] Identified the routine + line that leaked or deadlocked
- [ ] Reproduced in non-production (or have evidence ruling out reproduction)
- [ ] Wrote a regression test (probat or manual repro script)
- [ ] Fixed the code per `patterns-prevention.md`
- [ ] Reviewed adjacent routines for the same anti-pattern
- [ ] Updated runbook / oncall documentation with the symptom + diagnosis
