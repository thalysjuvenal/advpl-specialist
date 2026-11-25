---
name: probat-testing
description: Write or run unit, functional and integration tests for TLPP with ProBat - @TestFixture, @Test, assertions, TDD/CI. "testes unitarios", "criar teste ProBat", "testar rotina TLPP", "cobertura de testes".
---

# ProBat Testing (TLPP)

This skill covers ProBat, the native unit/functional/integration testing engine of tlppCore, used exclusively with TLPP (`.tlpp`) source files -- even when the code under test is legacy `.prw`. It covers the required `#include "tlpp-probat.th"`, the `test.<module>` namespace convention, the full annotation set (`@TestFixture`, `@Test`, `@Setup`, `@TearDown`, `@OneTimeSetUp`, `@OneTimeTearDown`, `@Skip`, `@ErrorLog`), the `tlpp.probat` assertion functions, the class-based execution lifecycle, and `SKIPASSERT` for conditional assertion skipping.

Activate this skill when the user wants to create a new ProBat test fixture, add test methods to cover a routine, set up setup/teardown logic, or understand how ProBat discovers and executes tests (via REST API or the VSCode extension). Concrete test-writing templates live in the sibling patterns file.

It does not cover generating the production TLPP code being tested (see `advpl-code-generation`), reviewing code quality outside of tests (see `advpl-code-review`), or writing embedded SQL used inside test fixtures (see `embedded-sql`).

| Reference file | Read when |
|---|---|
| reference.md | Always -- includes, namespace convention, annotations, assertion function reference, execution lifecycle, and how tests are run |
| patterns-unit-tests.md | Writing a concrete ProBat test fixture and need ready-to-adapt templates/patterns |
