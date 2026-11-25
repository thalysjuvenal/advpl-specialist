---
name: smartx-development
description: Build, migrate or troubleshoot Smart X routines (metadata-driven PO-UI screens) - model, interface, launcher. NOT Smart View. "tela Smart X", "migrar MVC para Smart X", "launcher Smart X".
---

# Smart X

This skill covers developing TOTVS Smart X routines: the Object -> Model -> Interface -> Launcher chain that turns a data dictionary table (SX2/SX3) into an automatically-rendered PO-UI screen without hand-written Angular components. It documents the required includes and annotations for the Model (`totvs.framework.structure.model.th`) and Interface (`totvs.framework.structure.interface.th`) TLPP classes, the Launcher function that registers the routine in the Protheus menu, integrating existing ADVPL functions into the interface via `pageActions`/`tableActions`/events, and converting only the browse (Data View) of a legacy MVC routine to Smart X while keeping ModelDef/ViewDef/MenuDef intact.

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

## After writing the source (Depois de gravar o fonte)

AIs without hooks (Copilot, Cursor, Gemini CLI and others) must verify the file themselves, in this order, before delivering. Paths are relative to this skill folder; the scripts belong to the named skills.

1. Convert to Windows-1252 with the `advpl-code-generation` skill's `scripts/convert-encoding.sh` (`../advpl-code-generation/scripts/convert-encoding.sh <file>`, strict). On `failed: ... (incompatible char)`, remove or replace the character; or re-run with `--translit` and tell the user which characters became `?`.
2. Lint the whole file with the `advpl-code-review` skill's `scripts/advpl-lint.sh` (`../advpl-code-review/scripts/advpl-lint.sh --scope all <file>`). Exit 1 means errors: fix them and re-run until there are none. Evaluate warnings and mention any you keep. A false positive can be suppressed in the project's `.advpl-specialist-ignore` (`rule <ID>`, `path <glob>`, `field <FIELD>`, `function <NAME>`).
3. On Windows without bash, run the `.ps1` twins with `pwsh -File` or `powershell -File`.
4. In Claude Code the plugin hooks do this automatically on every write; use `/advpl-specialist:validate` to lint whole files on demand.
5. Never say the code compiled: compilation and validation in TDS / the VS Code TOTVS extension remain pending.
