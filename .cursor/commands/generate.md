# /generate — Generate ADVPL/TLPP code for functions, classes, MVC structures, REST APIs, web services, and entry points on TOTVS Protheus

You are an expert ADVPL/TLPP assistant for TOTVS Protheus. This command generates new ADVPL or TLPP source code following Protheus conventions.

## Knowledge to load first
Locate the advpl-specialist skills (installed via `npx skills add thalysjuvenal/advpl-specialist`; in this repository they live under `skills/`) and read, in order:
1. `skills/advpl-code-generation/critical-rules.md` (Function keyword, TLPP namespace, identifier length limits)
2. `skills/advpl-code-generation/reference.md` (naming, includes, variable scope, error handling)
3. The pattern file matching the requested `type`:

| Type | Pattern file |
|------|-------------|
| `mvc` | `skills/advpl-code-generation/patterns-mvc.md` |
| `rest` | `skills/advpl-code-generation/patterns-rest.md` |
| `webservice` | `skills/advpl-code-generation/patterns-soap.md` |
| `treport` | `skills/advpl-code-generation/patterns-treport.md` / `patterns-fwmsprinter.md` |
| `fwformbrowse` | `skills/advpl-code-generation/patterns-fwformbrowse.md` |
| `job` | `skills/advpl-code-generation/patterns-jobs.md` |
| `workflow` | `skills/advpl-code-generation/patterns-workflow.md` |
| `class` | `skills/advpl-code-generation/templates-classes.md` |
| `ponto-entrada` | `skills/advpl-code-generation/patterns-pontos-entrada.md` (or `patterns-pontos-entrada-mvc.md` for MVC entry points); check `skills/advpl-code-generation/catalogo-top-50-pes.md` first for known PARAMIXB metadata, then `skills/tdn-lookup/reference.md` as fallback |

## Workflow
1. Check the declared release: if a `.protheus-version` file exists in the project root, read it (one release string, e.g. `12.1.2310`), look up the minimum release of the requested feature in `skills/protheus-reference/releases.md` and compare the third component as an integer. If the declared release is below the minimum (e.g. TLPP+MVC or `.tlpp` with `namespace` needs `12.1.2410`), warn the user and propose the alternative (e.g. `.prw` ADVPL instead of TLPP+MVC); continue only with the user's choice. If the file does not exist, proceed as usual and add one line suggesting the user create `.protheus-version` with the Protheus release.
2. Parse `type`, `name`, and flags (`--module`, `--lang`, `--output`) from the request.
3. Do not scan the user's project source tree looking for patterns — this command is template-driven; only read the plugin's own skill files above, plus `.protheus-version` and any single file the user explicitly references.
4. If `name` or `--module` is missing, ask the user before proceeding.
5. Validate identifier length: `User Function` in `.prw` must be ≤ 8 chars, `Static Function` ≤ 10 chars, TLPP with `namespace` up to 255 chars. If too long, offer either a shortened name or switching to TLPP with a `namespace`.
6. For `.tlpp` output, derive `namespace custom.<agrupador>.<servico>` from `--module` (agrupador) and the service/class name; ask for the agrupador if `--module` is absent.
7. For `ponto-entrada`, resolve PARAMIXB, return type, calling routine, and execution moment from the catalog first, then TDN.
8. Draft a plan: files to create, function keyword for each routine (`User Function`, `Static Function`, or `Method ... Class` — never bare `Function`), namespace line (if TLPP), includes, error handling and DB-area save/restore approach. Present it and wait for approval before writing code.
9. After approval, generate the complete source file and save it to the current directory (or `--output` path).
10. Report what was created and the key decisions made.

## Output rules
- Use `#include "totvs.ch"` in `.prw` files; use `tlpp-core.th` / `tlpp-rest.th` in `.tlpp` files.
- Follow Hungarian notation for variables and module-prefixed naming for routines/tables.
- Use Embedded SQL (`BeginSQL`/`EndSQL` with `%table%`, `%notDel%`, `%xFilial%` macros) — never raw SQL strings.
- Every `.tlpp` file must declare `namespace custom.<agrupador>.<servico>` right after the includes.
- Include a Protheus.doc header, proper error handling (`BEGIN SEQUENCE ... RECOVER ... END SEQUENCE`), and area save/restore around DB operations.
- Validate any custom field (`<prefix>_X*`) against SX3 conventions before referencing it; user functions use the `U_` prefix.
- Compilation must be validated in TDS / VS Code TOTVS extension — never claim the code compiles.
