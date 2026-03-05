# ADVPL/TLPP Common Errors Reference

Top 50 most common ADVPL/TLPP errors organized by category with cause and solution for each.

---

## Compilation Errors

### 1. Syntax error at line X / Unexpected token

**Error Message:** `Syntax error at line 45: unexpected token 'EndIf'`

**Cause:** Mismatched control structures, missing operators, or typos in keywords. Common when mixing uppercase/lowercase keywords or forgetting operators between expressions.

**Solution:**
```advpl
// WRONG - missing operator
If cCodCli "001"
    // ...
EndIf

// FIXED - add comparison operator
If cCodCli == "001"
    // ...
EndIf
```

### 2. Variable XXXX already declared

**Error Message:** `Variable 'cNome' already declared`

**Cause:** Declaring the same variable name twice in the same scope with `Local`, `Static`, or `Private`.

**Solution:**
```advpl
// WRONG
Local cNome := ""
Local cNome := "Test"  // duplicate declaration

// FIXED - declare once, assign later if needed
Local cNome := ""
cNome := "Test"
```

### 3. Function XXXX not found / Undefined function

**Error Message:** `Function 'XPTO001' not found`

**Cause:** The function does not exist in the RPO, is misspelled, or the source file was not compiled. In TLPP, may also be a missing namespace.

**Solution:**
```advpl
// Check spelling matches exactly
// Verify the .prw/.tlpp file is compiled into the RPO
// If using TLPP with namespaces, ensure the .tlpp file
// with the class/function is compiled and the caller
// references the correct namespace via fully qualified name
// e.g.: custom.vendas.PedidoService():New()
```

### 4. Missing END / ENDDO / ENDIF

**Error Message:** `Missing ENDIF for IF at line 20`

**Cause:** Every `If` needs `EndIf`, every `While` needs `EndDo`, every `For` needs `Next`, every `Do Case` needs `EndCase`.

**Solution:**
```advpl
// WRONG
If lCondition
    nTotal := 100
// Missing EndIf

// FIXED
If lCondition
    nTotal := 100
EndIf
```

### 5. Missing operator

**Error Message:** `Missing operator at line 12`

**Cause:** Two expressions placed next to each other without an operator, or a missing concatenation operator (`+`).

**Solution:**
```advpl
// WRONG
cMsg := "Total: " cValToChar(nTotal)

// FIXED
cMsg := "Total: " + cValToChar(nTotal)
```

### 6. Type clash in expression

**Error Message:** `Type clash in expression at line 30`

**Cause:** Attempting to combine incompatible types at compile time. For example, concatenating a string with a numeric literal.

**Solution:**
```advpl
// WRONG
cMsg := "Value: " + 100

// FIXED
cMsg := "Value: " + cValToChar(100)
```

### 7. #Include file not found

**Error Message:** `#Include file 'MyCustom.ch' not found`

**Cause:** The .ch file does not exist in the includes path configured in the Protheus IDE or the filename is misspelled.

**Solution:**
```advpl
// Verify file exists in the includes directory
// Check the includes path in your project configuration
// Standard includes are always available:
#Include "TOTVS.CH"
#Include "TopConn.ch"
#Include "FWMVCDef.ch"
```

### 8. Duplicate function name

**Error Message:** `Duplicate definition of function 'FATA001'`

**Cause:** Two User Functions with the same name exist in different .prw files compiled into the same RPO.

**Solution:**
```advpl
// Search your project for duplicate function names
// Rename one of the functions
// Use unique module prefix conventions: FATA001, FATA002, etc.
```

### 9. Too many parameters

**Error Message:** `Too many parameters in function call`

**Cause:** Passing more arguments to a function than it declares. ADVPL is lenient but TLPP strict mode enforces parameter counts.

**Solution:**
```advpl
// WRONG - function expects 2 params, called with 4
Local lRet := MyFunc(cCode, cName, dDate, nVal)

// FIXED - match the function signature
// If extra params are needed, update the function definition
Static Function MyFunc(cCode, cName, dDate, nVal)
    // ...
Return lRet
```

### 10. Missing RETURN

**Error Message:** `Missing RETURN statement in function 'MyFunc'`

**Cause:** Every function must end with a `Return` statement. The compiler enforces this.

**Solution:**
```advpl
// WRONG
User Function FATA001()
    Local nVal := 10
    // no Return

// FIXED
User Function FATA001()
    Local nVal := 10
Return nVal
```

### 11. Invalid character in source

**Error Message:** `Invalid character in source at line 5`

**Cause:** Non-ASCII characters in the source code outside of string literals (accented characters in variable names, BOM markers, invisible Unicode characters).

**Solution:**
```advpl
// WRONG
Local cNúmero := "123"  // accented u in variable name

// FIXED
Local cNumero := "123"  // ASCII only for identifiers
// Accented characters are fine inside strings:
Local cMsg := "Numero do documento"
```

### 12. Ambiguous reference

**Error Message:** `Ambiguous reference to 'cValue'`

**Cause:** A variable exists in multiple scopes (e.g., Local and Private) creating ambiguity. Also occurs with field names conflicting with variable names.

**Solution:**
```advpl
// WRONG - cValue exists as both Local and field
Local cValue := ""
cValue := SA1->A1_NOME  // ambiguous if there is a field called cValue

// FIXED - use explicit alias for field references
// and prefix variables properly
Local cNome := ""
cNome := SA1->A1_NOME
```

### 13. Missing #Include "TOTVS.CH"

**Error Message:** `Undefined symbol 'PSAY'` or `Syntax error` on standard macros

**Cause:** TOTVS.CH (formerly Protheus.ch, which is now obsolete) defines essential preprocessor macros (@ ... SAY, @ ... GET, DEFINE DIALOG, etc.). Without it, these commands are not recognized.

**Solution:**
```advpl
// WRONG - missing include causes many cryptic errors
User Function FATA001()
    @ 10,10 Say "Hello"  // error: undefined syntax
Return

// FIXED - always include as first line
#Include "TOTVS.CH"

User Function FATA001()
    @ 10,10 Say "Hello"
Return
```

### 14. Invalid preprocessor directive

**Error Message:** `Invalid preprocessor directive '#DEFINEE'`

**Cause:** Typo in preprocessor command. Valid directives: `#Include`, `#Define`, `#IfDef`, `#IfNDef`, `#Else`, `#EndIf`, `#xCommand`, `#xTranslate`.

**Solution:**
```advpl
// WRONG
#Definee MAX_SIZE 100

// FIXED
#Define MAX_SIZE 100
```

### 15. Class/Method not found (TLPP)

**Error Message:** `Class 'MyService' not found` or `Method 'getData' not found in class`

**Cause:** In TLPP, classes require proper namespace declaration and `Using Namespace` in the consumer file. Method must be declared in the class definition.

**Solution:**
```tlpp
// Class definition
Namespace mycompany.services

Class MyService
    Public Method New() As Object
    Public Method getData() As Array
EndClass

// Consumer file
#Include "TOTVS.CH"
Using Namespace mycompany.services

User Function TestSvc()
    Local oSvc := MyService():New()
    Local aData := oSvc:getData()
Return
```

---

## Runtime Errors

### 16. Variable does not exist

**Error Message:** `Error: Variable 'CCODCLI' does not exist`

**Cause:** Referencing a variable that was never declared with `Local`, `Static`, `Private`, or `Public`. Often a typo in the variable name.

**Solution:**
```advpl
// WRONG
User Function FATA001()
    cCodCli := "000001"  // not declared
Return

// FIXED
User Function FATA001()
    Local cCodCli := "000001"
Return
```

### 17. Array access out of bounds (index N of N)

**Error Message:** `Array access error: index 5 of 3`

**Cause:** Trying to access an array position that does not exist. Index is greater than `Len(aArray)` or less than 1.

**Solution:**
```advpl
// WRONG - no bounds check
Local aItems := {"A", "B", "C"}
cVal := aItems[5]  // only 3 elements

// FIXED - always check bounds
Local aItems := {"A", "B", "C"}
If Len(aItems) >= 5
    cVal := aItems[5]
Else
    Conout("Index out of bounds. Array size: " + cValToChar(Len(aItems)))
EndIf
```

### 18. Type mismatch on operation

**Error Message:** `Type mismatch on + : C and N`

**Cause:** Performing an operation between incompatible types, such as adding a string to a number.

**Solution:**
```advpl
// WRONG
Local cMsg := "Total: " + nTotal  // string + numeric

// FIXED - convert to same type
Local cMsg := "Total: " + cValToChar(nTotal)

// Or for numeric operations, ensure both are numeric:
Local nResult := Val(cNumStr) + nTotal
```

### 19. Divide by zero

**Error Message:** `Divide by zero`

**Cause:** Dividing a number by zero without a guard check.

**Solution:**
```advpl
// WRONG
nPerc := nParcial / nTotal  // nTotal might be 0

// FIXED - guard against zero
If nTotal != 0
    nPerc := nParcial / nTotal
Else
    nPerc := 0
EndIf

// Alternative - inline with NoRound or IIf
nPerc := IIf(nTotal > 0, nParcial / nTotal, 0)
```

### 20. NIL value in expression

**Error Message:** `Value is NIL` or `Type mismatch: U and C`

**Cause:** Using a variable that has not been initialized (defaults to NIL) or a function returned NIL unexpectedly.

**Solution:**
```advpl
// WRONG
Local cResult
cMsg := "Result: " + cResult  // cResult is NIL

// FIXED - always initialize
Local cResult := ""
cMsg := "Result: " + cResult

// Or guard with ValType check
If ValType(cResult) == "C"
    cMsg := "Result: " + cResult
EndIf
```

### 21. Invalid alias XXXX

**Error Message:** `Invalid alias 'SA1'`

**Cause:** Attempting to access a workarea/alias that has not been opened or has been closed.

**Solution:**
```advpl
// WRONG - alias not opened
cNome := SA1->A1_NOME

// FIXED - open the workarea first
DbSelectArea("SA1")
DbSetOrder(1)
If DbSeek(xFilial("SA1") + cCodCli)
    cNome := SA1->A1_NOME
EndIf

// Or check if alias is active:
If Select("SA1") > 0
    cNome := SA1->A1_NOME
EndIf
```

### 22. WorkArea not in use

**Error Message:** `WorkArea not in use`

**Cause:** The alias was closed (via `DbCloseArea()`) or was never opened, but code still tries to navigate or read from it.

**Solution:**
```advpl
// WRONG - area closed before usage
DbSelectArea("QRY_TMP")
DbCloseArea()
// ... later ...
QRY_TMP->FIELD1  // WorkArea not in use

// FIXED - check before using
If Select("QRY_TMP") > 0
    cVal := QRY_TMP->FIELD1
    DbSelectArea("QRY_TMP")
    DbCloseArea()
EndIf
```

### 23. RecLock timeout

**Error Message:** `Record lock timeout on alias 'SD1'`

**Cause:** Another user or thread holds a lock on the same record, and the timeout expired.

**Solution:**
```advpl
// WRONG - blocks indefinitely
RecLock("SD1", .T.)
SD1->D1_TOTAL := nVal
MsUnlock()

// FIXED - use non-blocking lock with retry
Local nRetries := 3
Local lLocked := .F.

While nRetries > 0 .And. !lLocked
    lLocked := RecLock("SD1", .F.)
    If !lLocked
        nRetries--
        Sleep(1000) // wait 1 second before retry
    EndIf
EndDo

If lLocked
    SD1->D1_TOTAL := nVal
    MsUnlock()
Else
    Conout("ERROR: Unable to lock record after retries")
EndIf
```

### 24. Code block evaluation error

**Error Message:** `Error evaluating code block`

**Cause:** The code block references variables that are out of scope, or contains a runtime error within the block.

**Solution:**
```advpl
// WRONG - variable cField not available when block executes
Static Function CreateBlock()
    Local cField := "A1_NOME"
Return {|| &cField }  // macro may fail at eval time

// FIXED - capture value inside the block
Static Function CreateBlock()
    Local cField := "A1_NOME"
Return {|| SA1->&(cField) }

// Or avoid macro entirely:
Static Function GetFieldValue(cAlias, cField)
    Local xVal := (cAlias)->&(cField)
Return xVal
```

### 25. Object method not found

**Error Message:** `Method 'PROCESS' not found in object of class 'TFONTS'`

**Cause:** Calling a method that does not exist on the object, or the object is of a different class than expected.

**Solution:**
```advpl
// Debug - check object class
Conout("Class: " + GetClassName(oObj))

// WRONG - calling wrong method
oObj:Process()  // method does not exist

// FIXED - check method exists or use correct class
If FindMember(oObj, "Process")
    oObj:Process()
Else
    Conout("Method Process not found on " + GetClassName(oObj))
EndIf
```

### 26. Stack overflow

**Error Message:** `Stack overflow` or `Internal error: stack limit exceeded`

**Cause:** Infinite recursion or extremely deep call chains. A function calls itself without a proper base case.

**Solution:**
```advpl
// WRONG - infinite recursion
Static Function Factorial(n)
    Return n * Factorial(n - 1)  // never stops when n <= 0

// FIXED - add base case
Static Function Factorial(n)
    If n <= 1
        Return 1
    EndIf
Return n * Factorial(n - 1)
```

### 27. Memory allocation error

**Error Message:** `Memory allocation error` or `Out of memory`

**Cause:** Arrays growing without bounds, large string concatenations, or unclosed workareas consuming resources.

**Solution:**
```advpl
// WRONG - unbounded array growth
Local aData := {}
While .T.  // endless loop
    aAdd(aData, GetRecord())
EndDo

// FIXED - add limits and cleanup
Local aData := {}
Local nLimit := 10000
While !Eof() .And. Len(aData) < nLimit
    aAdd(aData, GetRecord())
    DbSkip()
EndDo
```

### 28. String too long

**Error Message:** `String too long` or truncation issues

**Cause:** ADVPL strings have a maximum size limit. Repeated concatenation in a loop can exceed it.

**Solution:**
```advpl
// WRONG - builds massive string in loop
Local cHtml := ""
While !Eof()
    cHtml += "<tr><td>" + ALIAS->FIELD1 + "</td></tr>"
    DbSkip()
EndDo

// FIXED - use array and join at the end
Local aHtml := {}
While !Eof()
    aAdd(aHtml, "<tr><td>" + ALIAS->FIELD1 + "</td></tr>")
    DbSkip()
EndDo
cHtml := ArrTokStr(aHtml, CRLF)
```

### 29. Date conversion error (invalid date)

**Error Message:** `Invalid date` or wrong date returned

**Cause:** Using `StoD()` with an incorrectly formatted string (expected YYYYMMDD), or `CtoD()` with wrong date format.

**Solution:**
```advpl
// WRONG
Local dDate := StoD("01/01/2024")  // StoD expects YYYYMMDD

// FIXED
Local dDate := StoD("20240101")     // correct format for StoD
Local dDate2 := CtoD("01/01/2024")  // CtoD uses system date format
```

### 30. Numeric overflow

**Error Message:** `Numeric overflow`

**Cause:** A numeric value exceeds the maximum precision defined for a field or variable. Often occurs when writing to a database field with limited size (e.g., N(10,2)).

**Solution:**
```advpl
// WRONG - value exceeds field precision
SD1->D1_TOTAL := 99999999999.99  // field is N(14,2) - too large

// FIXED - validate before writing
If nTotal <= 99999999999.99 .And. nTotal >= -99999999999.99
    SD1->D1_TOTAL := nTotal
Else
    Conout("ERROR: Numeric overflow for D1_TOTAL: " + cValToChar(nTotal))
EndIf
```

### 31. Invalid function argument

**Error Message:** `Invalid argument passed to function 'SubStr'`

**Cause:** Passing NIL or wrong type to a native function that expects a specific type.

**Solution:**
```advpl
// WRONG - first param is NIL
Local cResult := SubStr(cText, 1, 5)  // cText might be NIL

// FIXED - validate before calling
If ValType(cText) == "C" .And. !Empty(cText)
    cResult := SubStr(cText, 1, Min(5, Len(cText)))
Else
    cResult := ""
EndIf
```

### 32. Thread error

**Error Message:** `Thread creation error` or `Maximum number of threads exceeded`

**Cause:** Too many concurrent threads created, or the AppServer thread pool is exhausted.

**Solution:**
```advpl
// Check appserver.ini for MaxThreads setting
// [General]
// MaxThreads=200

// WRONG - creating threads without limit
For nI := 1 To 10000
    StartJob("U_PROCESS", cEnvServer, .F., nI)
Next

// FIXED - control concurrency
Local nMaxThreads := 10
Local nActive := 0
For nI := 1 To nTotal
    While nActive >= nMaxThreads
        Sleep(500)
        // Check for completed threads
    EndDo
    StartJob("U_PROCESS", cEnvServer, .F., nI)
    nActive++
Next
```

### 33. DLL load failure

**Error Message:** `Error loading DLL: 'mylib.dll'`

**Cause:** The DLL does not exist in the expected path, is not compatible (32/64 bit mismatch), or has missing dependencies.

**Solution:**
```advpl
// Verify DLL exists in the AppServer directory or system PATH
// Check 32-bit vs 64-bit compatibility with AppServer
// Use ExeDllRun2/ExeDllRun3 with full path:
Local nHandle := ExeDllRun2("C:\TOTVS\bin\appserver\mylib.dll", "MyFunction")
If nHandle < 0
    Conout("ERROR: DLL load failed. Verify path and architecture.")
EndIf
```

### 34. Connection refused (DB)

**Error Message:** `Connection refused` or `Cannot connect to database server`

**Cause:** The database server (SQL Server, PostgreSQL, Oracle) is unreachable due to network issues, wrong credentials, or the database service is down.

**Solution:**
```advpl
// Check dbaccess.ini / appserver.ini settings:
// [DBAccess]
// DBDataBase=MSSQL
// DBServer=localhost
// DBPort=7890

// In code - check connection before operations:
If !TCSqlExec("SELECT 1") == 0
    Conout("ERROR: Database connection failed")
    Conout("Check DBAccess configuration and network connectivity")
EndIf
```

### 35. Encoding/charset error

**Error Message:** `Character conversion error` or garbled text in output

**Cause:** Mismatch between the source file encoding, the Protheus environment encoding, and the database encoding. Common when mixing Latin1 and UTF-8.

**Solution:**
```advpl
// Check environment encoding in appserver.ini:
// [General]
// SourceEncoding=CP1252

// For explicit conversion:
Local cUtf8Text := EncodeUTF8(cAnsiText)
Local cAnsiText := DecodeUTF8(cUtf8Text)

// For REST APIs that require UTF-8:
oRest:SetContentType("application/json; charset=utf-8")
```

---

## Database Errors

### 36. Table/alias not found

**Error Message:** `Alias 'ZA1' not found` or `Table ZA1010 does not exist`

**Cause:** The table is not registered in SX2, or the physical table was not created in the database.

**Solution:**
```advpl
// Check if table exists in SX2
DbSelectArea("SX2")
DbSetOrder(1)
If !DbSeek("ZA1")
    Conout("Table ZA1 not found in SX2. Run UPDDISTR or add via configurator.")
EndIf

// If table exists in SX2 but not in DB, run:
// APSDU > Create Table or use TCGenQry to verify
```

### 37. Index not found / Invalid order

**Error Message:** `Invalid order number 4 for alias 'SA1'`

**Cause:** Calling `DbSetOrder(N)` with an order number that does not exist in the SIX index table for this alias.

**Solution:**
```advpl
// WRONG
DbSelectArea("SA1")
DbSetOrder(15)  // order 15 does not exist for SA1

// FIXED - verify available indexes
// Check SIX table for SA1 entries
// Use IndexOrd() to check current order
DbSelectArea("SA1")
If IndexOrd() == 0
    Conout("No indexes available for SA1")
EndIf
DbSetOrder(1)  // use a known valid index
```

### 38. Record lock timeout

**Error Message:** `Lock timeout on record 12345 of alias 'SC5'`

**Cause:** Extended lock held by another thread, often from a long transaction or user leaving a record open for editing.

**Solution:**
```advpl
// Monitor locks using Protheus Monitor (SIGAMNT)
// Or via AppServer console: check active threads

// Programmatic approach:
If RecLock("SC5", .F.)
    // perform update
    MsUnlock()
Else
    FWLogMsg("WARNING", , "LOCKMON", "MyModule", "", 01, ;
        "Lock timeout on SC5 RecNo: " + cValToChar(RecNo()))
EndIf
```

### 39. Transaction error

**Error Message:** `Transaction commit failed` or `Transaction already active`

**Cause:** Nesting `Begin Transaction` without proper `End Transaction`, or a transaction left open after an error.

**Solution:**
```advpl
// WRONG - nested transactions without control
Begin Transaction
    Begin Transaction  // already in transaction
        RecLock("SA1", .F.)
        SA1->A1_NOME := "Test"
        MsUnlock()
    End Transaction
End Transaction

// FIXED - single transaction scope
Begin Transaction
    RecLock("SA1", .F.)
    SA1->A1_NOME := "Test"
    MsUnlock()

    RecLock("SA2", .F.)
    SA2->A2_NOME := "Test"
    MsUnlock()
End Transaction
```

### 40. SQL syntax error (embedded query)

**Error Message:** `SQL syntax error near '...'`

**Cause:** Malformed embedded SQL query, missing quotes, wrong table name, or database-specific syntax issues.

**Solution:**
```advpl
// WRONG - missing quotes around string value
Local cQuery := "SELECT * FROM " + RetSqlName("SA1") + " WHERE A1_COD = " + cCodCli

// FIXED - proper quoting
Local cQuery := "SELECT * FROM " + RetSqlName("SA1") + " SA1 "
cQuery += "WHERE A1_FILIAL = '" + xFilial("SA1") + "' "
cQuery += "AND A1_COD = '" + cCodCli + "' "
cQuery += "AND SA1.D_E_L_E_T_ = ' ' "

// Always include D_E_L_E_T_ filter
// Always use RetSqlName() for table names
TCQuery cQuery New Alias "QRY_SA1"
```

### 41. Connection lost

**Error Message:** `Connection to database lost` or `DBAccess communication failure`

**Cause:** Network interruption, database server restart, or DBAccess timeout.

**Solution:**
```advpl
// Implement retry logic for critical operations
Local nRetries := 3
Local lOk := .F.

While nRetries > 0 .And. !lOk
    If TCSqlExec("SELECT 1") == 0
        lOk := .T.
    Else
        nRetries--
        Conout("DB connection lost. Retrying... (" + cValToChar(nRetries) + " left)")
        Sleep(2000)
        TCSqlReconnect()  // attempt reconnection
    EndIf
EndDo

If !lOk
    FWLogMsg("ERROR", , "DBCONN", "MyModule", "", 01, "Database connection unrecoverable")
EndIf
```

### 42. Deadlock detected

**Error Message:** `Deadlock detected` or `Transaction was deadlocked`

**Cause:** Two or more threads lock resources in opposite order, creating a circular wait.

**Solution:**
```advpl
// WRONG - Thread 1 locks SA1 then SC5, Thread 2 locks SC5 then SA1
// Thread 1:
RecLock("SA1", .F.)
RecLock("SC5", .F.)  // deadlock if Thread 2 holds SC5

// FIXED - always lock in consistent alphabetical order
// Thread 1 and Thread 2 both lock SA1 first, then SC5
RecLock("SA1", .F.)
RecLock("SC5", .F.)
// ... operations ...
MsUnlock()
DbSelectArea("SA1")
MsUnlock()
```

### 43. Exclusive lock required

**Error Message:** `Exclusive lock required for operation on 'SA1'`

**Cause:** Operations like PACK, ZAP, or index rebuild require exclusive table access, but shared locks exist.

**Solution:**
```advpl
// These operations need exclusive access:
// - DbPack()
// - DbZap()
// - Index rebuild

// Schedule during maintenance window when no users are connected
// Or use DBAccess admin tools for index rebuilding

// In code, check for exclusive access:
If FLock()  // try to lock entire file
    DbPack()
    DbUnlock()
Else
    Conout("Cannot obtain exclusive lock on table. Users may be connected.")
EndIf
```

### 44. Invalid field name

**Error Message:** `Field 'A1_XTEST' not found in alias 'SA1'`

**Cause:** Referencing a field that does not exist in the SX3 dictionary for this table, or a custom field that was not created.

**Solution:**
```advpl
// Check field exists in SX3 before accessing:
If FieldPos("A1_XTEST") > 0
    cVal := SA1->A1_XTEST
Else
    Conout("Field A1_XTEST not found in SA1 dictionary")
    cVal := ""
EndIf

// Verify field in SX3:
// DbSelectArea("SX3")
// DbSetOrder(1)  // X3_ARQUIVO + X3_CAMPO
// DbSeek("SA1" + "A1_XTEST")
```

### 45. Corrupted index

**Error Message:** `Index file corrupted` or inconsistent DbSeek results

**Cause:** AppServer crash during index update, disk failure, or concurrent uncontrolled writes.

**Solution:**
```advpl
// Rebuild index for the affected table:
// Option 1: Via APSDU - select table, rebuild indexes
// Option 2: Via code (requires exclusive access)
DbSelectArea("SA1")
If FLock()
    DbClearIndex()
    DbSetIndex(RetSqlName("SA1") + OrdBagExt())
    DbUnlock()
    Conout("Index rebuilt for SA1")
EndIf

// Prevention: ensure proper MsUnlock() after RecLock()
// and clean AppServer shutdown procedures
```

---

## Network/REST Errors

### 46. HTTP timeout

**Error Message:** `HTTP request timeout` or `Connection timed out`

**Cause:** The remote server is slow to respond or unreachable. Default timeouts may be too short for large payloads.

**Solution:**
```advpl
// Set appropriate timeout
Local oRest := FWRest():New("https://api.example.com")
oRest:SetTimeout(30) // 30 seconds

If oRest:Get("/endpoint")
    cResponse := oRest:GetResult()
Else
    Conout("HTTP Error: " + cValToChar(oRest:GetLastError()))
    Conout("Check network connectivity and server availability")
EndIf
```

### 47. Connection refused

**Error Message:** `Connection refused` or `ECONNREFUSED`

**Cause:** The target server is not listening on the specified port, firewall blocking, or wrong URL/port.

**Solution:**
```advpl
// Verify URL and port are correct
// Check firewall rules on both AppServer and target server
// Test connectivity: ping and telnet from the AppServer machine

Local oRest := FWRest():New("https://api.example.com")
If !oRest:Get("/health")
    Conout("Connection failed to api.example.com")
    Conout("Error: " + cValToChar(oRest:GetLastError()))
    Conout("Check: URL, port, firewall, DNS resolution")
EndIf
```

### 48. Invalid JSON response

**Error Message:** `JSON parse error` or unexpected response format

**Cause:** The server returned non-JSON content (HTML error page, empty response) or malformed JSON.

**Solution:**
```advpl
// Always validate response before parsing
Local oRest := FWRest():New("https://api.example.com")
If oRest:Get("/data")
    Local cResponse := oRest:GetResult()

    // Check if response looks like JSON
    If Left(Alltrim(cResponse), 1) $ "{["
        Local oJson := JsonObject():New()
        If oJson:FromJson(cResponse) == 0
            // Valid JSON - process
            cValue := oJson:GetJsonText("field")
        Else
            Conout("Invalid JSON: " + cResponse)
        EndIf
        FreeObj(oJson)
    Else
        Conout("Response is not JSON: " + Left(cResponse, 200))
    EndIf
EndIf
```

### 49. Authentication failed (401)

**Error Message:** `HTTP 401 Unauthorized` or `Authentication required`

**Cause:** Missing, expired, or invalid authentication token/credentials.

**Solution:**
```advpl
// Basic Auth
Local oRest := FWRest():New("https://api.example.com")
oRest:SetAuthorization("Basic " + Encode64(cUser + ":" + cPassword))

// Bearer Token
oRest:SetAuthorization("Bearer " + cToken)

// Check token expiration before making requests:
If dTokenExpiry < Date() .Or. cToken == ""
    cToken := RefreshAuthToken()
    If Empty(cToken)
        Conout("ERROR: Unable to obtain auth token")
        Return .F.
    EndIf
EndIf
```

### 50. SSL certificate error

**Error Message:** `SSL certificate problem` or `Unable to verify SSL certificate`

**Cause:** Self-signed certificate, expired certificate, or the CA certificate is not trusted by the AppServer.

**Solution:**
```advpl
// Option 1: Add CA certificate to AppServer trust store
// Copy .pem certificate to AppServer cert directory
// Configure in appserver.ini:
// [SSLConfigure]
// CertificateClient=cert\client.pem
// KeyClient=cert\client.key

// Option 2: Disable SSL verification (DEVELOPMENT ONLY - never in production)
Local oRest := FWRest():New("https://api.example.com")
oRest:SetSslVerify(.F.)  // DANGER: disables all SSL verification
```

---

## Quick Lookup Index

| # | Error | Category |
|---|-------|----------|
| 1 | Syntax error / Unexpected token | Compilation |
| 2 | Variable already declared | Compilation |
| 3 | Function not found | Compilation |
| 4 | Missing END/ENDDO/ENDIF | Compilation |
| 5 | Missing operator | Compilation |
| 6 | Type clash in expression | Compilation |
| 7 | #Include file not found | Compilation |
| 8 | Duplicate function name | Compilation |
| 9 | Too many parameters | Compilation |
| 10 | Missing RETURN | Compilation |
| 11 | Invalid character in source | Compilation |
| 12 | Ambiguous reference | Compilation |
| 13 | Missing TOTVS.CH | Compilation |
| 14 | Invalid preprocessor directive | Compilation |
| 15 | Class/Method not found (TLPP) | Compilation |
| 16 | Variable does not exist | Runtime |
| 17 | Array out of bounds | Runtime |
| 18 | Type mismatch | Runtime |
| 19 | Divide by zero | Runtime |
| 20 | NIL value in expression | Runtime |
| 21 | Invalid alias | Runtime |
| 22 | WorkArea not in use | Runtime |
| 23 | RecLock timeout | Runtime |
| 24 | Code block evaluation error | Runtime |
| 25 | Object method not found | Runtime |
| 26 | Stack overflow | Runtime |
| 27 | Memory allocation error | Runtime |
| 28 | String too long | Runtime |
| 29 | Date conversion error | Runtime |
| 30 | Numeric overflow | Runtime |
| 31 | Invalid function argument | Runtime |
| 32 | Thread error | Runtime |
| 33 | DLL load failure | Runtime |
| 34 | Connection refused (DB) | Runtime |
| 35 | Encoding/charset error | Runtime |
| 36 | Table/alias not found | Database |
| 37 | Index not found | Database |
| 38 | Record lock timeout | Database |
| 39 | Transaction error | Database |
| 40 | SQL syntax error | Database |
| 41 | Connection lost | Database |
| 42 | Deadlock detected | Database |
| 43 | Exclusive lock required | Database |
| 44 | Invalid field name | Database |
| 45 | Corrupted index | Database |
| 46 | HTTP timeout | Network/REST |
| 47 | Connection refused | Network/REST |
| 48 | Invalid JSON response | Network/REST |
| 49 | Authentication failed (401) | Network/REST |
| 50 | SSL certificate error | Network/REST |
