---
name: smartx-development
description: Use when the user wants to build, migrate, or troubleshoot a Smart X routine -- TOTVS's metadata-driven UI framework that generates modern PO-UI screens from a data dictionary Object/Model/Interface/Launcher chain. Covers the model.tlpp/interface.tlpp/launcher artifacts, ADVPL function integration via pageActions/tableActions/onChange, converting a legacy MVC browse to Smart X, and common troubleshooting. Also triggers on Portuguese phrasing like "tela Smart X", "gerar tela por metadados", "migrar MVC para Smart X", "criar Modelo e Interface Smart X", "launcher Smart X", or names like FINA050SM/MATA110SX.
---

# Smart X

This skill covers developing TOTVS Smart X routines: the Object -> Model -> Interface -> Launcher chain that turns a data dictionary table (SX2/SX3) into an automatically-rendered PO-UI screen without hand-written Angular components. It documents the required includes and annotations for the Model (`totvs.framework.structure.model.th`) and Interface (`totvs.framework.structure.Interface.th`) TLPP classes, the Launcher function that registers the routine in the Protheus menu, integrating existing ADVPL functions into the interface via `pageActions`/`tableActions`/events, and converting only the browse (Data View) of a legacy MVC routine to Smart X while keeping ModelDef/ViewDef/MenuDef intact.

Activate this skill when the user is creating a new Smart X routine from scratch, wiring an ADVPL function call into a Smart X page/table action, converting a legacy MVC browse to a Smart X browse, or debugging a Smart X screen/model/interface issue. It does not cover classic MVC routine development without Smart X (see `advpl-code-generation`, file `patterns-mvc.md`), nor data dictionary configuration scripts for SX2/SX3 themselves (see `sx-configuration`). It is also unrelated to **Smart View**, the TReports analytics tool whose custom business objects are covered by `smartview-development` -- the names are similar, the frameworks are not.

The referenced files are written in Brazilian Portuguese.

| Reference file | Read when |
|---|---|
| reference.md | Always -- Smart X concept, Object/Model/Interface/Launcher architecture, includes/annotations, minimal end-to-end example |
| patterns-model.md | Writing or reviewing the Model (`model.tlpp`) class and its data/business-rule definitions |
| patterns-interface.md | Writing or reviewing the Interface (`interface.tlpp`) class and its UI contract (browse/forms) |
| patterns-launcher-browse.md | Converting only the browse (Data View) of an existing MVC routine to Smart X rendering |
| patterns-advpl-integration.md | Calling existing ADVPL functions from Smart X via `pageActions`, `tableActions`, or events like `onChange` |
| patterns-migration.md | Migrating a full legacy routine to a 100% Smart X implementation |
| troubleshooting.md | Diagnosing errors or unexpected behavior in a Smart X screen, Model, or Interface |
