# Security Rules

Rules for detecting security vulnerabilities in ADVPL/TLPP code. Each rule includes a detection pattern, violation example, correct example, and explanation.

---

## [SEC-001] SQL built by string concatenation with external input (SQL injection risk)

**Severity:** CRITICAL

**Description:** Building SQL queries by concatenating user-supplied or external variables directly into the query string allows SQL injection attacks. Attackers can manipulate input to execute arbitrary SQL commands, potentially reading, modifying, or deleting data.

**What to look for:** `TCQuery` or string-based SQL construction where variables are concatenated with `+`, and `BeginSQL` blocks where a user-supplied or external value is inserted with `%exp:variable%`. The `%exp:` macro is **not** a bind parameter: it inserts the value into the SQL text (TDN, "Embedded SQL"), so it does not prevent injection for external input.

**Violation:**

<!-- advpl-lint: anti-exemplo -->
```advpl
User Function SearchClient(cSearch)
    Local cQuery := ""

    // DANGEROUS: cSearch is concatenated directly into SQL
    cQuery := "SELECT A1_COD, A1_NOME FROM " + RetSqlName("SA1")
    cQuery += " WHERE A1_NOME LIKE '%" + cSearch + "%'"
    cQuery += " AND D_E_L_E_T_ = ' '"

    TCQuery cQuery New Alias "QRY_CLI"

    // If cSearch = "'; DROP TABLE SA1; --"
    // the query becomes destructive!

Return
```

**Correct:**

```advpl
#include "totvs.ch"
#include "topconn.ch"

User Function SearchClient(cSearch)
    Local cAlias := GetNextAlias()
    Local oStmt  := FWPreparedStatement():New()
    Local cQuery := ""

    cQuery := "SELECT A1_COD, A1_NOME FROM " + RetSqlName("SA1") + " SA1 "
    cQuery += "WHERE SA1.D_E_L_E_T_ = ' ' "
    cQuery +=   "AND SA1.A1_FILIAL = ? "
    cQuery +=   "AND SA1.A1_NOME LIKE ? "

    oStmt:SetQuery(cQuery)
    oStmt:SetString(1, xFilial("SA1"))
    oStmt:SetString(2, "%" + cSearch + "%")

    DBUseArea(.T., "TOPCONN", TCGenQry(,, oStmt:GetFixQuery()), cAlias, .F., .T.)

    // ... read the result ...

    (cAlias)->(DBCloseArea())
    oStmt:Destroy()

Return
```

**Why it matters:** SQL injection is one of the most exploited vulnerabilities in web applications and internal systems alike. In Protheus, an injected query could bypass access controls, extract sensitive financial data, or corrupt critical business tables. `FWPreparedStatement` treats the value of each `?` as data (a `'` inside the value stays part of it, not a delimiter), which is what prevents injection; use it for every value that comes from outside the function. `BeginSQL` with `%exp:` is adequate only for values internal to the routine (see the `embedded-sql` and `query-builder` skills).

---

## [SEC-002] REST endpoint using SELF:GetContent() without input validation

**Severity:** CRITICAL

**Description:** REST API endpoints that read request body content via `SELF:GetContent()` (or `oRest:getBodyRequest()`) and use the data directly without validation expose the system to injection attacks, type errors, and business logic bypass.

**What to look for:** `SELF:GetContent()`, `oRest:getBodyRequest()`, or similar request body reading methods where the returned content is used directly in SQL queries, database operations, or business logic without validation or sanitization.

**Violation:**

<!-- advpl-lint: anti-exemplo -->
```tlpp
@Get("/api/v1/clients")
Method GetClient() Class ClientService
    Local cBody   := SELF:GetContent()
    Local jBody   := JsonObject():New()
    Local cCodCli := ""

    jBody:FromJson(cBody)
    cCodCli := jBody["code"]  // No validation!

    // Used directly in database lookup
    DbSelectArea("SA1")
    DbSetOrder(1)
    DbSeek(xFilial("SA1") + cCodCli)

    // cCodCli could be NIL, empty, oversized, or contain
    // malicious data - no checks performed

Return
```

**Correct:**

```tlpp
#include "tlpp-core.th"
#include "tlpp-rest.th"
#include "totvs.ch"

namespace custom.cadastro

@Post("/api/v1/clients/search")
user function getClient()
    Local cBody   := oRest:getBodyRequest()
    Local jBody   := JsonObject():New()
    Local cCodCli := ""
    Local cErro   := jBody:FromJson(cBody)
    Local aArea   := GetArea()

    // Validate JSON parsing (FromJson returns NIL on success)
    If cErro <> Nil
        oRest:setStatusCode(400)
        oRest:setResponse(errorBody("JSON_INVALIDO", "Invalid JSON body", cErro))
        RestArea(aArea)
        Return .T.
    EndIf

    // Validate required field existence and type
    If ValType(jBody["code"]) <> "C" .Or. Empty(jBody["code"])
        oRest:setStatusCode(400)
        oRest:setResponse(errorBody("CAMPO_OBRIGATORIO", "Field code is required and must be a string", "code"))
        RestArea(aArea)
        Return .T.
    EndIf

    // Validate field length and content
    cCodCli := PadR(AllTrim(jBody["code"]), TamSX3("A1_COD")[1])

    DbSelectArea("SA1")
    DbSetOrder(1)
    If DbSeek(xFilial("SA1") + cCodCli)
        // Process valid client
        oRest:setStatusCode(200)
        oRest:setResponse('{"code": "' + AllTrim(SA1->A1_COD) + '"}')
    Else
        oRest:setStatusCode(404)
        oRest:setResponse(errorBody("CLIENTE_NAO_ENCONTRADO", "Client not found", "A1_COD: " + cCodCli))
    EndIf

    RestArea(aArea)

Return .T.

// Error body: {code, message, detailedMessage}
static function errorBody(cCode, cMessage, cDetail)
    Local jErr := JsonObject():New()

    jErr["code"]            := cCode
    jErr["message"]         := cMessage
    jErr["detailedMessage"] := cDetail

Return jErr:toJson()
```

**Why it matters:** REST endpoints are exposed to external consumers and potentially the public internet. Without input validation, attackers can send malformed payloads that cause runtime errors (crashing the thread), bypass business rules, or exploit downstream operations. Every input must be validated for type, length, format, and business constraints.

---

## [SEC-003] Sensitive data in FWLogMsg/ConOut output

**Severity:** WARNING

**Description:** Logging sensitive information such as passwords, API tokens, CPF/CNPJ numbers, credit card numbers, or personal data in `FWLogMsg` (or the legacy `ConOut`) exposes it to anyone with access to the AppServer console or log files.

**What to look for:** `ConOut` or `FWLogMsg` calls that output variables containing passwords, tokens, credentials, CPF, CNPJ, or any personally identifiable information (PII).

**Violation:**

<!-- advpl-lint: anti-exemplo -->
```advpl
User Function AuthenticateUser(cUser, cPassword)
    Local lOk := .F.

    // DANGER: password logged in plain text!
    FWLogMsg("INFO", /*cTransactionId*/, "AUTH", "Security", /*cStep*/, /*cMsgId*/, "Attempting login - User: " + cUser + " Password: " + cPassword)

    lOk := ValidateCredentials(cUser, cPassword)

    If !lOk
        FWLogMsg("WARN", /*cTransactionId*/, "AUTH", "Security", /*cStep*/, /*cMsgId*/, "Failed login for user: " + cUser + " with password: " + cPassword)
    EndIf

Return lOk
```

**Correct:**

```advpl
User Function AuthenticateUser(cUser, cPassword)
    Local lOk := .F.

    FWLogMsg("INFO", /*cTransactionId*/, "AUTH", "Security", /*cStep*/, /*cMsgId*/, "Attempting login - User: " + cUser)

    lOk := ValidateCredentials(cUser, cPassword)

    If !lOk
        FWLogMsg("WARN", /*cTransactionId*/, "AUTH", "Security", /*cStep*/, /*cMsgId*/, "Failed login attempt for user: " + cUser)
    EndIf

Return lOk
```

**Why it matters:** Log files are often stored unencrypted, shared across teams, and retained for long periods. Sensitive data in logs can be accessed by unauthorized personnel, leaked through log aggregation tools, or exposed in security breaches. Regulations like LGPD (Brazil) and GDPR explicitly require that personal data not be logged unnecessarily.

---

## [SEC-004] Hardcoded credentials in source code

**Severity:** WARNING

**Description:** Passwords, API keys, database connection strings, and other credentials must never be hardcoded in source code. Source code is stored in version control, compiled into RPO, and accessible to all developers, making hardcoded secrets a significant security risk.

**What to look for:** String literals that appear to be passwords, API keys, bearer tokens, connection strings, or authentication secrets assigned to variables or used directly in function calls.

**Violation:**

<!-- advpl-lint: anti-exemplo -->
```advpl
User Function ConnectAPI()
    Local cUrl    := "https://api.example.com/v1"
    Local cApiKey := "sk-abc123def456ghi789jkl012mno345"
    Local cPass   := "P@ssw0rd!2025"
    Local aHeaders := {}
    Local cResponse := ""

    aAdd(aHeaders, "Authorization: Bearer " + cApiKey)
    aAdd(aHeaders, "Content-Type: application/json")

    cResponse := HttpGet(cUrl + "/data", "", aHeaders)

Return cResponse
```

**Correct:**

```advpl
User Function ConnectAPI()
    Local cUrl     := "https://api.example.com/v1"
    Local cApiKey  := GetAPICredential("EXAMPLE_API_KEY")
    Local aHeaders := {}
    Local cResponse := ""

    If Empty(cApiKey)
        FWLogMsg("ERROR", /*cTransactionId*/, "ConnectAPI", "Config", /*cStep*/, /*cMsgId*/, "API key not configured. Check SX6 parameter EXAMPLE_API_KEY.")
        Return ""
    EndIf

    aAdd(aHeaders, "Authorization: Bearer " + cApiKey)
    aAdd(aHeaders, "Content-Type: application/json")

    cResponse := HttpGet(cUrl + "/data", "", aHeaders)

Return cResponse

// Store credentials in SX6 parameters, environment variables,
// or a secure vault - never in source code
Static Function GetAPICredential(cParamName)
    Local cValue := AllTrim(SuperGetMV(cParamName, .F., ""))
Return cValue
```

**Why it matters:** Hardcoded credentials in source code are exposed to every developer with repository access, remain in version history even after deletion, and can be extracted from compiled RPO. If the repository is compromised, all hardcoded credentials are immediately exposed. Use Protheus SX6 parameters, environment variables, or a secrets management solution instead.

---

## [SEC-005] Usage of TOTVS restricted/internal functions, classes, or variables

**Severity:** CRITICAL

**Description:** TOTVS maintains a list of functions, classes, and variables that are internal property. These resources are NOT documented, NOT supported, and may be altered or removed without notice. Some have their compilation blocked since release 12.1.33. Using them in custom code causes compilation failures, runtime errors, or unpredictable behavior after updates.

**What to look for:** Any call to functions or classes listed in the TOTVS restricted resources list. See `restricted-functions.md` in the protheus-reference skill for the complete list.

**Compilation BLOCKED (will not compile on 12.1.33+):**

- `StaticCall()` — use public User Functions or TLPP namespaced calls instead
- `PTInternal()` — no replacement available; redesign the logic

**Commonly found restricted functions (NOT supported, may change without notice):**

| Restricted | Alternative |
|------------|-------------|
| `PARAMBOX` | Use `Pergunte()` with SX1 or `FWInputDialog()` |
| `MsExcel` | Use `FWMsExcel` or `FWAdaptor` |
| `CriaVar` | Use `FWCriaVar()` |
| `LASTKEY` | Use specific navigation control logic |
| `SetPrvt` | Declare variables explicitly with `Private` |
| `MontaBlock` | Build code blocks directly with `{|| ... }` |
| `FWMVCROTAUTO` | Use `MsExecAuto` per the routine's documented example or, for MVC routines, the model API (`FWLoadModel` + `SetOperation` + `Activate` + `SetValue` + `VldData` + `CommitData` + `DeActivate`); `FWExecView()` opens the UI and is not automation |
| `FWLOOKUP` | Use `FWInputDialog()` or standard F3 lookups |
| `OPENSXS` | Tables are opened automatically by the framework |
| `APPEND FROM` | Use `RecLock` + field-by-field copy |
| `COPY TO` | Use `RecLock` + field-by-field copy |
| `LoadLayout()` | Use `FWLoadLayout()` |
| `PivotTable` | Use `FWPivotTable` |
| `StaticCall()` | Use `User Function` (public) or TLPP namespace |
| `ApOleClient` | Use `FWMsExcel` for Excel or native file operations |
| `FWAUTHUSER` | Use proper REST authentication mechanisms |
| `E_FIELD` | Use `GetSx3Cache()` or `TamSx3()` |

**Violation:**

<!-- advpl-lint: anti-exemplo -->
```advpl
User Function MyReport()
    // WRONG: StaticCall is BLOCKED since 12.1.33
    Local aMenu := StaticCall(MATA030, MenuDef)

    // WRONG: PARAMBOX is restricted
    PARAMBOX(aParams, "Filtros", , , , , , , , , .F., .F.)

    // WRONG: CriaVar is restricted
    Local xVal := CriaVar("A1_COD")
Return
```

**Correct:**

```advpl
User Function MyReport()
    Local aMenu := {}
    Local xVal  := Nil

    // CORRECT: load the menu through the framework
    aMenu := FWLoadMenuDef("MATA030")

    // CORRECT: Use Pergunte() with SX1 configuration
    Pergunte("MYREPORT", .F.)

    // CORRECT: Use FWCriaVar
    xVal := FWCriaVar("A1_COD")
Return
```

**Reference:** Full list at https://centraldeatendimento.totvs.com/hc/pt-br/articles/360016461772

**Why it matters:** TOTVS reserves the right to modify or remove internal functions without notice. Code that uses restricted functions will break silently after Protheus updates — or fail to compile entirely on releases 12.1.33+. The TOTVS support team does NOT provide assistance for issues caused by restricted function usage. Always use documented, supported alternatives.
