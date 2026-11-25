# Copilot Instructions — ADVPL/TLPP (TOTVS Protheus)

This repo is either the `advpl-specialist` knowledge plugin itself (skills in `skills/`, commands in `commands/`, agents in `agents/`) or a Protheus source tree that copied this file as a template. Full standards live in `AGENTS.md` at the repo root — read it first.

Critical rules when suggesting or completing ADVPL/TLPP code:

- `.prw` files: `#include "totvs.ch"` lowercase — never `"protheus.ch"`.
- `.tlpp` files: use `.th` includes (`tlpp-core.th`, `tlpp-rest.th`, etc.); no `using namespace tlpp.*`.
- Hungarian notation for variables (`c`/`n`/`d`/`l`/`a`/`o`/`b`/`x` prefixes). Prefer `Local` over `Private`/`Public`, always declared at the top of the function.
- Database queries: Embedded SQL only (`BeginSQL`/`EndSQL` with `%table%`, `%xFilial%`, `%notDel%`, `%exp%`) — never raw SQL strings or concatenated `TCQuery`.
- Every `RecLock` needs a matching `MsUnlock`, including on error paths.
- Automation: `MsExecAuto` following the routine's documented example; for MVC routines use the model API (`FWLoadModel` + `SetValue` + `VldData` + `CommitData`). `FWMVCRotAuto` is restricted (TOTVS internal use) — do not use.
- Never access SX*/SM0/SIX tables via direct `DbSelectArea` — use framework APIs (`FWSX3Util`, `GetMV`, `RetSqlName`, `Pergunte`).
- Never use `ConOut()` (use `FWLogMsg()`), `IIF()` inline ternaries, or hardcoded credentials.
- Validate custom fields in SX3 before use (`<prefix>_X*` pattern); custom functions use the `U_` prefix.
- ADVPL/TLPP source files are Windows-1252 encoded, not UTF-8.
- To validate sources on demand, run the lint engine `skills/advpl-code-review/scripts/advpl-lint.sh` (PowerShell twin: `advpl-lint.ps1`); in Claude Code, the `/advpl-specialist:validate` command adds a semantic pass (S1-S6).
- There is no ADVPL compiler in CI — never claim code is compiled/verified; that only happens in TDS/VS Code TOTVS extension.

For task-specific guidance (code generation, review, debugging, migration, SQL, tests, locks, Smart X, Smart View, ADVPR tests, SX dictionary), consult `skills/<name>/SKILL.md` per the map in `AGENTS.md`.
