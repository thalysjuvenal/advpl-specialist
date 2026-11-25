---
description: Gera ou migra rotinas Smart X (telas web por metadados) - modelo, interface e launcher TLPP; converte mBrowse/AxCadastro/MVC para Smart X
allowed-tools: Read, Write, Glob, Grep, Agent
argument-hint: "[--mode generate|migrate] [--output path]"
---

**IMPORTANT:** Always respond in the same language the user is writing in. If the user writes in Portuguese, respond in Portuguese. If in English, respond in English.

# /advpl-specialist:smartx

Gera ou migra rotinas Smart X (telas web modernas orientadas a metadados) para o TOTVS Protheus.

## Usage

```bash
/advpl-specialist:smartx [options]
```

Descreva em linguagem natural a rotina Smart X desejada (nova ou existente para migração) após o comando. O agente irá interpretar a descrição e gerar os fontes `model.tlpp`, `interface.tlpp` e launcher correspondentes.

## Options

| Flag | Description | Default |
|------|------------|---------|
| `--mode` | Modo de operação: `generate` (nova rotina Smart X) ou `migrate` (converter rotina existente) | Inferir automaticamente: menções a rotina existente, mBrowse, AxCadastro, MVC ou "converter"/"migrar" indicam `migrate`; caso contrário `generate` |
| `--output` | Caminho de saída dos arquivos `.tlpp` gerados | Diretório atual |

## Fluxo

### Passo inicial (ambos os modos) — release declarada

Antes de gerar ou planejar, se existir um arquivo `.protheus-version` na raiz do projeto, leia-o (uma release por arquivo, ex.: `12.1.2410`). Consulte o mínimo do recurso em `${CLAUDE_PLUGIN_ROOT}/skills/protheus-reference/releases.md` e compare o terceiro componente como inteiro. Se a release declarada for menor que o mínimo, avise o usuário e proponha a alternativa; continue apenas com a escolha dele:

- Rotina Smart X nativa (`generate`): exige a release 12.1.2510. Abaixo dela, avise e proponha manter a rotina em MVC/ADVPL.
- Conversão de browse legado e campo "Valid Smart X" (`migrate`): exigem a release 12.1.2610 em ambiente produtivo (desenvolvimento interno: RPO D-1). Abaixo dela, avise e proponha manter o fonte legado.

Se o conteúdo, após remover espaços em branco, não for `12.1.N` com N só dígitos (vazio, várias linhas, `12.1`, não numérico), ignore o arquivo, avise o usuário e siga como se ele não existisse.

Se o arquivo não existir, siga normalmente e acrescente uma linha sugerindo criar `.protheus-version` com a release do Protheus.

### Modo `generate`

1. **Carregar referência base** — Ler `${CLAUDE_PLUGIN_ROOT}/skills/smartx-development/reference.md`, `${CLAUDE_PLUGIN_ROOT}/skills/smartx-development/patterns-model.md`, `${CLAUDE_PLUGIN_ROOT}/skills/smartx-development/patterns-interface.md` e `${CLAUDE_PLUGIN_ROOT}/skills/smartx-development/patterns-launcher-browse.md`
2. **Carregar integração ADVPL (condicional)** — Se a descrição mencionar ponto de entrada ou reaproveitamento de função ADVPL existente, ler também `${CLAUDE_PLUGIN_ROOT}/skills/smartx-development/patterns-advpl-integration.md`
3. **Delegar ao agent `code-generator`** — Gerar os fontes respeitando:
   - Namespace `custom.<agrupador>.<servico>` em todos os arquivos TLPP
   - Separação clara entre `model.tlpp` (regras de negócio/persistência), `interface.tlpp` (definição de campos e layout) e o launcher (browse/entrada da rotina)
   - Hungarian notation, tratamento de erros e demais convenções do `${CLAUDE_PLUGIN_ROOT}/skills/advpl-code-generation/reference.md`

### Modo `migrate`

1. **Carregar referência base** — Ler `${CLAUDE_PLUGIN_ROOT}/skills/smartx-development/reference.md`, `${CLAUDE_PLUGIN_ROOT}/skills/smartx-development/patterns-migration.md`, `${CLAUDE_PLUGIN_ROOT}/skills/smartx-development/troubleshooting.md` e `${CLAUDE_PLUGIN_ROOT}/skills/advpl-to-tlpp-migration/gap-report.md` (modelo do relatório de lacunas)
2. **Analisar rotina de origem** — Identificar se a origem é mBrowse, AxCadastro ou MVC (ModelDef/ViewDef/MenuDef) para mapear a estratégia de conversão
3. **Delegar ao agent `migrator`** — Converter a rotina para a estrutura Smart X equivalente, preservando regras de negócio e apontando riscos/pontos de atenção da migração
4. **Entregar o relatório de lacunas (obrigatório)** — Junto com os fontes, a tabela `Item | Situação | Motivo | Ação` do `${CLAUDE_PLUGIN_ROOT}/skills/advpl-to-tlpp-migration/gap-report.md` (situação `migrado`, `não migrável` ou `mantido no legado`), com o checklist geral daquele arquivo e as linhas do "Passo 9 — Relatório de lacunas" de `${CLAUDE_PLUGIN_ROOT}/skills/smartx-development/patterns-migration.md`

## Mapeamento --mode → arquivos

| Modo | Arquivos gerados/afetados |
|------|---------------------------|
| `generate` | `model.tlpp` (regras de negócio e persistência), `interface.tlpp` (metadados de campos e layout), launcher (browse/entrada da rotina) |
| `migrate` | `model.tlpp` e `interface.tlpp` convertidos a partir da rotina de origem (mBrowse/AxCadastro/MVC), launcher atualizado, relatório de lacunas obrigatório (formato do `gap-report.md`) |

## Exemplos

```bash
# Gerar uma nova rotina Smart X de cadastro de clientes
/advpl-specialist:smartx --mode generate
Cadastro de clientes com campos código, nome, CNPJ e status.

# Inferir o modo automaticamente a partir da descrição
/advpl-specialist:smartx
Preciso migrar o cadastro atual em MVC MATA030 para Smart X.

# Migrar uma rotina existente explicitamente
/advpl-specialist:smartx --mode migrate
Converter o mBrowse de pedidos de compra para Smart X.

# Salvar em caminho específico
/advpl-specialist:smartx --mode generate --output src/smartx/clientes
```
