---
name: advpl-code-review
description: Review or audit ADVPL/TLPP code for best practices, performance, security and SonarQube rules (CA/BG/CS). "revisar codigo", "auditar rotina", "checar boas praticas", "code review advpl".
---

# ADVPL/TLPP Code Review

This skill provides a systematic code review methodology for existing ADVPL/TLPP code, producing findings tagged with a rule ID (`BP-*`, `PERF-*`, `SEC-*`, `MOD-*`), a severity (CRITICAL/WARNING/INFO), the file/line, the issue, and the fix. It covers four review categories: best practices, performance, security, and modernization, and can map findings to the official TOTVS SonarQube quality gate.

Activate this skill when the user wants existing code inspected for quality, compliance, security, or performance issues -- e.g. before a merge, before a deploy, during an onboarding audit, or when assessing migration readiness from `.prw` to `.tlpp`. It does not cover generating new code (see `advpl-code-generation`), diagnosing a specific runtime/compilation error (see `advpl-debugging`), restructuring code without adding features (see `advpl-refactoring`), or performing the actual `.prw` to `.tlpp` conversion (see `advpl-to-tlpp-migration`).

| Reference file | Read when |
|---|---|
| reference.md | Always -- review categories, output format, severity levels, review process, rule ID prefixes |
| rules-best-practices.md | Checking RecLock/MsUnlock pairing, variable scope, area management, error handling, documentation (BP-* rules) |
| rules-performance.md | Checking Embedded SQL efficiency, loop efficiency, string operations, index usage (PERF-* rules) |
| rules-security.md | Checking SQL injection, input validation, credential exposure, sensitive data logging (SEC-* rules) |
| rules-modernization.md | Checking TLPP migration candidates, namespace usage, OOP patterns, modern UI frameworks (MOD-* rules) |
| sonarqube-rules-catalog.md | Aligning findings with the official TOTVS SonarQube ruleset (groups G1-G5, CA/BG/CS codes) |
