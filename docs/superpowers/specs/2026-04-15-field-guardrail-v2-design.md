# Field Guardrail v2 + Remoção do EP Context Guardrail — Design Spec

## Contexto

A v1.1.0 implementou dois guardrails comportamentais:
1. **Field Name Validation** — regra "pergunte ou use cx*" para campos SX3
2. **Entry Point Context Validation** — regra "use Type() para variáveis de contexto em PEs"

Ambos falharam na prática:
- **Campos**: O LLM continua inventando campos plausíveis (ignora a regra). O fallback cx* gera código inútil.
- **PE Context**: Muito genérico, código verboso com Type(), não resolve o problema real.

## Objetivo

1. **Remover** completamente o guardrail de contexto em PE (não resolve, adiciona ruído)
2. **Substituir** o guardrail comportamental de campos por abordagem data-driven com arquivo de campos reais + fallback automático via SempreJu

## Parte 1: Remoção do EP Context Guardrail

### Arquivos a alterar

| Arquivo | Ação |
|---------|------|
| `agents/code-generator.md` | Remover seção CRITICAL: Entry Point Context Validation (~75 linhas) |
| `agents/code-generator.md` | Remover item do checklist sobre pontos de entrada |
| `skills/advpl-code-generation/patterns-pontos-entrada.md` | Remover seção CRITICAL: Context Availability (~27 linhas) |
| `CHANGELOG.md` | Remover entradas sobre Entry Point Context Validation |
| `documentation/content/docs/agentes/code-generator.mdx` | Remover seção CRITICO: Validação de Contexto em PE + item checklist |
| `documentation/content/docs/changelog.mdx` | Remover entrada sobre EP context |
| Release GitHub v1.1.0 | Atualizar notas removendo seção EP |

## Parte 2: Field Guardrail v2 (Data-Driven)

### Novo arquivo: `skills/protheus-reference/sx3-common-fields.md`

Arquivo com ~15 campos mais usados de cada uma das 15 tabelas principais do Protheus. Fonte: https://sempreju.com.br/tabelas_protheus/tabelas/tabela_{alias}.html

**Tabelas incluídas:**

| Módulo | Tabela | Descrição |
|--------|--------|-----------|
| Cadastros | SA1 | Clientes |
| Cadastros | SA2 | Fornecedores |
| Estoque | SB1 | Produtos |
| Estoque | SB2 | Saldos em Estoque |
| Estoque | SD3 | Movimentações Internas |
| Compras | SC7 | Pedidos de Compra |
| Compras | SF1 | Cabeçalho NF Entrada |
| Compras | SD1 | Itens NF Entrada |
| Faturamento | SC5 | Pedidos de Venda |
| Faturamento | SC6 | Itens do Pedido de Venda |
| Faturamento | SF2 | Cabeçalho NF Saída |
| Faturamento | SD2 | Itens NF Saída |
| Financeiro | SE1 | Contas a Receber |
| Financeiro | SE2 | Contas a Pagar |
| Financeiro | SE5 | Movimentação Bancária |

**Formato por tabela:**

```markdown
## SE2 — Contas a Pagar

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| E2_FILIAL | C | 8 | Filial |
| E2_PREFIXO | C | 3 | Prefixo do Título |
| E2_NUM | C | 9 | Número do Título |
| E2_PARCELA | C | 1 | Parcela |
| E2_TIPO | C | 3 | Tipo do Título |
| E2_FORNECE | C | 6 | Código do Fornecedor |
| E2_LOJA | C | 2 | Loja do Fornecedor |
| E2_NATUREZ | C | 10 | Natureza Financeira |
| E2_EMISSAO | D | 8 | Data de Emissão |
| E2_VENCTO | D | 8 | Data de Vencimento |
| E2_VALOR | N | 16 | Valor do Título |
| E2_SALDO | N | 16 | Saldo do Título |
| E2_HIST | C | 40 | Histórico |
| E2_PORTADO | C | 3 | Código do Portador |
| E2_NOMFOR | C | 20 | Nome do Fornecedor |
```

~15 campos x 15 tabelas = ~225 campos. Estimativa: ~2.500-3.000 tokens quando carregado.

### Seção CRITICAL: Field Name Validation reescrita

**Localização**: Mesma posição atual em `agents/code-generator.md` (entre FWFormView e Code Quality Checklist).

**Nova lógica em 3 camadas:**

1. **Camada 1 — Referência local**: O campo está em `sx3-common-fields.md`? → Usa diretamente, sem perguntas.

2. **Camada 2 — SempreJu (automático)**: Campo não encontrado localmente? → `WebFetch` em `https://sempreju.com.br/tabelas_protheus/tabelas/tabela_{alias_lowercase}.html` e buscar o campo na página. Se encontrar (campo existe na tabela SX3 oficial) → usa. URL previsível, sem busca necessária.

3. **Camada 3 — Perguntar ao usuário**: SempreJu não retornou ou campo não encontrado? → Perguntar ao usuário o nome exato.

**Regra absoluta**: Se NENHUMA das 3 camadas confirmou o campo, NÃO emitir o identificador. Nunca inventar.

**Sem fallback cx***: Variáveis placeholder `cxCampo` com TODO foram eliminadas. Ou o campo é confirmado ou não é emitido.

**Exceção mantida**: Campos que aparecem em exemplos de código dentro das references do plugin continuam sendo considerados confirmados.

### Carregamento sob demanda

O agent carrega `sx3-common-fields.md` **apenas** quando o código envolve operações com tabelas:
- MVC (ModelDef, ViewDef)
- Pontos de entrada
- CRUD / operações de banco
- REST com acesso a dados
- Relatórios (TReport com queries)
- Embedded SQL

**NÃO carrega** para:
- Classes utilitárias sem banco
- Helpers/funções de cálculo
- Web Services SOAP sem acesso a tabelas
- Código puramente lógico

### Atualização de arquivos existentes

| Arquivo | Alteração |
|---------|-----------|
| `agents/code-generator.md` | Reescrever CRITICAL: Field Name Validation (3 camadas, sem cx*) |
| `agents/code-generator.md` | Atualizar item do checklist de campos |
| `agents/code-generator.md` | Adicionar `sx3-common-fields.md` na Phase 2 (sob demanda) |
| `skills/advpl-code-generation/reference.md` | Atualizar Common Mistakes (sem cx*, com SempreJu) |
| `skills/protheus-reference/reference.md` | Atualizar Lookup Strategy (adicionar SempreJu como fonte) |
| `commands/generate.md` | Adicionar WebFetch em allowed-tools (se não estiver) |

### Documentação

| Arquivo | Alteração |
|---------|-----------|
| `CHANGELOG.md` | Atualizar entrada v1.1.0 — substituir guardrail comportamental por data-driven |
| `documentation/content/docs/agentes/code-generator.mdx` | Reescrever seção CRITICO de campos |
| `documentation/content/docs/changelog.mdx` | Atualizar |
| Release GitHub v1.1.0 | Atualizar notas |

## Trade-offs

| Aspecto | Antes (v1 comportamental) | Depois (v2 data-driven) |
|---------|--------------------------|------------------------|
| Precisão | Baixa — LLM ignora regra | Alta — dados reais + SempreJu |
| Tokens (base) | ~200 | ~3.000 (sob demanda) |
| Tokens (fallback) | 0 | ~500-1.000 (WebFetch, só quando necessário) |
| UX | Pergunta demais ou inventa | Resolve sozinho na maioria |
| Manutenção | Zero | Baixa — campos padrão raramente mudam |
| Código gerado | cx* inútil ou campo inventado | Campo real confirmado |
| EP Context | Type() verboso, genérico | Removido |

## Critérios de Sucesso

1. O agent usa campos reais do `sx3-common-fields.md` sem inventar
2. Para campos não documentados localmente, busca no SempreJu automaticamente
3. Só pergunta ao usuário como último recurso (camada 3)
4. Nenhum código com cx* ou TODO é gerado
5. Seção de EP context completamente removida de todos os arquivos
6. O arquivo sx3-common-fields.md é carregado apenas quando necessário
