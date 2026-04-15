# Field Hallucination Guardrail — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Impedir que o agent code-generator invente nomes de campos SX3, adicionando guardrail comportamental em 4 pontos de arquivos existentes.

**Architecture:** 4 edições cirúrgicas em arquivos markdown existentes — nova seção CRITICAL, item no checklist, linha na tabela Common Mistakes e entrada no Lookup Strategy. Nenhum arquivo novo.

**Tech Stack:** Markdown (Claude Code plugin system)

---

## File Structure

| Ação | Arquivo | Responsabilidade |
|------|---------|-----------------|
| Modify | `agents/code-generator.md:641-670` | Nova seção CRITICAL + novo item no checklist |
| Modify | `skills/advpl-code-generation/reference.md:254` | Nova linha na tabela Common Mistakes |
| Modify | `skills/protheus-reference/reference.md:46` | Nova entrada no Lookup Strategy |

---

### Task 1: Adicionar seção CRITICAL: Field Name Validation no code-generator

**Files:**
- Modify: `agents/code-generator.md:641-642` (inserir entre FWFormView e Code Quality Checklist)

- [ ] **Step 1: Ler o arquivo para confirmar contexto**

```bash
# Confirmar que a linha 641 termina com ``` (fim do bloco FWFormView)
# e a linha 643 começa com ## Code Quality Checklist
```

Read `agents/code-generator.md` linhas 630-670.

- [ ] **Step 2: Inserir a nova seção CRITICAL após a linha 641**

Inserir o seguinte bloco entre a linha 641 (fim do bloco de código FWFormView) e a linha 643 (início do Code Quality Checklist):

```markdown
## CRITICAL: Field Name Validation

**The rule:** NEVER emit an identifier in the format `ALIAS_XXXXXX` (e.g., `E2_CCONTAB`, `A1_NOME`, `D1_TOTAL`, `C5_XRESP`) unless it comes from ONE of these 3 confirmed sources:

1. **Plugin reference examples** — the field appears in code examples inside this plugin's reference files (reference.md, patterns-*.md)
2. **User-provided** — the user explicitly cited the field name in their prompt or in response to a question
3. **TDN-confirmed** — the field was returned by a TDN lookup (CQL search by table alias)

**Why this matters:** The plugin does NOT contain a catalog of SX3 fields per table. The LLM will infer plausible field names (e.g., `E2_CCONTAB` for "conta contábil" in SE2) that may not exist in the customer's data dictionary. This causes runtime errors (`Variable does not exist`, `Field not found`) that are hard to trace.

**Mandatory fallback:** If a field is NOT confirmed by any of the 3 sources above, you MUST do ONE of these:

- **(A) Ask the user:**
  > "O campo `{ALIAS_CAMPO}` não consta na minha referência. Confirma o nome exato na sua base, ou deseja que eu use uma variável local e você preenche depois?"

- **(B) Generate a placeholder local variable** using the `cx*` convention (2nd letter `x` indicates unconfirmed) with a TODO comment:
  ```advpl
  Local cxCContab := "" // TODO: confirmar campo E2_??? no SX3
  ```

**Exception:** Fields that appear in code examples within the plugin's reference files (e.g., `A1_COD`, `A1_NOME` in SA1 examples) are considered confirmed and do not require user confirmation.

### Forbidden patterns

```advpl
// WRONG — field E2_CCONTAB was not confirmed by any source:
SE2->E2_CCONTAB := cContab

// WRONG — field C5_XRESP inferred without confirmation:
If Empty(SC5->C5_XRESP)
```

### Correct patterns

```advpl
// CORRECT — ask the user first:
// Agent: "O campo E2_CCONTAB não consta na minha referência.
//         Confirma o nome exato na sua base?"
// User: "O campo correto é E2_CCONTAB sim, pode usar."
SE2->E2_CCONTAB := cContab

// CORRECT — use placeholder variable with TODO:
Local cxCContab := "" // TODO: confirmar campo E2_??? no SX3
// ... later in code:
SE2->(FieldGet(FieldPos(cxCContab)))
```
```

- [ ] **Step 3: Verificar a edição**

Read `agents/code-generator.md` nas linhas onde a seção foi inserida para confirmar que:
- A seção aparece entre FWFormView e Code Quality Checklist
- O markdown está bem formatado
- Não há quebra de conteúdo adjacente

- [ ] **Step 4: Commit**

```bash
git add agents/code-generator.md
git commit -m "feat: adicionar CRITICAL Field Name Validation no code-generator"
```

---

### Task 2: Adicionar item no Code Quality Checklist

**Files:**
- Modify: `agents/code-generator.md:669` (após o último item do checklist, que será deslocado pela inserção da Task 1)

- [ ] **Step 1: Ler o checklist atualizado**

Read `agents/code-generator.md` para encontrar a posição atual do Code Quality Checklist (deslocado pela Task 1). Localizar a última linha do checklist que atualmente termina com:
```
- [ ] TLPP REST endpoints use `User Function` (or class+method) with annotations, matching `totvs/tlpp-sample-rest` samples
```

- [ ] **Step 2: Inserir o novo item após a última linha do checklist**

Adicionar após a linha `TLPP REST endpoints use...`:

```markdown
- [ ] **Todo identificador `ALIAS_CAMPO` citado foi confirmado (usuário, reference local ou TDN) — nenhum campo inventado**
```

- [ ] **Step 3: Verificar a edição**

Read `agents/code-generator.md` no trecho do checklist para confirmar que o item 23 aparece corretamente após o item 22.

- [ ] **Step 4: Commit**

```bash
git add agents/code-generator.md
git commit -m "feat: adicionar verificacao de campos no Code Quality Checklist"
```

---

### Task 3: Adicionar linha na tabela Common Mistakes

**Files:**
- Modify: `skills/advpl-code-generation/reference.md:254`

- [ ] **Step 1: Ler a tabela Common Mistakes atual**

Read `skills/advpl-code-generation/reference.md` linhas 238-255. A última linha da tabela é:
```
| TLPP REST endpoint with bare `Function` | Use `User Function` with `@Get/@Post/...` annotation (official `rest-mod02.tlpp` pattern) |
```

- [ ] **Step 2: Inserir nova linha após a última entrada da tabela**

Adicionar após a linha 254 (última entrada da tabela):

```markdown
| **Inventar nome de campo `ALIAS_CAMPO` não confirmado no SX3** | **Perguntar ao usuário o nome exato ou usar variável local `cx*` com `// TODO: confirmar campo no SX3`** |
```

- [ ] **Step 3: Verificar a edição**

Read `skills/advpl-code-generation/reference.md` linhas 238-256 para confirmar que a nova linha aparece corretamente na tabela.

- [ ] **Step 4: Commit**

```bash
git add skills/advpl-code-generation/reference.md
git commit -m "feat: adicionar campo inventado na tabela Common Mistakes"
```

---

### Task 4: Adicionar entrada no Lookup Strategy

**Files:**
- Modify: `skills/protheus-reference/reference.md:46`

- [ ] **Step 1: Ler a seção Lookup Strategy atual**

Read `skills/protheus-reference/reference.md` linhas 44-48. O conteúdo atual é:
```
1. **Local first:** Check supporting files (native-functions.md, sx-dictionary.md, rest-api-reference.md)
2. **Online fallback:** Load skill `tdn-lookup` e seguir a estratégia de busca em 3 tiers...
```

- [ ] **Step 2: Inserir nova entrada após a linha 46**

Adicionar após a linha 46 (Online fallback):

```markdown
3. **Field validation:** Para validar se um campo `ALIAS_CAMPO` existe em uma tabela padrão, usar CQL do tdn-lookup: `type=page AND title~"{TABLE_ALIAS}" AND text~"{FIELD_NAME}"`. Se o campo não for confirmado, perguntar ao usuário ou usar variável `cx*` com TODO.
```

- [ ] **Step 3: Verificar a edição**

Read `skills/protheus-reference/reference.md` linhas 44-50 para confirmar que a entrada 3 aparece corretamente após a entrada 2.

- [ ] **Step 4: Commit**

```bash
git add skills/protheus-reference/reference.md
git commit -m "feat: adicionar validacao de campos no Lookup Strategy"
```

---

### Task 5: Atualizar documentação (CHANGELOG e README)

**Files:**
- Modify: `CHANGELOG.md` (nova entrada na versão atual ou nova seção)
- Modify: `README.md` (se necessário atualizar descrição de funcionalidades)

- [ ] **Step 1: Ler CHANGELOG.md para entender o formato atual**

Read `CHANGELOG.md` primeiras 30 linhas para ver a estrutura da versão 1.1.0.

- [ ] **Step 2: Adicionar entrada no CHANGELOG**

Na seção `## [1.1.0]` existente, adicionar dentro de `### Changed / Alterado` (ou criar `### Added / Adicionado` se não existir):

```markdown
- **Field Name Validation**: Guardrail contra alucinação de nomes de campos SX3 — agent agora valida campos contra 3 fontes (reference local, prompt do usuário, TDN) antes de emitir identificadores `ALIAS_CAMPO`. Se incerto, pergunta ao usuário ou gera variável `cx*` com TODO.
  **Field Name Validation**: Guardrail against SX3 field name hallucination — agent now validates fields against 3 sources (local reference, user prompt, TDN) before emitting `ALIAS_CAMPO` identifiers. When uncertain, asks the user or generates `cx*` variable with TODO.
```

- [ ] **Step 3: Verificar a edição**

Read `CHANGELOG.md` primeiras 40 linhas para confirmar a entrada.

- [ ] **Step 4: Commit**

```bash
git add CHANGELOG.md README.md
git commit -m "docs: adicionar field validation guardrail no changelog"
```

---

### Task 6: Verificação final

- [ ] **Step 1: Grep por termos-chave para confirmar todas as inserções**

```bash
# Confirmar seção CRITICAL
grep -n "CRITICAL: Field Name Validation" agents/code-generator.md

# Confirmar item no checklist
grep -n "ALIAS_CAMPO" agents/code-generator.md

# Confirmar Common Mistakes
grep -n "Inventar nome de campo" skills/advpl-code-generation/reference.md

# Confirmar Lookup Strategy
grep -n "Field validation" skills/protheus-reference/reference.md

# Confirmar CHANGELOG
grep -n "Field Name Validation" CHANGELOG.md
```

Todos os 5 greps devem retornar exatamente 1 resultado cada.

- [ ] **Step 2: Verificar que nenhum arquivo foi corrompido**

Read cada arquivo modificado nas seções adjacentes às edições para confirmar que o markdown está íntegro.
