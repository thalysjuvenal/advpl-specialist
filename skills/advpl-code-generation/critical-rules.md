# Critical Rules for ADVPL/TLPP Code Generation

These rules are binding for every piece of generated ADVPL/TLPP code. Read this file **before planning or generating any code**: the `code-generator` agent loads it in Phase 2, and any other agent that only reads the skills must apply it the same way. Phase numbers below refer to the `code-generator` workflow (Phase 3 = Plan, before any code is written); without that workflow, run the same checks in your planning step, before writing any file.

Covered here: the `User Function` vs bare `Function` keyword, the TLPP `namespace` declaration, identifier length limits, the valid `JsonObject`, `TWsdlManager` and `FWFormView` methods, and the validation of `ALIAS_CAMPO` field names.

## User Function vs Function Keyword

This is one of the **most common generation errors** and causes silent compilation failures in customer RPOs. Follow this rule **without exception**.

### The rule

| Keyword | Where valid | Invoked as | Use in generation? |
|---------|-------------|-----------|-------------------|
| `User Function NAME()` | Any `.prw` or `.tlpp` file — always compiles in customer RPO | `u_NAME()` | **YES — default choice for ALL customer-callable code** |
| `user function NAME()` (lowercase) | TLPP files — equivalent to `User Function` | `u_NAME()` | YES in `.tlpp` (TLPP is case-insensitive; both work) |
| `Static Function NAME()` | Current `.prw` / `.tlpp` file only — internal helper | direct call within file | YES for private helpers inside the same file |
| `Method NAME() Class XXX` | Inside a TLPP `class ... endclass` block | `oObj:NAME()` | YES for class-based designs |
| `Function NAME()` (bare) | **RESERVED for TOTVS core RPO** — fails in customer RPO | ❌ | **NEVER** emit bare `Function` in generated code |
| `function U_NAME()` + explicit `namespace` | TLPP with `namespace custom.xxx` and `U_` prefix inside function name | `u_NAME()` | Rare / legacy — only when explicitly requested. Prefer `User Function` + file-level `namespace` (see "TLPP Namespace Declaration" below) |

Typical `User Function` uses: any customer-callable entry point, REST endpoint, job, workflow or entry point (ponto de entrada); the lowercase `user function` is the form used by TLPP REST endpoints with annotations (`@Get`, `@Post`, etc.).

### Why this matters

Customers compile their ADVPL/TLPP code into their **own RPO** (not the TOTVS core RPO). The bare `Function` keyword is reserved for TOTVS-maintained core/standard routines and is blocked by the compiler in customer RPOs. Customers must be able to call their own code via the `u_` prefix (e.g., `u_getCustomers()`), which requires `User Function`.

### TLPP REST with annotations — the official TOTVS pattern

Both the TDN documentation (`Migração WsRESTful para REST tlppCore`) and the official sample repository `totvs/tlpp-sample-rest` (file `rest-mod02.tlpp`) use `user function` with `@Get/@Post/@Put/@Patch/@Delete` annotations. This is the **authoritative reference** for TLPP REST endpoints — always follow it.

```tlpp
#include "tlpp-core.th"
#include "tlpp-rest.th"

@Get("/api/v1/customers")
User Function getCustomers()
    // implementation
return oRest:setResponse(cData)

@Post("/api/v1/customers")
User Function createCustomer()
    // implementation
return oRest:setResponse(cData)
```

The plugin adds one extra requirement on top of the sample: a mandatory `namespace` declaration (see "TLPP Namespace Declaration" below; the complete form is under "Correct patterns — ALWAYS generate these").

A class-based approach is also officially supported (`rest-mod03.tlpp`):

```tlpp
class CustomersAPI from LongClassName
    @Get("/api/v1/customers")
    public method listAll()

    @Post("/api/v1/customers")
    public method create()
endclass
```

Both patterns compile in customer RPOs and both require the `namespace` declaration. Never use bare `Function` with TLPP REST annotations.

### Exceptions (when bare `Function` IS correct)

The bare `Function` keyword is ONLY correct in these narrow cases, and you should **never** emit them without explicit user request:

1. **Localization sources** consumed by `FwExecLocaliz` — the lookup mechanism requires the exact function name without `u_` prefix (e.g., `Function ExemploBRA(aParam)` in a TOTVS-maintained localized source file)
2. **TOTVS core/standard routines** — not applicable to customer customization code at all

If in doubt, default to `User Function`.

### Forbidden patterns — NEVER generate these

```advpl
// WRONG — bare Function in a customer .prw file
Function MyCustomerCode()
    // will NOT compile in customer RPO
Return .T.
```

```tlpp
// WRONG — bare Function with TLPP REST annotation
@Get("/api/v1/products")
Function getProducts()
    // will NOT compile in customer RPO
Return
```

### Correct patterns — ALWAYS generate these

```advpl
// RIGHT — customer .prw file
#include "totvs.ch"

User Function MyCustomerCode()
    // compiles in customer RPO, callable as u_MyCustomerCode()
Return .T.
```

```tlpp
// RIGHT — TLPP REST endpoint
#include "tlpp-core.th"
#include "tlpp-rest.th"

// Namespace inferred from --module est + service name ProductsAPI
namespace custom.est.productsapi

@Get("/api/v1/products")
User Function getProducts()
    // compiles in customer RPO
return oRest:setResponse(cData)
```

## TLPP Namespace Declaration

Every `.tlpp` file generated for customer code **must** declare a `namespace`. This is as important as the `User Function` rule above — missing it breaks consistency with the ADVPL→TLPP migration reference and risks name collisions between customer projects that share the same Protheus environment.

### The rule

| Scenario | Namespace required? | Convention |
|----------|--------------------|-----------|
| `.tlpp` REST endpoint (function-based, annotations) | **YES** | `custom.<module>.<servicename>` |
| `.tlpp` REST endpoint (class-based) | **YES** | `custom.<module>.<classname>` |
| `.tlpp` Class (Service, Repository, DTO, etc.) | **YES** | `custom.<module>.<classname>` |
| `.tlpp` Job / batch process | **YES** | `custom.<module>.<jobname>` |
| `.prw` file (ADVPL) | No | N/A — namespaces are TLPP-only |

### Inference from `--module` and file/service name

The generator must derive the namespace automatically from the command arguments:

- **`--module <agrupador>`** provides the `<agrupador>` segment (lowercase)
- **File or service name** provides the `<servico>` segment (lowercase, no underscores, no special characters)
- **Result:** `namespace custom.<agrupador>.<servico>`

**Examples:**

| Command | Inferred namespace |
|---------|--------------------|
| `/generate rest Purchase --lang tlpp --module compras` | `namespace custom.compras.purchase` |
| `/generate rest ProductsAPI --lang tlpp --module est` | `namespace custom.est.productsapi` |
| `/generate class PedidoService --lang tlpp --module fat` | `namespace custom.fat.pedidoservice` |
| `/generate class ClienteRepository --lang tlpp --module fat` | `namespace custom.fat.clienterepository` |
| `/generate job JobProcessaNotas --lang tlpp --module fat` | `namespace custom.fat.jobprocessanotas` |

### When `--module` is not provided

**Ask the user** during the Planning Phase — do NOT silently omit the namespace and do NOT invent a default like `custom.geral.xxx`. Example question:

> "Você não passou `--module`. Qual é o agrupador do namespace? Ex: `compras`, `fat`, `fin`. O namespace do arquivo será `custom.<agrupador>.<servico>`."

Only proceed after the user provides the value.

### Format rules (TOTVS convention)

All rules must hold simultaneously. If any is violated, fix before emitting:

1. **All lowercase** — `custom.compras.purchase`, never `Custom.Compras.Purchase`
2. **Dot separators** — never slashes, backslashes, underscores or hyphens between segments
3. **No underscores inside segments** — `purchaseorder` not `purchase_order`
4. **No spaces** — collapse if needed
5. **Only `custom.*` prefix for customer code** — `totvs.protheus.*` is reserved for TOTVS product code
6. **One namespace declaration per file** — always immediately after the includes, before the `/*/{Protheus.doc}` header
7. **Functions keep a simple name** — `namespace custom.fat.pedidos` + `user function calcTotal(...)`. Never put the dotted name in the declaration (`function custom.fat.pedidos.calcTotal()` is not a form documented on TDN); callers use `custom.fat.pedidos.u_calcTotal()` or `using namespace custom.fat.pedidos`

### Do NOT use `using namespace tlpp.*`

`tlpp.core`, `tlpp.rest`, `tlpp.log`, `tlpp.data` are provided by the `.th` includes (`tlpp-core.th`, `tlpp-rest.th`, etc.). Writing `using namespace tlpp.core` is incorrect and unnecessary. `using namespace` is only valid to consume **other custom namespaces** (e.g., `using namespace custom.fat.pedidoservice` in a consumer file). Exception: ProBat test sources declare `using namespace tlpp.probat` (TDN: needed to call the asserts unqualified; the alternative is `tlpp.probat.assertEquals(...)`).

### Canonical file header for generated TLPP

```tlpp
#include "tlpp-core.th"
#include "tlpp-rest.th"  // only if REST endpoint
#include "totvs.ch"      // when framework features are used (PARAMIXB, DEFAULT, MsExecAuto, BeginSQL, MVC...)

// Namespace inferred from --module <agrupador> + service/class name
namespace custom.<agrupador>.<servico>

/*/{Protheus.doc} <Name>
...
/*/
```

**Includes in `.tlpp`:** `#include "tlpp-core.th"` (TDN: recommended for every TLPP source) brings the TLPP language features; `#include "totvs.ch"` brings the Protheus framework commands. A `.tlpp` that uses the framework (`Default`, `BeginSQL`, `Begin Transaction`, `PARAMIXB`, `MsExecAuto`, MVC) includes **both**, `tlpp-core.th` first. Whether `BeginSQL` compiles in a `.tlpp` without `totvs.ch` is not documented (a confirmar no TDS) — keep `totvs.ch`.

### Forbidden patterns — NEVER generate these

```tlpp
// WRONG — no namespace in a customer TLPP file
#include "tlpp-core.th"
#include "tlpp-rest.th"

@Get("/api/v1/customers")
User Function getCustomers()
return oRest:setResponse(cData)
```

<!-- advpl-lint: anti-exemplo -->
```tlpp
// WRONG — using namespace tlpp.* (already provided by .th includes)
#include "tlpp-core.th"
using namespace tlpp.core
using namespace tlpp.rest

namespace custom.fat.pedidoservice
```

```tlpp
// WRONG — uppercase, underscores, or hyphens in the namespace
namespace Custom.FAT.Pedido_Service
```

### Correct patterns — ALWAYS generate these

```tlpp
// RIGHT — function-based TLPP REST with namespace
#include "tlpp-core.th"
#include "tlpp-rest.th"

namespace custom.compras.purchase

@Get("/api/v1/purchases")
User Function getPurchases()
return oRest:setResponse(cData)
```

```tlpp
// RIGHT — class-based TLPP REST with namespace
#include "tlpp-core.th"
#include "tlpp-rest.th"

namespace custom.compras.purchasesapi

class PurchasesAPI from LongClassName
    @Get("/api/v1/purchases")
    public method listAll()
endclass
```

```tlpp
// RIGHT — TLPP Service class with namespace
#include "tlpp-core.th"

namespace custom.fat.pedidoservice

Class PedidoService
    Method New() Constructor
    Method CriarPedido(oData)
EndClass
```

## Identifier Length Validation

ADVPL inherits a **10-character limit** on identifiers (functions, methods, variables, fields) from the legacy DBase DBF format — only the first 10 chars are used to identify the symbol. TLPP removes this limit, but **only when a `namespace` is declared**. Generating a name that exceeds the limit produces code that fails to compile or silently collides with another symbol sharing the first 10 characters. This check is **mandatory** during Phase 3 (Plan).

### The limits

| Construct | Target file | Effective limit | Reason |
|-----------|-------------|-----------------|--------|
| `User Function NAME()` | `.prw` | **8 characters** | 10-char limit minus the `u_` invocation prefix (2 chars) |
| `Static Function NAME()` | `.prw` | **10 characters** | Full 10 chars — no prefix |
| `Function NAME()` (core) | `.prw` | 10 characters | Reserved for TOTVS core RPO |
| Class method (ADVPL) | `.prw` | 10 characters | Exception: classes inheriting from `longnameclass` (legacy workaround) |
| Variable / parameter | `.prw` / `.tlpp` without namespace | 10 characters | Same DBF legacy |
| **TLPP with `namespace`** | `.tlpp` | **255 characters** | Available from Protheus release **12.1.2410** — effectively unlimited |
| TLPP **without** `namespace` | `.tlpp` | 10 characters | Falls back to ADVPL limit |

### Validation rule (enforced during Phase 3)

Before entering `EnterPlanMode`, compute `len(name)` and compare against the limit for the chosen language/construct:

1. **`--lang advpl` (or default `.prw`) + `User Function`:** `len(name) <= 8`
2. **`--lang advpl` + `Static Function`:** `len(name) <= 10`
3. **`--lang tlpp` + `namespace` declared:** `len(name) <= 255` (no practical limit)

If the name exceeds the limit, **do NOT proceed with the plan**. Instead, present the user with two options and wait for their choice:

> "O nome `<NAME>` tem X caracteres, mas `<User Function|Static Function>` em ADVPL suporta no máximo `<8|10>` caracteres (limite herdado do DBF). Como deseja prosseguir?
>
> **(A) Encurtar o nome** — sugestões: `<SUGGESTION1>`, `<SUGGESTION2>`, `<SUGGESTION3>`
> **(B) Gerar em TLPP com namespace** (aceita até 255 chars, disponível a partir do release 12.1.2410). Seria: `custom.<agrupador>.<nome em lowercase>`. Qual o agrupador (`--module`)?"

Only enter plan mode after the user picks (A) + a shortened name, or (B) + an agrupador for the namespace.

### Suggestion rules (when offering option A)

Generate 2-3 alternatives using these heuristics, in order of preference:

1. **Module prefix + sequence** (when `--module` is present) — follows Protheus convention: `FATA100`, `COMA200`, `ESTA001`. Max 7-8 chars.
2. **Mnemonic abbreviation** — drop vowels or keep consonants: `ProcessaValidacaoItens` → `PRCVALIT`, `PRVLDITM`, `VLDITENS`.
3. **Functional abbreviation** — use domain verbs: `AtualizaCadastroCliente` → `ATUCLI`, `UPDCLI`, `CADCLI`.

Always keep suggestions readable and discoverable — never return random truncations like `Process123`.

### About `longnameclass`

`longnameclass` is a **legacy ADVPL mechanism** (magical inheritance) that allowed class methods and properties to exceed the 10-char limit. **Do NOT generate new code based on `longnameclass`.** The modern, officially supported replacement is TLPP with `namespace`. The plugin only recognizes `longnameclass` as an exception in the code review reference (BP-010) to avoid false positives on legacy customer code.

If the user explicitly asks for a `longnameclass`-based generation, refuse and offer TLPP with namespace as the modern alternative.

### Forbidden patterns — NEVER generate these

```advpl
// WRONG — User Function with 12 chars in a .prw file
User Function ProcessaValida()
    // fails: effective limit is 8 chars for User Function
Return .T.
```

```advpl
// WRONG — Static Function with 15 chars in a .prw file
Static Function ValidaCadastroItem()
    // fails: effective limit is 10 chars for Static Function
Return .T.
```

```tlpp
// WRONG — TLPP file without namespace but with a 15-char function name
#include "tlpp-core.th"

User Function ProcessaCadastro()
    // fails: without namespace, TLPP falls back to the 10-char ADVPL limit
Return .T.
```

### Correct patterns — ALWAYS generate these

```advpl
// RIGHT — User Function respecting the 8-char limit (.prw)
#include "totvs.ch"

User Function FATA100()
    // compiles: 7 chars, invoked as u_FATA100()
Return .T.
```

```advpl
// RIGHT — Static Function respecting the 10-char limit (.prw)
#include "totvs.ch"

Static Function ValidaItem()
    // compiles: 10 chars, direct call within the same file
Return .T.
```

```tlpp
// RIGHT — TLPP with namespace: long names are allowed
#include "tlpp-core.th"
#include "tlpp-rest.th"

namespace custom.fat.processavalidacaoitens

@Post("/api/v1/validacao")
User Function processaValidacaoItens()
    // compiles: namespace removes the ADVPL length limit
Return
```

### References

- TDN — [Tamanho do nome (identificador) de função](https://tdn.totvs.com/pages/viewpage.action?pageId=172296510)
- TDN — [Suporte a TLPP no Protheus](https://tdn.totvs.com/display/public/framework/Suporte+a+TLPP+no+Protheus)

## JsonObject Methods

When generating code that uses `JsonObject`, **ONLY use methods that actually exist** in the class. The complete list of valid methods from the TDN is:

| Method | Description |
|--------|-------------|
| `JsonObject():New()` | Constructor |
| `:FromJSON(cJSON)` | Parse JSON string (returns NIL on success) |
| `:toJSON()` | Serialize to JSON string |
| `:GetNames()` | Returns array of property names |
| `:HasProperty(cKey)` | Check if key exists (case-sensitive) |
| `:GetJsonObject(cKey)` | Get sub-object or value |
| `:GetJsonText(cKey)` | Get value as string |
| `:GetJsonValue(cKey, @xVal, @cType)` | Get value and type by reference |
| `:DelName(cKey)` | Remove property |
| `:Set(aJson)` | Set array/object at root |
| `oJson["key"]` | Bracket notation for get/set |

**DO NOT generate fabricated methods** like `:Keys()`, `:GetKeys()`, `:Names()`, `:GetHeaders()`, `:HasKey()`, `:Count()`, `:Items()`, or any other method not listed above.

**For case-insensitive header/key matching**, use `GetNames()` + `Upper()`:

```advpl
// Correct pattern for case-insensitive key lookup
Local aNames := oJson:GetNames()
Local cUpper := Upper(cTargetKey)
For i := 1 To Len(aNames)
    If Upper(aNames[i]) == cUpper
        cValue := oJson:GetJsonText(aNames[i])
    EndIf
Next i
```

## TWsdlManager Methods

When generating code that uses `TWsdlManager`, **ONLY use methods/properties that actually exist** in the class. The complete list of valid methods from the TDN is:

| Method/Property | Description |
|-----------------|-------------|
| `TWsdlManager():New()` | Constructor |
| `:ParseURL(cUrl)` | Load WSDL from URL. Returns `.T.`/`.F.` |
| `:ParseFile(cPath)` | Load WSDL from local file. Returns `.T.`/`.F.` |
| `:SetOperation(cOp)` | Select operation to call. Returns `.T.`/`.F.` |
| `:SendSoapMsg(cXml)` | Send SOAP envelope. Returns `.T.`/`.F.` |
| `:GetParsedResponse()` | Get parsed response body |
| `:GetSoapResponse()` | Get raw SOAP XML response |
| `:GetSoapMsg()` | Get the SOAP message that will be/was sent |
| `:ListOperations()` | List operations for the current service |
| `:SetPort(cPort)` | Select a service port from the WSDL |
| `:SetValue(cParam, cValue)` | Set input parameter value |
| `:SimpleInput(cField)` | Navigate to a simple input field |
| `:ComplexInput(cField)` | Navigate to a complex input field |
| `:NextComplex()` | Navigate complex types |
| `:SetComplexOccurs(n)` | Define tag occurrence count |
| `.cError` | Last error message (property) |
| `.cFaultCode` | SOAP Fault code (property) |
| `.cFaultSubCode` | SOAP Fault sub-code (property) |
| `.cFaultString` | SOAP Fault description (property) |
| `.cFaultActor` | SOAP Fault actor (property) |
| `.nTimeout` | Timeout in seconds (property, default 120) |
| `.bNoCheckPeerCert` | Skip SSL cert validation (property) |
| `.lProcResp` | Auto-process response (property) |

**DO NOT generate fabricated methods** like `:GetSoapFault()`, `:ListServices()`, `:GetError()`, or any other method not listed above. SOAP Fault data is accessed via **properties** (`cFaultCode`, `cFaultString`), NOT via a getter method.

## FWFormView Methods

When generating MVC ViewDef code, the correct method name for adding titles to view sections is **`EnableTitleView`**, NOT `EnableTitleGroup`.

```advpl
// CORRECT:
oView:EnableTitleView("VIEW_SA1", "Dados do Cliente")

// WRONG — EnableTitleGroup DOES NOT EXIST:
// oView:EnableTitleGroup("VIEW_SA1", "Dados do Cliente")
```

## Field Name Validation

**The rule:** NEVER emit an identifier in the format `ALIAS_XXXXXX` (e.g., `E2_CCONTAB`, `A1_NOME`, `D1_TOTAL`) unless it has been confirmed by one of the 3 layers below. **NEVER invent a field name.**

### Layer 1 — Local reference (instant, no cost)

Check `skills/protheus-reference/sx3-common-fields.md`. If the field appears there → use it directly.

### Layer 2 — SempreJu lookup (automatic, ~500 tokens)

If the field is NOT in the local reference, automatically fetch:
`https://sempreju.com.br/tabelas_protheus/tabelas/tabela_{alias_lowercase}.html`

Search the page for the field name. If found → use it. If the page does not load or the field is not found → proceed to Layer 3.

**Example:** For field `E2_PORTADO` in table SE2:
1. Check sx3-common-fields.md → not found
2. WebFetch `https://sempreju.com.br/tabelas_protheus/tabelas/tabela_se2.html`
3. Search page for `E2_PORTADO` → found (C, 3, "Código do Portador") → use it

### Layer 3 — Ask the user (last resort)

If Layers 1 and 2 did not confirm the field, ask the user:
> "O campo `{ALIAS_CAMPO}` não foi encontrado na minha referência local nem no SempreJu. Confirma o nome exato na sua base?"

**NEVER generate a field that was not confirmed by any layer. No exceptions. No placeholder variables.**

### Forbidden patterns

<!-- advpl-lint: anti-exemplo -->
```advpl
// WRONG — field not confirmed by any layer:
SE2->E2_CCONTAB := cContab

// WRONG — placeholder variable instead of real field:
Local cxCContab := "" // TODO: confirmar campo
```

### Correct patterns

```advpl
// CORRECT — field confirmed in sx3-common-fields.md (Layer 1):
SE2->E2_VALOR := nValor

// CORRECT — field confirmed via SempreJu WebFetch (Layer 2):
// Agent fetched tabela_se2.html, found E2_PORTADO (C, 3, "Código do Portador")
SE2->E2_PORTADO := cPortador
```

```advpl
// CORRECT — field confirmed by user (Layer 3):
// Agent: "O campo E2_XCCONTB não foi encontrado. Confirma o nome?"
// User: "Sim, E2_XCCONTB existe na minha base."
SE2->E2_XCCONTB := cContab
```
