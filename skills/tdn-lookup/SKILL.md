---
name: tdn-lookup
description: Search TDN (tdn.totvs.com) as a fallback when local reference lacks the answer - functions, entry points, unknown errors. "buscar documentacao no TDN", "nao encontrei na referencia local", "pesquisar funcao no TDN".
---

# TDN Lookup — Online Search Strategy

This skill defines the standardized fallback strategy for finding official TOTVS documentation on TDN (tdn.totvs.com, a public Confluence Data Center 7.19 site with an unauthenticated REST API) whenever local reference material is insufficient. It specifies a five-tier escalation: Tier 1 always checks the relevant local cache file first (native functions, SX dictionary, common errors, entry points, business modules); Tier 2 queries the Confluence REST search API directly via WebFetch with a CQL query; Tier 3 falls back to Playwright hitting the same API when WebFetch is blocked; Tier 4 uses WebSearch plus Playwright navigation when CQL search yields nothing; Tier 5 is a last-resort manual/visual search on the TDN site itself.

Activate this skill whenever a native function, entry point, error code, or business process is not found (or only partially found) in the local reference files, or whenever the user explicitly asks for official TOTVS documentation. It does not itself contain domain knowledge -- it only orchestrates the search process; the actual native function, entry point, and error catalogs live in `protheus-reference`, `advpl-code-generation`, `advpl-debugging`, and `protheus-business`.

| Reference file | Read when |
|---|---|
| reference.md | Always -- tier-by-tier search strategy, CQL query construction, HTML/JSON parsing steps, fallback conditions per tier |
