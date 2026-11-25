---
description: Generate ADVPL/TLPP code - functions, classes, MVC structures, REST APIs, Web Services, and entry points for TOTVS Protheus
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, WebSearch, WebFetch
argument-hint: "<type> [name] [--module module]"
---

# /advpl-specialist:generate

**IMPORTANT:** Always respond in the same language the user is writing in. If the user writes in Portuguese, respond in Portuguese. If in English, respond in English. Adapt all explanations and suggestions to the user's language. Code comments may remain in English or match the user's language.

Generate new ADVPL or TLPP code following Protheus conventions and best practices.

## Usage

```bash
/advpl-specialist:generate <type> [name] [--module <module>]
```

## Types

| Type | Description | Output |
|------|------------|--------|
| `function` | User Function | .prw file |
| `class` | TLPP class | .tlpp file |
| `mvc` | MVC structure (MenuDef, ModelDef, ViewDef) | .prw file |
| `rest` | REST API endpoint | .prw or .tlpp file |
| `ponto-entrada` | Entry point | .prw file |
| `webservice` | SOAP Web Service | .prw file |
| `treport` | TReport report | .prw file |
| `fwformbrowse` | FWFormBrowse/FWExecView screen | .prw file |
| `job` | Batch job / scheduled process | .prw or .tlpp file |
| `workflow` | Approval workflow process | .prw file |

## Options

| Flag | Description | Default |
|------|------------|---------|
| `--module` | Module prefix (COM, FAT, FIN, etc.). For TLPP output, also used as the namespace agrupador: `custom.<module>.<servico>` | Ask user |
| `--lang` | Language: advpl or tlpp | advpl for function/mvc/pe, tlpp for class |
| `--output` | Output file path | Current directory + name + extension. **Do NOT scan the project to infer a path** — if the user wants a specific location, they must pass `--output` explicitly or answer a question about it. |

> **TLPP namespace (mandatory for `.tlpp` files):** every generated `.tlpp` file declares a `namespace custom.<agrupador>.<servico>` line right after the includes. The generator derives the namespace from `--module` (as agrupador) plus the service/class name (as servico), all lowercase with no underscores. If `--module` is not provided, the generator asks the user for the agrupador during the Planning Phase. See [advpl-code-generation — TLPP Namespace Rules](../skills/advpl-code-generation/reference.md) for the complete rule.

## Process

**MANDATORY: Always enter planning mode before generating code. Never skip planning.**

### No Project Source Scanning (CRITICAL)

**Do NOT scan the customer's project source files.** The plugin is template-driven — all code is generated from the plugin's own templates and skills. Reading existing `.prw` / `.tlpp` / `.prx` files from the customer's project is **not required** for any `/generate` scenario and must be avoided because:

- Protheus projects routinely have thousands of source files — scanning them is prohibitively slow and wastes the user's time
- The generated code comes from the plugin's templates, not from the customer's codebase
- Naming, style and patterns come from `skills/advpl-code-generation/reference.md`, not from existing files
- The caller already provides everything the generator needs: `type`, `name`, `--module`, business requirements

**Allowed uses of `Read` / `Glob` / `Grep`:**
- Reading files **inside the plugin itself** — `skills/*`, `templates-*.md`, `patterns-*.md`, `agents/code-generator.md`, `skills/advpl-code-generation/reference.md`
- `Write` the final generated `.prw` / `.tlpp` file to disk
- `Read` a **specific file** the user explicitly referenced in their request (single file, exact path the user provided)

**Forbidden uses:**
- `Glob "**/*.prw"`, `Glob "**/*.tlpp"`, `Glob "src/**/*"` — never list customer source files
- `Grep` across the customer's source tree to "find patterns" or "check existing naming"
- `Read` customer source files "to understand the codebase" — the templates are self-contained
- `Bash ls`, `Bash find`, `Bash tree` on the customer project root — same prohibition

**Output path rule:** Save the generated file to the **current working directory** using `<name>.<ext>` (or the path passed via `--output`). Never `Glob` to discover module folders, never "guess" the right location by scanning. If the user has a preferred location, either they pass `--output` or the generator asks a direct question.

**Only exception:** The user explicitly references an existing file in their request (e.g., *"gere um REST similar ao que está em `src/fontes/FATA001.prw`"*). In that case, `Read` is allowed **only** on the exact path the user provided — never expanded into a full-project scan.

### Planning Phase (REQUIRED)
1. **Parse arguments** - Extract type, name, and flags
2. **Ask missing details** - If name or module not provided, ask the user. **For TLPP generation (`.tlpp` output), also collect the namespace agrupador: if `--module <agrupador>` is provided, infer `namespace custom.<agrupador>.<servico>` automatically; if `--module` is missing, ask the user explicitly for the agrupador before entering plan mode. Never silently omit the namespace and never invent a default.**
2a. **Validate identifier length (BLOCKING)** - Compute `len(name)` and compare against the effective limit for the chosen language/construct: `User Function` in `.prw` must be ≤ 8 chars, `Static Function` in `.prw` must be ≤ 10 chars, TLPP with `namespace` accepts up to 255 chars. If the name exceeds the limit, **do NOT enter plan mode**. Present the user with two explicit options and wait for their choice:
   - **(A) Shorten the name** — suggest 2-3 alternatives following Protheus conventions (module prefix + sequence like `FATA100`, mnemonic abbreviation, or functional abbreviation). Never offer random truncations.
   - **(B) Switch to TLPP with namespace** — explain that TLPP with namespace supports up to 255 chars (available from Protheus release 12.1.2410). Ask for the agrupador (`--module`) if missing.
   Only proceed to the next step after the user picks (A) + shortened name, or (B) + namespace agrupador. See [advpl-code-generation — critical-rules.md, Identifier Length Validation](../skills/advpl-code-generation/critical-rules.md) for the complete rule and the suggestion heuristics. **Never generate code that depends on `longnameclass` as a workaround — TLPP with namespace is the modern, officially supported alternative.**
3. **Ask business requirements** - What should the code do?
4. **Load reference** - Read `skills/advpl-code-generation/reference.md`
5. **Load patterns** - Read appropriate supporting file for the type
6. **Resolve entry point metadata** - **If the type is `ponto-entrada`**, resolve PARAMIXB, return type, calling routine and execution moment in this order:
   1. **Tier 1 — local cache first:** read [`skills/advpl-code-generation/catalogo-top-50-pes.md`](../skills/advpl-code-generation/catalogo-top-50-pes.md) and search for the exact PE name. If found with complete metadata, extract PARAMIXB, return type, calling routine and moment directly from the catalog. **Skip TDN search.** Initial coverage: 20 PEs across COM, FAT, EST and FIN.
   2. **Tier 2+ — TDN fallback:** if the PE is not in the local catalog, apply the full lookup strategy documented in [`skills/tdn-lookup/reference.md`](../skills/tdn-lookup/reference.md) (WebFetch on Confluence REST API, then Playwright fallbacks). Extract the same metadata from the TDN page.

   This cache-first strategy reduces latency by ~70% for the most common entry points and keeps TDN search as a correctness-preserving fallback. The generated code must cite the source used (catalog or TDN URL) in a code comment so reviewers can trace where the PARAMIXB came from.
7. **Enter plan mode** - Use `EnterPlanMode` to create a structured implementation plan
8. **Present plan** - Show the user a clear plan including:
   - File(s) to be created (name, path, extension)
   - Code structure (functions, classes, methods to implement)
   - **Explicit declaration of the function keyword** to be used for every function in the plan: `User Function` (default for customer-callable code), `Static Function` (internal helper), or `Method ... Class` (TLPP class). **Never** plan a bare `Function` keyword for customer code — it is reserved for the TOTVS core RPO and will not compile in a customer RPO.
   - **For every `.tlpp` file, the exact `namespace` declaration to be emitted**, following the convention `custom.<agrupador>.<servico>` (all lowercase, dots as separators, no underscores). Show it as a literal line (e.g., `namespace custom.compras.purchase`) derived from `--module` + the service/class name. If `--module` was not provided, this must have been resolved in step 2.
   - **Identifier length check result** — explicitly confirm in the plan that every function/method name fits the effective limit for the chosen language: `User Function` ≤ 8 chars (`.prw`), `Static Function` ≤ 10 chars (`.prw`), TLPP with `namespace` ≤ 255 chars. If the name was shortened in step 2a, also mention the original name for traceability (e.g., `FATA100 (shortened from ProcessaValidacaoItens)`).
   - Includes and dependencies
   - Key patterns to apply (MVC, REST, SOAP, etc.)
   - Naming conventions to follow (Hungarian notation, module prefix)
   - Error handling and DB operation patterns
   - **For entry points:** TDN documentation found (PARAMIXB parameters, return type, calling routine)
   - **For REST endpoints (TLPP annotation-based):** confirm the plan uses `User Function` with `@Get/@Post/@Put/@Patch/@Delete` annotations, following the official TOTVS sample `totvs/tlpp-sample-rest/rest-mod02.tlpp`. The class-based variant (`rest-mod03.tlpp`) is also supported — use it when multiple methods share state. **Both variants require the `namespace` declaration.**
9. **Wait for approval** - The user must approve the plan before any code is written. If the user requests changes, revise the plan.
10. **Exit plan mode** - Use `ExitPlanMode` after approval

### Implementation Phase (only after approval)
11. **Generate code** - Create complete, production-ready code following the approved plan
12. **Write file** - Save with correct extension (.prw or .tlpp)
13. **Report** - Show what was created and key decisions

## Examples

```bash
# Create a User Function for billing module
/advpl-specialist:generate function FATA050 --module FAT

# Create a TLPP service class
/advpl-specialist:generate class PedidoService

# Create complete MVC CRUD
/advpl-specialist:generate mvc CadProduto --module EST

# Create a REST API endpoint
/advpl-specialist:generate rest ClienteAPI --lang tlpp

# Create an entry point
/advpl-specialist:generate ponto-entrada MT100LOK

# Create a SOAP Web Service
/advpl-specialist:generate webservice WSPedido

# Create a TReport report
/advpl-specialist:generate treport RelProdutos --module EST

# Create a FWFormBrowse screen
/advpl-specialist:generate fwformbrowse CadFornecedores --module COM

# Create a batch processing job
/advpl-specialist:generate job JobProcessaNotas --module FAT

# Create an approval workflow
/advpl-specialist:generate workflow AprovacaoPedido --module COM
```

## Output

A complete, compilable source file saved to the project directory with:
- Protheus.doc documentation header
- Proper includes (`TOTVS.CH` for `.prw`, `tlpp-core.th` / `tlpp-rest.th` for `.tlpp`)
- **Mandatory `namespace custom.<agrupador>.<servico>` line for every generated `.tlpp` file**
- Full implementation following conventions
- Error handling
- Area save/restore for DB operations
