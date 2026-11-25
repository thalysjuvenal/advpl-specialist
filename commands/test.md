---
description: Generate ProBat unit tests for TLPP classes and functions
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, WebSearch, WebFetch
argument-hint: "<file.tlpp|function> [--type unit|api] [--output path]"
---

# /advpl-specialist:test

**IMPORTANT:** Always respond in the same language the user is writing in. If the user writes in Portuguese, respond in Portuguese. If in English, respond in English. Adapt all explanations and suggestions to the user's language. Code comments may remain in English or match the user's language.

Generate ProBat unit tests for TLPP classes and functions on TOTVS Protheus.

## Usage

```bash
/advpl-specialist:test <target> [options]
```

Where `<target>` is a `.tlpp` file path or a function/class name.

## Types

| Type | Description | Output |
|------|------------|--------|
| `unit` | Unit test for functions or class methods | `.tlpp` file with `@TestFixture` and assertions |
| `api` | REST API endpoint test | `.tlpp` file using `tlpp.rest.runTestSimple` |

## Options

| Flag | Description | Default |
|------|------------|---------|
| `--type` | Test type: `unit` or `api` | `unit` |
| `--output` | Output file path | `test/unit/test_<name>.tlpp` |
| `--suite` | Suite name for grouped execution | None |
| `--owner` | Team/author identifier for `@TestFixture` | Ask user |

## Important: ProBat is TLPP Only

ProBat only works with TLPP (`.tlpp` files). If a `.prw` file is passed:

1. Inform the user that ProBat requires TLPP
2. Suggest using `/advpl-specialist:migrate` first to convert the source to TLPP
3. The test file itself is always `.tlpp`, even when testing ADVPL functions

## Process

1. **Parse arguments** - Extract target file/function, type, and flags
2. **Read target source** - Analyze the file or function to understand what to test
3. **Load reference** - Read `${CLAUDE_PLUGIN_ROOT}/skills/probat-testing/reference.md`
4. **Load patterns** - Read `${CLAUDE_PLUGIN_ROOT}/skills/probat-testing/patterns-unit-tests.md` for the appropriate template
5. **Identify test cases** - Determine:
   - Functions/methods to test
   - Input parameters and expected outputs
   - Edge cases (NIL values, empty strings, invalid types, boundary values)
   - Error scenarios
6. **Present plan** - Show the user:
   - Test file name and path
   - Test class/function name
   - List of test methods with descriptions
   - Assertions to be used
   - Setup/TearDown needs (if any)
7. **Wait for approval** - The user must approve before generating code
8. **Generate test code** - Create the `.tlpp` test file following ProBat conventions:
   - `#include "tlpp-probat.th"` (and `"tlpp-core.th"` if needed)
   - Proper namespace (`test.<module>` or `custom.tests.<module>`)
   - `@TestFixture` with `owner` and `target` properties
   - `@Test` with descriptive mandatory descriptions
   - Typed variable declarations
   - Appropriate assertions from the ProBat assertion library
9. **Write file** - Save with `.tlpp` extension
10. **Report** - Show what was created and how to run the tests

## Examples

```bash
# Generate unit tests for a TLPP file
/advpl-specialist:test src/calculadora.tlpp

# Generate API tests for a REST endpoint
/advpl-specialist:test src/customer_api.tlpp --type api

# Generate tests with a specific output path
/advpl-specialist:test src/pedido_service.tlpp --output test/unit/test_pedido.tlpp

# Generate tests for a specific function
/advpl-specialist:test U_calculateTotal --type unit

# Generate tests grouped in a suite
/advpl-specialist:test src/financeiro/ --suite financeiro
```

## Output

A complete, compilable `.tlpp` test file saved to the project with:

- `#include "tlpp-probat.th"` header
- Proper namespace declaration
- `@TestFixture` with owner and target metadata
- Test methods with `@Test` annotations and descriptive names
- Typed local variables
- Appropriate assertions (`assertEquals`, `assertTrue`, etc.)
- Setup/TearDown methods when needed (`@OneTimeSetUp`, `@Setup`, `@TearDown`, `@OneTimeTearDown`)
- Return `.T.` from all test functions/methods
