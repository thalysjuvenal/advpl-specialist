---
description: Generate technical documentation from ADVPL/TLPP source code - Protheus.doc headers, routine docs, API docs
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, WebSearch, WebFetch
argument-hint: "<file> [--type header|full|api] [--output path]"
---

**IMPORTANT:** Always respond in the same language the user is writing in. If the user writes in Portuguese, respond in Portuguese. If in English, respond in English.

# /advpl-specialist:document

Generate technical documentation from existing ADVPL/TLPP source code.

## Usage

```bash
/advpl-specialist:document <target> [options]
```

## Options

| Flag | Description | Default |
|------|------------|---------|
| `--type` | Documentation type: `header`, `full`, `api` | `full` |
| `--output` | Output file path for the documentation | Display in chat |

## Documentation Types

| Type | What it generates |
|------|-------------------|
| `header` | Protheus.doc comment block (can be inserted into source) |
| `full` | Complete routine doc: objective, tables, MV_*, entry points, flow, dependencies |
| `api` | REST API doc: endpoint, parameters, request/response, auth |

## Process

1. **Parse arguments** — Identify target file and options
2. **Load documentation reference** — Read `${CLAUDE_PLUGIN_ROOT}/skills/documentation-patterns/reference.md`
3. **Prepare Windows-1252 sources** — Claude Code's Edit and Write refuse a file that is not valid UTF-8, and the doc-generator agent has no Bash to convert it. For each existing target with extension `.prw`, `.prx`, `.tlpp` or `.th` that the agent will edit (for example to insert Protheus.doc headers), in the same turn as the edits:
   1. Read the file before converting it, even if its content is already known: the plugin's hook then puts it on the list converted back at the end of the turn, edited or not, and shows the conversion hint.
   2. Convert it to UTF-8:

      ```bash
      bash "${CLAUDE_PLUGIN_ROOT}/skills/advpl-code-generation/scripts/convert-encoding.sh" --to-utf8 "<file>"
      ```

   3. On `converted:` or `already-utf8:`, go on. On `failed: <file> (undefined byte)`, tell the user and do not delegate the editing of that file.

   The plugin lints each edit the agent makes and converts the file back to Windows-1252 at the end of the turn, so an edit left for a later turn (for example after the user accepts the header insertion) needs this step again. If the user cancels before any edit, run the same script without `--to-utf8` on those targets to return them to Windows-1252.
4. **Delegate to doc-generator agent** — Pass target and type
5. **Analyze code** — Read source, detect tables, parameters, functions, dependencies
6. **Enrich** — Cross-reference with `${CLAUDE_PLUGIN_ROOT}/skills/protheus-reference/reference.md` and `${CLAUDE_PLUGIN_ROOT}/skills/protheus-business/reference.md`
7. **Generate** — Apply the correct template with extracted data
8. **Deliver** — Display or save to output file

## Examples

```bash
# Generate complete routine documentation
/advpl-specialist:document src/MATA461.prw

# Generate just the Protheus.doc header
/advpl-specialist:document src/MATA461.prw --type header

# Document a REST API endpoint
/advpl-specialist:document src/ApiClientes.tlpp --type api

# Save documentation to a file
/advpl-specialist:document src/MATA461.prw --output docs/MATA461.md

# Document all files in a directory
/advpl-specialist:document src/
```

## Output

- **header:** Protheus.doc comment block ready to insert
- **full:** Markdown document with objective, tables, MV_*, entry points, flow, dependencies, history
- **api:** Markdown document with endpoint, HTTP method, parameters, request/response examples, auth
