---
name: advpl-code-generation
description: Use when the user asks to generate, create, or scaffold ADVPL/TLPP code for TOTVS Protheus -- User Functions, Static Functions, TLPP classes, MVC (Model/View/Controller), REST APIs, SOAP web services, entry points (pontos de entrada), TReport/FWMsPrinter reports, jobs, or workflows. Also triggers on Portuguese phrasing like "gerar codigo", "criar rotina", "criar fonte", "novo ponto de entrada", "criar classe tlpp", "gerar api rest", "criar mvc", or routine name patterns like FATA001/MATA010. Covers naming conventions, Hungarian notation, namespace rules, identifier length limits, and mandatory User Function/error-handling structure.
---

# ADVPL/TLPP Code Generation

This skill provides patterns, templates, and mandatory structural rules for generating new ADVPL (`.prw`) and TLPP (`.tlpp`) code for TOTVS Protheus. It covers naming conventions (module prefixes, Hungarian notation), the mandatory User Function skeleton with Protheus.doc headers and error handling, variable scope rules, TLPP namespace conventions (`custom.<agrupador>.<servico>`), and the 8/10/255-character identifier length limits per construct type.

Activate this skill whenever the user requests new code creation: a new function, a TLPP class, an MVC screen, a REST endpoint, a SOAP web service, an entry point, a report, a batch job, or any new `.prw`/`.tlpp` file. It does not cover reviewing existing code (see `advpl-code-review`), fixing errors in existing code (see `advpl-debugging`), improving existing code structure without adding features (see `advpl-refactoring`), or converting legacy `.prw` to `.tlpp` (see `advpl-to-tlpp-migration`).

The reference and pattern files below hold the concrete templates -- read the specific pattern file that matches the type of code being generated instead of relying on memory.

| Reference file | Read when |
|---|---|
| critical-rules.md | Always, before generating any code -- `User Function` vs bare `Function`, TLPP namespace declaration, identifier length limits (8/10/255), valid `JsonObject`/`TWsdlManager`/`FWFormView` methods, `ALIAS_CAMPO` field-name validation |
| reference.md | Always -- overview, naming conventions, mandatory User Function structure, variable scope, error handling, common mistakes |
| templates-classes.md | Generating a TLPP class (data, methods, constructor) |
| patterns-mvc.md | Generating an MVC screen (ModelDef/ViewDef/MenuDef) |
| patterns-rest.md | Generating a REST API endpoint (WsRestFul or TLPP `@Get/@Post` annotations) |
| patterns-soap.md | Generating a SOAP Web Service |
| patterns-treport.md | Generating a TReport-based report with embedded SQL |
| patterns-pontos-entrada.md | Generating a legacy (non-MVC) entry point (ponto de entrada) |
| patterns-pontos-entrada-mvc.md | Generating an MVC-based entry point |
| patterns-workflow.md | Generating a Protheus workflow routine |
| patterns-jobs.md | Generating a scheduled/background job |
| patterns-fwmsprinter.md | Generating a coordinate-based PDF report with FWMsPrinter |
| patterns-fwformbrowse.md | Generating a browse screen with FWFormBrowse |
| catalogo-top-50-pes.md | Looking up existing well-known entry points before creating a duplicate |
