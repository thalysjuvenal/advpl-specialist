---
name: query-builder
description: Build, choose the pattern for or optimize SQL queries on Protheus tables - DbSeek vs Embedded SQL vs TCSqlExec, filters, indexes, FWPreparedStatement. "montar query", "otimizar consulta", "qual indice usar".
---

# Protheus Query Builder

This skill helps build correct, safe, and optimized SQL against Protheus ERP tables, respecting the platform's database conventions: mandatory soft-delete (`D_E_L_E_T_`) and multi-branch (`xFilial`) filters, Hungarian-notation field names, dictionary-driven physical schemas (`RetSqlName()`), and SIX index alignment. It guides the agent to choose the right access pattern -- Workarea navigation vs Embedded SQL vs raw `TCSqlExec` -- enforce mandatory filters, order `WHERE` clauses to match available indexes, and parameterize every dynamic value with `FWPreparedStatement` to eliminate injection risk.

Activate this skill when building any query against Protheus tables (standard `SA*`/`SE*`/`SF*` or custom `Z*`), deciding between `DbSelectArea`/`DbSeek` and Embedded SQL, reviewing code for missing mandatory filters, adding parameterized queries, diagnosing slow queries via index misalignment, or writing cross-database code. It does not cover `BeginSQL`/`EndSQL` macro syntax itself (see `embedded-sql`, its companion skill for macro details), nor record locking semantics during writes (see `protheus-locks-deadlocks`).

| Reference file | Read when |
|---|---|
| reference.md | Always -- database conventions, table/field naming, mandatory filters, pattern-choice overview |
| patterns-workarea.md | Generating record-by-record code with `DbSelectArea` + `DbSeek` + `RecLock` |
| patterns-fwpreparedstatement.md | Building parameterized `TCQuery`/`TCSqlExec`, LIKE clauses, INSERT/UPDATE/DELETE |
| index-awareness.md | Choosing/validating an index, ordering WHERE clauses, common SIX key expressions |
| cross-database.md | Using `ChangeQuery()`, `TCGetDB()`, DBAccess macros, MSSQL/PostgreSQL/Oracle equivalents |
