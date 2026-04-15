# Field Hallucination Guardrail — Design Spec

## Problema

O agent `code-generator` inventa nomes de campos SX3 plausíveis (ex: `E2_CCONTAB`, `A1_XRESP`) que não existem no dicionário de dados do cliente. Isso acontece porque:

1. O plugin documenta a **estrutura** do SX3 (quais propriedades um campo tem), não o **conteúdo** (quais campos existem por tabela)
2. O agent é proibido de escanear o projeto do cliente (seção "No Project-Wide Source Scanning")
3. Não existe nenhuma regra explícita contra campos inventados
4. O workflow Phase 1 não pergunta quais campos usar — o agent infere

## Objetivo

Impedir que o agent emita qualquer identificador `ALIAS_XXXXXX` que não tenha sido confirmado por uma fonte confiável, usando um guardrail comportamental (regras no agent) sem carregar dados adicionais.

## Abordagem Escolhida

**Guardrail comportamental** — regras inseridas em 4 pontos de arquivos já existentes. Nenhum arquivo novo. ~200 tokens adicionais por invocação. Zero manutenção.

Abordagens descartadas:
- **Allowlist de campos comuns**: 3.000-5.000 tokens por invocação, alta manutenção, nunca completa (campos custom `Z_*`, `X_*`)
- **Validação TDN obrigatória**: 5.000-10.000 tokens, depende de rede, lento

## Alterações

### 1. Nova seção CRITICAL em `agents/code-generator.md`

**Localização**: Após a seção "CRITICAL: FWFormView Methods" (linha ~641), antes do "Code Quality Checklist" (linha ~643).

**Título**: `## CRITICAL: Field Name Validation`

**Conteúdo**:

- **Regra**: Nunca emitir um identificador no formato `ALIAS_XXXXXX` (ex: `E2_CCONTAB`, `A1_NOME`, `D1_TOTAL`) a menos que ele venha de UMA destas 3 fontes:
  - (a) Exemplos explícitos dentro das references do plugin (reference.md, patterns-*.md)
  - (b) Campo citado literalmente pelo usuário no prompt ou em resposta a uma pergunta
  - (c) Retorno confirmado do TDN via tdn-lookup (CQL por alias da tabela)

- **Fallback obrigatório**: Se o campo não foi confirmado por nenhuma das 3 fontes, o agent DEVE fazer UMA de duas coisas:
  - (A) Perguntar: "O campo `{ALIAS_CAMPO}` não consta na minha referência. Confirma o nome exato na sua base, ou deseja que eu use uma variável local e você preenche depois?"
  - (B) Gerar variável local com convenção `cx*` (2a letra `x`) marcada com `// TODO: confirmar campo no SX3`. Exemplo: `Local cxCContab := "" // TODO: confirmar campo no SX3`

- **Padrões Forbidden/Correct**: No mesmo estilo das outras seções CRITICAL existentes:
  - Forbidden: gerar `SE2->E2_CCONTAB` sem confirmação
  - Correct: perguntar ao usuário ou usar `cxCContab` com TODO

- **Exceção**: Campos que aparecem em exemplos de código dentro das references do plugin (ex: `A1_COD`, `A1_NOME` em exemplos de SA1) são considerados confirmados — não precisam de pergunta.

### 2. Novo item no Code Quality Checklist (`agents/code-generator.md`)

**Localização**: Após o último item do checklist (linha ~668), antes do fechamento da seção.

**Item**:
```
- [ ] Todo identificador ALIAS_CAMPO citado foi confirmado (usuário, reference local ou TDN) — nenhum campo inventado
```

### 3. Nova linha na Common Mistakes table (`skills/advpl-code-generation/reference.md`)

**Localização**: Após a última linha da tabela (linha ~254).

**Linha**:
```
| Inventar nome de campo não confirmado no SX3 | Perguntar ao usuário ou usar variável `cx*` com `// TODO: confirmar campo` |
```

### 4. Nova entrada no Lookup Strategy (`skills/protheus-reference/reference.md`)

**Localização**: Na seção Lookup Strategy, após as entradas existentes.

**Entrada**: Adicionar ao fluxo de validação que, para campos de tabelas padrão, o agent pode usar CQL do tdn-lookup:
```
Para validar campo padrão: CQL type=page AND title~"{TABLE_ALIAS}" AND text~"{FIELD_NAME}"
```

## O que NÃO muda

- **Phase 1 questions**: Não adicionamos pergunta sobre campos antecipadamente. O agent pergunta sob demanda quando encontra incerteza durante a geração — mais eficiente em tokens.
- **Nenhum arquivo novo**: Todas as alterações são em arquivos existentes.
- **Nenhum dado carregado**: Não há allowlist de campos. O guardrail é comportamental.
- **`commands/generate.md`**: As tools permitidas já incluem tudo necessário (Read, WebSearch para TDN).
- **Seções CRITICAL existentes**: Permanecem intactas.

## Trade-offs

| Aspecto | Avaliação |
|---------|-----------|
| Tokens adicionais | ~200 por invocação (mínimo possível) |
| Manutenção | Zero — regras comportamentais não dependem de dados |
| Cobertura | ~90% dos casos de alucinação |
| Impacto no UX | Agent pergunta mais ao usuário (desejável — garante precisão) |
| Consistência | Segue o padrão CRITICAL já estabelecido no plugin |
| Evolução futura | Compatível com allowlist opcional no futuro |

## Critérios de Sucesso

1. O agent nunca emite `ALIAS_CAMPO` sem confirmação
2. Quando incerto, pergunta ao usuário OU usa variável `cx*` com TODO
3. Campos já presentes em exemplos das references não geram pergunta desnecessária
4. O Code Quality Checklist impede que código com campos não confirmados passe pela revisão
