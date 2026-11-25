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
| `evals/` | Suite local de evals do plugin (`claude plugin eval`): um `case.yaml` por caso, `fixtures/` de entrada e `lint-outputs.sh` |

### Exemplos de codigo ADVPL/TLPP

- Arquivos `.prw` usam `#include "totvs.ch"` em minusculas (nunca `protheus.ch` — `totvs.ch` ja o inclui)
- Arquivos `.tlpp` usam `#include "tlpp-core.th"` (recomendado) e tambem `#include "totvs.ch"` quando usam recursos do framework Protheus (PARAMIXB, MsExecAuto, BeginSQL, MVC...)
- Nenhum `using namespace tlpp.*` nos exemplos (excecao documentada: `using namespace tlpp.probat` em testes ProBat)
- `using namespace` e valido apenas para namespaces custom (ex: `custom.vendas`)
- Variaveis sempre `Local`; `Private`/`Public` so nas excecoes que o framework exige (as mesmas do `AGENTS.md`): `lMsErroAuto`, `lMsHelpAuto` e `lAutoErrNoFile` (MsExecAuto), `aRotina` e `cCadastro` (rotinas de browse)
- Notacao Hungara em todas as variaveis (`cNome`, `nValor`, `lOk`, etc.)

### Markdown

- Frontmatter YAML em commands e agents
- Tabelas para referencia rapida
- Blocos de codigo com linguagem especificada: ` ```advpl ` ou ` ```tlpp ` em skills, commands e agents
- No site (`documentation/`), blocos ADVPL/TLPP usam ` ```c `: o realce de sintaxe do site (Shiki) nao tem gramatica ADVPL. O `scripts/lint-docs.sh` reconhece ADVPL/TLPP dentro de blocos ` ```c ` (ou sem linguagem) pelos marcadores fortes descritos no cabecalho do script (`User Function`, `#include` de `.ch`/`.th`, `BeginSQL`, ...)

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
   - `bash tests/hooks/run-tests.sh` — testes dos hooks `pre-tool-use`/`post-tool-use`
   - `bash examples/encoding-tests/run-tests.sh` — testes de encoding (Windows-1252) dos exemplos
   - `bash scripts/lint-docs.sh skills commands agents AGENTS.md ai-commands .github/copilot-instructions.md README.md examples documentation/content` — 0 erros nos blocos ADVPL/TLPP da documentacao, mesmo escopo do CI (anti-exemplos usam `<!-- advpl-lint: anti-exemplo -->` na ultima linha nao vazia antes da cerca; em `.mdx`, `{/* advpl-lint: anti-exemplo */}`)
   - `node scripts/sync-lint-rules.mjs --check` — regras do lint em sincronia
   - `node scripts/build-ai-commands.mjs --check` — 48 saidas (16 comandos x 3 formatos: Copilot, Cursor e Gemini CLI) em sincronia com `ai-commands/src/`
   - `node scripts/check-descriptions.mjs` — descricoes dentro do limite (`SKILL.md` 250, commands 150 caracteres)
   - `bash scripts/check-refs.sh` — referencias cruzadas sem problemas (caminhos citados, paginas do site, skills dos agents, comandos do `session-start`)
   - `npx skills add ./ --list` — 19 skills descobertas
   - `cd documentation && npm run build` — site compila sem erros
4. **Rodar as evals locais** (consome a cota ou a fatura de API de quem roda): a suite de `evals/` executa os comandos do plugin em sessoes isoladas e da nota aos resultados; o `evals/lint-outputs.sh` passa o lint nos fontes que essas sessoes geraram. Da raiz do repositorio:

   ```bash
   out="evals/results/$(date -u +%Y-%m-%dT%H-%M-%SZ)"
   mkdir -p "$out"
   claude plugin eval . --runs 1 --ablation none --max-cost-usd 30 --no-publish \
     --trust-plugin --scaffold --keep-temp --allow-tools Write Edit Bash \
     --output-dir "$out" 2>&1 | tee "$out/eval.log"
   bash evals/lint-outputs.sh
   ```

   - O custo se multiplica: o padrao da CLI e 3 execucoes por caso (`case.runs`, senao 3) e, sem `--ablation none`, um segundo braco sem o plugin (baseline) para medir o delta (Δ). Os 15 casos com os padroes viram 90 execucoes; com `--runs 1 --ablation none`, 15. Os casos ja declaram `runs: 1`.
   - `--max-cost-usd <n>`: teto do custo estimado; ao atingir, a CLI para e sai com 2 (resultado parcial). Ajuste `30` ao seu orcamento.
   - `--no-publish`: mantem o relatorio HTML local (por padrao a CLI o publica no claude.ai).
   - `--trust-plugin`: so para este repositorio, o seu proprio plugin; nunca para plugins de terceiros.
   - `--scaffold`: roda os `scaffold.sh` dos casos com arquivos de entrada (copiam `fixtures/` para o workspace); sem ele esses casos rodam com o workspace vazio.
   - `--allow-tools Write Edit Bash`: sem essa concessao os casos nao gravam arquivos e o `/validate` nao roda o lint. Conceder `Bash` exige o sandbox do sistema (macOS; no Linux, `bubblewrap` e `socat`; no Windows, WSL2).
   - `--keep-temp` e o `tee` para `eval.log`: o `lint-outputs.sh` acha os fontes gerados pelas linhas `kept temp:` do log. Os diretorios mantidos ficam no temporario do sistema; apague-os depois. O script recusa execucoes com baseline e sai 1 com qualquer erro de lint, 2 sem resultados ou sem fontes.
   - `--case <glob>` (ou `--tag <tag>`) roda um subconjunto, por exemplo `--case 'generate-*'`.
   - Meta: todos os casos com nota 1.0 e `bash evals/lint-outputs.sh` com saida 0. Falha vira correcao na skill, nao ajuste do grader.
5. **Commit e merge**: commits convencionais em branch de feature, merge fast-forward na `main`, push (o workflow `validate-plugin.yml` revalida tudo no CI).
6. **Release no GitHub**: `gh release create vX.Y.Z --title "..." --notes "..."` com notas derivadas do `CHANGELOG.md`. A release mais recente deve ficar marcada como Latest.
7. **Pos-release**: conferir `npx skills add thalysjuvenal/advpl-specialist --list` (descoberta remota) e a pagina https://skills.sh/thalysjuvenal/advpl-specialist.

## Decisoes de arquitetura

Decisoes ja tomadas — nao reabrir sem motivo novo:

- **Sem agents dedicados para `/advpr` e `/smartx` (jul/2026).** Esses comandos reutilizam o agent `code-generator` de proposito: as skills `advpr-test-automation` e `smartx-development` ja concentram todo o conhecimento, e um agent proprio seria uma terceira camada sobre o mesmo conteudo — contra o principio de fonte unica — com valor apenas dentro do Claude Code.
- **`reference.md` + `SKILL.md` coexistem em cada skill.** `reference.md` e a base de conhecimento completa (lida por commands e agents do Claude Code); `SKILL.md` e a porta de entrada fina para outros agentes (Copilot, Cursor, Gemini, Codex via skills.sh). O `SKILL.md` nunca duplica conteudo — apenas descreve a skill e aponta para os arquivos de referencia.

## Licenca

Ao contribuir, voce concorda que suas contribuicoes serao licenciadas sob a [MIT License](LICENSE).
