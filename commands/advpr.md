---
description: Gera scripts de teste ADVPR (TestSuite, TestGroup, TestCase) para rotinas MVC, ExecAuto, relatorios, processamento, webservice, Smart View e SmartLink
allowed-tools: Read, Write, Glob, Grep, Agent
argument-hint: "[--type mvc|execauto|report|processing|webservice|smartview|message|smartlink|routine-prep] [--output path]"
---

**IMPORTANT:** Always respond in the same language the user is writing in. If the user writes in Portuguese, respond in Portuguese. If in English, respond in English.

# /advpl-specialist:advpr

Gera scripts de automação de testes ADVPR (Advanced Protheus Robot) para rotinas do TOTVS Protheus.

## Usage

```bash
/advpl-specialist:advpr [options]
```

Descreva em linguagem natural a rotina que deseja testar após o comando. O agente irá interpretar a descrição e gerar os scripts TestSuite, TestGroup e TestCase correspondentes.

## Options

| Flag | Description | Default |
|------|------------|---------|
| `--type` | Tipo de rotina: `mvc`, `execauto`, `report`, `processing`, `webservice`, `smartview`, `message`, `smartlink`, `routine-prep` | Auto-detectar a partir da descrição |
| `--output` | Caminho de saída do arquivo `.prw` gerado | Diretório atual |

## Fluxo

1. **Detectar tipo** — Identificar o `--type` informado ou inferir automaticamente a partir da descrição da rotina (ex.: menção a MVC, ExecAuto, relatório TReport, REST/webservice, Smart View, TOTVS Message, SmartLink ou preparação de rotina)
2. **Carregar referência base** — Ler `${CLAUDE_PLUGIN_ROOT}/skills/advpr-test-automation/reference.md` e `${CLAUDE_PLUGIN_ROOT}/skills/advpr-test-automation/best-practices.md`
3. **Carregar padrão correspondente** — Ler o arquivo `patterns-*` mapeado ao tipo detectado (ver tabela abaixo) e também `${CLAUDE_PLUGIN_ROOT}/skills/advpr-test-automation/api-fwtesthelper.md`
4. **Delegar ao agent `code-generator`** — Gerar os fontes TestSuite/TestGroup/TestCase respeitando:
   - Limite de 25 caracteres no nome da classe (sem sufixo `.prw`); o nome do arquivo `.prw` deve ser idêntico ao nome da classe
   - Proibições de boas práticas: sem `Sleep`, sem acesso direto a tabelas do Protheus via alias dentro do TestCase, sem asserts dentro de Setup/TearDown, sem dependência de ordem entre TestCases
   - Uso correto dos métodos `FWTestHelper` conforme `api-fwtesthelper.md`
   - Estrutura hierárquica obrigatória: TestSuite > TestGroup > TestCase

## Mapeamento --type → arquivo de padrão

| Tipo | Arquivo de padrão |
|------|-------------------|
| `mvc` | `patterns-mvc.md` |
| `execauto` | `patterns-execauto.md` |
| `routine-prep` | `patterns-routine-prep.md` |
| `report` | `patterns-reports.md` |
| `processing` | `patterns-processing.md` |
| `message` | `patterns-totvs-message.md` |
| `webservice` | `patterns-webservice.md` |
| `smartlink` | `patterns-smartlink.md` |
| `smartview` | `patterns-smartview.md` |

## Exemplos

```bash
# Gerar testes para rotina MVC de pedidos de venda
/advpl-specialist:advpr --type mvc
Rotina MVC MATA410 - Pedidos de Venda. Testar inclusão, alteração e exclusão de pedido.

# Gerar testes para ExecAuto de nota fiscal de saída
/advpl-specialist:advpr --type execauto
Automação da MATA461 via ExecAuto para emissão de NF-e de saída.

# Gerar testes para relatório TReport
/advpl-specialist:advpr --type report
Relatório de posição de estoque MATA230 com filtros por filial, produto e data.

# Gerar testes para webservice REST
/advpl-specialist:advpr --type webservice
Endpoint REST de consulta de saldo de estoque. GET /api/v1/estoque/{produto}.

# Inferir tipo automaticamente
/advpl-specialist:advpr
Preciso testar o processamento em batch da rotina FINA080 que atualiza títulos em aberto.

# Salvar em caminho específico
/advpl-specialist:advpr --type mvc --output tests/MATA410Suite.prw
```

## Saída

Um arquivo `.prw` completo e compilável contendo:

- Classe TestSuite com configuração de ambiente (Setup/TearDown)
- Um ou mais TestGroups agrupando cenários relacionados
- TestCases individuais com asserções via `FWTestHelper`
- Nomes de classe e arquivo respeitando o limite de 25 caracteres
- Comentários Protheus.doc em cada método
- Pronto para compilação e execução no ambiente ADVPR
