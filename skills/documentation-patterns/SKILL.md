---
name: documentation-patterns
description: Document ADVPL/TLPP code - Protheus.doc headers, routine docs, REST endpoint docs. "documentar rotina", "gerar cabecalho Protheus.doc", "documentar endpoint", "documentar API REST".
---

# ADVPL/TLPP Documentation Patterns

This skill provides templates and a generation process for turning ADVPL/TLPP source code into Protheus-standard technical documentation. It covers three output types: a `header` Protheus.doc comment block for a single function/method, a `full` markdown routine specification (objective, module, tables read/written, MV_* parameters, entry points, execution flow, dependencies, change history), and an `api` REST endpoint document (authentication, path/query parameters, request body, response schemas).

Activate this skill when the user asks to generate or add documentation for existing code -- headers, full routine specs, or API docs -- following TOTVS conventions. The process reads the target file, extracts functions/parameters/tables/MV_* usage/entry points/dependencies from the code itself, cross-checks git history for author and change log when available, then fills the appropriate template.

It does not cover explaining code in plain conversational language for an audience (see `code-explanation`), looking up native function signatures to fill in documentation accurately (see `protheus-reference`), or documenting the semantics of embedded SQL macros used inside a routine (see `embedded-sql`).

| Reference file | Read when |
|---|---|
| reference.md | Always -- the three documentation type templates (header/full/api) and the generation process |
