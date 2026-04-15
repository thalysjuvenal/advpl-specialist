# Changelog

All notable changes to this project will be documented in this file.
Todas as mudancas notaveis deste projeto serao documentadas neste arquivo.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-04-14

### Changed / Alterado
- Skills are now internal references — no longer appear as duplicate entries in the Claude Code skills list. Users interact exclusively through the 12 commands (`/advpl-specialist:*`). Agents and commands now load reference files directly via `Read` instead of the `Skill` tool.
- Skills agora sao referencias internas — nao aparecem mais como entradas duplicadas na lista de skills do Claude Code. Usuarios interagem exclusivamente pelos 12 comandos (`/advpl-specialist:*`). Agents e commands agora carregam arquivos de referencia diretamente via `Read` em vez da ferramenta `Skill`.
- Renamed `SKILL.md` to `reference.md` in all 14 skill directories to prevent auto-discovery by Claude Code plugin system
- Renomeado `SKILL.md` para `reference.md` em todos os 14 diretorios de skills para impedir auto-discovery pelo sistema de plugins do Claude Code
- Removed `Skill` from `allowed-tools` in all 12 command frontmatters
- Removido `Skill` de `allowed-tools` em todos os 12 frontmatters de commands
- Updated all 10 agent files to use `Read` for loading reference files instead of `Skill` tool
- Atualizados todos os 10 arquivos de agents para usar `Read` no carregamento de referencias em vez da ferramenta `Skill`
- Renamed README "Skills" section to "Referencia Interna" with clarification that references are loaded automatically by agents/commands
- Renomeada secao "Skills" do README para "Referencia Interna" com esclarecimento de que referencias sao carregadas automaticamente por agents/commands
- Added `tdn-lookup` reference to README (was missing from the skills table since v1.0.9)
- Adicionada referencia `tdn-lookup` ao README (estava faltando na tabela de skills desde v1.0.9)

### Added / Adicionado
- Field Name Validation guardrail: agent now validates SX3 field names against 3 confirmed sources (local reference examples, user prompt, TDN lookup) before emitting any `ALIAS_CAMPO` identifier. When uncertain, asks the user or generates a `cx*` placeholder variable with `// TODO: confirmar campo no SX3`
- Guardrail de validacao de nomes de campos: agent agora valida nomes de campos SX3 contra 3 fontes confirmadas (exemplos em referencias locais, prompt do usuario, busca TDN) antes de emitir qualquer identificador `ALIAS_CAMPO`. Quando incerto, pergunta ao usuario ou gera variavel placeholder `cx*` com `// TODO: confirmar campo no SX3`

## [1.0.9] - 2026-04-13

### Added / Adicionado
- Automatic plan persistence: all 8 agents with planning/generation phases now save approved plans to `docs/plans/YYYY-MM-DD-<command>-<description>.md` automatically after user approval
- Persistencia automatica de planos: todos os 8 agents com fases de planejamento/geracao agora salvam os planos aprovados em `docs/plans/YYYY-MM-DD-<comando>-<descricao>.md` automaticamente apos a aprovacao do usuario
- New TDN lookup strategy using Confluence REST API (4-tier online fallback): WebFetch API → Playwright API JSON → WebSearch + Playwright → Playwright visual search — reduces token consumption by 70-90% compared to HTML scraping
- Nova estrategia de busca no TDN usando API REST do Confluence (4 tiers online de fallback): WebFetch API → Playwright API JSON → WebSearch + Playwright → Playwright busca visual — reduz consumo de tokens em 70-90% comparado a scraping de HTML
- Centralized `tdn-lookup` skill replacing duplicated TDN lookup blocks across 8 agents (259 deletions, 133 insertions)
- Skill centralizada `tdn-lookup` substituindo blocos duplicados de busca no TDN em 8 agents (259 delecoes, 133 insercoes)

## [1.0.8] - 2026-04-07

### Fixed / Corrigido
- Fixed code generation using bare `Function` keyword instead of `User Function` in customer RPOs — bare `Function` is reserved for the TOTVS core RPO and fails to compile in customer environments
- Corrigida geracao de codigo usando palavra-chave `Function` pura em vez de `User Function` em RPOs de cliente — palavra-chave `Function` pura e reservada para o RPO core da TOTVS e falha ao compilar em ambientes de cliente
- Fixed `/generate` scanning all project source files on every invocation — the plugin is template-based and does not need to read customer `.prw`/`.tlpp` sources to generate code
- Corrigido `/generate` varrendo todos os arquivos-fonte do projeto a cada invocacao — o plugin e baseado em templates e nao precisa ler fontes `.prw`/`.tlpp` do cliente para gerar codigo

### Added / Adicionado
- Mandatory `namespace custom.<agrupador>.<servico>` declaration for every generated `.tlpp` file (REST endpoints, classes, jobs) — inferred from `--module` + service name, or prompted from user during Planning Phase
- Declaracao obrigatoria de `namespace custom.<agrupador>.<servico>` para todo arquivo `.tlpp` gerado (endpoints REST, classes, jobs) — inferido de `--module` + nome do servico, ou perguntado ao usuario durante a Fase de Planejamento
- New `[BP-009]` code review rule: detects bare `Function` keyword in customer code and suggests conversion to `User Function` / `Static Function` / class `Method`
- Nova regra de revisao `[BP-009]`: detecta palavra-chave `Function` pura em codigo de cliente e sugere conversao para `User Function` / `Static Function` / `Method` de classe
- New `[BP-010]` code review rule: detects identifier names exceeding the effective length limit (User Function ≤ 8 chars, Static Function ≤ 10 chars, TLPP with namespace ≤ 255 chars)
- Nova regra de revisao `[BP-010]`: detecta nomes de identificadores que excedem o limite efetivo de tamanho (User Function ≤ 8 chars, Static Function ≤ 10 chars, TLPP com namespace ≤ 255 chars)
- Blocking identifier length validation in `/generate` Planning Phase with two-option flow: (A) shorten name following Protheus conventions or (B) switch to TLPP with namespace (available from Protheus release 12.1.2410)
- Validacao bloqueante de tamanho de identificador na Fase de Planejamento do `/generate` com fluxo de duas opcoes: (A) encurtar nome seguindo convencoes Protheus ou (B) mudar para TLPP com namespace (disponivel a partir do release 12.1.2410 do Protheus)
- Explicit prohibition of project source scanning in `/generate` — `Glob`/`Grep`/`Read` on customer `.prw`/`.tlpp` files is no longer allowed (only internal plugin files, explicit user-referenced file, or final output write)
- Proibicao explicita de varredura de fontes do projeto no `/generate` — `Glob`/`Grep`/`Read` em arquivos `.prw`/`.tlpp` do cliente nao e mais permitido (apenas arquivos internos do plugin, arquivo unico referenciado pelo usuario, ou escrita do arquivo final)
- Documentation on identifier length limits, `longnameclass` legacy workaround, and TLPP namespace as the modern replacement
- Documentacao sobre limites de tamanho de identificador, workaround legado `longnameclass`, e TLPP com namespace como substituicao moderna

## [1.0.7] - 2026-03-26

### Added / Adicionado
- Complete TDN documentation for 74+ classes and functions across 5 phases in native-functions.md
- Documentacao completa do TDN para 74+ classes e funcoes em 5 fases no native-functions.md
- Phase 1: 9 UI/Browse classes (FwBrowse, FWMarkBrowse, FWBrwColumn, FWBrwRelation, FWLegend, FWGridProcess, tNewProcess, FWCalendar, FWSimpEdit)
- Fase 1: 9 classes UI/Browse (FwBrowse, FWMarkBrowse, FWBrwColumn, FWBrwRelation, FWLegend, FWGridProcess, tNewProcess, FWCalendar, FWSimpEdit)
- Phase 2: 20 daily utility functions (FwGetArea, FwRestArea, FwGetUserName, UsrRetName, FWMsgRun, FWInputBox, FWFreeObj, FWFreeVar, Fw8601ToDate, FWDateTo8601, FWHttpEncode, FWURIDecode, MayIUseCode, MPCriaNumS, MsGetDAuto, SaveInter, RestInter, FWX3Titulo, FWX2CHAVE, FWX2Unico)
- Fase 2: 20 funcoes utilitarias de uso diario (FwGetArea, FwRestArea, FwGetUserName, UsrRetName, FWMsgRun, FWInputBox, FWFreeObj, FWFreeVar, Fw8601ToDate, FWDateTo8601, FWHttpEncode, FWURIDecode, MayIUseCode, MPCriaNumS, MsGetDAuto, SaveInter, RestInter, FWX3Titulo, FWX2CHAVE, FWX2Unico)
- Phase 3: 8 security/authentication classes (FWoAuth2Client, FWoAuth2Url, FWSafeVault, FWSecretVault, FwProtectedDataUtil, FwPDFieldRepository, FwPDFieldDetailRepository, FwPDGroupRepository)
- Fase 3: 8 classes de seguranca/autenticacao (FWoAuth2Client, FWoAuth2Url, FWSafeVault, FWSecretVault, FwProtectedDataUtil, FwPDFieldRepository, FwPDFieldDetailRepository, FwPDGroupRepository)
- Phase 4: 12 company/branch and scheduling functions (FWLoadSM0, FWModeAccess, FwListBranches, FWJoinFilial, FwCallApp, FWSchdAvaiable, FWSchdByFunction, FWSchdEmpFil, FwExecLocaliz, FwExistLocaliz, FwBranAltInf, FwComAltInf)
- Fase 4: 12 funcoes de empresa/filial e scheduling (FWLoadSM0, FWModeAccess, FwListBranches, FWJoinFilial, FwCallApp, FWSchdAvaiable, FWSchdByFunction, FWSchdEmpFil, FwExecLocaliz, FwExistLocaliz, FwBranAltInf, FwComAltInf)
- Phase 5: 25+ niche classes and functions (FwChartFactory, XTree, ApWizard, FWCarolWizard, FWMsPrinter, PrinterVersion, FWBulk, FWQueryCache, FWExecCachedQuery, FWSX9Util, FWSM0Util, FWSXGUtil, FWUIWorkarea, MSProject, TKeyboard, FWBmpRep, MPFilesBinary, AddMashupAlias, AmIIn, ChkAdvplSyntax, MakeSqlExpr, PesqBrw)
- Fase 5: 25+ classes e funcoes de nicho (FwChartFactory, XTree, ApWizard, FWCarolWizard, FWMsPrinter, PrinterVersion, FWBulk, FWQueryCache, FWExecCachedQuery, FWSX9Util, FWSM0Util, FWSXGUtil, FWUIWorkarea, MSProject, TKeyboard, FWBmpRep, MPFilesBinary, AddMashupAlias, AmIIn, ChkAdvplSyntax, MakeSqlExpr, PesqBrw)
- Google Analytics 4 integration in documentation site
- Integracao do Google Analytics 4 no site de documentacao
- Daily traffic metrics collection workflow
- Workflow de coleta diaria de metricas de trafego

### Fixed / Corrigido
- Fixed code generation creating non-existent JsonObject methods for case-insensitive header iteration — now uses `GetNames()` + `Upper()` pattern (thanks [@edusfc15](https://github.com/edusfc15) for reporting [#3](https://github.com/thalysjuvenal/advpl-specialist/issues/3))
- Corrigida geracao de codigo criando metodos inexistentes do JsonObject para iteracao case-insensitive de headers — agora usa padrao `GetNames()` + `Upper()` (obrigado [@edusfc15](https://github.com/edusfc15) por reportar [#3](https://github.com/thalysjuvenal/advpl-specialist/issues/3))
- Updated rules count from 24 to 24 and registered corrections in CHANGELOG
- Atualizada contagem de regras e registradas correcoes no CHANGELOG
- Moved all Local declarations to function headers
- Movidas todas as declaracoes Local para o topo das funcoes

## [1.0.6] - 2026-03-23

### Added / Adicionado
- New `[BP-002]` code review rule: detects `Local` variable declarations outside the function header (inside If/While/For blocks or after executable statements)
- Nova regra de revisao `[BP-002]`: detecta declaracoes de variaveis `Local` fora do cabecalho da funcao (dentro de blocos If/While/For ou apos statements executaveis)
- Complete `TWsdlManager` class documentation in native-functions.md (11 methods + properties, validated against TDN)
- Documentacao completa da classe `TWsdlManager` em native-functions.md (11 metodos + propriedades, validados contra o TDN)
- Critical sections in code-generator agent for `JsonObject`, `TWsdlManager`, and `FWFormView` method validation
- Secoes criticas no agente code-generator para validacao de metodos de `JsonObject`, `TWsdlManager` e `FWFormView`
- New `[BP-008]` code review rule: detects usage of reserved system variables (`cFilial`, `cFilAnt`, `cEmpAnt`) as Local/Static variables, with recommended alternatives (`cCodFil`, `cCodEmp`)
- Nova regra de revisao `[BP-008]`: detecta uso de variaveis reservadas do sistema (`cFilial`, `cFilAnt`, `cEmpAnt`) como Local/Static, com alternativas recomendadas (`cCodFil`, `cCodEmp`)
- New `[SEC-005]` security rule: detects usage of 195+ TOTVS restricted/internal functions, classes, and variables with supported alternatives
- Nova regra de seguranca `[SEC-005]`: detecta uso de 195+ funcoes, classes e variaveis restritas/internas da TOTVS com alternativas suportadas
- New `restricted-functions.md` reference file with complete list of TOTVS internal-property functions (source: Central de Atendimento TOTVS)
- Novo arquivo de referencia `restricted-functions.md` com lista completa de funcoes de propriedade interna da TOTVS (fonte: Central de Atendimento TOTVS)
- New `Company/Branch Management Functions (FW*)` section in native-functions.md with 10 documented functions: `FWCodFil`, `FWCodEmp`, `FWFilial`, `FWCompany`, `FWGrpCompany`, `FWUnitBusiness`, `FWAllCompany`, `FWAllFilial`, `FWAllGrpCompany`, `FWSizeFilial`
- Nova secao `Company/Branch Management Functions (FW*)` em native-functions.md com 10 funcoes documentadas: `FWCodFil`, `FWCodEmp`, `FWFilial`, `FWCompany`, `FWGrpCompany`, `FWUnitBusiness`, `FWAllCompany`, `FWAllFilial`, `FWAllGrpCompany`, `FWSizeFilial`

### Fixed / Corrigido
- Removed fabricated `GetSoapFault()` method from TWsdlManager patterns — SOAP faults accessed via properties (`cFaultCode`, `cFaultString`)
- Removido metodo fabricado `GetSoapFault()` dos padroes TWsdlManager — SOAP faults acessados via propriedades (`cFaultCode`, `cFaultString`)
- Removed fabricated `ListServices()` method from TWsdlManager patterns — use `SetPort()` + `ListOperations()`
- Removido metodo fabricado `ListServices()` dos padroes TWsdlManager — usar `SetPort()` + `ListOperations()`
- Fixed `EnableTitleGroup` → `EnableTitleView` in MVC and FWFormBrowse patterns (EnableTitleGroup does not exist)
- Corrigido `EnableTitleGroup` → `EnableTitleView` nos padroes MVC e FWFormBrowse (EnableTitleGroup nao existe)
- Moved all `Local` variable declarations to function headers across 15+ code examples in patterns-rest.md, templates-classes.md
- Movidas todas as declaracoes de variaveis `Local` para o cabecalho das funcoes em 15+ exemplos de codigo em patterns-rest.md, templates-classes.md
- Updated rules count from 23 to 24 in README
- Atualizada contagem de regras de 23 para 24 no README
- Replaced `cFilial` with `cCodFil` and `cEmpresa` with `cCodEmp` in all code examples (reserved Private variable names must not be used as Local variables)
- Substituido `cFilial` por `cCodFil` e `cEmpresa` por `cCodEmp` em todos os exemplos de codigo (nomes de variaveis Private reservadas nao podem ser usados como variaveis Local)
- Updated `StaticCall()` documentation to reflect compilation blocked status since release 12.1.33
- Atualizada documentacao do `StaticCall()` para refletir status de compilacao bloqueada desde a release 12.1.33
- Added warnings about reserved variables in `xFilial()` and `RpcSetEnv()` documentation
- Adicionados avisos sobre variaveis reservadas na documentacao de `xFilial()` e `RpcSetEnv()`

## [1.0.5] - 2026-03-18

### Fixed / Corrigido
- Replaced direct SX dictionary access (`DbSelectArea("SX1/SX2/SX3/SX5/SX6/SIX")`) with recommended TOTVS framework classes: `FWSX1Util`, `FWSX2Util`, `FWSX3Util`, `FWSX6Util`, `FWSIXUtil`, `FWGetSX5()`, `FwPutSX5()` (thanks [@wesleywwf](https://github.com/wesleywwf) for reporting [#1](https://github.com/thalysjuvenal/advpl-specialist/issues/1))
- Substituido acesso direto aos dicionarios SX (`DbSelectArea("SX1/SX2/SX3/SX5/SX6/SIX")`) pelas classes recomendadas pela TOTVS: `FWSX1Util`, `FWSX2Util`, `FWSX3Util`, `FWSX6Util`, `FWSIXUtil`, `FWGetSX5()`, `FwPutSX5()` (obrigado [@wesleywwf](https://github.com/wesleywwf) por reportar [#1](https://github.com/thalysjuvenal/advpl-specialist/issues/1))

### Added / Adicionado
- TOTVS disclaimer in documentation site footer (no affiliation with TOTVS S.A.)
- Disclaimer TOTVS no rodape do site de documentacao (sem vinculo com a TOTVS S.A.)
- OG image for social media sharing preview (1200x630px)
- Imagem OG para preview de compartilhamento em redes sociais (1200x630px)
- Portuguese (pt-BR) translations for Fumadocs UI (search, TOC, navigation, theme)
- Traducoes em portugues (pt-BR) para a UI do Fumadocs (pesquisa, sumario, navegacao, tema)
- Translated all 10 agent documentation pages to Portuguese
- Traduzidas todas as 10 paginas de documentacao de agentes para portugues

## [1.0.4] - 2026-03-17

### Added / Adicionado
- New `/explain` command for code explanation at 3 audience levels (junior, senior, functional)
- Novo comando `/explain` para explicacao de codigo em 3 niveis de audiencia (junior, senior, funcional)
- New `/refactor` command with `refactorer` agent and `advpl-refactoring` skill (6 refactoring patterns with before/after)
- Novo comando `/refactor` com agent `refactorer` e skill `advpl-refactoring` (6 padroes de refatoracao com before/after)
- New `/document` command with `doc-generator` agent and `documentation-patterns` skill (Protheus.doc header, full docs, API docs)
- Novo comando `/document` com agent `doc-generator` e skill `documentation-patterns` (cabecalho Protheus.doc, documentacao completa, documentacao de API)
- New `/changelog` command with `changelog-generator` agent and `changelog-patterns` skill
- Novo comando `/changelog` com agent `changelog-generator` e skill `changelog-patterns`
- New `/sxgen` command with `sx-configurator` agent and `sx-configuration` skill (SX3, SIX, SX1, SX5, SX7 dictionary scripts from natural language)
- Novo comando `/sxgen` com agent `sx-configurator` e skill `sx-configuration` (scripts de dicionario SX3, SIX, SX1, SX5, SX7 a partir de linguagem natural)
- New `code-explanation` skill with 3-level methodology for explaining code
- Nova skill `code-explanation` com metodologia de 3 niveis para explicacao de codigo
- Documentation website built with Fumadocs (Next.js + MDX) deployed on GitHub Pages
- Site de documentacao construido com Fumadocs (Next.js + MDX) hospedado no GitHub Pages
- Full documentation covering all 12 commands, 10 agents, 14 skills, reference and business processes
- Documentacao completa cobrindo todos os 12 comandos, 10 agentes, 14 skills, referencia e processos de negocio

### Fixed / Corrigido
- Removed unsupported `bugs` key from plugin.json manifest
- Removida chave `bugs` nao suportada do manifesto plugin.json

## [1.0.3] - 2026-03-11

### Added / Adicionado
- New `/review` command for code quality analysis (best practices, performance, security, modernization)
- Novo comando `/review` para analise de qualidade de codigo (boas praticas, performance, seguranca, modernizacao)
- New `/test` command for ProBat unit test generation (TLPP only)
- Novo comando `/test` para geracao de testes unitarios ProBat (apenas TLPP)
- New `/process` command for ERP business process consultation
- Novo comando `/process` para consulta de processos de negocio ERP
- New `code-reviewer` agent for ADVPL/TLPP code analysis with 21 review rules
- Novo agent `code-reviewer` para analise de codigo ADVPL/TLPP com 21 regras de revisao
- New `process-consultant` agent for ERP business processes
- Novo agent `process-consultant` para processos de negocio ERP
- New `advpl-code-review` skill with 4 rule categories (BP, PERF, SEC, MOD)
- Nova skill `advpl-code-review` com 4 categorias de regras (BP, PERF, SEC, MOD)
- New `probat-testing` skill with ProBat API reference and unit test patterns (TDN-validated)
- Nova skill `probat-testing` com referencia ProBat API e padroes de testes unitarios (validado no TDN)
- New `protheus-business` skill with 8 ERP module references (COM, EST, FAT, FIN, CTB, FIS, PCP, MNT)
- Nova skill `protheus-business` com referencia de 8 modulos ERP (COM, EST, FAT, FIN, CTB, FIS, PCP, MNT)
- 4 new code generation patterns: TReport, FWFormBrowse, Jobs/Scheduler, Workflow/BPM
- 4 novos padroes de geracao de codigo: TReport, FWFormBrowse, Jobs/Scheduler, Workflow/BPM
- 16 new TDN-validated native functions (TReport, FWFormBrowse, Jobs, Email classes)
- 16 novas funcoes nativas validadas no TDN (TReport, FWFormBrowse, Jobs, classes de Email)
- 93 MV_* parameters validated across 8 modules via TDN and Terminal de Informacao
- 93 parametros MV_* validados em 8 modulos via TDN e Terminal de Informacao
- ProBat annotations validated via official TOTVS tlpp-probat-samples repository
- Anotacoes ProBat validadas via repositorio oficial TOTVS tlpp-probat-samples

### Fixed / Corrigido
- Removed 90+ fabricated MV_* parameters from business module skills
- Removidos 90+ parametros MV_* fabricados das skills de modulos de negocio
- Fixed incorrect parameter names (MV_ESTNEGA→MV_ESTNEG, MV_SPESSION→MV_USASPED, etc.)
- Corrigidos nomes de parametros incorretos (MV_ESTNEGA→MV_ESTNEG, MV_SPESSION→MV_USASPED, etc.)
- Removed fabricated SC2 table fields (C2_TESSION/C2_TESSION2) from PCP skill
- Removidos campos fabricados da tabela SC2 (C2_TESSION/C2_TESSION2) da skill PCP

## [1.0.2] - 2026-03-09

### Added / Adicionado
- Playwright MCP fallback for all web documentation access (agents: docs-reference, debugger, code-generator; skill: protheus-reference)
- Fallback via Playwright MCP para todo acesso web a documentacao (agents: docs-reference, debugger, code-generator; skill: protheus-reference)
- When WebSearch or WebFetch fails, agents now fall back to Playwright browser tools (browser_navigate, browser_snapshot, browser_take_screenshot)
- Quando WebSearch ou WebFetch falham, os agents agora utilizam as ferramentas Playwright como fallback (browser_navigate, browser_snapshot, browser_take_screenshot)
- Hybrid approach: tries text snapshot first, falls back to screenshot for complex visual content
- Abordagem hibrida: tenta snapshot de texto primeiro, usa screenshot para conteudo visual complexo
- Playwright MCP installation recommendation in session-start hook
- Recomendacao de instalacao do Playwright MCP no hook session-start

## [1.0.1] - 2026-03-05

### Added / Adicionado
- SOAP Web Service patterns (`patterns-soap.md`) with WsService and TWsdlManager
- Padroes de Web Service SOAP (`patterns-soap.md`) com WsService e TWsdlManager
- Superpowers plugin recommendation in session-start hook and README
- Recomendacao do plugin superpowers no hook session-start e README
- Planning mode enforcement for `generate` and `migrate` commands
- Modo planejamento obrigatorio para os comandos `generate` e `migrate`
- 50+ indicator in session-start hook when file count reaches limit
- Indicador 50+ no hook session-start quando a contagem de arquivos atinge o limite
- Official TOTVS TLPP naming conventions from TDN
- Convencoes oficiais de nomenclatura TLPP da TOTVS do TDN
- Language detection in all commands (responds in user's language)
- Deteccao de idioma em todos os comandos (responde no idioma do usuario)
- Embedded SQL skill with BeginSQL/EndSQL patterns and macros
- Skill de Embedded SQL com padroes BeginSQL/EndSQL e macros

### Fixed / Corrigido
- Replaced all obsolete `#Include "Protheus.ch"` with `#Include "TOTVS.CH"` across 10 files
- Substituido o obsoleto `#Include "Protheus.ch"` por `#Include "TOTVS.CH"` em 10 arquivos
- Corrected TLPP includes to use `.th` files (`tlpp-core.th`, `tlpp-rest.th`) instead of `TOTVS.CH`
- Corrigido includes TLPP para usar arquivos `.th` (`tlpp-core.th`, `tlpp-rest.th`) em vez de `TOTVS.CH`
- Removed incorrect `using namespace tlpp.*` (`tlpp.core`, `tlpp.rest`, `tlpp.log`, `tlpp.data`) from all examples
- Removido `using namespace tlpp.*` incorreto (`tlpp.core`, `tlpp.rest`, `tlpp.log`, `tlpp.data`) de todos os exemplos
- Fixed migration target to use `.th` includes instead of `TOTVS.CH`
- Corrigido alvo de migracao para usar includes `.th` em vez de `TOTVS.CH`
- Resolved ambiguous text across repository
- Resolvido texto ambiguo em todo o repositorio
- Added missing `Skill` and `Bash` to allowed-tools in all commands
- Adicionado `Skill` e `Bash` faltantes em allowed-tools de todos os comandos
- Fixed Local variable declarations placement in native-functions examples
- Corrigido posicionamento de declaracoes de variaveis Local nos exemplos de native-functions

## [1.0.0] - 2026-03-04

### Added / Adicionado
- Initial release
- Lancamento inicial
- 4 commands: `generate`, `migrate`, `diagnose`, `docs`
- 4 comandos: `generate`, `migrate`, `diagnose`, `docs`
- 4 agents: `code-generator`, `migrator`, `debugger`, `docs-reference`
- 4 agents: `code-generator`, `migrator`, `debugger`, `docs-reference`
- 5 skills: `advpl-code-generation`, `advpl-to-tlpp-migration`, `advpl-debugging`, `embedded-sql`, `protheus-reference`
- 5 skills: `advpl-code-generation`, `advpl-to-tlpp-migration`, `advpl-debugging`, `embedded-sql`, `protheus-reference`
- SessionStart hook with automatic ADVPL/TLPP project detection
- Hook SessionStart com deteccao automatica de projeto ADVPL/TLPP
- 165+ native functions documented
- 165+ funcoes nativas documentadas
- 9 SX tables reference
- Referencia de 9 tabelas SX
- REST API patterns (FWRest and WsRestFul)
- Padroes de REST API (FWRest e WsRestFul)
- 50 common errors with cause and solution
- 50 erros comuns com causa e solucao
- 10 performance optimization categories
- 10 categorias de otimizacao de performance
- 16 most-used entry points by module
- 16 pontos de entrada mais usados por modulo
- TLPP class templates (Service, Repository, DTO)
- Templates de classes TLPP (Service, Repository, DTO)
- Complete MVC patterns (MenuDef, ModelDef, ViewDef, FWMVCRotAuto)
- Padroes MVC completos (MenuDef, ModelDef, ViewDef, FWMVCRotAuto)
- Marketplace support via `marketplace.json`
- Suporte ao Marketplace via `marketplace.json`
