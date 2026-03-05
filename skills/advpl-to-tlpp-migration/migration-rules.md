# ADVPL to TLPP Migration Rules

Complete mapping reference for converting ADVPL procedural constructs to their TLPP object-oriented equivalents.

## Preprocessor Directives

| ADVPL | TLPP | Notes |
|-------|------|-------|
| `#Include "Protheus.ch"` | `#Include "tlpp-core.th"` | Main TLPP include; do NOT add `using namespace tlpp.core/tlpp.log` -- those are NOT replacements for includes |
| `#Include "TopConn.ch"` | `#Include "tlpp-core.th"` | Database connectivity is available via tlpp-core.th |
| `#Include "RestFul.ch"` | `#Include "tlpp-rest.th"` | For REST with TLPP annotations (`@RestService`, `@Get`, `@Post`) |
| `#Include "FWMVCDef.ch"` | `#Include "tlpp-core.th"` | MVC framework functions available via tlpp-core.th |
| `#Define CONST_NAME value` | `static data CONST_NAME := value` | Define constants as static class data, or use `#define` if purely compile-time |
| `#ifdef TOP_HAS_FEATURE` | Conditional compilation preserved | `#ifdef` / `#ifndef` blocks remain valid in `.tlpp` for compile-time branching |
| `#ifndef` | Conditional compilation preserved | Same as `#ifdef` -- unchanged in TLPP |

**Notes:**
- In TLPP, use the specific `.th` includes instead of the `.ch` ADVPL includes:
  - `#Include "tlpp-core.th"` -- main include for TLPP (replaces Protheus.ch, TopConn.ch)
  - `#Include "tlpp-rest.th"` -- for REST annotations (@RestService, @Get, @Post)
  - `#Include "tlpp-object.th"` -- for advanced object features
  - `#Include "tlpp-probat.th"` -- for automated testing (ProBat framework)
- Do NOT use `using namespace tlpp.core`, `tlpp.log`, `tlpp.data`, etc. as replacements for includes. Those are NOT include replacements -- they are namespace imports that are rarely needed.
- Only add the project's own `namespace` declaration following the official TOTVS convention (see Namespace Conventions below).
- `#Define` constants used only within a class can become `static data` properties. Constants shared across files should remain as `#define` in a shared `.ch` file.

## Namespace Conventions (Official TOTVS Standard - TDN)

All namespace names must be **lowercase**, separated by **dots**, with **no underscores**.

**For TOTVS product code:**
```
totvs.protheus.<segmento>.<agrupador/servico>
```

Available segments: agrobusiness, backoffice, construction, distribution, educational, financial, health, hospitality, legal, manufacturing, retail, services

Examples: `totvs.protheus.backoffice.customer`, `totvs.protheus.financial.payment.receive`

**For client customizations (most common):**
```
custom.<agrupador>.<servico>
```

Start with `custom.`, the rest is free. Examples: `custom.cadastros.cliente`, `custom.faturamento.pedido`

**File naming convention:**
- Product: `<segmento>.<agrupador>.<funcionalidade>.tlpp` (e.g., `backoffice.tgv.contact.controller.tlpp`)
- Customizations: `custom.<agrupador>.<funcionalidade>.tlpp` (e.g., `custom.cadastros.cliente.tlpp`)

**Classes, functions, and methods naming:**
- Classes: **PascalCase** (e.g., `ContactsController`, `PedidoService`)
- Functions and methods: **camelCase** (e.g., `validName()`, `calcTotal()`)
- **No underscores** in any identifier

## Variable Scope

| ADVPL Scope | TLPP Equivalent | Migration Action |
|-------------|-----------------|------------------|
| `Private cVar := "x"` | `data cVar as character` | Convert to class property; initialize in constructor |
| `Public nGlobal` | Remove entirely | Pass value via constructor parameters or method arguments; never use Public |
| `Local aArray := {}` | `local aArray := {}` | Unchanged -- keep Local variables as-is inside methods |
| `Static cShared := ""` | `static data cShared as character` | Convert to static class data if shared across instances; otherwise use instance `data` |

**Key rules:**
- If a `Private` variable is used across multiple functions in the same file, it becomes a class `data` property accessed via `::cVar`.
- If a `Private` variable is only used in one function, convert it to `Local` inside the corresponding method.
- `Public` variables must always be eliminated. Identify all consumers and pass the value explicitly.
- `Static` file-level variables become `static data` on the class when the value must be shared across all instances.

## Functions

| ADVPL | TLPP | Migration Action |
|-------|------|------------------|
| `User Function Name(params)` | `public method execute(params)` | Primary public method on the class; keep a `.prw` wrapper for backward compatibility |
| `Static Function Helper(params)` | `private method helper(params)` | Internal functions become private methods |
| `Main Function` | Constructor (`method new()`) | Initialization logic moves to the constructor |
| Multiple User Functions in one `.prw` | Separate classes or methods | Each User Function should map to its own class, or become a public method if logically related |

**Wrapper pattern for User Function:**

```advpl
// Original .prw file -- preserved as wrapper
#Include "Protheus.ch"

User Function OriginalName(cParam1, nParam2)
    Local oService := custom.mymodule.OriginalNameService():new()
Return oService:execute(cParam1, nParam2)
```

## Database Operations

Database operations remain functionally identical but are encapsulated within class methods. The critical rule is that every method performing database access must save and restore the work area.

| Pattern | ADVPL | TLPP (within method) |
|---------|-------|----------------------|
| Save area | `Local aArea := GetArea()` | `local aArea := GetArea()` -- unchanged |
| Restore area | `RestArea(aArea)` | `RestArea(aArea)` -- unchanged |
| Select area | `DbSelectArea("SA1")` | `DbSelectArea(::cAlias)` -- use class property for alias |
| Set order | `DbSetOrder(1)` | `DbSetOrder(1)` -- unchanged |
| Seek | `DbSeek(xFilial("SA1") + cKey)` | `DbSeek(xFilial(::cAlias) + cKey)` -- use class property |
| Record lock | `RecLock("SA1", .T.)` | `RecLock(::cAlias, .T.)` -- use class property |
| Unlock | `MsUnlock("SA1")` | `MsUnlock(::cAlias)` -- use class property |

**Best practice:** Store alias names as class `data` properties so they can be easily changed or injected for testing.

```tlpp
class ClienteRepository
    data cAlias as character

    public method new(cAlias as character) as object
    public method findByCod(cCod as character) as logical

endclass

method new(cAlias as character) class ClienteRepository
    ::cAlias := iif(empty(cAlias), "SA1", cAlias)
return self

method findByCod(cCod as character) class ClienteRepository
    local aArea := GetArea()
    local lFound := .F.

    DbSelectArea(::cAlias)
    DbSetOrder(1)
    lFound := DbSeek(xFilial(::cAlias) + cCod)

    RestArea(aArea)
return lFound
```

## Error Handling

| ADVPL | TLPP | Notes |
|-------|------|-------|
| `Begin Sequence` | `begin sequence` | Preserved -- same syntax |
| `Recover Using oError` | `recover using oError` | Preserved -- same syntax |
| `End Sequence` | `end sequence` | Preserved -- same syntax |
| `ErrorBlock({...})` | `ErrorBlock({...})` | Preserved -- optionally enhanced |
| `Conout("Erro: " + ...)` | `FWLogMsg("ERROR", ...)` or `FWLogError(...)` | Prefer structured logging in TLPP |
| `Break` | `break` | Preserved |

**Enhanced error handling in TLPP:**

```tlpp
method processOrder(cOrder as character) class OrderService
    local lRet := .T.
    local oError

    begin sequence

        // Business logic here
        ::validateOrder(cOrder)
        ::saveOrder(cOrder)

    recover using oError
        lRet := .F.
        FWLogMsg("ERROR", , "OrderService", "processOrder", , , ;
            "Erro ao processar pedido " + cOrder + ": " + oError:Description)
    end sequence

return lRet
```

## Code Blocks

Code blocks remain syntactically unchanged in TLPP. When used inside class methods, they follow the same rules:

| ADVPL | TLPP | Notes |
|-------|------|-------|
| `bBlock := {\|x\| x * 2}` | `local bBlock := {\|x\| x * 2}` | Unchanged syntax |
| `Eval(bBlock, nValue)` | `Eval(bBlock, nValue)` | Unchanged |
| `aEval(aArray, bBlock)` | `aEval(aArray, bBlock)` | Unchanged |
| `DbEval(bBlock)` | `DbEval(bBlock)` | Unchanged |

**Note:** Code blocks referencing class properties must use `self` explicitly when the block will be evaluated outside the method scope:

```tlpp
// Inside a method:
local oSelf := self
local bFilter := {|| (oSelf:cAlias)->(C6_NUM) == oSelf:cPedido}
```

## Array and String Handling

Array and string operations are unchanged in TLPP. They are native language features and do not require migration.

| Operation | ADVPL | TLPP | Notes |
|-----------|-------|------|-------|
| Array creation | `aArr := {}` | `local aArr := {}` | Unchanged |
| Array add | `aAdd(aArr, cVal)` | `aAdd(aArr, cVal)` | Unchanged |
| Array scan | `aScan(aArr, cVal)` | `aScan(aArr, cVal)` | Unchanged |
| Array size | `Len(aArr)` | `Len(aArr)` | Unchanged |
| String trim | `Alltrim(cStr)` | `Alltrim(cStr)` | Unchanged |
| String replace | `StrTran(cStr, cOld, cNew)` | `StrTran(cStr, cOld, cNew)` | Unchanged |
| String pad | `PadR(cStr, nLen)` | `PadR(cStr, nLen)` | Unchanged |

**The only change:** arrays and strings that were stored in `Private`/`Public` variables must now be stored as class `data` properties or passed as parameters.

## UI Elements

Dialog creation and UI element handling require special consideration when migrating to classes. The dialogs themselves are unchanged, but the structure around them moves into methods.

| ADVPL Pattern | TLPP Pattern | Notes |
|--------------|-------------|-------|
| UI logic mixed with business logic | Separate into View and Service classes | Apply SRP (Single Responsibility Principle) |
| `DEFINE MSDIALOG` inside User Function | `method buildDialog()` on a View/Controller class | Dialog construction moves to a dedicated method |
| `ACTIVATE MSDIALOG` | Same -- `ACTIVATE MSDIALOG` | Dialog activation unchanged |
| `@ ... MSGET ...` controls | Same -- placed inside `buildDialog()` method | Control creation syntax unchanged |
| Button actions calling Static Functions | Button actions calling `::methodName()` | Replace function references with method calls |
| `FWExecView(...)` / `Enchoice(...)` | Same -- called from within a method | Framework UI functions unchanged |

**Example -- UI migration:**

```tlpp
class ClienteView
    data oDlg    as object
    data cCodigo as character
    data cNome   as character

    public method new() as object
    public method show() as logical
    private method buildDialog() as object
    private method onConfirm() as logical

endclass

method new() class ClienteView
    ::cCodigo := Space(6)
    ::cNome   := Space(40)
return self

method show() class ClienteView
    ::buildDialog()
    ACTIVATE MSDIALOG ::oDlg CENTERED
return ::onConfirm()

method buildDialog() class ClienteView
    DEFINE MSDIALOG ::oDlg TITLE "Cadastro de Cliente" FROM 0,0 TO 300,500

    @ 10, 10 MSGET ::cCodigo SIZE 100, 20 OF ::oDlg
    @ 40, 10 MSGET ::cNome   SIZE 200, 20 OF ::oDlg

    @ 80, 10 BUTTON "Confirmar" SIZE 80, 25 OF ::oDlg ;
        ACTION (::oDlg:End())

return ::oDlg

method onConfirm() class ClienteView
    if Empty(::cCodigo) .Or. Empty(::cNome)
        MsgAlert("Preencha todos os campos")
        return .F.
    endif
return .T.
```

## Summary

The fundamental principle of ADVPL-to-TLPP migration is **structure changes, syntax mostly stays the same**. The language constructs (arrays, strings, database commands, error handling, code blocks, UI elements) are identical. What changes is:

1. **Organization** -- functions become methods on classes
2. **Scope** -- Private/Public variables become class properties
3. **Imports** -- ADVPL `.ch` includes are replaced by TLPP `.th` includes (`tlpp-core.th`, `tlpp-rest.th`, etc.); add your own `namespace` declaration following TOTVS convention (`custom.<agrupador>.<servico>` for customizations or `totvs.protheus.<segmento>.<agrupador>` for product)
4. **Naming** -- files follow `<namespace>.<funcionalidade>.tlpp` convention, classes use PascalCase, methods use camelCase, no underscores
5. **Encapsulation** -- internal helpers become private methods instead of Static Functions
