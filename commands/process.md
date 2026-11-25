---
description: Consult Protheus ERP business processes, module workflows, routines and integrations
allowed-tools: Read, Glob, Grep, WebSearch, WebFetch, Bash, Agent, mcp__playwright__browser_navigate, mcp__playwright__browser_snapshot, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_fill_form, mcp__playwright__browser_click, mcp__playwright__browser_close, mcp__plugin_playwright_playwright__browser_navigate, mcp__plugin_playwright_playwright__browser_snapshot, mcp__plugin_playwright_playwright__browser_take_screenshot, mcp__plugin_playwright_playwright__browser_fill_form, mcp__plugin_playwright_playwright__browser_click, mcp__plugin_playwright_playwright__browser_close
argument-hint: "<process|routine|module> [--type process|routine|module|integration]"
---

# /advpl-specialist:process

**IMPORTANT:** Always respond in the same language the user is writing in. If the user writes in Portuguese, respond in Portuguese. If in English, respond in English. Adapt all explanations, process descriptions, and references to the user's language.

Consult Protheus ERP business processes, module workflows, routines, and integrations.

## Usage

```bash
/advpl-specialist:process <query> [options]
```

## Options

| Flag | Description | Default |
|------|------------|---------|
| `--type` | Query type: `process`, `routine`, `module`, `integration` | auto-detect |

## Process

1. **Load reference** - Read `${CLAUDE_PLUGIN_ROOT}/skills/protheus-business/reference.md`
2. **Parse query** - Extract search term and options
3. **Classify query type** - If `--type` not specified, auto-detect:
   - Contains routine code (e.g. MATA410, FINA040) -> routine
   - Contains module name (Compras, Faturamento, Estoque, etc.) -> module
   - Contains two module names or keywords like "integracao" / "integration" -> integration
   - Otherwise -> process
4. **Delegate to process-consultant agent** - Pass the query and its type to the process-consultant agent for the local and TDN searches (steps 5-6); the Playwright fallback (step 7) runs in this command, which holds the Playwright tools
5. **Search local reference** - Check `${CLAUDE_PLUGIN_ROOT}/skills/protheus-business/` module files (`${CLAUDE_PLUGIN_ROOT}/skills/protheus-business/modulo-compras.md`, `${CLAUDE_PLUGIN_ROOT}/skills/protheus-business/modulo-estoque.md`, etc.)
6. **Search TDN** - If not found locally, search TDN online:
   - Process: `site:tdn.totvs.com "<process>" protheus fluxo`
   - Routine: `site:tdn.totvs.com "<ROUTINE_CODE>" rotina`
   - Module: `site:tdn.totvs.com "<module>" modulo protheus`
   - Integration: `site:tdn.totvs.com "<moduleA>" "<moduleB>" integracao`
7. **Playwright fallback** - If WebSearch/WebFetch fail:
   - If URL available: `browser_navigate` -> `browser_snapshot` -> `browser_take_screenshot` if needed
   - If no URL: `browser_navigate` to `https://tdn.totvs.com` -> `browser_fill_form` search -> `browser_click` submit -> `browser_snapshot` results -> navigate to best result
   - **Always** `browser_close` when finished to release resources
8. **Deliver answer** - Format response based on query type

## Response Format

Adaptive based on query type:

**Process query:**
- Description of the process
- Step-by-step flow with routines and tables at each step
- Integrations with other modules
- Available entry points

**Routine query:**
- What the routine does
- Tables it reads/writes
- MV parameters it uses
- Which process it belongs to
- Available entry points

**Module query:**
- Module overview
- Main tables
- Main routines
- Key business processes
- Integrations with other modules

**Integration query:**
- Data flow between modules
- Linking tables
- Routines involved at each side
- Direction of data flow

## Cross-References

When the user needs more detail, read additional references:
- **protheus-reference** - for native function details (syntax, parameters, return values)
- **advpl-code-generation** - for code examples and implementation patterns
- **embedded-sql** - for query examples using Embedded SQL

## Examples

```bash
# Understand a business process
/advpl-specialist:process fluxo de compras

# Look up a specific routine
/advpl-specialist:process MATA410

# Understand a module
/advpl-specialist:process modulo Faturamento --type module

# Understand integration between modules
/advpl-specialist:process integracao Compras Estoque --type integration

# Ask in natural language
/advpl-specialist:process como funciona o processo de faturamento no Protheus?

# Look up financial process
/advpl-specialist:process contas a pagar
```

## Output

- Clear, structured explanation adapted to query type
- References to routines, tables, and entry points
- Source citation (local reference or TDN)
- Suggestions for related references when further detail is needed
