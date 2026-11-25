---
name: smartview-development
description: Create, migrate or publish Smart View (TReports) business objects - IntegratedProvider, getSchema/getData, .trp. NOT Smart X. "objeto de negocio Smart View", "migrar relatorio para Smart View", "callTReports".
---

# Smart View

This skill covers building custom Smart View business objects on TOTVS Protheus: the TLPP class that inherits from `totvs.framework.treports.integratedprovider.IntegratedProvider`, declares the `@totvsFrameworkTReportsIntegratedProvider` annotation, and implements `new()`, `getSchema()` and `getData()`. It documents the schema contract (`addProperty`, column types, dates), the parameter contract (`addParameter`, `setPergunte`, advanced search via `setCustomURL`, and the custom REST endpoint a combo requires), the query patterns inside `getData`, the `callTReports` menu source, and the full `.trp` resource publication cycle that makes the object reachable from the Protheus menu.

Activate this skill when the user is creating a new Smart View report or data view from scratch, migrating an existing TReport/FWMSPrinter/TMSPrinter/FWMSExcel report into a Smart View business object, wiring parameters with advanced search or combo values, or diagnosing why an object does not appear in the tool, returns no rows, or fails to import its resource. It does not cover Smart X (see `smartx-development`), automated testing of Smart View objects (see `advpr-test-automation`, which has `UTSchemaSmartView`/`UTGetDataSmartView`), nor SX dictionary scripts for the tables being read (see `sx-configuration`).

The referenced files are written in Brazilian Portuguese.

| Reference file | Read when |
|---|---|
| reference.md | Always -- Smart View vs Smart X, environment prerequisites, minimum contract, annotation, REST routes, object identity, end-to-end example |
| patterns-schema.md | Defining columns with `addProperty`: types, dates, calculated columns, discriminator column, page size |
| patterns-parameters.md | Defining parameters: `addParameter`, `setPergunte`, advanced search (lookup), combo values and the custom options endpoint |
| patterns-getdata.md | Writing the query and feeding rows: BeginSQL vs FWExecStatement, multi-branch, currency, workarea rules |
| patterns-migration-reports.md | Converting an existing TReport, FWMSPrinter, TMSPrinter or FWMSExcel report into a Smart View business object |
| deploy-trp.md | Publishing: prerequisites, `.trp` naming, TDS extension allowance, compile/restart cycle, Protheus x Smart View binding |
| troubleshooting.md | Diagnosing errors: object missing from the list, resource not found, parameter screen 500, empty combo, zero rows |
