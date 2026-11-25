---
description: Explain ADVPL/TLPP code in plain language for developers and functional consultants
allowed-tools: Read, Glob, Grep, Bash, Agent
argument-hint: "<file|code> [--level junior|senior|funcional]"
---

**IMPORTANT:** Always respond in the same language the user is writing in. If the user writes in Portuguese, respond in Portuguese. If in English, respond in English.

# /advpl-specialist:explain

Explain ADVPL/TLPP code in plain language, adapted to the audience level.

## Usage

```bash
/advpl-specialist:explain <target> [--level level]
```

## Levels

| Level | Audience | Output |
|-------|----------|--------|
| `junior` | Dev iniciante | Explicacao detalhada, linha por linha, sem assumir conhecimento previo |
| `senior` | Dev experiente | Resumo focado na logica de negocio e decisoes de design |
| `funcional` | Consultor funcional | Explicacao sem termos tecnicos, foco no impacto no negocio |

If `--level` is not provided, default to `junior`.

## Process

1. **Parse arguments** — Identify target file/snippet and level
2. **Load explanation reference** — Read `${CLAUDE_PLUGIN_ROOT}/skills/code-explanation/reference.md`
3. **Read target code** — Read the file or interpret the snippet
4. **Load supporting references** — Read `${CLAUDE_PLUGIN_ROOT}/skills/protheus-reference/reference.md`, `${CLAUDE_PLUGIN_ROOT}/skills/protheus-business/reference.md`, `${CLAUDE_PLUGIN_ROOT}/skills/embedded-sql/reference.md` as needed
5. **Analyze code** — Identify structure, functions, variables, DB operations, business rules
6. **Generate explanation** — Follow the level-appropriate structure from the reference
7. **Present result** — Clear, structured explanation in the user's language

## Examples

```bash
# Explain code for a junior developer (default)
/advpl-specialist:explain src/MATA461.prw

# Explain for a functional consultant
/advpl-specialist:explain src/CustomFaturamento.prw --level funcional

# Explain for a senior developer
/advpl-specialist:explain src/JobProcessaNF.tlpp --level senior

# Explain a specific function
/advpl-specialist:explain src/Utils.prw::fCalcDesconto
```

## Output

Structured explanation adapted to the audience:
- **Junior:** Objective, includes, variables, step-by-step flow, native functions used, tables, warnings
- **Senior:** Objective, business logic, tables, dependencies, risks
- **Funcional:** What it does, when it runs, what data it reads/changes, business rules, module impact
