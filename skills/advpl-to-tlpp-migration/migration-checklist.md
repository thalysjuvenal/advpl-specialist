# ADVPL to TLPP Migration Checklist

Use this checklist for every migration from procedural ADVPL (`.prw`) to object-oriented TLPP (`.tlpp`). Complete each section in order.

---

## 1. Pre-Migration Analysis

Perform this analysis before writing any TLPP code.

- [ ] Identify all `User Function` definitions in the source `.prw` file
- [ ] Identify all `Static Function` definitions in the source `.prw` file
- [ ] Map function call dependencies (which functions call which)
- [ ] Identify `Private` variables shared across multiple functions
- [ ] Identify `Public` variables and all locations where they are read/written
- [ ] Identify `Static` file-level variables and their usage patterns
- [ ] List all external callers of each `User Function` (other `.prw` files, menus, jobs, schedules)
- [ ] Identify all database aliases used (`DbSelectArea`, `RecLock`, direct alias references)
- [ ] Document all `#Include` directives (they will be replaced by TLPP `.th` includes: `tlpp-core.th`, `tlpp-rest.th`, etc.)
- [ ] Identify any code blocks (`{|| ...}`) that reference `Private`/`Static` variables
- [ ] Check for `MV_*` parameter usage (`GetMV`, `SuperGetMV`) that may need class-level access
- [ ] Note any UI elements (dialogs, buttons, gets) that will need a separate View class

---

## 2. Migration Execution

Create the TLPP class structure and convert all functions.

### Namespace and File Setup

- [ ] Define the namespace following TOTVS convention: `custom.<agrupador>.<servico>` for customizations or `totvs.protheus.<segmento>.<agrupador>` for product code (all lowercase, dots, no underscores)
- [ ] Create the `.tlpp` file with one class per file, named following convention: `custom.<agrupador>.<funcionalidade>.tlpp`
- [ ] Add `#Include "tlpp-core.th"` at the top of the file (and `tlpp-rest.th` if using REST annotations)

### Class Skeleton

- [ ] Define the class name using PascalCase with a purpose suffix (e.g., `PedidoService`, `ClienteRepository`)
- [ ] Declare all `data` properties (converted from `Private`/`Static` variables) with `as <type>`
- [ ] Declare all `public method` signatures (from `User Function` conversions)
- [ ] Declare all `private method` signatures (from `Static Function` conversions)
- [ ] Add `endclass` at the end of the class definition

### Constructor

- [ ] Create `method new()` that initializes all class properties
- [ ] Move any values that were `Public` variables into constructor parameters
- [ ] Set default values for properties that had default `Private` variable values
- [ ] Return `self` from the constructor

### Convert Functions to Methods

- [ ] Convert each `User Function` to a `public method` with proper parameter typing (`as character`, `as numeric`, etc.)
- [ ] Convert each `Static Function` to a `private method`
- [ ] Replace all references to `Private` variables with `::propertyName`
- [ ] Replace all calls to `Static Function Helper()` with `::helper()`
- [ ] Ensure every method that accesses the database calls `GetArea()` at the start and `RestArea()` before returning
- [ ] Replace `Conout()` logging with `FWLogMsg()` where appropriate
- [ ] Verify that `xFilial(cAlias)` is used in all `DbSeek` operations

### Update Includes (in the `.tlpp` file)

- [ ] Replace ADVPL `.ch` includes with TLPP `.th` includes: `#Include "tlpp-core.th"` (main), `#Include "tlpp-rest.th"` (REST annotations), `#Include "tlpp-object.th"` (advanced objects)
- [ ] Add the `namespace` declaration for the project (e.g., `namespace custom.faturamento.pedido`)
- [ ] Do NOT add `using namespace tlpp.core`, `tlpp.log`, `tlpp.rest`, `tlpp.data`, etc. -- these are NOT needed; use the `.th` includes instead

### Backward Compatibility Wrapper (`.prw` file — uses `#Include "TOTVS.CH"`)

- [ ] Create or update the `.prw` wrapper file that preserves the original `User Function` name
- [ ] The wrapper must instantiate the TLPP class and delegate to the appropriate method
- [ ] Verify the wrapper passes all original parameters correctly
- [ ] Verify the wrapper returns the same type as the original function

---

## 3. Post-Migration Validation

Verify that the migration is complete and correct.

### Compilation

- [ ] The `.tlpp` file compiles without errors
- [ ] The `.prw` wrapper file compiles without errors
- [ ] No warnings related to undefined variables or methods

### Functional Validation

- [ ] All external callers (other functions, menus, jobs) work correctly through the wrapper
- [ ] Database operations produce the same results as the original code
- [ ] Record locking and unlocking (`RecLock` / `MsUnlock`) work correctly
- [ ] Error handling (`Begin Sequence` / `Recover`) catches and reports errors correctly
- [ ] Return values match the original function's return type and behavior

### Code Quality

- [ ] No `Private` or `Public` variable declarations remain in the `.tlpp` file
- [ ] No leaked variables -- all variables are either `Local`, `data`, or `static data`
- [ ] Class properties use correct Hungarian notation prefixes (`cName`, `nValue`, `lFlag`, `aList`, `oObj`)
- [ ] Method names follow camelCase convention
- [ ] Class name follows PascalCase convention
- [ ] Namespace follows TOTVS convention (`custom.<agrupador>.<servico>` or `totvs.protheus.<segmento>.<agrupador>`)
- [ ] One class per `.tlpp` file
- [ ] All `GetArea()` calls have matching `RestArea()` calls (no area leaks)
- [ ] Code blocks that reference class state use `self` explicitly when evaluated externally

### Documentation

- [ ] Class-level `Protheus.doc` comment block is present with `@type class`
- [ ] Each public method has a `Protheus.doc` comment block with `@param` and `@return`
- [ ] The wrapper `.prw` file documents that it delegates to the TLPP class

---

## Quick Reference: File Checklist per Migration

For each `.prw` file migrated, you should end up with:

| File | Purpose | Status |
|------|---------|--------|
| `ClassName.tlpp` | New TLPP class with all logic | - [ ] Created |
| `OriginalName.prw` | Wrapper preserving `User Function` signature | - [ ] Updated |
| Original `.prw` | Archived or removed after full rollout | - [ ] Handled |
