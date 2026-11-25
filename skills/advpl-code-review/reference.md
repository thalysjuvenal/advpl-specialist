# ADVPL/TLPP Code Review

## Overview

Systematic code review methodology for ADVPL/TLPP on TOTVS Protheus. This skill provides structured rules to identify issues related to best practices, performance bottlenecks, security vulnerabilities, and modernization opportunities in existing codebases.

## When to Use

- Reviewing ADVPL/TLPP source code before merge or deploy
- Auditing existing code for quality and compliance
- Identifying performance bottlenecks in slow routines
- Checking for security vulnerabilities (SQL injection, credential exposure)
- Evaluating code for migration readiness from .prw to .tlpp
- Onboarding reviews to enforce team coding standards

## Review Categories

| Category | File | Focus | Severity Range |
|----------|------|-------|----------------|
| Best Practices | `rules-best-practices.md` | RecLock/MsUnlock pairing, variable scope, area management, error handling, documentation | CRITICAL - INFO |
| Performance | `rules-performance.md` | Embedded SQL optimization, loop efficiency, string operations, index usage | CRITICAL - INFO |
| Security | `rules-security.md` | SQL injection, input validation, credential exposure, sensitive data logging | CRITICAL - WARNING |
| Modernization | `rules-modernization.md` | TLPP migration, namespace usage, OOP patterns, modern UI frameworks | INFO |

## Output Format

Each finding must include:

```
[RULE-ID] SEVERITY: Brief description
  File: filename.prw (line XX)
  Issue: What was found
  Fix: How to correct it
```

### Severity Levels

| Level | Meaning | Action Required |
|-------|---------|-----------------|
| **CRITICAL** | Data corruption, security breach, or system failure risk | Must fix before deploy |
| **WARNING** | Performance degradation, maintenance burden, or potential bugs | Should fix in current sprint |
| **INFO** | Improvement opportunity, style suggestion, or modernization hint | Fix when touching the code |

## Review Process

1. **Scan includes and headers** - Check for obsolete includes (`protheus.ch` is obsolete; use `#include "totvs.ch"`, directive and file name in lowercase), missing documentation headers
2. **Analyze variable declarations** - Verify scope (`Local` preferred), naming conventions (Hungarian notation)
3. **Check database operations** - Validate `RecLock`/`MsUnlock` pairing, `GetArea`/`RestArea` usage, error handling around DB ops
4. **Evaluate queries** - Review Embedded SQL for `SELECT *`, proper macro usage (`%exp:`, `%table:`, `%notDel%`), index alignment
5. **Inspect security surface** - Look for SQL injection vectors (`%exp:` inserts the value into the SQL text and is not a bind; external input goes through `FWPreparedStatement`), hardcoded credentials, sensitive data in logs, unvalidated REST input
6. **Assess modernization** - Identify candidates for TLPP migration, OOP refactoring, modern UI patterns

## Rule ID Format

| Prefix | Category | Example |
|--------|----------|---------|
| `BP` | Best Practices | `[BP-001]` RecLock without MsUnlock, `[BP-009]` Bare `Function` keyword in customer code, `[BP-010]` Identifier name exceeds the effective length limit |
| `PERF` | Performance | `[PERF-001]` SELECT * in Embedded SQL |
| `SEC` | Security | `[SEC-001]` SQL injection, `[SEC-005]` Restricted TOTVS functions |
| `MOD` | Modernization | `[MOD-001]` .prw class candidate for .tlpp |

## References

- `rules-best-practices.md` - Best practice rules with detection patterns and code examples
- `rules-performance.md` - Performance rules with detection patterns and code examples
- `rules-security.md` - Security rules with detection patterns and code examples
- `rules-modernization.md` - Modernization rules with detection patterns and code examples
- `sonarqube-rules-catalog.md` - Official TOTVS SonarQube ruleset for AdvPL/TLPP (groups G1-G5, all `CA`/`BG`/`CS` codes with severity, prohibited API, and required alternative). Tag findings with the canonical SonarQube code and map them to the internal `BP`/`PERF`/`SEC`/`MOD` IDs. Read it to align reviews with the official quality gate (`sonar-rules.engpro.totvs.com.br`).
