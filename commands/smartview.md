---
description: Gera ou migra objetos de negocio Smart View (Integrated Provider) - classe TLPP com getSchema/getData, fonte de menu callTReports e roteiro de publicacao do recurso .trp
allowed-tools: Read, Write, Glob, Grep, Agent
argument-hint: "[--mode generate|migrate] [--type data-grid|reports|pivot-table] [--output path]"
---

**IMPORTANT:** Always respond in the same language the user is writing in. If the user writes in Portuguese, respond in Portuguese. If in English, respond in English.

# /advpl-specialist:smartview

Gera um novo objeto de negocio Smart View ou migra um relatorio existente (TReport, FWMSPrinter, TMSPrinter, FWMSExcel) para o Smart View no TOTVS Protheus.

> Smart View e a ferramenta de analise de dados (TReports). Nao confundir com **Smart X**, que sao telas PO-UI geradas por metadados - para Smart X use `/advpl-specialist:smartx`.

## Usage

```bash
/advpl-specialist:smartview [options]
```

Descreva em linguagem natural o relatorio desejado (novo ou existente para migracao) apos o comando.

## Options

| Flag | Description | Default |
|------|------------|---------|
| `--mode` | Modo de operacao: `generate` (novo objeto) ou `migrate` (converter relatorio existente) | Inferir automaticamente: mencoes a fonte existente, TReport, FWMSPrinter, TMSPrinter, FWMSExcel, "converter" ou "migrar" indicam `migrate`; caso contrario `generate` |
| `--type` | Tipo do recurso: `data-grid` (visao de dados), `reports` (relatorio) ou `pivot-table` (tabela dinamica) | `data-grid`; para origem FWMSPrinter/TMSPrinter, sugerir `reports` e confirmar |
| `--output` | Caminho de saida dos fontes gerados | Diretorio atual |

## Fluxo

### Modo `generate`

1. **Carregar referencia base** — Ler `skills/smartview-development/reference.md`, `skills/smartview-development/patterns-schema.md`, `skills/smartview-development/patterns-getdata.md` e `skills/smartview-development/patterns-parameters.md`
2. **Confirmar tabelas e colunas** — Identificar as tabelas de origem e os campos; consultar `skills/sx-configuration/` ou o agent `sx-configurator` quando o dicionario precisar ser validado
3. **Delegar ao agent `code-generator`** — Gerar os fontes respeitando:
   - Nome do fonte no padrao `<area>.sv.<modulo>.<nome>` — e o **id** do objeto, usado no `callTReports` e no prefixo do `.trp`; nao pode mudar depois
   - Namespace terminando em `.treportsintegratedprovider` (exigencia do framework)
   - `#include "totvs.ch"` minusculo nos `.prw`, includes `.th` nos `.tlpp`
   - Consulta estatica em `BeginSQL`; `WHERE` condicional em `FWExecStatement` com bind
   - Datas com tipo `date` e valor por `stringToTimeStamp`
   - Demais convencoes de `skills/advpl-code-generation/reference.md`
4. **Entregar o roteiro de publicacao** — Ler `skills/smartview-development/deploy-trp.md` e incluir o ciclo do `.trp` na resposta; o arquivo `.trp` sai do designer web e **nao e gerado por codigo**

### Modo `migrate`

1. **Carregar referencia base** — Ler `skills/smartview-development/reference.md`, `skills/smartview-development/patterns-migration-reports.md` e `skills/smartview-development/patterns-parameters.md`
2. **Inventariar o fonte de origem** — Extrair colunas, consulta, perguntas (SX1) e regras de negocio; identificar o gerador (TReport, FWMSPrinter, TMSPrinter, FWMSExcel) e decidir o tipo de recurso
3. **Delegar ao agent `migrator`** — Converter para objeto de negocio, apontando explicitamente:
   - O que nao sobrevive (MSDIALOG, telas de marcacao, FWMsgRun, MsgInfo, MakeDir, MsExcel por OLE)
   - Mudanca de escopo de empresa para filial, quando houver
   - Os dois bugs silenciosos: faixas "ate" vazias (usar `TamSX3`) e datas publicadas como texto
4. **Entregar o checklist de homologacao** — Conferencia contra o relatorio original, mesmo periodo e filial, valores ao centavo

## Mapeamento --mode para arquivos

| Modo | Arquivos gerados/afetados |
|------|---------------------------|
| `generate` | `<area>.sv.<modulo>.<nome>.tlpp` (objeto de negocio), fonte de menu `.prw` com `callTReports`, e — quando houver combo — endpoint de opcoes `.tlpp` mais a funcao de opcoes em `.prw` sem namespace |
| `migrate` | Os mesmos fontes, derivados do relatorio de origem, mais o relatorio de/para com pontos de atencao e o checklist de homologacao |

## Exemplos

```bash
# Gerar um novo objeto de negocio
/advpl-specialist:smartview --mode generate
Visao de dados de titulos a receber (SE1) por faixa de vencimento e cliente.

# Inferir o modo automaticamente
/advpl-specialist:smartview
Preciso migrar o ALFATR06, que gera Excel de faturamento em tres abas.

# Migrar explicitamente, escolhendo o tipo de recurso
/advpl-specialist:smartview --mode migrate --type reports
Converter o relatorio de comissoes feito em FWMSPrinter.

# Salvar em caminho especifico
/advpl-specialist:smartview --mode generate --output src/smartview
```

## Saida

- **Modo `generate`**: a classe TLPP com a annotation `@totvsFrameworkTReportsIntegratedProvider`, `new()`, `getSchema()` e `getData()`; o fonte de menu com `callTReports`; e o roteiro de publicacao do `.trp` (exportar, renomear, liberar `.TRP` no TDS, compilar, reiniciar AppServer e servico do Smart View).
- **Modo `migrate`**: os mesmos fontes derivados do relatorio de origem, o de/para coluna a coluna, a lista do que nao tem caminho de conversao (UI e disco do cliente) e o checklist de homologacao contra o original.

Nenhum dos modos gera o arquivo `.trp`: ele e exportado do designer web do Smart View e apenas renomeado e compilado. Ver `skills/smartview-development/deploy-trp.md`.
