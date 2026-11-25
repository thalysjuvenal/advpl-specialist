# 12 — Validar fontes com lint e checagens semânticas

## Contexto

Antes de abrir o pull request, você quer saber se o fonte `src/ZFATA02.prw` (fictício) tem problemas que o hook de edição não mostra. O hook acusa só as linhas que você acabou de escrever e pula as regras que analisam o arquivo inteiro. O `/validate` roda o lint sobre **o arquivo todo** e acrescenta as checagens semânticas S1 a S6, em um relatório só.

## Prompt exato

```
/advpl-specialist:validate src/ZFATA02.prw
```

Variações do argumento: um glob (`"src/REST/*.tlpp"`), um diretório (`src/`, que expande `.prw`, `.prx`, `.tlpp` e `.th`) e `--errors-only`.

## O que o plugin faz

1. **Resolve os alvos** e mantém os caminhos como foram resolvidos. Arquivos com outras extensões (como `.ch`) ficam fora do lint e são citados como não validados.
2. **Roda o motor de lint** a partir da raiz do projeto, com `--scope all`: `skills/advpl-code-review/scripts/advpl-lint.sh` (ou o gêmeo `.ps1` no Windows sem bash). Se existir `./.advpl-specialist-ignore`, ele é aplicado. Saída com código `2` (erro de uso ou de leitura) interrompe o comando: sem relatório e sem etapa semântica.
3. **Lista os itens suprimidos**, quando o resumo do motor informa suprimidos, comparando com uma segunda execução sem o arquivo de ignore.
4. **Faz a passada semântica (S1 a S6)**, lendo o arquivo inteiro:
   - `S1` assinatura de funções nativas; `S2` campos do SX3 fora da cobertura do lint (campos `_X*` sempre listados para você confirmar)
   - `S3` pontos de entrada; `S4` coerência do MVC (ModelDef e ViewDef)
   - `S5` mistura incorreta de ADVPL e TLPP; `S6` automação (`FWMVCRotAuto` restrita, códigos de operação)
   - não repete o que o lint já apontou na mesma linha, respeita o `.advpl-specialist-ignore` e marca como **a confirmar** o que nenhuma fonte confirma
5. **Fecha o relatório** dizendo que a compilação e a validação no TDS ainda estão pendentes. O comando é somente leitura: relata e nunca edita o arquivo.

## Exemplo de `.advpl-specialist-ignore`

Um arquivo na raiz do projeto, uma diretiva por linha (`rule`, `field`, `function` ou `path`; `#` abre comentário):

```text
# IIf em expressao de dicionario nao tem alternativa em If/Else
rule ADV009

# campo customizado ja confirmado no SX3 do ambiente
field ZA1_XPROJ

# fontes legados fora do escopo desta revisao
path src/legado/**
```

## Output esperado

Relatório na ordem definida pelo comando (os números de linha e a redação das mensagens vêm do motor e podem variar):

```text
1 arquivo | advpl-lint: 2 error(s), 2 warning(s), 1 suppressed | 2 achados semânticos

Erros
src/ZFATA02.prw:1: error ADV002 include fora do padrao; use diretiva e nome em minusculas (#include "totvs.ch") [CA3001]
src/ZFATA02.prw:40: error ADV003 use FWLogMsg() em vez de ConOut()/OutErr()/? [CA1004]

Avisos
src/ZFATA02.prw:60: warning ADV011 API da era ISAM; use FWTemporaryTable em modo relacional (CriaTrab so para nome de arquivo) [CA1000]
src/ZFATA02.prw:75: warning ADV017 funcao sem suporte TOTVS (restricted-functions.md); pode mudar sem aviso, prefira a alternativa documentada

Suprimidos pelo .advpl-specialist-ignore
src/ZFATA02.prw:52: warning ADV009 evite IIf() inline; use bloco If/Else/EndIf [CA4000]

Achados semânticos
S2 (semântico) src/ZFATA02.prw:30 - campo ZA1_XORIGEM custom, nao verificavel externamente - confirmar no dicionario da base - critical-rules.md (Field Name Validation) - a confirmar
S6 (semântico) src/ZFATA02.prw:75 - FWMVCRotAuto e restrita (uso interno TOTVS) - usar MsExecAuto conforme o exemplo documentado da rotina ou a API do modelo (FWLoadModel + SetOperation + Activate + SetValue + VldData + CommitData + DeActivate) - restricted-functions.md - confirmado

Pendente: compilação e validação no TDS / extensão TOTVS do VS Code.
```

Observações sobre o relatório:

- o `S2` lista `ZA1_XORIGEM` porque ele não consta no `.advpl-specialist-ignore`; `ZA1_XPROJ`, que consta na diretiva `field`, não é listado porque você já o confirmou
- achados semânticos nunca somam nos totais do lint nem mudam o veredito do motor
- relatório limpo não significa que o código compila

## Variações

- `--errors-only` — omite a seção de avisos (o resumo ainda traz a contagem)
- **Diretório:** `/advpl-specialist:validate src/ --errors-only`
- **Mais de 20 arquivos:** o lint cobre todos; o plugin pergunta quais entram na passada semântica

## Próximos passos sugeridos

1. Corrigir os erros e rodar o `/validate` de novo
2. Para cada aviso mantido, decidir entre justificar no pull request ou registrar no `.advpl-specialist-ignore`
3. Compilar e validar no TDS antes de homologar
