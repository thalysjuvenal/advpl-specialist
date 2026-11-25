---
description: Migrate ADVPL procedural code to TLPP object-oriented code with classes, namespaces, and modern patterns
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, WebSearch, WebFetch
argument-hint: "<file.prw> [--output file.tlpp] [--dry-run]"
---

# /advpl-specialist:migrate

**IMPORTANT:** Always respond in the same language the user is writing in. If the user writes in Portuguese, respond in Portuguese. If in English, respond in English. Adapt all explanations and suggestions to the user's language. Code comments may remain in English or match the user's language.

Convert ADVPL procedural code to TLPP with object-oriented patterns.

## Usage

```bash
/advpl-specialist:migrate <file.prw> [options]
```

## Options

| Flag | Description | Default |
|------|------------|---------|
| `--output` | Output .tlpp file path | Same name with .tlpp extension |
| `--dry-run` | Show migration plan without generating files | false |
| `--keep-original` | Keep the original .prw file | true |
| `--wrapper` | Generate backward compatibility wrapper | true |
| `--namespace` | Override namespace | Auto-detect from module |

## Process

**MANDATORY: Always enter planning mode before migrating code. Never skip planning.**

### Analysis Phase
1. **Check the declared release** - If a `.protheus-version` file exists in the project root, read it (one release string, e.g. `12.1.2310`). Look up the minimum release of the target TLPP features in `${CLAUDE_PLUGIN_ROOT}/skills/protheus-reference/releases.md` (target `.tlpp`: rows "TLPP com MVC" and "TLPP com `namespace`", both 12.1.2410) and compare the third component as an integer. If the declared release is below the minimum (e.g. TLPP with `namespace` or TLPP+MVC needs `12.1.2410`), warn the user and propose the alternative (e.g. keep the code in `.prw` ADVPL and apply only the safe cleanups). Continue only with the user's choice. If the content, after trimming whitespace, is not `12.1.N` with N all digits (empty, multi-line, `12.1`, non-numeric), ignore the file, tell the user, and proceed as if it were absent. If the file does not exist, proceed as usual and add one line suggesting the user create `.protheus-version` with the Protheus release.
2. **Read source file** - Read the .prw file completely
3. **Analyze structure** - Identify functions, dependencies, shared variables
4. **Search for callers** - Grep codebase for `u_FunctionName` references

### Planning Phase (REQUIRED)
5. **Load reference** - Read `${CLAUDE_PLUGIN_ROOT}/skills/advpl-to-tlpp-migration/reference.md` for rules and checklist
6. **Enter plan mode** - Use `EnterPlanMode` to create a structured migration plan
7. **Design class structure** - Map functions to classes and methods
8. **Present plan** - Show the user a detailed migration plan including:
   - Source file analysis (functions found, dependencies, shared variables)
   - External callers that will be impacted
   - Target class structure (class name, namespace, properties, methods)
   - Mapping: which function becomes which method (public/private)
   - Private/Public variables to convert to class properties
   - Includes to update (TOTVS.CH -> tlpp-core.th, etc.)
   - Whether a backward compatibility wrapper is needed
   - Any risks or breaking changes
9. **Wait for approval** - The user must approve the plan before any code is written. If the user requests changes, revise the plan.
10. **If --dry-run** - Stop here after showing the plan
11. **Exit plan mode** - Use `ExitPlanMode` after approval

### Implementation Phase (only after approval)
12. **Execute migration** - Generate .tlpp file(s) following the approved plan and `${CLAUDE_PLUGIN_ROOT}/skills/advpl-to-tlpp-migration/reference.md`
13. **Generate wrapper** - Create backward compatibility .prw wrapper if --wrapper
14. **Run checklist** - Validate against migration-checklist.md
15. **Report** - Show summary of changes

## Examples

```bash
# Migrate a file (shows plan first, then generates)
/advpl-specialist:migrate src/FATA001.prw

# Preview migration without generating files
/advpl-specialist:migrate src/FATA001.prw --dry-run

# Specify output path and namespace
/advpl-specialist:migrate src/FATA001.prw --output src/tlpp/PedidoService.tlpp --namespace mycompany.faturamento

# Migrate without backward compatibility wrapper
/advpl-specialist:migrate src/FATA001.prw --wrapper false
```

## Output

- `.tlpp` file with migrated class-based code
- Optional `.prw` wrapper for backward compatibility
- Migration summary with what changed and why
