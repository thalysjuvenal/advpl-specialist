# Releases por recurso (Protheus 12.1.x)

> Consolida os recursos que as skills do plugin **já** ligam a uma release. Cada linha aponta para a página do TDN ou da Central TOTVS que a skill citante indica. Quando a skill não indica fonte, a coluna diz isso e o ponto fica **a confirmar no TDN** (use a skill `tdn-lookup`). Não há aqui release inventada: o que não está nas skills não está nesta tabela.

Os comandos `/generate`, `/migrate` e `/smartx` leem o arquivo `.protheus-version` (uma release por arquivo, ex.: `12.1.2410`, na raiz do projeto) e consultam esta tabela para avisar quando o recurso pedido exige release maior.

## Como comparar

Compare o **terceiro componente como inteiro**, ignorando zeros à esquerda: `12.1.17` < `12.1.33` < `12.1.2210` < `12.1.2310` < `12.1.2410` < `12.1.2510` < `12.1.2610`. Vale para os dois estilos de numeração (`12.1.NN` antigo e `12.1.AAMM` novo, em que `AAMM` = ano e mês). É a mesma ordem que `version_gte` do hook (`hooks/lib/detect-protheus-version.sh`) obtém com `sort -V`.

## Tabela

| Recurso | Desde a release | Fonte |
|---|---|---|
| TLPP com MVC | 12.1.2410 | Mínimo aplicado pelo hook `hooks/session-start` (`MIN_TLPP_MVC`); fonte no TDN a confirmar |
| TLPP com `namespace`: identificadores de até 255 caracteres (em `.prw` o limite é 10 para função/variável) | 12.1.2410 | Citado em `skills/advpl-code-generation/critical-rules.md` e `skills/advpl-code-review/rules-best-practices.md` (fonte a confirmar no TDN) |
| `StaticCall()` e `PTInternal()`: compilação bloqueada | 12.1.33 | Central TOTVS: [artigo 56931144146579](https://centraldeatendimento.totvs.com/hc/pt-br/articles/56931144146579) (lista de restritas); substituições: [StaticCall](https://centraldeatendimento.totvs.com/hc/pt-br/articles/4411463269911) e [PTInternal](https://centraldeatendimento.totvs.com/hc/pt-br/articles/4411463486871) (citados em `skills/protheus-reference/restricted-functions.md`) |
| Smart X: rotinas nativas (modelo, interface, launcher) | 12.1.2510 | TDN "Construindo uma Rotina CRUD do Zero com SmartX" ([link](https://tdn.totvs.com/display/framework/Construindo+uma+rotina+do+zero+com+Smart+X)), citado em `skills/smartx-development/reference.md` |
| Smart X: conversão de browse legado (`SetSmartX`/`setSmartX`, `hasSmartX()`) em ambiente produtivo | 12.1.2610 (desenvolvimento interno: RPO D-1) | Citado em `skills/smartx-development/patterns-launcher-browse.md`, `troubleshooting.md` e `patterns-migration.md` (fonte a confirmar no TDN) |
| Smart X: campo "Valid Smart X" no ATUSX (contrato SX3 `serverValidate`), metadado ≥ 12.1.2610 | 12.1.2610 | Citado em `skills/smartx-development/patterns-model.md` (fonte a confirmar no TDN) |
| Smart View: release mínima do recurso | não declarada nas skills | `skills/smartview-development/reference.md` só traz o atributo `initialRelease` da annotation: padrão `12.1.2310` na tabela de atributos e `12.1.2210` nos exemplos (divergente, a confirmar) |
| ADVPR: execução de suíte sem interface do robô (antes de 12.1.2310 só pelo SmartClient `EXECSUITE`) | 12.1.2310 | Citado em `skills/advpr-test-automation/reference.md` (fonte a confirmar no TDN) |
| Rotinas migradas para MVC: pontos de entrada legados de validação/botões deixam de disparar (ex.: `MA020TOK` desde 12.1.17; MATA010 e MATA020 citadas) | 12.1.17 | TDN [MA020TOK, nota de descontinuação](https://tdn.totvs.com/pages/releaseview.action?pageId=6087599), citado em `skills/advpl-code-generation/patterns-pontos-entrada-mvc.md` |
| `FWSafeVault` e `FWSecretVault` (requerem também LIB ≥ 20210405 e appserver ≥ 17.3.0.15) | 12.1.23 | Citado em `skills/protheus-reference/native-functions.md` (fonte a confirmar no TDN) |
| Campo `X6_EXPDEST` do SX6 | 12.1.025 | Citado em `skills/protheus-reference/sx-dictionary.md` (fonte a confirmar no TDN) |

## Notas

- Smart X tem dois mínimos: 12.1.2510 para criar rotinas nativas e 12.1.2610 para converter browse legado e usar o "Valid Smart X". A própria skill `smartx-development` distingue os dois; a frase genérica "a partir da Release 12.1.2610" em `patterns-migration.md` vale para a conversão de rotinas existentes.
- `12.1.025` e `12.1.023` (esta aparece só como valor de exemplo em `native-functions.md`) seguem a grafia antiga com zero à esquerda; leia como 25 e 23.
- Esta tabela não cita a release do exemplo `GetReleaseRobo() >= "12.1.19"` (`skills/advpr-test-automation/api-fwtesthelper.md`): é só um exemplo de uso da função, não um recurso atrelado a release.
