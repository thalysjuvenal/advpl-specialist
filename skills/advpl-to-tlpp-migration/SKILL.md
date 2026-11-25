---
name: advpl-to-tlpp-migration
description: Migrate or modernize procedural ADVPL (.prw) to TLPP classes with namespaces, keeping compatible wrappers. "migrar para tlpp", "converter prw para tlpp", "compatibilizar fonte", "transformar em classe".
---

# ADVPL to TLPP Migration

This skill guides the conversion of legacy `.prw` procedural code (User Functions, Static Functions, Private/Public variables) into modern `.tlpp` classes with `namespace` declarations, `data` properties, and `public`/`private` methods -- following the official TOTVS naming conventions (lowercase dot-separated namespaces, PascalCase classes, camelCase methods, no underscores). It defines the migration workflow (analyze -> identify -> map to class design -> user approval -> generate -> checklist -> validate) and mandates keeping the original `.prw` User Function as a thin backward-compatible wrapper delegating to the new class.

Activate this skill when the user wants an existing procedural routine converted to TLPP, needs help deciding a namespace, or is modernizing multiple `#Include` directives to `.th` includes. It does not cover generating brand-new TLPP code that has no ADVPL predecessor (see `advpl-code-generation`), behavior-preserving cleanup of code that stays in ADVPL (see `advpl-refactoring`), auditing code quality before migration (see `advpl-code-review`), or fixing errors encountered during or after migration (see `advpl-debugging`).

| Reference file | Read when |
|---|---|
| reference.md | Always -- overview, migration strategy flow, core conversion rules table, TLPP naming conventions, full before/after example, key migration decisions, common mistakes |
| migration-rules.md | Needing the complete mapping of every ADVPL construct (preprocessor directives, database operations, error handling, UI elements) to its TLPP equivalent |
| migration-checklist.md | Verifying a completed migration is thorough before declaring it done |
