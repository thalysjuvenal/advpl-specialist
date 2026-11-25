---
name: protheus-locks-deadlocks
description: Use when the user needs to understand, diagnose, or prevent Protheus record locks and deadlocks -- covering RecLock/MsUnlock/SoftLock/LockByName semantics, BeginTran/EndTran transaction scoping, lock leak and deadlock diagnostics (TopMemoStatus, MonitorActiveLocks, DBAccess monitor, SQL Server/PostgreSQL/Oracle lock queries), and prevention patterns (BEGIN SEQUENCE/RECOVER, lock ordering). Also triggers on Portuguese phrasing like "registro travado", "trava de registro", "deadlock", "erro de lock", "travamento no Protheus", "quem esta travando o registro", or "RecLock nao libera".
---

# Protheus Locks & Deadlocks

This skill documents the Protheus hybrid locking model -- record-level Workarea locks (`RecLock`/`MsUnlock`) coordinated by DBAccess on top of the underlying RDBMS (PostgreSQL, MSSQL, Oracle) -- and how to diagnose and prevent the lock leaks, contention, and deadlocks that are among the most common production issues. It covers lock API semantics (`RecLock`, `MsUnlock`/`MsUnlockAll`, `SoftLock`, `LockByName`, `TCSqlExec`, `BeginTran`/`EndTran`/`DisarmTransaction`), safe transaction scoping with `BEGIN SEQUENCE/RECOVER`, and live diagnostic procedures per database engine.

Activate this skill when the user reports a "Record locked by user XYZ" error, needs to investigate performance degradation under concurrent load, is writing or reviewing code that locks records, or is designing a batch job over large data sets where lock ordering matters. It does not cover query design or database-specific locking hints in SQL (see `query-builder`), general runtime/performance debugging unrelated to locking (see `advpl-debugging`), or `BeginSQL`/`EndSQL` macro syntax (see `embedded-sql`).

| Reference file | Read when |
|---|---|
| reference.md | Always -- lock types table, core lock/transaction APIs, when-to-use guidance |
| patterns-prevention.md | Writing or refactoring code that locks records -- `BEGIN SEQUENCE/RECOVER`, `SoftLock`, transaction scoping, lock ordering rules |
| diagnostics.md | Investigating live lock contention or deadlocks -- `TopMemoStatus`, MonitorActiveLocks, DBAccess monitor, engine-specific SQL lock queries |
