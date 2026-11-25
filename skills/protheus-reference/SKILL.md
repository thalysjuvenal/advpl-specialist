---
name: protheus-reference
description: Look up Protheus native functions, SX data dictionary, REST patterns (FWRest, WsRestFul), MV_* parameters and restricted functions. "funcao nativa", "dicionario de dados", "parametro MV_", "campo SX3".
---

# Protheus Reference

This skill is a quick-lookup reference guide for the TOTVS Protheus ecosystem: native function syntax/parameters/return values across categories (String, Date/Time, Array, Database, Interface, Network, JsonObject, ExecAuto, etc.), the SX data dictionary (SX1 Perguntas through SXB/SIX), REST API patterns (FWRest annotations vs. legacy WsRestFul), and MV_* system parameters.

Activate this skill when the user needs to confirm how a native function works, validate a custom field against SX3, check REST endpoint conventions, or verify a function isn't on the restricted/internal-only list (checked first, always, before recommending any function). The lookup strategy is local-first (native-functions.md, sx-dictionary.md, sx3-common-fields.md, rest-api-reference.md), falling back to a tiered TDN online search (WebFetch API, then Playwright API JSON, then Playwright HTML) via the `tdn-lookup` skill when not found locally.

It does not cover business-process context for why a table/field is used (see `protheus-business`), writing the SQL to query these tables (see `embedded-sql`), or generating documentation that references these functions (see `documentation-patterns`).

| Reference file | Read when |
|---|---|
| reference.md | Always -- function category index, data dictionary overview, REST API pattern summary, and the local-first/TDN lookup strategy |
| native-functions.md | Looking up exact syntax, parameters, and return value of a specific native function |
| sx-dictionary.md | Understanding SX1-SX9/SIX table structure and programmatic usage of the data dictionary |
| sx3-common-fields.md | Validating whether a custom or standard field exists on a table before referencing it in code |
| restricted-functions.md | Checking whether a function/class is internal-only or blocked from compilation before recommending it |
| rest-api-reference.md | Building or documenting a REST endpoint (FWRest annotations or legacy WsRestFul) |
