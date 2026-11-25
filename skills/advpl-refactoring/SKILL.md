---
name: advpl-refactoring
description: Refactor or clean up ADVPL/TLPP without changing behavior - extract functions, simplify conditionals, remove dead code. "refatorar rotina", "extrair funcao", "remover codigo morto", "God function".
---

# ADVPL/TLPP Refactoring

This skill defines safe refactoring patterns (RF-001 through RF-006) for improving ADVPL/TLPP code structure without altering behavior: extract function, simplify conditionals with guard clauses, remove dead code, improve naming to Hungarian notation, eliminate duplication, and reduce function parameter count. It also defines the mandatory process -- analyze, prioritize, present a before/after plan, wait for user approval, apply one change at a time, verify -- and hard safety rules (never change business logic, never rename externally-used symbols without a caller check).

Activate this skill when the user wants existing, working code restructured for readability or maintainability: long functions, deep nesting, unclear names, copy-pasted blocks, or functions with excessive parameters. It does not cover fixing bugs or errors (see `advpl-debugging`), generating brand-new functionality (see `advpl-code-generation`), a formal quality/security audit (see `advpl-code-review`), or converting procedural `.prw` to object-oriented `.tlpp` (see `advpl-to-tlpp-migration`, which is a structural paradigm change rather than a behavior-preserving cleanup).

| Reference file | Read when |
|---|---|
| reference.md | Always -- the only file in this skill; contains all refactoring patterns (RF-001 to RF-006), the refactoring process, and safety rules |
