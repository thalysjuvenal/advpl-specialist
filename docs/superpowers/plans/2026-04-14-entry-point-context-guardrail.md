# Entry Point Context Guardrail — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Impedir que o agent code-generator assuma variáveis de contexto e work areas disponíveis em pontos de entrada sem confirmação, adicionando guardrail comportamental com fallback defensivo via `Type()`.

**Architecture:** 3 edições em 2 arquivos existentes — nova seção CRITICAL + item no checklist em `code-generator.md`, e seção de alerta em `patterns-pontos-entrada.md`. Nenhum arquivo novo.

**Tech Stack:** Markdown (Claude Code plugin system)

---

## File Structure

| Ação | Arquivo | Responsabilidade |
|------|---------|-----------------|
| Modify | `agents/code-generator.md:688-718` | Nova seção CRITICAL + novo item no checklist |
| Modify | `skills/advpl-code-generation/patterns-pontos-entrada.md:25-27` | Nova seção CRITICAL: Context Availability |

---

### Task 1: Adicionar seção CRITICAL: Entry Point Context Validation no code-generator

**Files:**
- Modify: `agents/code-generator.md` (inserir entre Field Name Validation e Code Quality Checklist)

- [ ] **Step 1: Ler o arquivo para confirmar contexto**

Read `agents/code-generator.md` linhas 685-695. Confirmar que:
- Linha 688 termina com ``` (fim do bloco Correct patterns de Field Name Validation)
- Linha 690 começa com `## Code Quality Checklist`

- [ ] **Step 2: Inserir a nova seção CRITICAL entre a linha 688 e a linha 690**

Encontrar o `old_string` que contém o fim da seção Field Name Validation e o início do Code Quality Checklist. Inserir o seguinte bloco ENTRE eles:

````markdown

## CRITICAL: Entry Point Context Validation

**The rule:** When generating code for an entry point (ponto de entrada), NEVER assume that any of the following are available without confirmation:

1. **Private/Public variables from the caller** — e.g., `CNFISCAL`, `CNFSERIE`, `CCONDPAG`, `CFILANT`. These are set by the calling routine and may not exist in all contexts or Protheus versions.
2. **Work areas (ALIAS->CAMPO)** — e.g., `SF1->F1_DOC`, `SD1->D1_COD`. The table may not be open or the record may not be positioned.
3. **Memvars (M->CAMPO)** — e.g., `M->F1_DOC`, `M->D1_COD`. The EnchoiceBar/MsGetDados context may not be active.

**The ONLY guaranteed data source in an entry point is PARAMIXB** — and its contents MUST be confirmed via TDN lookup before use.

**Confirmed sources for context variables:**
1. **TDN documentation** — PARAMIXB parameters documented on the TDN page for the specific entry point
2. **User-provided** — the user explicitly confirmed which variables are available
3. **Local reference** — the variable appears in `patterns-pontos-entrada.md` for the specific entry point

**Mandatory defensive fallback:** If a context variable or work area is NOT confirmed by any of the 3 sources above, generate code with `Type()` verification:

```advpl
// Verificacao defensiva — variavel pode nao existir neste PE
If Type("CNFISCAL") == "C"
    cNFiscal := CNFISCAL
Else
    ConOut("[MT140TOK] Variavel CNFISCAL nao disponivel neste contexto")
    // TODO: confirmar variavel disponivel no PE
EndIf
```

For work areas, verify with `Select()`:

```advpl
// Verificacao defensiva — work area pode nao estar posicionada
If Select("SF1") > 0 .And. !Empty(SF1->(RecNo()))
    cDoc := SF1->F1_DOC
Else
    cDoc := "" // TODO: confirmar work area disponivel no PE
EndIf
```

**PARAMIXB is safe:** Parameters documented on TDN via PARAMIXB can be accessed directly without defensive verification — they are guaranteed by the calling routine.

### Forbidden patterns

```advpl
// WRONG — assuming CNFISCAL exists without confirmation:
cNFiscal := CNFISCAL

// WRONG — assuming SF1 is positioned without confirmation:
cDoc := SF1->F1_DOC

// WRONG — assuming M-> has the field without confirmation:
cDoc := M->F1_DOC
```

### Correct patterns

```advpl
// CORRECT — PARAMIXB confirmed via TDN:
Local aParams := PARAMIXB
Local cDoc    := aParams[1] // Position 1 = document number (confirmed TDN)

// CORRECT — defensive check for caller variable:
Local cNFiscal := ""
If Type("CNFISCAL") == "C"
    cNFiscal := CNFISCAL
EndIf

// CORRECT — defensive check for work area:
Local cDoc := ""
If Select("SF1") > 0
    cDoc := SF1->F1_DOC
EndIf

// CORRECT — ask the user:
// Agent: "No PE MT140TOK, quais variaveis de contexto estao
//         disponiveis alem do PARAMIXB? (ex: CNFISCAL, M->F1_DOC)"
```
````

- [ ] **Step 3: Verificar a edição**

Read `agents/code-generator.md` nas linhas onde a seção foi inserida para confirmar que:
- A seção aparece entre Field Name Validation e Code Quality Checklist
- O markdown está bem formatado
- Não há quebra de conteúdo adjacente

- [ ] **Step 4: Commit**

```bash
git add agents/code-generator.md
git commit -m "feat: adicionar CRITICAL Entry Point Context Validation no code-generator"
```

---

### Task 2: Adicionar item no Code Quality Checklist

**Files:**
- Modify: `agents/code-generator.md` (após o último item do checklist)

- [ ] **Step 1: Ler o checklist atualizado**

Read `agents/code-generator.md` para encontrar o último item do Code Quality Checklist, que atualmente termina com:
```
- [ ] **Todo identificador `ALIAS_CAMPO` citado foi confirmado (usuário, reference local ou TDN) — nenhum campo inventado**
```

- [ ] **Step 2: Inserir o novo item após a última linha do checklist**

Adicionar após a linha do `ALIAS_CAMPO`:

```markdown
- [ ] **Em pontos de entrada: nenhuma variável de contexto ou work area assumida sem confirmação (TDN, usuário ou reference local) — usar `Type()` para verificação defensiva**
```

- [ ] **Step 3: Verificar a edição**

Read `agents/code-generator.md` no trecho do checklist para confirmar que o novo item aparece como último item.

- [ ] **Step 4: Commit**

```bash
git add agents/code-generator.md
git commit -m "feat: adicionar verificacao de contexto de PE no Code Quality Checklist"
```

---

### Task 3: Adicionar seção CRITICAL: Context Availability no patterns-pontos-entrada.md

**Files:**
- Modify: `skills/advpl-code-generation/patterns-pontos-entrada.md` (inserir após a seção "IMPORTANT: Always Search TDN First")

- [ ] **Step 1: Ler o início do arquivo**

Read `skills/advpl-code-generation/patterns-pontos-entrada.md` linhas 24-30. Confirmar que:
- Linha 25 contém texto sobre TDN page not found
- Linha 26 contém `---` (separador)
- Linha 28 começa com `## 1. What are Entry Points`

- [ ] **Step 2: Inserir a nova seção entre o separador (linha 26) e "## 1. What are Entry Points" (linha 28)**

Encontrar o `old_string` que contém o separador `---` seguido de `## 1. What are Entry Points`. Inserir entre eles:

```markdown

## CRITICAL: Context Availability

**PARAMIXB is the ONLY guaranteed data source in an entry point.** Everything else depends on the calling routine and may NOT be available:

| Source | Availability | Action |
|--------|-------------|--------|
| `PARAMIXB[n]` | **Guaranteed** (if documented on TDN) | Access directly |
| `PARAMIXE[n]` | **Probable** (secondary params) | Verify with `Type("PARAMIXE")` |
| Private variables (`CNFISCAL`, `CNFSERIE`, etc.) | **NOT guaranteed** — depends on caller and Protheus version | Verify with `Type("VAR") == "C"` |
| `M->CAMPO` (memvars) | **NOT guaranteed** — depends on EnchoiceBar/MsGetDados context | Verify with `Type("M->CAMPO")` |
| `ALIAS->CAMPO` (work areas) | **NOT guaranteed** — table may not be open or positioned | Verify with `Select("ALIAS") > 0` |

**Always use `Type()` for defensive verification** before accessing any non-PARAMIXB source. This prevents runtime errors when the variable does not exist in the entry point's context.

```advpl
// Padrao defensivo para variaveis de contexto em PE:
Local cNFiscal := ""
If Type("CNFISCAL") == "C"
    cNFiscal := CNFISCAL
EndIf

// Padrao defensivo para work areas em PE:
Local cDoc := ""
If Select("SF1") > 0
    cDoc := SF1->F1_DOC
EndIf
```

```

- [ ] **Step 3: Verificar a edição**

Read `skills/advpl-code-generation/patterns-pontos-entrada.md` linhas 26-58 para confirmar que a seção aparece entre o separador e "## 1. What are Entry Points".

- [ ] **Step 4: Commit**

```bash
git add skills/advpl-code-generation/patterns-pontos-entrada.md
git commit -m "feat: adicionar CRITICAL Context Availability no patterns-pontos-entrada"
```

---

### Task 4: Atualizar CHANGELOG e fechar issue

**Files:**
- Modify: `CHANGELOG.md` (adicionar entrada na seção Added da v1.1.0)

- [ ] **Step 1: Ler CHANGELOG.md para encontrar a seção Added da v1.1.0**

Read `CHANGELOG.md` primeiras 30 linhas. Localizar a seção `### Added / Adicionado` da v1.1.0.

- [ ] **Step 2: Adicionar entrada no CHANGELOG**

Na seção `### Added / Adicionado` da v1.1.0, adicionar após a entrada do Field Name Validation:

```markdown
- Entry Point Context Validation guardrail: agent now validates that context variables (Private/Public from caller), work areas (ALIAS->CAMPO), and memvars (M->CAMPO) are available before using them in entry point code. When uncertain, generates defensive code with `Type()` verification instead of assuming availability. Resolves #6.
- Guardrail de validacao de contexto em pontos de entrada: agent agora valida que variaveis de contexto (Private/Public do caller), work areas (ALIAS->CAMPO) e memvars (M->CAMPO) estao disponiveis antes de usa-los em codigo de pontos de entrada. Quando incerto, gera codigo defensivo com verificacao `Type()` em vez de assumir disponibilidade. Resolve #6.
```

- [ ] **Step 3: Commit e fechar issue**

```bash
git add CHANGELOG.md
git commit -m "docs: adicionar entry point context guardrail no changelog v1.1.0 — closes #6"
```

---

### Task 5: Verificação final

- [ ] **Step 1: Grep por termos-chave para confirmar todas as inserções**

```bash
# Confirmar seção CRITICAL no code-generator
grep -n "CRITICAL: Entry Point Context Validation" agents/code-generator.md

# Confirmar item no checklist
grep -n "pontos de entrada" agents/code-generator.md

# Confirmar seção no patterns
grep -n "CRITICAL: Context Availability" skills/advpl-code-generation/patterns-pontos-entrada.md

# Confirmar CHANGELOG
grep -n "Entry Point Context Validation" CHANGELOG.md
```

Todos os 4 greps devem retornar exatamente 1 resultado cada.

- [ ] **Step 2: Verificar integridade dos arquivos**

Read cada arquivo modificado nas seções adjacentes às edições para confirmar que o markdown está íntegro.
