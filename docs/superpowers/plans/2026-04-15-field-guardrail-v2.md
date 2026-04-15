# Field Guardrail v2 + Remoção EP Context — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remover o guardrail de contexto em PE (não funciona) e substituir o guardrail comportamental de campos SX3 por abordagem data-driven com arquivo de campos reais + fallback SempreJu.

**Architecture:** Remoção de ~100 linhas (EP context) + criação de `sx3-common-fields.md` com dados do SempreJu + reescrita da seção CRITICAL de campos com lógica de 3 camadas.

**Tech Stack:** Markdown (Claude Code plugin system), WebFetch (SempreJu)

---

## File Structure

| Ação | Arquivo | Responsabilidade |
|------|---------|-----------------|
| Remove content | `agents/code-generator.md` | Remover EP context section + checklist item |
| Remove content | `skills/advpl-code-generation/patterns-pontos-entrada.md` | Remover CRITICAL: Context Availability |
| Remove content | `documentation/content/docs/agentes/code-generator.mdx` | Remover seções EP context do site |
| Create | `skills/protheus-reference/sx3-common-fields.md` | Campos das 21 tabelas principais |
| Modify | `agents/code-generator.md` | Reescrever CRITICAL: Field Name Validation (3 camadas) |
| Modify | `agents/code-generator.md` | Atualizar Phase 2 + checklist |
| Modify | `skills/advpl-code-generation/reference.md` | Atualizar Common Mistakes |
| Modify | `skills/protheus-reference/reference.md` | Atualizar Lookup Strategy |
| Modify | `CHANGELOG.md` | Atualizar entrada v1.1.0 |
| Modify | `documentation/content/docs/agentes/code-generator.mdx` | Reescrever seção campos |
| Modify | `documentation/content/docs/changelog.mdx` | Atualizar |

---

### Task 1: Remover EP Context Guardrail do code-generator.md

**Files:**
- Modify: `agents/code-generator.md` (remover linhas 690-765 + linha 795)

- [ ] **Step 1: Ler o arquivo para confirmar o conteúdo a remover**

Read `agents/code-generator.md` linhas 688-796. Confirmar que:
- Linha 690 começa com `## CRITICAL: Entry Point Context Validation`
- Linha 765 termina com o bloco de código Correct patterns (```)
- Linha 795 contém o item do checklist sobre pontos de entrada

- [ ] **Step 2: Remover a seção CRITICAL: Entry Point Context Validation**

Remover o bloco completo das linhas 690-765 (de `## CRITICAL: Entry Point Context Validation` até o fim do bloco de código Correct patterns). Usar Edit com `old_string` contendo o início e o fim da seção.

- [ ] **Step 3: Remover o item do checklist sobre PE**

Remover a linha:
```
- [ ] **Em pontos de entrada: nenhuma variável de contexto ou work area assumida sem confirmação (TDN, usuário ou reference local) — usar `Type()` para verificação defensiva**
```

- [ ] **Step 4: Verificar a edição**

Read `agents/code-generator.md` para confirmar que:
- A seção Field Name Validation é seguida diretamente pelo Code Quality Checklist
- O checklist não contém mais o item sobre PE
- Nenhum conteúdo adjacente foi afetado

- [ ] **Step 5: Commit**

```bash
git add agents/code-generator.md
git commit -m "refactor: remover CRITICAL Entry Point Context Validation do code-generator"
```

---

### Task 2: Remover EP Context Guardrail do patterns-pontos-entrada.md

**Files:**
- Modify: `skills/advpl-code-generation/patterns-pontos-entrada.md` (remover linhas 28-54)

- [ ] **Step 1: Ler o arquivo**

Read `skills/advpl-code-generation/patterns-pontos-entrada.md` linhas 26-58. Confirmar que:
- Linha 28 começa com `## CRITICAL: Context Availability`
- Linha 54 termina com ``` (fim do bloco de código)
- Linha 56 começa com `## 1. What are Entry Points`

- [ ] **Step 2: Remover a seção CRITICAL: Context Availability**

Remover o bloco das linhas 28-54 (de `## CRITICAL: Context Availability` até o fim do bloco de código, incluindo a linha em branco após).

- [ ] **Step 3: Verificar a edição**

Read para confirmar que `---` (separador) é seguido diretamente por `## 1. What are Entry Points`.

- [ ] **Step 4: Commit**

```bash
git add skills/advpl-code-generation/patterns-pontos-entrada.md
git commit -m "refactor: remover CRITICAL Context Availability do patterns-pontos-entrada"
```

---

### Task 3: Criar sx3-common-fields.md com dados do SempreJu

**Files:**
- Create: `skills/protheus-reference/sx3-common-fields.md`

- [ ] **Step 1: Buscar dados das 21 tabelas no SempreJu**

Para cada tabela, fazer `WebFetch` na URL `https://sempreju.com.br/tabelas_protheus/tabelas/tabela_{alias_lowercase}.html` e extrair os ~15 campos mais usados. As URLs são:

```
tabela_sa1.html, tabela_sa2.html, tabela_sb1.html, tabela_sb2.html,
tabela_sd3.html, tabela_sc7.html, tabela_sf1.html, tabela_sd1.html,
tabela_sc5.html, tabela_sc6.html, tabela_sf2.html, tabela_sd2.html,
tabela_se1.html, tabela_se2.html, tabela_se5.html,
tabela_ct1.html, tabela_ct2.html, tabela_ctd.html,
tabela_sf3.html, tabela_sft.html, tabela_cdo.html
```

Para cada tabela, extrair: Campo (X3_CAMPO), Tipo (X3_TIPO), Tamanho (X3_TAMANHO), Descrição (X3_DESCRIC).

Selecionar os ~15 campos mais relevantes por tabela. Critérios de seleção:
- Campos da chave primária (X2_UNICO)
- Campos com Browse=Sim
- Campos obrigatórios (X3_OBRIGAT)
- Campos de valor, data, status, código de relacionamento
- Campos contábeis/fiscais quando existirem (CCD, DEBITO, CREDITO, TES, CF, IPI, ICMS)

- [ ] **Step 2: Criar o arquivo sx3-common-fields.md**

Formato do arquivo:

```markdown
# SX3 Common Fields — Campos mais usados das tabelas padrão Protheus

Referência rápida com os ~15 campos mais usados de cada tabela principal.
Fonte: https://sempreju.com.br/tabelas_protheus/

**Para campos não listados aqui:** O agent deve buscar automaticamente em
`https://sempreju.com.br/tabelas_protheus/tabelas/tabela_{alias_lowercase}.html`
usando WebFetch.

---

## SA1 — Clientes

| Campo | Tipo | Tam | Descrição |
|-------|------|-----|-----------|
| A1_FILIAL | C | 8 | Filial |
| A1_COD | C | 6 | Código do Cliente |
| A1_LOJA | C | 2 | Loja |
| A1_NOME | C | 40 | Nome/Razão Social |
| ... (completar com dados reais do SempreJu) |

## SA2 — Fornecedores
... (repetir para todas as 21 tabelas)
```

Incluir campos contábeis/fiscais nas tabelas que os possuem:
- SE1/SE2: E1_CCD, E1_DEBITO, E1_CREDITO, E2_CCD, E2_DEBITO, E2_CREDITO
- SD1/SD2: D1_TES, D1_CF, D1_IPI, D1_ICMS, D2_TES, D2_CF, D2_IPI, D2_ICMS
- SF1/SF2: F1_FORMUL, F1_ESPECIE, F2_FORMUL, F2_ESPECIE

- [ ] **Step 3: Verificar o arquivo**

Read `skills/protheus-reference/sx3-common-fields.md` e confirmar que:
- Todas as 21 tabelas estão presentes
- Cada tabela tem ~15 campos
- Os campos contábeis/fiscais estão incluídos nas tabelas relevantes
- O formato está consistente (tabela markdown)

- [ ] **Step 4: Commit**

```bash
git add skills/protheus-reference/sx3-common-fields.md
git commit -m "feat: criar sx3-common-fields.md com campos das 21 tabelas principais"
```

---

### Task 4: Reescrever CRITICAL: Field Name Validation (3 camadas)

**Files:**
- Modify: `agents/code-generator.md` (substituir seção atual linhas 643-688)

- [ ] **Step 1: Ler a seção atual**

Read `agents/code-generator.md` na seção CRITICAL: Field Name Validation. Após a Task 1, ela está entre FWFormView (linha ~641) e Code Quality Checklist.

- [ ] **Step 2: Substituir a seção inteira**

Substituir todo o conteúdo de `## CRITICAL: Field Name Validation` até o último ``` (fim do bloco Correct patterns) pelo novo conteúdo:

```markdown
## CRITICAL: Field Name Validation

**The rule:** NEVER emit an identifier in the format `ALIAS_XXXXXX` (e.g., `E2_CCONTAB`, `A1_NOME`, `D1_TOTAL`) unless it has been confirmed by one of the 3 layers below. **NEVER invent a field name.**

### Layer 1 — Local reference (instant, no cost)

Check `skills/protheus-reference/sx3-common-fields.md`. If the field appears there → use it directly.

### Layer 2 — SempreJu lookup (automatic, ~500 tokens)

If the field is NOT in the local reference, automatically fetch:
`https://sempreju.com.br/tabelas_protheus/tabelas/tabela_{alias_lowercase}.html`

Search the page for the field name. If found → use it. If the page does not load or the field is not found → proceed to Layer 3.

**Example:** For field `E2_PORTADO` in table SE2:
1. Check sx3-common-fields.md → not found
2. WebFetch `https://sempreju.com.br/tabelas_protheus/tabelas/tabela_se2.html`
3. Search page for `E2_PORTADO` → found (C, 3, "Código do Portador") → use it

### Layer 3 — Ask the user (last resort)

If Layers 1 and 2 did not confirm the field, ask the user:
> "O campo `{ALIAS_CAMPO}` não foi encontrado na minha referência local nem no SempreJu. Confirma o nome exato na sua base?"

**NEVER generate a field that was not confirmed by any layer. No exceptions. No placeholder variables.**

### Forbidden patterns

```advpl
// WRONG — field not confirmed by any layer:
SE2->E2_CCONTAB := cContab

// WRONG — placeholder variable instead of real field:
Local cxCContab := "" // TODO: confirmar campo
```

### Correct patterns

```advpl
// CORRECT — field confirmed in sx3-common-fields.md (Layer 1):
SE2->E2_VALOR := nValor

// CORRECT — field confirmed via SempreJu WebFetch (Layer 2):
// Agent fetched tabela_se2.html, found E2_PORTADO (C, 3, "Código do Portador")
SE2->E2_PORTADO := cPortador

// CORRECT — field confirmed by user (Layer 3):
// Agent: "O campo E2_CCONTAB não foi encontrado. Confirma o nome?"
// User: "Sim, E2_CCONTAB existe na minha base."
SE2->E2_CCONTAB := cContab
```
```

- [ ] **Step 3: Verificar a edição**

Read `agents/code-generator.md` para confirmar que a nova seção contém as 3 camadas, sem cx*, sem TODO.

- [ ] **Step 4: Commit**

```bash
git add agents/code-generator.md
git commit -m "feat: reescrever CRITICAL Field Name Validation com 3 camadas (local/SempreJu/usuario)"
```

---

### Task 5: Atualizar Phase 2 + Checklist no code-generator.md

**Files:**
- Modify: `agents/code-generator.md` (Phase 2 e Code Quality Checklist)

- [ ] **Step 1: Ler a Phase 2 atual**

Read `agents/code-generator.md` linhas 48-64. Localizar onde adicionar o carregamento sob demanda do sx3-common-fields.md.

- [ ] **Step 2: Adicionar carregamento sob demanda na Phase 2**

Após a linha sobre embedded-sql (linha 62), adicionar:

```markdown
- **For code that involves database tables (MVC, entry points, CRUD, REST with data access, TReport, Embedded SQL):** Read `skills/protheus-reference/sx3-common-fields.md` for field validation. Do NOT load this file for utility classes, helpers, or code without database operations.
```

- [ ] **Step 3: Atualizar o item do checklist de campos**

Encontrar a linha atual:
```
- [ ] **Todo identificador `ALIAS_CAMPO` citado foi confirmado (usuário, reference local ou TDN) — nenhum campo inventado**
```

Substituir por:
```
- [ ] **Todo identificador `ALIAS_CAMPO` foi confirmado via sx3-common-fields.md, SempreJu (WebFetch), ou usuário — nenhum campo inventado, nenhum placeholder cx***
```

- [ ] **Step 4: Verificar as edições**

Read as seções modificadas para confirmar.

- [ ] **Step 5: Commit**

```bash
git add agents/code-generator.md
git commit -m "feat: atualizar Phase 2 e checklist para sx3-common-fields e SempreJu"
```

---

### Task 6: Atualizar Common Mistakes e Lookup Strategy

**Files:**
- Modify: `skills/advpl-code-generation/reference.md` (Common Mistakes table)
- Modify: `skills/protheus-reference/reference.md` (Lookup Strategy)

- [ ] **Step 1: Ler os arquivos**

Read `skills/advpl-code-generation/reference.md` para localizar a linha atual sobre campos inventados na tabela Common Mistakes.
Read `skills/protheus-reference/reference.md` para localizar a entrada sobre Field validation no Lookup Strategy.

- [ ] **Step 2: Atualizar Common Mistakes**

Encontrar a linha atual:
```
| **Inventar nome de campo `ALIAS_CAMPO` não confirmado no SX3** | **Perguntar ao usuário ou usar variável local `cx*` com `// TODO: confirmar campo no SX3`** |
```

Substituir por:
```
| **Inventar nome de campo `ALIAS_CAMPO` não confirmado no SX3** | **Verificar em `sx3-common-fields.md` → se não encontrar, buscar via WebFetch no SempreJu → se não encontrar, perguntar ao usuário. NUNCA inventar.** |
```

- [ ] **Step 3: Atualizar Lookup Strategy**

Encontrar a linha atual:
```
3. **Field validation:** Para validar se um campo `ALIAS_CAMPO` existe em uma tabela padrão, usar CQL do tdn-lookup: `type=page AND title~"{TABLE_ALIAS}" AND text~"{FIELD_NAME}"`. Se o campo não for confirmado, perguntar ao usuário ou usar variável `cx*` com TODO.
```

Substituir por:
```
3. **Field validation:** Para validar campos SX3: (1) Verificar `sx3-common-fields.md` (referência local com ~15 campos das 21 tabelas principais). (2) Se não encontrar, WebFetch em `https://sempreju.com.br/tabelas_protheus/tabelas/tabela_{alias_lowercase}.html`. (3) Se não encontrar, perguntar ao usuário. NUNCA inventar campo.
```

- [ ] **Step 4: Verificar as edições**

Read ambos os arquivos nas linhas modificadas.

- [ ] **Step 5: Commit**

```bash
git add skills/advpl-code-generation/reference.md skills/protheus-reference/reference.md
git commit -m "feat: atualizar Common Mistakes e Lookup Strategy para SempreJu"
```

---

### Task 7: Atualizar CHANGELOG.md

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Ler o CHANGELOG**

Read `CHANGELOG.md` primeiras 35 linhas para localizar as entradas sobre Field Name Validation e Entry Point Context.

- [ ] **Step 2: Substituir as entradas na v1.1.0**

Na seção `### Added / Adicionado` da v1.1.0, substituir as 4 linhas atuais (Field Name Validation + Entry Point Context) por:

```markdown
- Field Name Validation v2 (data-driven): agent now validates SX3 field names against `sx3-common-fields.md` (21 tables, ~315 fields). For fields not in local reference, automatically fetches from SempreJu (`sempreju.com.br`). Only asks the user as last resort. Never invents field names, never generates placeholder variables.
- Validacao de nomes de campos v2 (data-driven): agent agora valida nomes de campos SX3 contra `sx3-common-fields.md` (21 tabelas, ~315 campos). Para campos nao encontrados na referencia local, busca automaticamente no SempreJu (`sempreju.com.br`). So pergunta ao usuario como ultimo recurso. Nunca inventa nomes de campos, nunca gera variaveis placeholder.
```

- [ ] **Step 3: Verificar a edição**

Read `CHANGELOG.md` para confirmar.

- [ ] **Step 4: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs: atualizar changelog v1.1.0 com field guardrail v2"
```

---

### Task 8: Atualizar documentação do site

**Files:**
- Modify: `documentation/content/docs/agentes/code-generator.mdx`
- Modify: `documentation/content/docs/changelog.mdx`

- [ ] **Step 1: Ler code-generator.mdx**

Read `documentation/content/docs/agentes/code-generator.mdx` para localizar as seções CRITICO sobre campos e PE context, e os itens do checklist.

- [ ] **Step 2: Remover seção CRITICO de PE context**

Remover a seção `## CRITICO: Validacao de Contexto em Pontos de Entrada` inteira.

- [ ] **Step 3: Reescrever seção CRITICO de campos**

Substituir a seção `## CRITICO: Validacao de Nomes de Campos` pelo novo conteúdo com 3 camadas (sem cx*, com SempreJu). Traduzir para pt-BR mantendo consistência com as outras seções.

- [ ] **Step 4: Atualizar itens do checklist**

Remover o item sobre PE context. Atualizar o item sobre campos para refletir as 3 camadas (sem cx*, com SempreJu).

- [ ] **Step 5: Atualizar changelog.mdx**

Substituir as entradas sobre Field Name Validation e Entry Point Context pelo novo conteúdo v2.

- [ ] **Step 6: Verificar as edições**

Read ambos os arquivos nas seções modificadas.

- [ ] **Step 7: Commit**

```bash
git add documentation/content/docs/agentes/code-generator.mdx documentation/content/docs/changelog.mdx
git commit -m "docs(site): atualizar documentacao para field guardrail v2 e remover EP context"
```

---

### Task 9: Atualizar Release GitHub e verificação final

- [ ] **Step 1: Atualizar release notes v1.1.0**

```bash
gh release edit v1.1.0 --notes "... (notas atualizadas sem EP context, com field guardrail v2)"
```

- [ ] **Step 2: Grep de verificação**

```bash
# Confirmar que EP context foi removido
grep -rn "Entry Point Context Validation" agents/ skills/ documentation/
# Deve retornar 0 resultados

# Confirmar que cx* foi removido
grep -rn "cxCContab\|cx\*.*TODO" agents/ skills/
# Deve retornar 0 resultados

# Confirmar que sx3-common-fields existe
ls skills/protheus-reference/sx3-common-fields.md

# Confirmar que SempreJu está referenciado
grep -rn "sempreju" agents/code-generator.md skills/protheus-reference/reference.md
# Deve retornar pelo menos 2 resultados
```

- [ ] **Step 3: Push**

```bash
git push origin main
```
