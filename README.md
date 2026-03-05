# advpl-specialist

![Version](https://img.shields.io/badge/version-1.0.1-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-Claude%20Code-blueviolet)
![TOTVS](https://img.shields.io/badge/TOTVS-Protheus-orange)
![ADVPL](https://img.shields.io/badge/lang-ADVPL%20%7C%20TLPP-yellow)

Plugin para Claude Code especializado em **ADVPL** e **TLPP** para desenvolvimento no ecossistema **TOTVS Protheus**.

## Indice

- [Quick Start](#quick-start)
- [Funcionalidades](#funcionalidades)
- [Instalacao](#instalacao)
- [Commands](#commands)
- [Agents](#agents)
- [Skills](#skills)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Referencia Embutida](#referencia-embutida)
- [Contribuindo](#contribuindo)
- [Changelog](#changelog)
- [Licenca](#licenca)

## Quick Start

```bash
# 1. Instale o plugin
/plugin marketplace add thalysjuvenal/advpl-specialist
/plugin install advpl-specialist@thalysjuvenal-advpl-specialist

# 2. Abra um projeto Protheus e use os comandos
/advpl-specialist:generate function FATA050 --module FAT
/advpl-specialist:diagnose "Variable does not exist: cCodCli"
/advpl-specialist:docs FWExecView
```

## Funcionalidades

- **Geracao de codigo** - Funcoes, classes TLPP, MVC, REST APIs, Web Services, pontos de entrada
- **Migracao ADVPL -> TLPP** - Conversao de codigo procedural para orientado a objetos
- **Diagnostico de erros** - Analise de erros de compilacao, runtime, performance e locks
- **Referencia de documentacao** - Funcoes nativas, dicionario SX, APIs REST, parametros MV_*

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

### Plugin recomendado: superpowers

Para uma experiencia completa, recomendamos instalar o plugin oficial **superpowers** que adiciona skills de planejamento, brainstorming, debugging sistematico e code review:

```bash
/plugin marketplace add anthropics/claude-code-plugins
/plugin install superpowers@anthropics-claude-code-plugins
```

## Commands

| Comando | Descricao |
|---------|-----------|
| `/advpl-specialist:generate` | Gerar codigo ADVPL/TLPP (funcoes, classes, MVC, REST, pontos de entrada) |
| `/advpl-specialist:migrate` | Migrar codigo ADVPL procedural para TLPP orientado a objetos |
| `/advpl-specialist:diagnose` | Diagnosticar erros e problemas em codigo ADVPL/TLPP |
| `/advpl-specialist:docs` | Consultar documentacao de funcoes, APIs e dicionario Protheus |

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
```

## Agents

| Agent | Descricao |
|-------|-----------|
| `code-generator` | Gera codigo ADVPL/TLPP seguindo convencoes e boas praticas |
| `migrator` | Converte codigo procedural ADVPL para TLPP com classes e namespaces |
| `debugger` | Diagnostica erros de compilacao, runtime, performance e locks |
| `docs-reference` | Consulta referencia local + TDN para funcoes, tabelas SX e APIs |

## Skills

| Skill | Descricao |
|-------|-----------|
| `advpl-code-generation` | Padroes e templates para geracao de codigo (MVC, REST, pontos de entrada, classes) |
| `advpl-to-tlpp-migration` | Regras de conversao, checklist e exemplos before/after |
| `advpl-debugging` | Top 50 erros comuns, metodologia de debug, dicas de performance |
| `protheus-reference` | 165+ funcoes nativas, dicionario SX, referencia REST API |
| `embedded-sql` | BeginSQL/EndSQL, macros %table%, %notDel%, %xfilial%, %exp%, column types |

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
├── agents/                        # 4 agents especializados
│   ├── code-generator.md
│   ├── migrator.md
│   ├── debugger.md
│   └── docs-reference.md
├── commands/                      # 4 commands invocaveis
│   ├── generate.md
│   ├── migrate.md
│   ├── diagnose.md
│   └── docs.md
├── skills/                        # 5 skills com supporting files
│   ├── advpl-code-generation/     # Padroes MVC, REST, SOAP, PE, classes
│   ├── advpl-to-tlpp-migration/   # Regras e checklist de migracao
│   ├── advpl-debugging/           # Erros comuns e performance
│   ├── embedded-sql/              # BeginSQL/EndSQL, macros, patterns
│   └── protheus-reference/        # Funcoes nativas, SX, REST API
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

- **165+ funcoes nativas** documentadas com sintaxe, parametros e exemplos
- **9 tabelas SX** (SX1-SX9, SIX) com campos e uso programatico
- **REST API patterns** completos para WsRestFul e TLPP annotations
- **50 erros comuns** com causa e solucao
- **10 categorias de otimizacao** de performance com before/after
- **16 pontos de entrada** mais usados por modulo
- **Templates de classes TLPP** (Service, Repository, DTO)
- **MVC completo** com MenuDef, ModelDef, ViewDef e FWMVCRotAuto
- **Embedded SQL** completo com BeginSQL/EndSQL, macros, JOINs, aggregations

Para casos nao cobertos localmente, o plugin busca no TDN (TOTVS Developer Network) automaticamente.

## Contribuindo

Contribuicoes sao bem-vindas! Leia o [CONTRIBUTING.md](CONTRIBUTING.md) para saber como participar.

## Changelog

Veja o [CHANGELOG.md](CHANGELOG.md) para o historico completo de versoes.

## Licenca

[MIT](LICENSE)
