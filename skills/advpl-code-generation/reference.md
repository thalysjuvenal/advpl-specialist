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

## Critical Rules (Function keyword, TLPP namespace, identifier length)

The binding rules for the `Function` keyword, TLPP namespaces and identifier length are in [`critical-rules.md`](critical-rules.md) (read it before generating code). That file also lists the valid `JsonObject`, `TWsdlManager` and `FWFormView` methods and the validation of `ALIAS_CAMPO` field names.

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
