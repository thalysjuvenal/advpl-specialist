# ProBat Unit Test Patterns

Templates and patterns for writing ProBat tests in TLPP. All examples are based on the official TOTVS `tlpp-probat-samples` repository.

---

## Naming Convention

- Test files: `test_<target_name>.tlpp`
- Test classes: `Test<TargetName>` (e.g., `TestClienteService`)
- Test functions: `U_test<TargetName>` (e.g., `U_testCalculatePercent`)
- Test methods: descriptive name starting with `test` (e.g., `testInsert`, `testUpdate`, `testInvalidInput`)

---

## 1. Function Test (Basic)

The simplest ProBat test: a function with `@TestFixture` that calls the target and asserts the result.

```tlpp
#include "tlpp-probat.th"

namespace test.mymodule

@TestFixture(owner='myteam', target='my_source.tlpp')
function U_testMyFunction() as logical

  local cInput    := 'test_value'        as character
  local xValue    := mymodule.U_myFunction(cInput)
  local xExpected := 'expected_result'

  tlpp.probat.assertEquals(xValue, xExpected, 'myFunction should return expected result')

return .T.
```

**Key points:**
- `#include "tlpp-probat.th"` is mandatory
- The function must return `.T.`
- Use `target` property to link the test to its source file
- Assertions can use full qualified name `tlpp.probat.assertEquals` or `using namespace tlpp.probat`

---

## 2. Class Test (Simple)

Testing a class method with a class-based test fixture.

```tlpp
#include "tlpp-core.th"
#include "tlpp-probat.th"

namespace test.mymodule

using namespace tlpp.probat

@TestFixture(owner='myteam', target='cliente_service.tlpp')
class TestClienteService

  private data cCodigo as character

  public method new() constructor

  @Test('should validate client code format')
  public method testValidateCode()

  @Test('should return client name by code')
  public method testGetClientName()

endclass

method new() class TestClienteService
  ::cCodigo := '000001'
return self

method testValidateCode() class TestClienteService

  local lResult := mymodule.validateCode(::cCodigo)

  assertTrue(lResult, 'valid code should return true')

return .T.

method testGetClientName() class TestClienteService

  local cName := mymodule.getClientName(::cCodigo)

  assertNotEquals(cName, '', 'client name should not be empty')
  assertIsContained(cName, ' ', 'client name should contain space')

return .T.
```

---

## 3. Class Test with Setup/TearDown (Full Lifecycle)

Complete test with initialization, per-test setup, and cleanup.

```tlpp
#include "tlpp-core.th"
#include "tlpp-probat.th"

namespace test.mymodule

using namespace tlpp.probat

@TestFixture(owner='myteam')
class TestPedidoService

  private data nTotal   as numeric
  private data cPedido  as character
  private data lSetup   as logical

  public method new() constructor

  // Runs ONCE before all tests
  @OneTimeSetUp()
  public method initEnvironment()

  // Runs BEFORE EACH test
  @Setup()
  public method resetValues()

  // Tests
  @Test('should calculate order total correctly')
  public method testCalculateTotal()

  @Test('should apply discount when applicable')
  public method testApplyDiscount()

  // Runs AFTER EACH test
  @TearDown()
  public method clearValues()

  // Runs ONCE after all tests
  @OneTimeTearDown()
  public method cleanupEnvironment()

endclass

method new() class TestPedidoService
  ::nTotal  := 0
  ::cPedido := ''
  ::lSetup  := .F.
return self

method initEnvironment() class TestPedidoService
  // One-time initialization (e.g., open connection, prepare data)
  ::lSetup := .T.
  FWLogMsg('INFO', , 'PROBAT', , , , '-> [OneTimeSetUp] Environment initialized')
return .T.

method resetValues() class TestPedidoService
  // Reset state before each test
  ::nTotal  := 0
  ::cPedido := ''
  FWLogMsg('INFO', , 'PROBAT', , , , '-> [Setup] Values reset')
return .T.

method testCalculateTotal() class TestPedidoService
  ::nTotal := mymodule.calculateTotal(100, 3) // price * qty
  assertEquals(::nTotal, 300, 'total should be price * quantity')
return .T.

method testApplyDiscount() class TestPedidoService
  ::nTotal := mymodule.applyDiscount(1000, 10) // value, percent
  assertEquals(::nTotal, 900, 'should apply 10% discount')
  assertLess(::nTotal, 1000, 'discounted total should be less than original')
return .T.

method clearValues() class TestPedidoService
  ::nTotal  := 0
  ::cPedido := ''
  FWLogMsg('INFO', , 'PROBAT', , , , '-> [TearDown] Values cleared')
return .T.

method cleanupEnvironment() class TestPedidoService
  ::lSetup := .F.
  FWLogMsg('INFO', , 'PROBAT', , , , '-> [OneTimeTearDown] Environment cleaned up')
return .T.
```

---

## 4. REST Endpoint Test

Testing a REST API using `tlpp.rest.runTestSimple` from tlppCore.

```tlpp
#include "tlpp-core.th"
#include "tlpp-probat.th"

namespace test.api

using namespace tlpp.probat

@TestFixture(owner='myteam')
function U_testCustomerAPI() as logical

  local cEndPoint   := '/api/v1/customers'
  local cMethod     := 'GET'
  local cBodyOut    := ''
  local cHeadRet    := ''
  local cBodyRet    := ''
  local nStatusCode := 0
  local nServiceRet := -1

  // Execute the REST endpoint
  nServiceRet := tlpp.rest.runTestSimple( ;
    @cHeadRet,    ;
    @cBodyRet,    ;
    @nStatusCode, ;
    cEndPoint,    ;
    cMethod,      ;
    cBodyOut      ;
  )

  if (nServiceRet >= 0)

    // Validate HTTP status
    assertEquals(nStatusCode, 200, 'should return HTTP 200')

    // Validate response header
    assertIsRegexPartial(cHeadRet, "HTTP.([\w:\/.]+)([200 OK]+)", 'header should contain 200 OK')

    // Validate response body
    assertJson(cBodyRet, '{"success":true}', 'response should contain success flag')

  else
    assertError('could not execute the REST service')
  endif

return .T.
```

### REST POST Test

```tlpp
#include "tlpp-core.th"
#include "tlpp-probat.th"

namespace test.api

using namespace tlpp.probat

@TestFixture(owner='myteam')
function U_testCustomerPost() as logical

  local cEndPoint   := '/api/v1/customers'
  local cMethod     := 'POST'
  local cBodyOut    := '{"code":"000001","name":"Test Customer","store":"01"}'
  local cHeadRet    := ''
  local cBodyRet    := ''
  local nStatusCode := 0
  local nServiceRet := -1

  nServiceRet := tlpp.rest.runTestSimple( ;
    @cHeadRet,    ;
    @cBodyRet,    ;
    @nStatusCode, ;
    cEndPoint,    ;
    cMethod,      ;
    cBodyOut      ;
  )

  if (nServiceRet >= 0)
    assertEquals(nStatusCode, 201, 'should return HTTP 201 Created')
  else
    assertError('could not execute the REST service')
  endif

return .T.
```

---

## 5. Data Validation Patterns

### Testing Multiple Scenarios

```tlpp
#include "tlpp-core.th"
#include "tlpp-probat.th"

namespace test.mymodule

using namespace tlpp.probat

@TestFixture(owner='myteam')
function U_testInputValidation() as logical

  local xValue
  local xExpected
  local cError := '' as character

  // Valid input
  if (mymodule.U_validate(100, 10, @xValue, @cError))
    xExpected := 10
    assertEquals(xValue, xExpected, 'valid input should return correct result')
  else
    assertError('valid input should not fail: ' + cError)
  endif

  // Invalid input - string instead of number
  if (mymodule.U_validate('', 10, @xValue, @cError))
    assertError('invalid input should not return success')
  else
    xExpected := 'Invalid value!'
    assertEquals(cError, xExpected, 'should return correct error message')
  endif

  // Boundary value - zero
  if (mymodule.U_validate(0, 10, @xValue, @cError))
    xExpected := 0
    assertEquals(xValue, xExpected, 'zero input should return zero')
  else
    assertError('zero should be a valid input')
  endif

return .T.
```

### Testing with Arrays and JSON

```tlpp
#include "tlpp-core.th"
#include "tlpp-probat.th"

namespace test.mymodule

using namespace tlpp.probat

@TestFixture(owner='myteam')
function U_testDataStructures() as logical

  local aResult   := {1, 2, 3, 'four', Nil, 6}
  local aExpected := {1, 2, 3, 'four', Nil, 6}
  local oJson1, oJson2

  // Array comparison
  assertVector(aResult, aExpected, 'arrays should be equal')

  // JSON object comparison
  oJson1 := JsonObject():New()
  oJson1:fromJson('{"key":"value","num":42}')

  oJson2 := JsonObject():New()
  oJson2:fromJson('{"key":"value","num":42}')

  assertJson(oJson1, oJson2, 'JSON objects should be equal')

  // JSON object vs string
  assertJson(oJson1, '{"key":"value","num":42}', 'JSON should match string representation')

  // Nil check
  assertNil(, 'nil value should be nil')

return .T.
```

---

## 6. Skip Patterns

### Skip Entire Test

```tlpp
@TestFixture(owner='myteam')
@Skip()
function U_testNotReady() as logical
  assertError('this should never execute')
return .T.
```

### Skip by Environment

```tlpp
// Skip on Windows
@TestFixture(owner='myteam')
@Skip(system="windows")
function U_testLinuxOnly() as logical
  // ...
return .T.

// Skip on specific AppServer
@TestFixture(owner='myteam')
@Skip(appServerName="HARPIA")
function U_testNotOnHarpia() as logical
  // ...
return .T.

// Skip based on TLPP version
@TestFixture(owner='myteam')
@Skip(tlppVersion=">= 01.02.10")
function U_testOlderVersionOnly() as logical
  // ...
return .T.
```

### Skip Individual Assertions (SKIPASSERT)

```tlpp
@TestFixture(owner='myteam')
function U_testWithConditionalSkip() as logical

  // Skip next assertion unconditionally
  SKIPASSERT
  assertError('this assert is skipped')

  // Skip next assertion on Windows
  SKIPASSERT SYSTEM "windows"
  assertError('skipped on windows')

  // This assertion always runs
  assertOK('this always runs')

return .T.
```

---

## 7. Suite Organization

Group tests into suites for selective execution:

```tlpp
@TestFixture(owner='myteam', suite='financeiro')
function U_testContasReceber() as logical
  // ...
return .T.

@TestFixture(owner='myteam', suite='financeiro')
function U_testContasPagar() as logical
  // ...
return .T.
```

---

## 8. Expected Error Test

When testing code that should produce an error:

```tlpp
@TestFixture(owner='myteam', target='risky_operation.tlpp')
@ErrorLog('type mismatch')
function U_testExpectedError() as logical
  mymodule.U_riskyOperation()
return .T.
```

Class-based:

```tlpp
@TestFixture(owner='myteam')
class TestErrorHandling

  public method new() constructor

  @Test('should handle type mismatch gracefully')
  @ErrorLog('type mismatch')
  public method testTypeMismatch()

endclass

method new() class TestErrorHandling
return self

method testTypeMismatch() class TestErrorHandling
  mymodule.U_riskyOperation()
return .T.
```

---

## 9. Integration Test with Database

Pattern for tests that require database access.

```tlpp
#include "tlpp-core.th"
#include "tlpp-probat.th"

namespace test.integration

using namespace tlpp.probat

@TestFixture(suite='database')
class TestDatabaseOperations

  private data nConn   as numeric
  private data lConn   as logical
  private data cTable  as character
  private data cAlias  as character
  private data oTmp    as object

  public method new() constructor

  @OneTimeSetUp()
  public method openConnection()

  @Setup()
  public method prepareTable()

  @Test('should insert record into table')
  public method testInsert()

  @Test('should update existing record')
  public method testUpdate()

  @TearDown()
  public method clearData()

  @OneTimeTearDown()
  public method closeConnection()

endclass

method new() class TestDatabaseOperations
  ::nConn  := -1
  ::lConn  := .F.
  ::cTable := 'TEST_TBL'
  ::cAlias := 'TST'
  ::oTmp   := nil
return self

method openConnection() class TestDatabaseOperations
  local cEnv := GetEnvServer()
  local cIni := GetSrvIniName()
  local cDB  := GetPvProfString(cEnv, 'DBDATABASE', '', cIni)
  local cDsn := GetPvProfString(cEnv, 'DBALIAS', '', cIni)
  local cSrv := GetPvProfString(cEnv, 'DBSERVER', '', cIni)
  local nPort := Val(GetPvProfString(cEnv, 'DBPORT', '', cIni))

  ::nConn := TcLink(cDB + '/' + cDsn, cSrv, nPort)
  ::lConn := (::nConn >= 0)

  assertTrue(::lConn, 'database connection should succeed')
return .T.

method prepareTable() class TestDatabaseOperations
  // Create the test table as a temporary table (FWTemporaryTable, relational mode)
  local aFields := {{'ID', 'C', 5, 0}, {'DESCR', 'C', 50, 0}}

  ::oTmp := FWTemporaryTable():New(::cAlias, aFields)
  ::oTmp:Create()

  assertTrue(Select(::cAlias) > 0, 'temporary table should be open')
return .T.

method testInsert() class TestDatabaseOperations
  dbSelectArea(::cAlias)
  dbAppend(.T.)
    (::cAlias)->ID    := '00001'
    (::cAlias)->DESCR := 'Test Record'
  dbCommit()
  dbRUnLock(RecNo())

  assertEquals((::cAlias)->ID, '00001', 'inserted ID should match')
return .T.

method testUpdate() class TestDatabaseOperations
  dbSelectArea(::cAlias)
  dbRLock(RecNo())
    (::cAlias)->DESCR := 'Updated Record'
  dbCommit()
  dbRUnLock(RecNo())

  assertEquals((::cAlias)->DESCR, 'Updated Record', 'updated description should match')
return .T.

method clearData() class TestDatabaseOperations
  TCCommit(1)
  dbSelectArea(::cAlias)
  TcSqlExec('DELETE FROM ' + ::oTmp:GetRealName())
  TCCommit(2)
  TCCommit(4)
return .T.

method closeConnection() class TestDatabaseOperations
  if (::oTmp != nil)
    ::oTmp:Delete()
    ::oTmp := nil
  endif
  if (::lConn)
    TCUNLink(::nConn)
  endif
return .T.
```

---

## Recommended Project Structure

```
project/
  src/
    mymodule/
      cliente_service.tlpp
      pedido_service.tlpp
  test/
    unit/
      mymodule/
        test_cliente_service.tlpp
        test_pedido_service.tlpp
    api/
      test_customer_api.tlpp
    integration/
      test_database.tlpp
```
