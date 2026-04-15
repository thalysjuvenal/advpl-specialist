# Entry Point Context Guardrail — Design Spec

## Problema

O agent `code-generator` assume que variáveis de contexto (Private/Public do caller), work areas (ALIAS->CAMPO) e memvars (M->CAMPO) estão disponíveis em pontos de entrada sem verificação. Isso gera código que falha em runtime.

**Exemplo real (Issue #6):** No PE `MT140TOK` (validação da NF de entrada), `SF1->F1_DOC` e `M->F1_DOC` não estão disponíveis. Os dados vêm via variáveis como `CNFISCAL`, que também pode não existir dependendo do contexto de chamada.

## Objetivo

Impedir que o agent emita código que acessa variáveis de contexto, work areas ou memvars em pontos de entrada sem confirmação de disponibilidade, usando um guardrail comportamental com fallback defensivo via `Type()`.

## Abordagem Escolhida

**Guardrail comportamental com fallback defensivo** — regras inseridas em 2 arquivos existentes + 1 item no checklist. Nenhum arquivo novo. ~150 tokens adicionais por invocação. Zero manutenção.

Abordagens descartadas:
- **Enriquecer PEs existentes com variáveis de contexto**: manutenção contínua, nunca completo (centenas de PEs)
- **Catálogo expandido de PEs**: custo alto, manutenção contínua, alto consumo de tokens

## Alterações

### 1. Nova seção CRITICAL em `agents/code-generator.md`

**Localização**: Após a seção "CRITICAL: Field Name Validation" e antes do "Code Quality Checklist".

**Título**: `## CRITICAL: Entry Point Context Validation`

**Conteúdo**:

- **Regra**: Ao gerar código de ponto de entrada, NUNCA assumir que:
  - Variáveis Private/Public do caller estão disponíveis (ex: `CNFISCAL`, `CNFSERIE`, `CCONDPAG`)
  - Work areas estão posicionadas (ex: `SF1->F1_DOC`, `SD1->D1_COD`)
  - Memvars M-> contêm os campos esperados (ex: `M->F1_DOC`)

- **Fontes válidas para contexto de PE**:
  1. **PARAMIXB documentado no TDN** — única fonte garantida, deve ser buscado via tdn-lookup antes de gerar
  2. **Variáveis confirmadas pelo usuário** — o usuário citou explicitamente quais variáveis estão disponíveis
  3. **Documentação local** — variável aparece em `patterns-pontos-entrada.md` para o PE específico

- **Fallback defensivo obrigatório**: Se uma variável de contexto ou work area NÃO foi confirmada por nenhuma das 3 fontes, gerar código com verificação `Type()`:
  ```advpl
  // Verificacao defensiva — variavel pode nao existir neste PE
  If Type("CNFISCAL") == "C"
      cNFiscal := CNFISCAL
  Else
      ConOut("[PE_NAME] Variavel CNFISCAL nao disponivel neste contexto")
      // TODO: confirmar variavel disponivel no PE
  EndIf
  ```

- Para work areas, verificar posicionamento:
  ```advpl
  // Verificacao defensiva — work area pode nao estar posicionada
  If Select("SF1") > 0 .And. !Empty(SF1->F1_DOC)
      cDoc := SF1->F1_DOC
  Else
      cDoc := "" // TODO: confirmar work area disponivel no PE
  EndIf
  ```

- **PARAMIXB é seguro**: Parâmetros documentados no TDN via PARAMIXB podem ser acessados diretamente sem verificação defensiva.

- **Padrões Forbidden/Correct** no mesmo estilo das seções CRITICAL existentes.

### 2. Seção de alerta em `skills/advpl-code-generation/patterns-pontos-entrada.md`

**Localização**: No início do arquivo, logo após a introdução existente e antes do primeiro PE documentado.

**Título**: `## CRITICAL: Context Availability`

**Conteúdo**:
- PARAMIXB é a única fonte garantida de dados em um PE (documentada no TDN)
- Variáveis Private do caller (`CNFISCAL`, `CNFSERIE`, `CCONDPAG`, etc.) podem NÃO existir — dependem da rotina chamadora e da versão do Protheus
- `M->CAMPO` pode NÃO conter os campos esperados — o contexto de memvars depende de quem chamou o PE
- `ALIAS->CAMPO` pode NÃO estar posicionado — a work area pode não ter sido aberta ou o registro pode não estar posicionado
- Sempre usar `Type("VAR")` para verificação defensiva antes de acessar variáveis de contexto
- Sempre verificar `Select("ALIAS")` antes de acessar work areas

### 3. Novo item no Code Quality Checklist (`agents/code-generator.md`)

**Localização**: Após o item de Field Name Validation no checklist.

**Item**:
```
- [ ] **Em pontos de entrada: nenhuma variável de contexto ou work area assumida sem confirmação (TDN, usuário ou reference local) — usar `Type()` para verificação defensiva**
```

## O que NÃO muda

- **Os 16 PEs existentes** em `patterns-pontos-entrada.md` — não adicionamos variáveis de contexto individuais
- **O fluxo do TDN lookup** — já é obrigatório para PEs e continua sendo
- **Nenhum arquivo novo** criado
- **Common Mistakes table** — não adicionamos entrada (o alerta no patterns-pontos-entrada.md é suficiente)

## Trade-offs

| Aspecto | Avaliação |
|---------|-----------|
| Tokens adicionais | ~150 por invocação (apenas quando gerando PE) |
| Manutenção | Zero — regras comportamentais, não dependem de dados |
| Cobertura | Todos os PEs, incluindo os não documentados localmente |
| Código gerado | Mais defensivo (Type() check), mas nunca quebra em runtime |
| UX | Agent pode perguntar quais variáveis estão disponíveis (desejável) |

## Critérios de Sucesso

1. O agent nunca acessa `CNFISCAL`, `M->F1_DOC` ou `SF1->F1_DOC` em PE sem confirmação
2. Código gerado para PEs inclui verificação `Type()` para variáveis não confirmadas
3. PARAMIXB documentado no TDN continua sendo acessado diretamente (sem Type())
4. O Code Quality Checklist impede que código com variáveis não confirmadas passe pela revisão

## Relação com Issue #6

Esta melhoria resolve o cenário reportado na issue #6 (MT140TOK com variáveis indisponíveis). O agent passará a:
- Buscar no TDN os PARAMIXB do MT140TOK antes de gerar
- Perguntar ao usuário quais variáveis de contexto estão disponíveis
- Gerar código defensivo com `Type()` para qualquer variável não confirmada
