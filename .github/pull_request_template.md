## Descricao

Descreva as alteracoes feitas neste PR.

## Tipo de mudanca

- [ ] Bug fix
- [ ] Nova funcionalidade
- [ ] Melhoria de documentacao
- [ ] Refactoring
- [ ] Outro: ___

## Checklist

- [ ] Exemplos ADVPL (.prw) usam `#Include "TOTVS.CH"` (nunca `Protheus.ch`)
- [ ] Exemplos TLPP (.tlpp) usam includes `.th` (`tlpp-core.th`, `tlpp-rest.th`, etc.)
- [ ] Nenhum `using namespace tlpp.*` nos exemplos de codigo
- [ ] Variaveis declaradas como `Local` (nao `Private`/`Public`)
- [ ] Notacao Hungara nas variaveis dos exemplos
- [ ] Frontmatter YAML correto em arquivos de commands/skills/agents
- [ ] CHANGELOG.md atualizado
- [ ] README.md atualizado (se aplicavel)

## Como testar

1. `claude --plugin-dir ./advpl-specialist`
2. Execute: `...`
3. Verifique: `...`
