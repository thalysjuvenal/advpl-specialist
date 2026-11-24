# ADVPL/TLPP Code Generation

## Overview

Patterns and templates for generating clean, standardized ADVPL and TLPP code for TOTVS Protheus. Covers User Functions, classes, MVC, REST APIs, Web Services, and entry points (pontos de entrada).

## When to Use

- Creating new functions (User Function, Static Function)
- Creating TLPP classes with methods
- Building MVC structures (Model/View/Controller)
- Implementing REST API endpoints
- Writing entry points (pontos de entrada)
- Creating SOAP Web Services
- Any new .prw or .tlpp file creation

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| User Function | Module prefix + descriptive name | `FATA001` (Faturamento), `COMA100` (Compras) |
| Static Function | Descriptive, camelCase or PascalCase | `ValidaCampo`, `GravaRegistro` |
| Class (TLPP) | PascalCase, suffix with purpose | `PedidoService`, `ClienteController` |
| Method | camelCase | `getTotal`, `validarDados` |
| Variable Local | c/n/d/l/a/o prefix + PascalCase | `cNome`, `nTotal`, `dData`, `lOk`, `aItens`, `oObj` |
| Parameter | Same as variable | `cCodCli`, `nQuantidade` |
| Constant | UPPER_SNAKE_CASE | `MAX_RETRIES`, `DEFAULT_TIMEOUT` |

**Type prefixes (Hungarian notation):**
| Prefix | Type | Example |
|--------|------|---------|
| c | Character/String | `cNome`, `cEndereco` |
| n | Numeric | `nValor`, `nQuantidade` |
| d | Date | `dEmissao`, `dVencimento` |
| l | Logical/Boolean | `lOk`, `lContinua` |
| a | Array | `aItens`, `aCampos` |
| o | Object | `oModel`, `oView` |
| b | Code Block | `bBloco`, `bCondic` |
| u | Indefinido (any) — official TDN table | `uRetorno`, `uParam` |
| x | Indefinido (any) — variant used by the plugin | `xRetorno`, `xParam` |
| j | JsonObject — convention of the official TLPP examples (not in the TDN table) | `jBody`, `jResponse` |

**Module prefixes:**
| Prefix | Module |
|--------|--------|
| COM | Compras |
| EST | Estoque |
| FAT | Faturamento |
| FIN | Financeiro |
| CTB | Contabilidade |
| FIS | Fiscal |
| GFE | Gestao de Frete |
| HCM | Capital Humano |
| MNT | Manutencao de Ativos |
| PCP | Planejamento e Controle de Producao |

## Mandatory Structure - User Function

Every User Function MUST follow this pattern:

```advpl
#include "totvs.ch"

/*/{Protheus.doc} FATA001
Descricao breve da funcao
@type User Function
@author Nome do Autor
@since DD/MM/YYYY
@version 1.0
@param cParam1, Caractere, Descricao do parametro
@return lRet, Logico, Retorno da funcao
@example
    u_FATA001("001")
/*/
User Function FATA001(cParam1)
    Local lRet      := .T.
    Local cAlias    := "SA1"
    Local aArea     := GetArea() // Salva area de trabalho
    Local oError
    Local bOldError := ErrorBlock({|e| Break(e)})

    Begin Sequence

        // Logica principal aqui
        DbSelectArea(cAlias)
        DbSetOrder(1)

        If DbSeek(xFilial(cAlias) + cParam1)
            // Processamento
        Else
            lRet := .F.
            MsgAlert("Registro nao encontrado")
        EndIf

    Recover Using oError
        lRet := .F.
        FWLogMsg("ERROR", /*cTransactionId*/, "FATA001", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Erro em FATA001: " + oError:Description)
    End Sequence

    // Restaura o tratamento de erro e a area
    ErrorBlock(bOldError)
    RestArea(aArea)

Return lRet
```

## Variable Scope Rules

| Scope | Keyword | Visibility | Use Case |
|-------|---------|-----------|----------|
| Local | `Local` | Current function only | **Always prefer this** |
| Static | `Static` | Current PRW file | Shared state within file |
| Private | `Private` | Current function + called functions | **Avoid - use parameters** |
| Public | `Public` | Entire application | **Never use in new code** |

**Best practice:** Always use `Local`. Pass data via parameters, never via Private/Public.

## Error Handling Pattern

**ADVPL (`.prw`)** — `Begin Sequence` only reaches `Recover` on an explicit `Break`, so install an `ErrorBlock` that turns runtime errors into `Break(e)` and restore the previous one at the end:

```advpl
Local oError
Local bOldError := ErrorBlock({|e| Break(e)})

Begin Sequence

    // Codigo que pode falhar

Recover Using oError
    FWLogMsg("ERROR", /*cTransactionId*/, "MinhaRotina", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Erro: " + oError:Description)
    // Tratar o erro (retorno .F., DisarmTransaction(), etc.)

End Sequence

ErrorBlock(bOldError)
```

**TLPP (`.tlpp`)** — `Try`/`Catch`/`EndTry` (TDN "Try...Catch", AppServer 20.3.0.0+); `Finally` is optional and always runs. The caught object is an `ErrorClass`; the TDN example reads `description` and `genCode` (other properties: a confirmar no TDS):

```tlpp
Try
    // Codigo que pode falhar
Catch oError
    FWLogMsg("ERROR", /*cTransactionId*/, "MinhaClasse", /*cCategory*/, /*cStep*/, /*cMsgId*/, "Erro: " + oError:description)
Finally
    // Executa sempre (opcional): liberar objetos, restaurar area
EndTry
```

`FWLogMsg(cSeverity, [cTransactionId], cGroup, [cCategory], [cStep], [cMsgId], [cMessage], [nMensure], [nElapseTime], [aMessage])` (TDN): `cSeverity` is `INFO`, `WARN`, `ERROR`, `FATAL` or `DEBUG`; `cSeverity` and `cGroup` are mandatory. Never log with `ConOut()`.

## Quick Reference - Code Types

| Type | File Extension | Pattern File |
|------|---------------|-------------|
| User Function | .prw | Inline above |
| Static Function | .prw | Inline above (same file as User Function) |
| Class TLPP | .tlpp | templates-classes.md |
| MVC | .prw | patterns-mvc.md |
| REST API | .prw or .tlpp | patterns-rest.md |
| Ponto de Entrada | .prw | patterns-pontos-entrada.md |
| Web Service SOAP | .prw | patterns-soap.md |
| PDF report (coordinate-based) | .prw | patterns-fwmsprinter.md |

## Function Keyword Rules (CRITICAL)

Customer code compiled into a customer RPO **must** use `User Function` (or `Static Function` for internal helpers, or class `Method` for TLPP classes). The bare `Function` keyword is reserved for the TOTVS core RPO and will fail to compile in customer environments.

| Keyword | Valid in customer RPO? | Callable as | Typical use |
|---------|------------------------|-------------|-------------|
| `User Function NAME()` | Yes (always) | `u_NAME()` | Any customer-callable entry point, REST endpoint, job, workflow, entry point (ponto de entrada) |
| `user function NAME()` | Yes (TLPP, lowercase = same thing) | `u_NAME()` | TLPP REST endpoints with annotations (`@Get`, `@Post`, etc.) |
| `Static Function NAME()` | Yes | direct call within file | Private helper inside the same `.prw`/`.tlpp` |
| `Method NAME() Class XXX` | Yes | `oObj:NAME()` | TLPP classes |
| `Function NAME()` (bare) | **NO — fails in customer RPO** | N/A | Reserved for TOTVS core only |

### TLPP REST with annotations

The official TOTVS pattern (from `totvs/tlpp-sample-rest/rest-mod02.tlpp`) is `user function` with annotations. The plugin adds one extra requirement on top of the sample: a mandatory `namespace` declaration (see "TLPP Namespace Rules" below).

```tlpp
#include "tlpp-core.th"
#include "tlpp-rest.th"

namespace custom.fat.customersapi

@Get("/api/v1/customers")
User Function getCustomers()
    Local cData := ""

    // implementation: build cData (JSON)
return oRest:setResponse(cData)
```

The class-based variant (`rest-mod03.tlpp`) is also supported — use `class ... from LongClassName` with `@Get/@Post` decorators on methods. Both patterns compile in customer RPOs, both require the `namespace` declaration. Never use bare `Function` with TLPP REST annotations.

## TLPP Namespace Rules (CRITICAL)

Every generated `.tlpp` file for customer code **must** declare a `namespace` immediately after the includes. This applies to REST endpoints, classes, jobs — any TLPP generation. Missing the namespace breaks consistency with the ADVPL→TLPP migration skill and risks name collisions between customer projects.

**Convention:** `custom.<agrupador>.<servico>` — all lowercase, dots as separators, no underscores.

**Inference rule:**
- `--module <agrupador>` → `<agrupador>` (lowercase, no underscores)
- File/service/class name → `<servico>` (lowercase, no underscores)
- Result: `namespace custom.<agrupador>.<servico>`

**Examples:**

| Command | Inferred namespace |
|---------|--------------------|
| `/generate rest Purchase --lang tlpp --module compras` | `namespace custom.compras.purchase` |
| `/generate class PedidoService --lang tlpp --module fat` | `namespace custom.fat.pedidoservice` |
| `/generate job JobProcessaNotas --lang tlpp --module fat` | `namespace custom.fat.jobprocessanotas` |

**Format rules (all must hold):**

1. All lowercase — `custom.compras.purchase`, never `Custom.Compras.Purchase`
2. Dot separators — never slashes, underscores, or hyphens between segments
3. No underscores inside segments — `purchaseorder` not `purchase_order`
4. Only `custom.*` prefix for customer code (`totvs.protheus.*` is reserved for TOTVS)
5. Exactly one `namespace` line per file, after the includes, before the Protheus.doc header
6. Functions keep a simple name: `namespace custom.fat.pedidos` + `user function calcTotal(...)`. Never put the dotted name in the declaration (`function custom.fat.pedidos.calcTotal()` is not a form documented on TDN); callers use `custom.fat.pedidos.u_calcTotal()` or `using namespace custom.fat.pedidos`

**Includes in `.tlpp`:** `#include "tlpp-core.th"` (TDN: recommended for every TLPP source) brings the TLPP language features; `#include "totvs.ch"` brings the Protheus framework commands. A `.tlpp` that uses the framework (`Default`, `BeginSQL`, `Begin Transaction`, `PARAMIXB`, `MsExecAuto`, MVC) includes **both**, `tlpp-core.th` first. Whether `BeginSQL` compiles in a `.tlpp` without `totvs.ch` is not documented (a confirmar no TDS) — keep `totvs.ch`.

**When `--module` is missing:** ask the user during the Planning Phase for the agrupador. Never silently omit the namespace and never invent a default like `custom.geral.xxx`.

**Do NOT use `using namespace tlpp.*`:** `tlpp.core`, `tlpp.rest`, `tlpp.log`, `tlpp.data` are provided by the `.th` includes. `using namespace` is only valid to consume **other custom namespaces** in consumer files (e.g., `using namespace custom.fat.pedidoservice`). Exception: ProBat test sources declare `using namespace tlpp.probat` (TDN: needed to call the asserts unqualified; the alternative is `tlpp.probat.assertEquals(...)`).

## Identifier Length Limits (CRITICAL)

ADVPL inherits a **10-character limit** on identifiers (functions, methods, variables, fields) from the legacy DBase DBF format — only the first 10 characters are used to identify the symbol. TLPP removes this limit, but **only when a `namespace` is declared**. Generating a name that exceeds the limit produces code that either fails to compile or silently collides with another symbol sharing the first 10 characters.

| Construct | File | Effective limit | Why |
|-----------|------|-----------------|-----|
| `User Function NAME()` | `.prw` | **8 characters** | 10-char limit minus the `u_` prefix (2 chars) |
| `Static Function NAME()` | `.prw` | **10 characters** | No prefix — full 10 chars available |
| `Function NAME()` (core) | `.prw` | 10 characters | Reserved for TOTVS core RPO |
| Class method (ADVPL) | `.prw` | 10 characters | Exception: classes inheriting from `longnameclass` (legacy workaround) |
| Variable / parameter | `.prw` / `.tlpp` | 10 characters | Same DBF legacy |
| **TLPP with `namespace`** | `.tlpp` | **255 characters** | Available from Protheus release **12.1.2410** — effectively unlimited |
| TLPP **without** `namespace` | `.tlpp` | 10 characters | Falls back to the ADVPL limit |

**Generation rule (enforced during Planning Phase):**

1. If `--lang advpl` (or default `.prw`) and the target is `User Function`: **name must be ≤ 8 characters**
2. If `--lang advpl` and the target is `Static Function`: **name must be ≤ 10 characters**
3. If `--lang tlpp` and a `namespace` is declared: **name must be ≤ 255 characters** (no practical limit)
4. If the requested name exceeds the ADVPL limit, the generator **must not generate the file**. Instead, present two options to the user in the plan:
   - **(A) Shorten the name** — suggest 2-3 abbreviated alternatives (module prefix + mnemonic, e.g., `ProcessaValidacaoItens` → `FATA100`, `VLDITENS`, `PRCVALIT`)
   - **(B) Switch to TLPP with namespace** — ask for the agrupador if `--module` is missing and generate `custom.<agrupador>.<servico>`

**About `longnameclass`:** it is a legacy ADVPL mechanism (magical inheritance) that historically allowed class methods and properties to exceed the 10-char limit. **Do not generate new code based on `longnameclass`** — TLPP with `namespace` is the modern, officially supported replacement. The plugin only recognizes `longnameclass` as an exception during code review (BP-010) to avoid false positives on legacy code.

**References:**
- TDN — [Tamanho do nome (identificador) de função](https://tdn.totvs.com/pages/viewpage.action?pageId=172296510)
- TDN — [Suporte a TLPP no Protheus](https://tdn.totvs.com/display/public/framework/Suporte+a+TLPP+no+Protheus)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| **Using bare `Function` keyword in customer code** | **Always use `User Function` (customer RPO requires it; invoked as `u_NAME()`)** |
| **Omitting `namespace` in a generated `.tlpp` file** | **Always declare `namespace custom.<agrupador>.<servico>` after the includes — infer from `--module` + service name, or ask the user** |
| **Using `using namespace tlpp.core` / `tlpp.rest` / `tlpp.log` / `tlpp.data`** | **Remove it — those namespaces come from `.th` includes automatically** |
| **`User Function` with more than 8 characters in the name** | **Shorten to ≤ 8 chars (ADVPL limit is 10, minus the `u_` prefix) or switch to TLPP with `namespace`** |
| **`Static Function` with more than 10 characters in the name** | **Shorten to ≤ 10 chars (ADVPL legacy limit from DBF) or switch to TLPP with `namespace` (supports up to 255 chars)** |
| Using Private instead of Local | Always declare as Local, pass via parameters |
| Not saving/restoring area (GetArea/RestArea) | Always wrap DB operations with area save/restore |
| Missing error handling | `.prw`: `ErrorBlock({\|e\| Break(e)})` + `Begin Sequence` / `Recover Using oError` / `End Sequence` + `ErrorBlock(bOldError)`; `.tlpp`: `Try` / `Catch oError` / `EndTry` |
| Logging with `ConOut()` | Use `FWLogMsg()` (see "Error Handling Pattern") |
| Automating a routine with `FWMVCRotAuto` | Restricted to TOTVS internal use since 2019 — use `MsExecAuto` per the routine's documented example; for MVC, the model API (`FWLoadModel` + `SetValue` + `VldData` + `CommitData`) per the documented examples (see `patterns-workflow.md`) |
| Not closing RecLock | Always use MsUnlock() after RecLock() |
| Hardcoded branch (filial) | Use xFilial(cAlias) for multi-branch compatibility |
| Missing `totvs.ch` include | `.prw`: always `#include "totvs.ch"` (lowercase); `.tlpp` using the framework: `#include "tlpp-core.th"` + `#include "totvs.ch"` |
| Not validating function parameters | Check ValType() and empty values at function start |
| TLPP REST endpoint with bare `Function` | Use `User Function` with `@Get/@Post/...` annotation (official `rest-mod02.tlpp` pattern) |
| **Inventar nome de campo `ALIAS_CAMPO` não confirmado no SX3** | **Verificar em `sx3-common-fields.md` → se não encontrar, buscar via WebFetch no SempreJu → se não encontrar, perguntar ao usuário. NUNCA inventar.** |
