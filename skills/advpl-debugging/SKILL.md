---
name: advpl-debugging
description: Debug ADVPL/TLPP errors - compilation, runtime (NIL, type mismatch), slow queries, locks, AppServer logs and stack traces. "erro de compilacao", "travou o lock", "performance lenta", "analisar log".
---

# ADVPL/TLPP Debugging

This skill provides a systematic methodology for diagnosing and resolving ADVPL/TLPP errors: a decision flow (compilation vs. runtime), a quick-diagnosis table by symptom, logging tool guidance (`Conout`, `FWLogMsg`, `ErrorBlock`), database lock diagnosis (`RecLock`/`MsUnlock`), and quick performance checks (wrong index, array growth in loops, Embedded SQL vs ISAM).

Activate this skill when the user reports an error message, a stack trace, a compilation failure, a hanging/locked record, a slow routine, or an AppServer crash/log to investigate. It does not cover generating new code from scratch (see `advpl-code-generation`), a general quality audit of working code (see `advpl-code-review`), restructuring code that already works correctly (see `advpl-refactoring`), or converting `.prw` to `.tlpp` (see `advpl-to-tlpp-migration`).

| Reference file | Read when |
|---|---|
| reference.md | Always -- debug methodology flow, quick diagnosis by symptom, logging tools, lock diagnosis, performance quick checks, common debugging mistakes |
| common-errors.md | Looking up a specific compilation or runtime error message (top 50 ADVPL/TLPP errors with cause and fix) |
| performance-tips.md | Investigating a performance bottleneck in depth (query optimization, loop efficiency, memory) |
