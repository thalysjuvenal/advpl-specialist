# Contributing

Obrigado pelo interesse em contribuir com o **advpl-specialist**! Este guia explica como participar do projeto.

## Como contribuir

### Reportar bugs

1. Verifique se o bug ja nao foi reportado em [Issues](https://github.com/thalysjuvenal/advpl-specialist/issues)
2. Crie uma nova issue usando o template **Bug Report**
3. Inclua: versao do plugin, versao do Claude Code, passos para reproduzir, comportamento esperado vs atual

### Sugerir melhorias

1. Crie uma issue usando o template **Feature Request**
2. Descreva o caso de uso e o beneficio para a comunidade ADVPL/TLPP

### Enviar codigo

1. Fork o repositorio
2. Crie uma branch a partir de `main`: `git checkout -b feat/minha-feature`
3. Faca suas alteracoes seguindo as convencoes abaixo
4. Commit com mensagens [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat:` para novas funcionalidades
   - `fix:` para correcoes
   - `docs:` para documentacao
   - `chore:` para tarefas de manutencao
5. Abra um Pull Request usando o template disponivel

## Convencoes do projeto

### Estrutura de arquivos

| Diretorio | Conteudo |
|-----------|----------|
| `commands/` | Comandos invocaveis pelo usuario (`/advpl-specialist:*`) |
| `agents/` | Agents especializados com workflows definidos |
| `skills/` | References com reference.md + arquivos de suporte |
| `hooks/` | Hooks de sessao (bash scripts) |

### Exemplos de codigo ADVPL/TLPP

- Arquivos `.prw` usam `#include "totvs.ch"` em minusculas (nunca `protheus.ch` — `totvs.ch` ja o inclui)
- Arquivos `.tlpp` usam `#include "tlpp-core.th"` (recomendado) e tambem `#include "totvs.ch"` quando usam recursos do framework Protheus (PARAMIXB, MsExecAuto, BeginSQL, MVC...)
- Nenhum `using namespace tlpp.*` nos exemplos (excecao documentada: `using namespace tlpp.probat` em testes ProBat)
- `using namespace` e valido apenas para namespaces custom (ex: `custom.vendas`)
- Variaveis sempre `Local` (nunca `Private`/`Public` em codigo novo)
- Notacao Hungara em todas as variaveis (`cNome`, `nValor`, `lOk`, etc.)

### Markdown

- Frontmatter YAML em commands e agents
- Tabelas para referencia rapida
- Blocos de codigo com linguagem especificada (` ```advpl ` ou ` ```tlpp `)

## Ambiente de desenvolvimento

```bash
# Clone o repositorio
git clone https://github.com/thalysjuvenal/advpl-specialist.git

# Teste localmente com Claude Code
claude --plugin-dir ./advpl-specialist
```

## Runbook de release

Passos para publicar uma nova versao (executados pelo mantenedor, mas documentados para qualquer co-mantenedor futuro):

1. **Alinhar a versao em 6 pontos** (o CI valida): `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (raiz e `plugins[0]`), `documentation/app/page.tsx` (`PLUGIN_VERSION`), badge de versao do `README.md` e badge de `documentation/content/docs/index.mdx`.
2. **Atualizar changelogs**: `CHANGELOG.md` (bilingue EN/PT, padrao Keep a Changelog) e `documentation/content/docs/changelog.mdx` (pt-BR).
3. **Validar localmente**:
   - `bash tests/lint/run-tests.sh` — testes do lint de exemplos
   - `bash scripts/lint-docs.sh skills commands agents AGENTS.md ai-commands` — 0 erros nos blocos ADVPL/TLPP da documentacao (anti-exemplos usam `<!-- advpl-lint: anti-exemplo -->` na ultima linha nao vazia antes da cerca)
   - `node scripts/sync-lint-rules.mjs --check` — regras do lint em sincronia
   - `node scripts/build-ai-commands.mjs --check` — 45 saidas em sincronia com `ai-commands/src/`
   - `npx skills add ./ --list` — 19 skills descobertas
   - `cd documentation && npm run build` — site compila sem erros
4. **Commit e merge**: commits convencionais em branch de feature, merge fast-forward na `main`, push (o workflow `validate-plugin.yml` revalida tudo no CI).
5. **Release no GitHub**: `gh release create vX.Y.Z --title "..." --notes "..."` com notas derivadas do `CHANGELOG.md`. A release mais recente deve ficar marcada como Latest.
6. **Pos-release**: conferir `npx skills add thalysjuvenal/advpl-specialist --list` (descoberta remota) e a pagina https://skills.sh/thalysjuvenal/advpl-specialist.

## Decisoes de arquitetura

Decisoes ja tomadas — nao reabrir sem motivo novo:

- **Sem agents dedicados para `/advpr` e `/smartx` (jul/2026).** Esses comandos reutilizam o agent `code-generator` de proposito: as skills `advpr-test-automation` e `smartx-development` ja concentram todo o conhecimento, e um agent proprio seria uma terceira camada sobre o mesmo conteudo — contra o principio de fonte unica — com valor apenas dentro do Claude Code.
- **`reference.md` + `SKILL.md` coexistem em cada skill.** `reference.md` e a base de conhecimento completa (lida por commands e agents do Claude Code); `SKILL.md` e a porta de entrada fina para outros agentes (Copilot, Cursor, Gemini, Codex via skills.sh). O `SKILL.md` nunca duplica conteudo — apenas descreve a skill e aponta para os arquivos de referencia.

## Licenca

Ao contribuir, voce concorda que suas contribuicoes serao licenciadas sob a [MIT License](LICENSE).
