---
name: changelog-patterns
description: Generate a changelog or release notes from ADVPL/TLPP code changes, classifying each change and its business impact. "gerar changelog", "notas de versao", "documentar entrega", "o que mudou".
---

# Changelog Patterns

This skill defines how to analyze ADVPL/TLPP code changes (via git diff or a supplied file list) and produce a structured changelog: change type classification (NEW/FIX/CHANGE/REMOVE/REFACTOR with Portuguese labels), impact level assessment (ALTO/MEDIO/BAIXO), detection of affected database tables from `DBSelectArea`/`RecLock`/`BeginSQL` patterns, and output in either Markdown or plain-text format.

Activate this skill when the user wants a client-facing or internal changelog, release notes, or delivery documentation generated from a set of code changes. It does not cover generating documentation headers or technical routine specs from a single source file with no diff context -- that is closer to a documentation-generation task and out of scope for this skill's diff-analysis process; it also does not cover code review findings (see `advpl-code-review`) or the migration checklist for `.prw` to `.tlpp` conversions (see `advpl-to-tlpp-migration`).

| Reference file | Read when |
|---|---|
| reference.md | Always -- the only file in this skill; contains change types, impact levels, Markdown/TXT changelog formats, and the full analysis process |
