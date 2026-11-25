# Best Practices Rules

Rules for detecting violations of ADVPL/TLPP best practices. Each rule includes a detection pattern, violation example, correct example, and explanation.

---

## [BP-001] RecLock without corresponding MsUnlock

**Severity:** CRITICAL

**Description:** Every `RecLock` call must have a corresponding `MsUnlock` call. Forgetting to unlock a record keeps it locked, blocking other users and threads from accessing it, potentially causing deadlocks and data access failures.

**What to look for:** A `RecLock` call that is not followed by `MsUnlock` within the same logical block. Check that all code paths (including error branches) release the lock.

**Violation:**

```advpl
User Function UpdateClient()
    Local cCodCli := "000001"

    DbSelectArea("SA1")
    DbSetOrder(1)

    If DbSeek(xFilial("SA1") + cCodCli)
        RecLock("SA1", .F.)
        SA1->A1_NOME := "New Name"
        // Missing MsUnlock - record stays locked!
    EndIf

Return
```

**Correct:**

```advpl
User Function UpdateClient()
    Local cCodCli := "000001"

    DbSelectArea("SA1")
    DbSetOrder(1)

    If DbSeek(xFilial("SA1") + cCodCli)
        If RecLock("SA1", .F.)
            SA1->A1_NOME := "New Name"
            MsUnlock()
        EndIf
    EndIf

Return
```

**Why it matters:** An unreleased lock blocks all other threads attempting to write to the same record. In high-concurrency environments this leads to lock timeouts, deadlocks, and user complaints about frozen screens.

---

## [BP-002] Local variables declared outside the function header

**Severity:** ERROR

**Description:** In ADVPL/TLPP, ALL `Local` variable declarations MUST appear at the top of the function, immediately after the function signature and before any executable code. Declaring `Local` inside `If`, `While`, `For` blocks, or after any executable statement is a violation that can cause compilation errors or unpredictable behavior.

**What to look for:** `Local` keyword appearing after any executable statement (DbSelectArea, If, While, RecLock, assignments, function calls, etc.).

**Violation:**

```advpl
User Function ProcessData()
    Local aArea := GetArea()
    Local cAlias := "SA1"

    DbSelectArea(cAlias)
    DbSetOrder(1)

    If DbSeek(xFilial("SA1") + "000001")
        Local cNome := AllTrim(SA1->A1_NOME)  // WRONG: Local inside If block
        Local nSaldo := SA1->A1_SALDUP         // WRONG: Local after executable code
    EndIf

    RestArea(aArea)
Return cNome
```

**Correct:**

```advpl
User Function ProcessData()
    Local aArea  := GetArea()
    Local cAlias := "SA1"
    Local cNome  := ""
    Local nSaldo := 0

    DbSelectArea(cAlias)
    DbSetOrder(1)

    If DbSeek(xFilial("SA1") + "000001")
        cNome  := AllTrim(SA1->A1_NOME)
        nSaldo := SA1->A1_SALDUP
    EndIf

    RestArea(aArea)
Return cNome
```

**Why it matters:** ADVPL/TLPP requires all variable declarations at the function header. Declaring variables in the middle of executable code violates the language specification and can lead to compilation errors in strict mode or undefined behavior. Variables that are conditionally needed should be declared at the top with a default value (Nil, "", 0, .F., {}) and assigned later.

---

## [BP-002b] Variables declared as Private or Public instead of Local

**Severity:** WARNING

**Description:** Variables should be declared as `Local` unless there is a specific need for broader scope. `Private` and `Public` variables pollute the call stack and can be accidentally overwritten by called functions.

**What to look for:** `Private` or `Public` variable declarations where `Local` would suffice. Legitimate uses of `Private` include passing variables to MVC models or legacy framework functions that expect them.

**Violation:**

```advpl
User Function CalcTotal()
    Private nTotal  := 0
    Private cCodCli := "000001"
    Private nIdx    := 0

    For nIdx := 1 To 10
        nTotal += GetValue(nIdx)
    Next nIdx

Return nTotal
```

**Correct:**

```advpl
User Function CalcTotal()
    Local nTotal  := 0
    Local cCodCli := "000001"
    Local nIdx    := 0

    For nIdx := 1 To 10
        nTotal += GetValue(nIdx)
    Next nIdx

Return nTotal
```

**Why it matters:** `Private` variables are visible to all functions called from the declaring function. A called function may unintentionally read or overwrite a `Private` variable, causing hard-to-trace bugs. `Local` variables are scoped to the declaring function only, making code predictable and safer.

---

## [BP-003] Missing GetArea/RestArea in functions that use DbSelectArea/DbSetOrder/DbSeek

**Severity:** WARNING

**Description:** Functions that change the current WorkArea (via `DbSelectArea`, `DbSetOrder`, `DbSeek`, etc.) must save and restore the caller's WorkArea state using `GetArea()` and `RestArea()`. Otherwise, the calling function's WorkArea context is silently altered.

**What to look for:** Any function that calls `DbSelectArea`, `DbSetOrder`, `DbSeek`, or `DbGoTo` without first calling `GetArea()` on the affected alias and calling `RestArea()` before returning.

**Violation:**

```advpl
User Function GetClientName(cCodCli)
    Local cNome := ""

    DbSelectArea("SA1")
    DbSetOrder(1)

    If DbSeek(xFilial("SA1") + cCodCli)
        cNome := SA1->A1_NOME
    EndIf

Return cNome
```

**Correct:**

```advpl
User Function GetClientName(cCodCli)
    Local cNome   := ""
    Local aAreaSA1 := SA1->(GetArea())

    DbSelectArea("SA1")
    DbSetOrder(1)

    If DbSeek(xFilial("SA1") + cCodCli)
        cNome := SA1->A1_NOME
    EndIf

    RestArea(aAreaSA1)

Return cNome
```

**Why it matters:** Without saving and restoring the area, the calling function loses its WorkArea position. This causes incorrect reads, skipped records, and mysterious bugs that are extremely difficult to diagnose because they depend on call order.

---

## [BP-004] #include "protheus.ch" instead of #include "totvs.ch"

**Severity:** WARNING

**Description:** The include `protheus.ch` is obsolete. All `.prw` files should use `#include "totvs.ch"` (lowercase, per rule CA3001), which is the current standard and already includes `protheus.ch`.

**What to look for:** Any line containing `#include "protheus.ch"` (case-insensitive).

**Violation:**

<!-- advpl-lint: anti-exemplo -->
```advpl
#Include "Protheus.ch"

User Function MyFunc()
    // ...
Return
```

**Correct:**

```advpl
#include "totvs.ch"

User Function MyFunc()
    // ...
Return
```

**Why it matters:** `Protheus.ch` is a legacy include that may not contain all current definitions and may be removed in future Protheus versions. `totvs.ch` is the officially supported include that aggregates all necessary header definitions.

---

## [BP-005] Missing Begin Sequence/Recover/End Sequence around critical operations

**Severity:** WARNING

**Description:** Critical operations such as `RecLock`, database writes, external API calls, and file operations should be wrapped in `Begin Sequence`/`Recover`/`End Sequence` blocks to handle errors gracefully instead of crashing.

**What to look for:** `RecLock`, `MsExecAuto`, `HttpGet`, `HttpPost`, `FT_FUse`, or web service calls that are not inside a `Begin Sequence` block.

**Violation:**

```advpl
User Function ProcessOrder(cOrder)
    Local lRet := .T.

    DbSelectArea("SC5")
    DbSetOrder(1)
    DbSeek(xFilial("SC5") + cOrder)

    RecLock("SC5", .F.)
    SC5->C5_LIBEROK := "S"
    MsUnlock()

    // If RecLock fails or an error occurs, function crashes
    // with an unhandled exception

Return lRet
```

**Correct:**

```advpl
User Function ProcessOrder(cOrder)
    Local lRet   := .T.
    Local oError

    DbSelectArea("SC5")
    DbSetOrder(1)
    DbSeek(xFilial("SC5") + cOrder)

    Begin Sequence

        If RecLock("SC5", .F.)
            SC5->C5_LIBEROK := "S"
            MsUnlock()
        Else
            lRet := .F.
            FWLogMsg("ERROR", , "ProcessOrder", "SC5", "LOCK", "001", "Could not lock SC5 for order: " + cOrder)
        EndIf

    Recover Using oError
        lRet := .F.
        FWLogMsg("ERROR", , "ProcessOrder", "SC5", "ERR", "002", "Error: " + oError:Description)

    End Sequence

Return lRet
```

**Why it matters:** Without error handling, any failure in database or external operations causes the entire thread to crash, potentially leaving records locked and data in an inconsistent state. Structured error handling allows graceful recovery and proper cleanup.

---

## [BP-006] Variable names not following Hungarian notation

**Severity:** INFO

**Description:** ADVPL convention uses Hungarian notation with a type prefix followed by PascalCase: `c` for character, `n` for numeric, `l` for logical, `d` for date, `a` for array, `o` for object, `b` for code block, `x` for variant/indefinite.

**What to look for:** Variable declarations where the name does not start with a recognized type prefix (`c`, `n`, `l`, `d`, `a`, `o`, `b`, `x`) or does not follow PascalCase after the prefix.

**Violation:**

```advpl
User Function Calculate()
    Local total     := 0
    Local clientName := ""
    Local flag      := .T.
    Local items     := {}
    Local dt        := Date()

    // Variable names do not indicate their type

Return
```

**Correct:**

```advpl
User Function Calculate()
    Local nTotal      := 0
    Local cClientName := ""
    Local lFlag       := .T.
    Local aItems      := {}
    Local dDate       := Date()

    // Each variable name starts with its type prefix

Return
```

**Why it matters:** Hungarian notation makes code self-documenting. When reading `nTotal`, any developer immediately knows it is a numeric value. This reduces bugs caused by type mismatches and speeds up code reviews.

---

## [BP-007] Functions missing Protheus.doc documentation header

**Severity:** INFO

**Description:** Every `User Function`, `Static Function`, and `Main Function` should have a `Protheus.doc` documentation header describing the function's purpose, author, date, parameters, and return value.

**What to look for:** Function definitions without a preceding `Protheus.doc` comment block.

**Violation:**

```advpl
User Function CalcDiscount(nPrice, nPercent)
    Local nDiscount := nPrice * (nPercent / 100)
Return nDiscount
```

**Correct:**

```advpl
/*/{Protheus.doc} CalcDiscount
Calculates discount value based on price and percentage.

@type  User Function
@author Developer Name
@since 01/01/2025
@version 1.0

@param nPrice, Numeric, Original price
@param nPercent, Numeric, Discount percentage (0-100)

@return Numeric, Calculated discount value

@example
Local nDisc := CalcDiscount(100.00, 10) // Returns 10.00
/*/
User Function CalcDiscount(nPrice, nPercent)
    Local nDiscount := nPrice * (nPercent / 100)
Return nDiscount
```

**Why it matters:** Documentation headers enable IDE tooltips, automatic documentation generation, and help other developers understand the function's contract without reading the implementation. They are especially important in large teams and long-lived codebases.

---

## [BP-008] Using reserved system variables as Local/Static variable names

**Severity:** CRITICAL

**Description:** The Protheus framework maintains several `Private` variables to track the current company, branch, and environment context. Declaring a `Local` variable with the same name shadows the system variable, causing loss of context, incorrect data filtering, and hard-to-reproduce bugs in multi-branch/multi-company environments.

**Reserved variable names (NEVER use as Local/Static):**

| Variable | Purpose |
|----------|---------|
| `cFilial` | Branch context — used internally by xFilial() and other framework functions |
| `cFilAnt` | Current branch code — default value for xFilial() second parameter |
| `cEmpAnt` | Current company/group code — used by FWSizeFilial() and environment functions |
| `nModulo` | Current module number |
| `cUsuario` | Current user login |

**Violation:**

```advpl
User Function MyJob()
    Local cEmpresa := "99"
    Local cFilial  := "01"   // WRONG: shadows system Private variable

    RpcSetEnv(cEmpresa, cFilial)
    // After this call, the system's cFilial Private is overwritten
    // xFilial() and other functions may return incorrect values
Return
```

**Correct:**

```advpl
User Function MyJob()
    Local cCodEmp := "99"
    Local cCodFil := "01"   // Safe: different name from system variable

    RpcSetEnv(cCodEmp, cCodFil)
    // System's cFilAnt/cEmpAnt are set correctly by RpcSetEnv
    // xFilial() works as expected
Return
```

**Recommended alternatives:**

| Instead of | Use |
|------------|-----|
| `cFilial` | `cCodFil` |
| `cEmpresa` | `cCodEmp` |
| `cFilAnt` | (never reassign — read-only system variable) |
| `cEmpAnt` | (never reassign — read-only system variable) |

**Use FW* functions to read company/branch values:**

| Function | Purpose |
|----------|---------|
| `FWCodFil()` | Returns current branch code (M0_CODFIL) |
| `FWCodEmp()` | Returns current company code |
| `FWFilial(cAlias)` | Returns branch for the given alias (respects sharing mode) |
| `FWCompany(cAlias)` | Returns company for the given alias |
| `FWGrpCompany()` | Returns current company group |
| `FWUnitBusiness(cAlias)` | Returns current business unit |
| `FWAllFilial()` | Returns array of all branches for current group/company |
| `FWAllCompany()` | Returns array of all companies for current group |
| `FWAllGrpCompany()` | Returns array of all company groups |
| `FWSizeFilial()` | Returns branch field size |
| `xFilial(cAlias)` | Returns branch for index composition (respects sharing mode) |

**Why it matters:** Shadowing system Private variables is one of the most dangerous bugs in Protheus because it is silent — the code compiles and appears to work in single-branch testing, but fails in multi-branch production environments where branch context is critical for data isolation.

---

## [BP-009] Bare `Function` keyword in customer code

**Severity:** CRITICAL

**Description:** The bare `Function` keyword (without `User`, `Static`, or a `Class` prefix) is reserved for the TOTVS core RPO. Customer code compiled into a customer RPO **must** use `User Function` (or `Static Function` for internal helpers, or a class `Method` for TLPP classes). Using bare `Function` in customer code causes a compilation failure, and in TLPP REST files it silently breaks the endpoint because the code never reaches the RPO.

**What to look for:** Any line matching `^\s*Function\s+\w+\(` in a `.prw` or `.tlpp` file, where the function is **not** preceded by `User`, `Static`, or inside a `Class ... EndClass` block. Also check TLPP REST files where `@Get`, `@Post`, `@Put`, `@Patch`, or `@Delete` annotations are immediately followed by bare `Function`.

**Violation:**

```advpl
#include "totvs.ch"

// WRONG — bare Function in a customer .prw file
Function CalcDiscount(nPrice, nPercent)
    Local nDiscount := nPrice * (nPercent / 100)
Return nDiscount
```

```tlpp
#include "tlpp-core.th"
#include "tlpp-rest.th"

// WRONG — bare Function with REST annotation (will not compile in customer RPO)
@Get("/api/v1/products")
Function getProducts()
    // implementation
return oRest:setResponse(cData)
```

**Correct:**

```advpl
#include "totvs.ch"

/*/{Protheus.doc} CalcDiscount
Calcula o valor do desconto
@type User Function
@param nPrice, Numeric, Preco original
@param nPercent, Numeric, Percentual de desconto
@return nDiscount, Numeric, Valor do desconto
/*/
User Function CalcDiscount(nPrice, nPercent)
    Local nDiscount := nPrice * (nPercent / 100)
Return nDiscount
```

```tlpp
#include "tlpp-core.th"
#include "tlpp-rest.th"

// RIGHT — User Function matches the official TOTVS sample rest-mod02.tlpp
@Get("/api/v1/products")
User Function getProducts()
    // implementation
return oRest:setResponse(cData)
```

**Rule summary:**

| Keyword | Valid in customer RPO? | Notes |
|---------|------------------------|-------|
| `User Function NAME()` | Yes | Default choice; callable as `u_NAME()` |
| `user function NAME()` (TLPP, lowercase) | Yes | Equivalent to `User Function` (case-insensitive) |
| `Static Function NAME()` | Yes | Internal helper (file-scoped) |
| `Method NAME() Class XXX` | Yes | Inside `Class ... EndClass` |
| `Function NAME()` (bare) | **NO** | Reserved for TOTVS core RPO |

**Exceptions:** The bare `Function` keyword is legitimate only in narrow scenarios outside regular customer code — for example, localization sources consumed by `FwExecLocaliz` (where the lookup mechanism requires the exact function name without the `u_` prefix). These cases should be flagged for human review but not auto-rewritten.

**Why it matters:** This is a silent failure mode. The code may look valid in an editor, but the customer's `appre` compiler will reject it when building the customer RPO, or TLPP REST annotations will never be registered. Users who copy-paste from stale examples (including older plugin-generated code) hit this and are blocked until they rename the keyword. Always default to `User Function` unless there is an explicit, documented reason to use something else.

**Authoritative reference:** TOTVS sample repository `totvs/tlpp-sample-rest`, file `rest-mod02.tlpp` (annotation-based REST with `user function`) and `rest-mod03.tlpp` (class-based REST with annotated methods).

---

## [BP-010] Identifier name exceeds the effective length limit

**Severity:** CRITICAL

**Description:** ADVPL inherits a **10-character limit** on identifiers (functions, methods, variables, fields) from the legacy DBase DBF format — only the first 10 characters are used to uniquely identify the symbol. TLPP removes this limit, but **only when a `namespace` is declared**. A name that exceeds the limit either fails to compile or silently collides with another symbol sharing the first 10 characters, producing one of the most insidious bugs in Protheus: two different functions/methods invoked as if they were the same.

The effective limits are:

| Construct | File | Effective limit | Reason |
|-----------|------|-----------------|--------|
| `User Function NAME()` | `.prw` | **8 characters** | 10-char limit minus the `u_` invocation prefix (2 chars) |
| `Static Function NAME()` | `.prw` | **10 characters** | Full 10 chars — no prefix |
| Class method (ADVPL) | `.prw` | 10 characters | Exception: classes inheriting from `longnameclass` (legacy) |
| Variable / parameter | `.prw` / `.tlpp` without namespace | 10 characters | Same DBF legacy |
| **TLPP with `namespace`** | `.tlpp` | **255 characters** | Available from Protheus release **12.1.2410** |
| TLPP **without** `namespace` | `.tlpp` | 10 characters | Falls back to ADVPL limit |

**What to look for:**

1. **`.prw` files:**
   - `User Function NAME` where `len(NAME) > 8`
   - `Static Function NAME` where `len(NAME) > 10`
   - `Method NAME() Class XXX` where `len(NAME) > 10`, **unless** the class declaration contains `from longnameclass` (case-insensitive)
2. **`.tlpp` files WITHOUT a `namespace` declaration:**
   - Any function/method/class with `len(name) > 10` — same fallback as ADVPL
3. **`.tlpp` files WITH a `namespace` declaration:**
   - Only flag if `len(name) > 255` (extreme edge case, practically unreachable)

Skip the check for variables and parameters during static review (too noisy) — focus exclusively on function, method, and class names, which are the cases that cause real compilation/collision incidents.

**Violation:**

```advpl
#include "totvs.ch"

// WRONG — User Function with 14 chars (limit is 8)
User Function ProcessaValidacao()
    Local lRet := .T.
Return lRet
```

```advpl
#include "totvs.ch"

// WRONG — Static Function with 15 chars (limit is 10)
Static Function ValidaCadastroItem()
    Return .T.
```

```tlpp
#include "tlpp-core.th"
#include "tlpp-rest.th"

// WRONG — TLPP file without namespace and 17-char function name
// Falls back to the 10-char ADVPL limit
@Post("/api/v1/validacao")
User Function processaCadastroCliente()
return
```

**Correct:**

```advpl
#include "totvs.ch"

// RIGHT — User Function with 7 chars (respects the 8-char limit)
User Function FATA100()
    Local lRet := .T.
Return lRet
```

```advpl
#include "totvs.ch"

// RIGHT — Static Function with 10 chars (at the limit)
Static Function ValidaItem()
    Return .T.
```

```tlpp
#include "tlpp-core.th"
#include "tlpp-rest.th"

// RIGHT — TLPP with namespace: long function names are allowed (up to 255 chars)
namespace custom.fat.processacadastrocliente

@Post("/api/v1/cadastro")
User Function processaCadastroCliente()
return
```

**Exception — `longnameclass`:**

`longnameclass` is a legacy ADVPL mechanism (magical inheritance) that allows class methods and properties to exceed the 10-char limit. When a class declaration contains `from longnameclass`, the reviewer must **NOT** flag its methods for exceeding the 10-char limit. Example:

```advpl
// OK — methods can exceed 10 chars because of longnameclass inheritance
Class MinhaClasseCustomizada From LongNameClass
    Method AtualizaCadastroCliente()  // 23 chars — OK here
EndClass
```

However, **do not recommend `longnameclass` as a fix** when generating new code or suggesting refactors. The modern, officially supported replacement is TLPP with `namespace`. Mention `longnameclass` only when reviewing pre-existing legacy code.

**Suggested fixes (in order of preference):**

1. **For `.prw` files** — two equally valid options:
   - **(A) Shorten the name** to fit within 8 (User Function) or 10 (Static Function) chars. Follow Protheus conventions: module prefix + sequence (`FATA100`), mnemonic abbreviation (`PRCVALIT`), or functional abbreviation (`VLDITENS`).
   - **(B) Migrate the file to `.tlpp` with a `namespace`** declaration. The namespace lifts the length limit to 255 chars and aligns with the modern TLPP direction.
2. **For `.tlpp` files without namespace** — add the `namespace custom.<agrupador>.<servico>` declaration right after the includes. This is almost always the correct fix since the file is already `.tlpp`.
3. **Never** suggest `longnameclass` as a fix for new code or active refactors.

**Rule summary:**

| Scenario | Limit | Fix |
|----------|-------|-----|
| `.prw` + `User Function` > 8 chars | 8 | Shorten or migrate to TLPP + namespace |
| `.prw` + `Static Function` > 10 chars | 10 | Shorten or migrate to TLPP + namespace |
| `.prw` + class method > 10 chars, no `longnameclass` | 10 | Shorten or migrate to TLPP + namespace |
| `.tlpp` without namespace + name > 10 chars | 10 | Add `namespace custom.<agrupador>.<servico>` |
| `.tlpp` with namespace + name > 255 chars | 255 | Shorten (rare) |

**Why it matters:** The 10-char collision is one of the hardest ADVPL bugs to diagnose. Two functions named `ProcessaPedidoCliente` and `ProcessaPedidoFornecedor` are **the same function** to the ADVPL compiler — only the first call to `u_Processa` is reachable, the second is silently shadowed. On TLPP files without namespace, the failure is identical. Adopting TLPP with `namespace` (available since release **12.1.2410**) removes the limit entirely and is the officially documented path forward from TOTVS.

**Authoritative references:**
- TDN — [Tamanho do nome (identificador) de função](https://tdn.totvs.com/pages/viewpage.action?pageId=172296510)
- TDN — [Suporte a TLPP no Protheus](https://tdn.totvs.com/display/public/framework/Suporte+a+TLPP+no+Protheus)
