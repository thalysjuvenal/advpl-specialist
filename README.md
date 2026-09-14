# advpl-specialist

![Version](https://img.shields.io/badge/version-1.5.1-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-Claude%20Code-blueviolet)
![TOTVS](https://img.shields.io/badge/TOTVS-Protheus-orange)
![ADVPL](https://img.shields.io/badge/lang-ADVPL%20%7C%20TLPP-yellow)
[![skills.sh](https://skills.sh/b/thalysjuvenal/advpl-specialist)](https://skills.sh/thalysjuvenal/advpl-specialist)

Plugin para Claude Code especializado em **ADVPL** e **TLPP** para desenvolvimento no ecossistema **TOTVS Protheus** — para **desenvolvedores** e **consultores funcionais**.

**Documentacao completa:** [https://thalysjuvenal.github.io/advpl-specialist](https://thalysjuvenal.github.io/advpl-specialist)

## Indice

- [Quick Start](#quick-start)
- [Funcionalidades](#funcionalidades)
- [Instalacao](#instalacao)
- [Uso com Copilot, Cursor, Gemini e outras IAs](#uso-com-copilot-cursor-gemini-e-outras-ias)
- [Commands](#commands)
- [Exemplos](#exemplos)
- [Agents](#agents)
- [Referencia Interna](#referencia-interna)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Referencia Embutida](#referencia-embutida)
- [Contribuindo](#contribuindo)
- [Changelog](#changelog)
- [Licenca](#licenca)

## Quick Start

Repositorio: [https://github.com/thalysjuvenal/advpl-specialist](https://github.com/thalysjuvenal/advpl-specialist)

```bash
# 1. Adicione o marketplace do plugin (dentro do Claude Code)
/plugin marketplace add thalysjuvenal/advpl-specialist

# 2. Instale o plugin
/plugin install advpl-specialist@thalysjuvenal-advpl-specialist

# 3. Abra um projeto Protheus e use os comandos
/advpl-specialist:generate function FATA050 --module FAT
/advpl-specialist:diagnose "Variable does not exist: cCodCli"
/advpl-specialist:docs FWExecView
```

## Funcionalidades

### Para Desenvolvedores

- **Geracao de codigo** - Funcoes, classes TLPP, MVC, REST APIs, Web Services, pontos de entrada, TReport, FWMSPrinter (relatorios PDF por coordenadas), FWFormBrowse, Jobs, Workflow
- **Migracao ADVPL -> TLPP** - Conversao de codigo procedural para orientado a objetos
- **Diagnostico de erros** - Analise de erros de compilacao, runtime, performance e locks
- **Revisao de codigo** - Analise com 24 regras de boas praticas, performance, seguranca e modernizacao (inclui deteccao de funcoes restritas da TOTVS e variaveis reservadas do sistema)
- **Testes ProBat** - Geracao de testes unitarios para codigo TLPP
- **Referencia de documentacao** - Funcoes nativas, dicionario SX, APIs REST, parametros MV_*, funcoes FW* de empresa/filial, lista de funcoes restritas da TOTVS
- **Processos de negocio** - Consulta de rotinas, tabelas, integracoes e fluxos de 8 modulos ERP
- **Explicacao de codigo** - Explicacao em linguagem simples com niveis junior, senior e funcional
- **Refatoracao** - Sugestoes de melhoria de estrutura com 6 padroes (RF-001 a RF-006)
- **Documentacao automatica** - Cabecalho Protheus.doc, documentacao completa e documentacao de API
- **Changelog** - Geracao de changelog a partir do git diff com classificacao de impacto
- **Conversao automatica para CP1252** - Todo arquivo ADVPL/TLPP (`.prw`, `.tlpp`, `.prx`, `.ch`, `.prg`, `.apw`, `.aph`, `.tlh`) escrito ou editado pelo plugin e automaticamente convertido para Windows-1252 (CP1252), encoding esperado pelo TOTVS Protheus. Caracteres incompativeis (ex: emojis, kanji) geram um warning visivel e o arquivo permanece em UTF-8 — o plugin nunca bloqueia o fluxo. Requer `iconv` no PATH (presente nativamente em macOS, Linux, WSL e Git Bash).

### Para Consultores Funcionais

- **Explicacao de codigo** - Nivel funcional: entenda customizacoes sem ler codigo
- **Geracao de dicionario SX** - Descreva campos em linguagem natural e gere scripts SX2, SX3, SIX, SXG, SXA, SX1, SX5, SXB e SX7
- **Changelog** - Documento de mudancas pronto para entregar ao cliente

## Instalacao

### Opcao 1: Via Marketplace (recomendado)

Adicione o marketplace e instale o plugin:

```bash
# Dentro do Claude Code, adicione o marketplace
/plugin marketplace add thalysjuvenal/advpl-specialist

# Instale o plugin
/plugin install advpl-specialist@thalysjuvenal-advpl-specialist
```

### Opcao 2: Direto do diretorio local (para teste/desenvolvimento)

Clone o repositorio e inicie o Claude Code com a flag `--plugin-dir`:

```bash
git clone https://github.com/thalysjuvenal/advpl-specialist.git
claude --plugin-dir ./advpl-specialist
```

O plugin detecta automaticamente projetos Protheus (`.prw`, `.tlpp`, `.prx`, `.ch`) ao iniciar uma sessao.

### Recomendado: Playwright MCP

O plugin utiliza o **Playwright MCP** como fallback quando o acesso direto a documentacao (WebSearch/WebFetch) falha. Com ele, o plugin abre a pagina em um navegador real para extrair o conteudo:

```bash
claude mcp add playwright -- npx @anthropic-ai/mcp-playwright@latest
```

### Recomendado: Plugin superpowers

Para uma experiencia completa, recomendamos instalar o plugin oficial **superpowers** que adiciona skills de planejamento, brainstorming, debugging sistematico e code review:

```bash
/plugin marketplace add anthropics/claude-code-plugins
/plugin install superpowers@anthropics-claude-code-plugins
```

## Uso com Copilot, Cursor, Gemini e outras IAs

O `advpl-specialist` tambem funciona fora do Claude Code, em GitHub Copilot, Cursor, Gemini CLI, Codex e mais de 70 agentes de IA.

### Passo 1: Skills (qualquer agente)

```bash
npx skills add thalysjuvenal/advpl-specialist
```

Instala as 19 skills em Copilot CLI, Codex, Cursor, Gemini CLI, OpenCode e 70+ agentes.

### Passo 2: Instrucoes de repositorio

Copie `AGENTS.md`, `.github/copilot-instructions.md` e `CLAUDE.md` para a raiz do SEU repositorio Protheus.

### Passo 3: Comandos (opcional)

Copie a pasta da sua plataforma para o seu repositorio:

- `.github/prompts/` (Copilot — funciona no VS Code/Visual Studio/JetBrains; NAO funciona em github.com nem no coding agent)
- `.cursor/commands/` (Cursor)
- `.gemini/commands/` (Gemini CLI)

**Nota Codex:** coberto por `AGENTS.md` + skills (os custom prompts do Codex estao deprecated; as skills ficam em `.agents/skills/` no projeto).

**Nota manutencao:** os comandos sao gerados a partir de `ai-commands/src/` via `node scripts/build-ai-commands.mjs` — nao edite as saidas manualmente.

## Commands

| Comando | Descricao |
|---------|-----------|
| `/advpl-specialist:generate` | Gerar codigo ADVPL/TLPP (funcoes, classes, MVC, REST, PE, TReport, FWFormBrowse, Jobs, Workflow) |
| `/advpl-specialist:migrate` | Migrar codigo ADVPL procedural para TLPP orientado a objetos |
| `/advpl-specialist:diagnose` | Diagnosticar erros e problemas em codigo ADVPL/TLPP |
| `/advpl-specialist:docs` | Consultar documentacao de funcoes, APIs e dicionario Protheus |
| `/advpl-specialist:review` | Revisar codigo ADVPL/TLPP (boas praticas, performance, seguranca, modernizacao) |
| `/advpl-specialist:test` | Gerar testes unitarios ProBat para codigo TLPP |
| `/advpl-specialist:process` | Consultar processos de negocio, rotinas e integracoes entre modulos |
| `/advpl-specialist:explain` | Explicar codigo em linguagem simples (nivel junior, senior ou funcional) |
| `/advpl-specialist:refactor` | Sugerir refatoracoes de estrutura sem mudar comportamento |
| `/advpl-specialist:document` | Gerar documentacao tecnica automatica (header, full, api) |
| `/advpl-specialist:changelog` | Gerar changelog formatado a partir do git diff |
| `/advpl-specialist:sxgen` | Gerar scripts de dicionario SX a partir de descricao em linguagem natural |
| `/advpl-specialist:advpr` | Gerar scripts de automacao de testes ADVPR (Advanced Protheus Robot) - TestSuite/TestGroup/TestCase para MVC, ExecAuto, relatorios, processamento, webservice, Smart View, TOTVS Message e SmartLink |
| `/advpl-specialist:smartx` | Gerar ou migrar rotinas Smart X (telas web modernas a partir de metadados) - modelo, interface e launcher TLPP; conversao de mBrowse/FWMBrowse/MVC para Smart X |
| `/advpl-specialist:smartview` | Gerar ou migrar objetos de negocio Smart View (Integrated Provider) - classe TLPP com getSchema/getData, fonte de menu callTReports e roteiro de publicacao do recurso .trp |

### Exemplos

```bash
# Gerar uma User Function para o modulo de faturamento
/advpl-specialist:generate function FATA050 --module FAT

# Gerar uma classe TLPP
/advpl-specialist:generate class PedidoService

# Gerar estrutura MVC completa
/advpl-specialist:generate mvc CadProduto --module EST

# Migrar arquivo ADVPL para TLPP
/advpl-specialist:migrate src/FATA001.prw

# Diagnosticar um erro
/advpl-specialist:diagnose "Variable does not exist: cCodCli"

# Consultar documentacao de funcao
/advpl-specialist:docs FWExecView

# Explicar codigo para consultor funcional
/advpl-specialist:explain src/MATA461.prw --level funcional

# Sugerir refatoracoes
/advpl-specialist:refactor src/FATA001.prw

# Gerar documentacao completa
/advpl-specialist:document src/MATA461.prw --type full

# Gerar changelog desde uma data
/advpl-specialist:changelog --since 2026-03-01 --format markdown

# Gerar script de dicionario SX3
/advpl-specialist:sxgen --type sx3

# Gerar script de teste ADVPR para rotina MVC
/advpl-specialist:advpr --type mvc "incluir prospect TMKA260"

# Gerar rotina Smart X (modelo + interface + launcher)
/advpl-specialist:smartx --mode generate "cadastro de produtos SB1"
```

## Exemplos

Consulte a pasta [examples/](examples/) para seis cenarios end-to-end prontos para executar, com prompts exatos, output esperado e variacoes.

| # | Cenario | Comando principal |
|---|---------|-------------------|
| 01 | Gerar MVC completo para tabela customizada ZA1 | `/advpl-specialist:generate` |
| 02 | Migrar ADVPL procedural (FATA001) para TLPP | `/advpl-specialist:migrate` |
| 03 | Diagnosticar erro de lock infinito em `RecLock` | `/advpl-specialist:diagnose` |
| 04 | Criar endpoint REST em TLPP com namespace | `/advpl-specialist:generate` |
| 05 | Revisar codigo focando em performance | `/advpl-specialist:review` |
| 06 | Gerar dicionario SX3 + SIX + SX1 para nova tabela | `/advpl-specialist:sxgen` |

## Agents

| Agent | Descricao |
|-------|-----------|
| `code-generator` | Gera codigo ADVPL/TLPP seguindo convencoes e boas praticas |
| `migrator` | Converte codigo procedural ADVPL para TLPP com classes e namespaces |
| `debugger` | Diagnostica erros de compilacao, runtime, performance e locks |
| `docs-reference` | Consulta referencia local + TDN para funcoes, tabelas SX e APIs |
| `code-reviewer` | Analisa codigo existente para boas praticas, performance, seguranca e modernizacao |
| `process-consultant` | Consulta processos de negocio, rotinas, tabelas e integracoes entre modulos |
| `refactorer` | Analisa codigo e sugere refatoracoes de estrutura com before/after |
| `doc-generator` | Gera documentacao tecnica automatica a partir do codigo-fonte |
| `changelog-generator` | Analisa git diff e gera changelog formatado com classificacao de impacto |
| `sx-configurator` | Gera scripts de dicionario SX a partir de descricao em linguagem natural |

## Referencia Interna

Os agents e commands carregam automaticamente bases de conhecimento internas (`skills/*/reference.md`) conforme necessario. Estas referencias nao aparecem como skills invocaveis — o usuario interage exclusivamente pelos [Commands](#commands) acima.

| Referencia | Descricao |
|------------|-----------|
| `advpl-code-generation` | Padroes e templates para geracao de codigo (MVC, REST, PE, SOAP, TReport, FWFormBrowse, Jobs, Workflow) |
| `advpl-to-tlpp-migration` | Regras de conversao, checklist e exemplos before/after |
| `advpl-debugging` | Top 50 erros comuns, metodologia de debug, dicas de performance |
| `advpl-code-review` | 24 regras de revisao de codigo (boas praticas, performance, seguranca, modernizacao) |
| `probat-testing` | Framework ProBat para testes unitarios TLPP (annotations, assertions, patterns) |
| `advpr-test-automation` | Automacao de testes ADVPR (FWTestHelper): TestSuite/Group/Case, MVC, ExecAuto, relatorios, webservice, SmartLink, Smart View |
| `smartx-development` | Desenvolvimento Smart X: modelo/interface/launcher a partir de metadados, conversao de browse (SetSmartX), pontos de entrada, migracao de legado e troubleshooting |
| `smartview-development` | Objetos de negocio Smart View (Integrated Provider): schema, parametros com lookup e combo, getData, migracao de relatorios (TReport/FWMSPrinter/TMSPrinter/FWMSExcel) e ciclo de publicacao do .trp |
| `protheus-reference` | 190+ funcoes nativas, dicionario SX, referencia REST API, funcoes FW*, lista de funcoes restritas |
| `protheus-business` | 8 modulos ERP com tabelas, rotinas, parametros MV_* e integracoes |
| `embedded-sql` | BeginSQL/EndSQL, macros %table%, %notDel%, %xfilial%, %exp%, column types |
| `query-builder` | Decisao Workarea vs SQL, FWPreparedStatement, consciencia de indices SIX, queries cross-database |
| `protheus-locks-deadlocks` | Semantica de locks (RecLock/MsUnlock/DBAccess), leaks, prevencao (BEGIN SEQUENCE/RECOVER, SoftLock) e diagnostico de deadlocks |
| `code-explanation` | Metodologia de explicacao de codigo com 3 niveis de audiencia |
| `advpl-refactoring` | 6 padroes de refatoracao com before/after e regras de seguranca |
| `documentation-patterns` | Templates para Protheus.doc header, documentacao completa e API REST |
| `changelog-patterns` | Tipos de mudanca, niveis de impacto e formatos markdown/texto |
| `sx-configuration` | Definicoes completas SX2/SX3/SIX/SXG/SXA/SX1/SX5/SXB/SX7 com validacoes e pictures |
| `tdn-lookup` | Estrategia de busca online no TDN via API REST do Confluence (4 tiers) |

## Estrutura do Projeto

```
advpl-specialist/
├── .claude-plugin/
│   ├── plugin.json                # Metadata do plugin
│   └── marketplace.json           # Catalogo do marketplace
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md          # Template para reportar bugs
│   │   └── feature_request.md     # Template para sugestoes
│   └── pull_request_template.md   # Template para PRs
├── agents/                        # 10 agents especializados
│   ├── code-generator.md
│   ├── code-reviewer.md
│   ├── migrator.md
│   ├── debugger.md
│   ├── docs-reference.md
│   ├── process-consultant.md
│   ├── refactorer.md
│   ├── doc-generator.md
│   ├── changelog-generator.md
│   └── sx-configurator.md
├── commands/                      # 15 commands invocaveis
│   ├── generate.md
│   ├── migrate.md
│   ├── diagnose.md
│   ├── docs.md
│   ├── review.md
│   ├── test.md
│   ├── process.md
│   ├── explain.md
│   ├── refactor.md
│   ├── document.md
│   ├── changelog.md
│   ├── sxgen.md
│   ├── advpr.md
│   ├── smartx.md
│   └── smartview.md
├── skills/                        # 19 referencias internas (reference.md + supporting files)
│   ├── advpl-code-generation/     # Padroes MVC, REST, SOAP, PE, TReport, FWFormBrowse, Jobs, Workflow
│   ├── advpl-to-tlpp-migration/   # Regras e checklist de migracao
│   ├── advpl-debugging/           # Erros comuns e performance
│   ├── advpl-code-review/         # 26 regras de revisao + catalogo SonarQube (44 codigos)
│   ├── probat-testing/            # Testes unitarios ProBat (TLPP)
│   ├── advpr-test-automation/     # Automacao de testes ADVPR: FWTestHelper, MVC, ExecAuto, relatorios, webservice, SmartLink, Smart View
│   ├── smartx-development/        # Smart X: modelo/interface/launcher, conversao de browse, PEs, migracao
│   ├── smartview-development/     # Smart View: objeto de negocio, schema, parametros, migracao de relatorios, ciclo do .trp
│   ├── protheus-business/         # 8 modulos ERP (COM, EST, FAT, FIN, CTB, FIS, PCP, MNT)
│   ├── embedded-sql/              # BeginSQL/EndSQL, macros, patterns
│   ├── query-builder/             # Decisao Workarea vs SQL, FWPreparedStatement, indices SIX, cross-DB
│   ├── protheus-locks-deadlocks/  # Locks/deadlocks: semantica, leaks, prevencao e diagnostico
│   ├── protheus-reference/        # 190+ funcoes nativas, SX, REST API, funcoes restritas
│   ├── code-explanation/          # Explicacao de codigo com 3 niveis de audiencia
│   ├── advpl-refactoring/         # 6 padroes de refatoracao com before/after
│   ├── documentation-patterns/    # Templates Protheus.doc, documentacao completa, API
│   ├── changelog-patterns/        # Tipos de mudanca, impacto, formatos
│   ├── sx-configuration/          # Dicionario SX2/SX3/SIX/SXG/SXA/SX1/SX5/SXB/SX7 completo
│   └── tdn-lookup/                # Busca online no TDN via API Confluence
├── hooks/                         # SessionStart hook
│   ├── hooks.json
│   └── session-start
├── CHANGELOG.md                   # Historico de versoes
├── CODE_OF_CONDUCT.md             # Codigo de conduta
├── CONTRIBUTING.md                # Guia de contribuicao
├── LICENSE                        # Licenca MIT
├── SECURITY.md                    # Politica de seguranca
└── README.md
```

## Referencia Embutida

O plugin inclui referencia local para consulta rapida:

- **190+ funcoes nativas** documentadas com sintaxe, parametros e exemplos
- **10 funcoes FW*** de gestao de empresa/filial (FWCodFil, FWCodEmp, FWFilial, FWCompany, etc.)
- **195+ funcoes restritas** da TOTVS catalogadas com alternativas documentadas
- **9 tabelas SX** (SX1-SX9, SIX) com campos e uso programatico, e geracao de scripts para SX2/SX3/SIX/SXG/SXA/SX1/SX5/SXB/SX7
- **REST API patterns** completos para WsRestFul e TLPP annotations
- **50 erros comuns** com causa e solucao
- **10 categorias de otimizacao** de performance com before/after
- **16 pontos de entrada** mais usados por modulo
- **Templates de classes TLPP** (Service, Repository, DTO)
- **MVC completo** com MenuDef, ModelDef, ViewDef e FWMVCRotAuto
- **Embedded SQL** completo com BeginSQL/EndSQL, macros, JOINs, aggregations

Para casos nao cobertos localmente, o plugin busca no TDN (TOTVS Developer Network) automaticamente. Se o acesso ao TDN falhar (timeout, erro ou conteudo vazio), o plugin utiliza o **Playwright MCP** como fallback — abrindo a pagina em um navegador real para extrair a documentacao via snapshot de texto ou captura visual.

## Contribuindo

Contribuicoes sao bem-vindas! Leia o [CONTRIBUTING.md](CONTRIBUTING.md) para saber como participar.

### Contribuidores

Obrigado a quem contribui com o projeto:

- **Henrique Patriota** ([@suportem3](https://github.com/suportem3), M3 Case) — referencia FWMSPrinter para relatorios PDF por coordenadas ([PR #12](https://github.com/thalysjuvenal/advpl-specialist/pull/12)) e referencia de pontos de entrada em rotinas MVC ([PR #13](https://github.com/thalysjuvenal/advpl-specialist/pull/13)).

## Changelog

Veja o [CHANGELOG.md](CHANGELOG.md) para o historico completo de versoes.

## Licenca

[MIT](LICENSE)
