# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-03-05

### Added
- SOAP Web Service patterns (`patterns-soap.md`) with WsService and TWsdlManager
- Superpowers plugin recommendation in session-start hook
- Superpowers plugin recommendation in README
- Planning mode enforcement for `generate` and `migrate` commands
- 50+ indicator in session-start hook when file count reaches limit
- Official TOTVS TLPP naming conventions from TDN
- Language detection in all commands (responds in user's language)
- Embedded SQL skill with BeginSQL/EndSQL patterns and macros

### Fixed
- Replaced all obsolete `#Include "Protheus.ch"` with `#Include "TOTVS.CH"` across 10 files
- Corrected TLPP includes to use `.th` files (`tlpp-core.th`, `tlpp-rest.th`) instead of `TOTVS.CH`
- Removed incorrect `using namespace tlpp.*` (`tlpp.core`, `tlpp.rest`, `tlpp.log`, `tlpp.data`) from all examples
- Fixed migration target to use `.th` includes instead of `TOTVS.CH`
- Resolved ambiguous text across repository
- Added missing `Skill` and `Bash` to allowed-tools in all commands
- Fixed Local variable declarations placement in native-functions examples

## [1.0.0] - 2026-03-04

### Added
- Initial release
- 4 commands: `generate`, `migrate`, `diagnose`, `docs`
- 4 agents: `code-generator`, `migrator`, `debugger`, `docs-reference`
- 5 skills: `advpl-code-generation`, `advpl-to-tlpp-migration`, `advpl-debugging`, `embedded-sql`, `protheus-reference`
- SessionStart hook with automatic ADVPL/TLPP project detection
- 165+ native functions documented
- 9 SX tables reference
- REST API patterns (FWRest and WsRestFul)
- 50 common errors with cause and solution
- 10 performance optimization categories
- 16 most-used entry points by module
- TLPP class templates (Service, Repository, DTO)
- Complete MVC patterns (MenuDef, ModelDef, ViewDef, FWMVCRotAuto)
- Marketplace support via `marketplace.json`
