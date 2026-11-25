---
name: embedded-sql
description: Use when the user needs to write, review, or migrate SQL queries in ADVPL/TLPP using BeginSQL/EndSQL blocks and macro expressions (%table%, %xfilial%, %notDel%, %exp%, %Order%) instead of raw TCQuery string concatenation -- covering INNER/LEFT JOIN patterns, aggregations (SUM/COUNT/GROUP BY/HAVING), subqueries, column type declarations, DML via TCSqlExec, and routing user input to FWPreparedStatement. Also triggers on Portuguese phrasing like "consulta SQL", "query embutida", "migrar TCQuery para BeginSQL", "escrever SELECT com filial e notDel", or "montar JOIN em ADVPL".
---

# Embedded SQL in ADVPL/TLPP

This skill covers writing SQL inside ADVPL/TLPP using `BeginSQL ... EndSQL` blocks and their special macro expressions -- `%table:TABLE%` for physical table resolution, `%xfilial:TABLE%` for branch filtering, `%notDel%` for logical-deletion filtering, `%exp:EXPRESSION%` to insert an expression value into the SQL text (it is not parameter binding), and `%Order:TABLE%` for primary-key ordering. It also covers `column` type declarations, JOIN and aggregation patterns, subqueries, and migrating legacy `TCQuery` string-concatenation code to Embedded SQL. The macros suit static/internal values; text typed by the user or received from outside goes through `FWPreparedStatement`.

Activate this skill whenever the user is writing a new query, reviewing an existing one for correctness/safety, or converting old concatenated-string SQL to the modern BeginSQL syntax. It also covers the restrictions and gotchas of BeginSQL (no `*` at line start, always include `%notDel%` and filial filtering, use `GetNextAlias()`, close aliases) and when to use `TCSqlExec` instead for INSERT/UPDATE/DELETE.

It does not cover general native function lookups unrelated to SQL (see `protheus-reference`), business-process context for which tables/fields to query (see `protheus-business`), or generating documentation for a routine that happens to contain SQL (see `documentation-patterns`).

| Reference file | Read when |
|---|---|
| reference.md | Always -- BeginSQL syntax, macro expressions, JOIN/aggregation/subquery patterns, DML via TCSqlExec, performance tips, and TCQuery migration |
