# 05 — Revisar código focando em performance

## Contexto

Uma rotina batch de reprocessamento está levando 45 minutos para rodar com 10k registros. O desenvolvedor original saiu da empresa. Você precisa identificar gargalos sem reescrever tudo — prioridade é achar os 2-3 pontos mais caros.

O arquivo [`exemplo-lento.prw`](exemplo-lento.prw) simula problemas típicos: `DbSeek` dentro de loop, consulta sem `TCSetField` e concatenação de string em loop.

## Prompt exato

```
/advpl-specialist:review examples/05-review-com-focus-performance/exemplo-lento.prw --focus performance
```

## O que o plugin faz

1. **Lê o arquivo** e aplica as regras da skill `advpl-code-review` (`rules-performance.md`, prefixo `PERF`):
   - `PERF-001` — `SELECT *` em Embedded SQL
   - `PERF-002` — `DbSeek` dentro de loop quando uma única query resolveria
   - `PERF-003` — falta de `TCSetField` para tipar colunas após a query
   - `PERF-004` — concatenação de string dentro de loop
   - `PERF-005` — `RecCount()` para verificar existência de registros
   - `PERF-006` — query sem índice adequado ou sem `ORDER BY` compatível
2. **Classifica cada finding** por severidade (`CRITICAL`, `WARNING`, `INFO`), como definido em cada regra
3. **Apresenta relatório** agrupado por severidade, com:
   - Trecho atual e sugestão de correção para cada finding
   - Uma explicação curta do motivo
4. **Resumo** com a contagem de findings por severidade, para priorizar a correção

Neste exemplo, `exemplo-lento.prw` dispara `PERF-002`, `PERF-003` e `PERF-004`. As regras `PERF-001`, `PERF-005` e `PERF-006` não se aplicam a ele.

## Output esperado

Relatório estruturado no formato do agente `code-reviewer` (a redação exata e os números de linha podem variar):

```text
## Review: exemplo-lento.prw

### CRITICAL (0)

### WARNING (3)
1. **[PERF-002]** exemplo-lento.prw:45 - DbSeek dentro de loop
   DbSeek na SB1 a cada iteracao do While; N buscas individuais.
   Sugestao: trazer o dado da SB1 na query principal (JOIN) ou fazer uma unica consulta.
2. **[PERF-003]** exemplo-lento.prw:38 - Falta de TCSetField
   B2_QATU lido da query sem tipagem de coluna numerica.
   Sugestao: chamar TCSetField na coluna numerica logo apos a query.
3. **[PERF-004]** exemplo-lento.prw:51 - Concatenacao de string em loop
   cLog := cLog + cLinha realoca a string a cada iteracao.
   Sugestao: acumular em array e montar o texto uma unica vez ao final.

### INFO (0)

### Resumo: 0 critical, 3 warnings, 0 info
```

## Arquivo de apoio

- [`exemplo-lento.prw`](exemplo-lento.prw) — rotina batch com os problemas `PERF-002`, `PERF-003` e `PERF-004`

## Variações

- `--focus seguranca` — troca regras de performance por regras de segurança (SQL injection, credenciais, validação de entrada)
- `--focus boas-praticas` — boas práticas (variáveis, locks, tratamento de erro, nomenclatura)
- `--focus modernizacao` — migração ADVPL para TLPP e padrões legados

## Próximos passos sugeridos

1. `/advpl-specialist:refactor exemplo-lento.prw` — aplicar as correções sugeridas automaticamente
2. Após correção, rodar `/advpl-specialist:test exemplo-lento.prw` para garantir que o comportamento não mudou
