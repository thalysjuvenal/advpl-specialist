# Smart View — parâmetros

Os parâmetros são a tela que o usuário preenche antes de a grade abrir. É a parte do objeto com
mais armadilhas: duas delas custam um dia de investigação cada e nenhuma aparece como erro de
compilação.

## `addParameter`

```tlpp
self:oSchema:addParameter(cNome, cLabel, cTipo, lFlag, , , , , , cHelp)
```

| Posição | Argumento | Conteúdo |
|---|---|---|
| 1 | `cNome` | Nome do parâmetro. Use `MV_PARxx` para acompanhar a convenção do SX1, ou nome próprio (`MV_FIL`) |
| 2 | `cLabel` | Pergunta exibida na tela |
| 3 | `cTipo` | `"string"`, `"number"` ou `"date"` |
| 4 | `lFlag` | **Não é validação** — ver abaixo |
| 10 | `cHelp` | Texto de ajuda do parâmetro |

### O 4º argumento não bloqueia nada

Marcar `.T.` **não impede o envio do formulário**. O Smart View executa a consulta do mesmo
jeito e simplesmente devolve grade vazia, porque sem o valor nada é encontrado. É assim que os
objetos padrão funcionam: o flag é semântico, não é validação.

Consequência de código: **parâmetro "obrigatório" pode chegar vazio no `getData`**, e tratar
valor ausente é responsabilidade do objeto. Assuma um default sensato (a filial da sessão, a
faixa completa) em vez de confiar no flag.

Nos objetos do SIGAFAT o único parâmetro com `.T.` é também o único que aceita **lista** de
valores, o que deixa em aberto se o flag significa "obrigatório" ou "multivalorado". Sem
impacto prático até aqui; se for multivalorado, marcar `.T.` no parâmetro de filial daria
seleção múltipla no lookup e dispensaria a convenção de separar por `;`.

## Parâmetros a partir do SX1

```tlpp
//no new()
self:setPergunte("MEUGRUPO")
```

Carrega o grupo de perguntas do SX1 como parâmetros do objeto, na ordem do dicionário. É o
caminho mais curto quando o relatório de origem já tinha um grupo — a migração aproveita
pergunta, tipo, tamanho e validação de faixa sem reescrever nada.

**O que o `setPergunte` NÃO faz: combo.** Um `MV_PARxx` com `X1_GSC = 'C'` e opções cadastradas
no SX1 aparece como campo de texto comum. Não existe caminho por dicionário — combo em objeto
de negócio depende de endpoint de opções, sempre. Ver a seção de combo abaixo.

### A dependência que o `setPergunte` cria

O grupo **precisa existir no SX1 do ambiente**, e o objeto de negócio não o cria. Em migração de
relatório, quem cria o grupo é o `ValidPerg` do fonte original — o que produz uma dependência
que precisa estar escrita em algum lugar, porque não aparece em erro nenhum:

> O relatório de origem tem de permanecer compilado e ter sido executado ao menos uma vez no
> ambiente, senão o objeto abre sem parâmetro nenhum.

**Não leve a criação do SX1 para dentro do objeto de negócio.** Gravar dicionário com `RecLock`
dentro de thread REST é receita de lock em concorrência: vários usuários abrindo a mesma visão
ao mesmo tempo disputam o mesmo registro do SX1.

Duas saídas quando a dependência incomoda:

| Saída | Quando |
|---|---|
| Manter o `setPergunte` e documentar a dependência | O relatório original continua no ar (caso normal em migração aditiva) |
| Declarar os parâmetros com `addParameter` e abandonar o grupo | O original vai ser desativado, ou o grupo tem perguntas sem sentido no Smart View |

A segunda é o caminho definitivo; a primeira encurta a primeira entrega.

Quando não há grupo no SX1, ou quando ele traria perguntas que não fazem sentido no Smart View
(caminho de arquivo, seleção de impressora), declare os parâmetros manualmente com
`addParameter`. Os dois caminhos convivem no mesmo objeto.

## `setCustomURL`

```tlpp
self:setCustomURL(cParametro, cURL, nTipo)
```

Amarra uma URL a um parâmetro já declarado. **Tem de vir depois** do `addParameter`
correspondente — a referência é pelo nome.

| `nTipo` | Constante | O que faz | Precisa de endpoint próprio? |
|---|---|---|---|
| 1 | `KEYVALUE` | Combo de valores | **Sim** |
| 2 | `LOOKUP` | Busca avançada em tabela | Não — endpoint do framework |
| 3 | `LOOKUPQUERY` | Busca avançada por consulta | Não |
| 4 | `LOOKUPSX5` | Busca avançada em tabela genérica | Não |

## Busca avançada (tipo 2) — a receita

Dois passos, e nada a publicar:

```tlpp
//1. no new()
self:setIsLookUp(.T.)

//2. no fim do getSchema(), depois dos addParameter
self:setCustomURL("MV_PAR01", "api/framework/v1/genericLookupService/smartview/SA1", 2)
```

O `genericLookupService` é endpoint **do framework**: basta trocar o alias no fim da URL
(`SA1`, `SB1`, `SED`, `SM0`, ...). Exige `FwLibVersion() >= "20231121"`.

**A busca avançada devolve só a chave.** O lookup de cliente grava no campo apenas o `A1_COD` —
não devolve código e loja concatenados. O valor que chega ao `getData` é a chave simples, e o
`BETWEEN` funciona direto sobre ela. Quando a loja importar, ela vira **parâmetro próprio**,
declarado à parte. Não é limitação a contornar: é como o recurso funciona.

## Combo (tipo 1) — exige endpoint próprio

Esta é a parte mais cara. Três fatos, todos comprovados em ambiente:

### 1. A rota de options do módulo padrão não alcança objeto customizado

A rota que serve os combos dos objetos da TOTVS monta o caminho no padrão de nomenclatura
deles e **não resolve namespace `custom.*`**. Testado com o mesmo token, mesma rota: com o
objeto e a função da TOTVS ela devolve as opções; com objeto customizado devolve `{"data": []}`
— com função global em `.prw`, com e sem o prefixo `U_`, e com `User Function` ou
`Static Function` dentro do `.tlpp` do objeto. Não é licença, não é autenticação, não é o
prefixo.

### 2. A rota interna do provider também não serve

O include define `SMARTVIEW_OPTIONS_ENDPOINT` apontando para
`/api/framework/treports/integratedprovider/v1/options/:optionsId/:paramId`. Isso descreve a
rota **interna** do provider; chamá-la de fora devolve resposta que o conector não consegue
desserializar. Não é atalho para dispensar endpoint próprio.

### 3. Onde a função de opções pode morar — três paredes

| Tentativa | Resultado |
|---|---|
| `Function` pura (como no fonte padrão da TOTVS) | **Não compila** em fonte customizado: *"functions are not allowed in code. Use USER FUNCTION or STATIC FUNCTION"*. O fonte padrão compila com permissão que customização não tem |
| `Static Function` | Visível só dentro do próprio fonte; o endpoint chama de fora |
| `User Function` dentro do `.tlpp` **com namespace** | Não é registrada globalmente: *"InterFunctionCall: cannot find function U_XXX in AppMap"*. O namespace vale para o arquivo inteiro |

Sobra: **`User Function` num `.prw` sem namespace**.

### A solução

Um endpoint REST próprio, que resolve a função contra **lista explícita** e monta o contrato de
resposta:

```tlpp
#include "tlpp-core.th"
#include "tlpp-rest.th"

namespace custom.smartview.fat.api

//-------------------------------------------------------------------
/*/{Protheus.doc} svFatOptions
Opções de combo dos objetos de negócio Smart View customizados.

O segmento :funcao NÃO é executado por macro: é resolvido contra uma
lista explícita de funções conhecidas. Endpoint autenticado não pode
virar executor de função arbitrária do RPO a partir da URL.

@return logical: resultado do setStatusResponse
/*/
//-------------------------------------------------------------------
@Get(endpoint="/api/custom/smartview/v1/options/:funcao/:opcao", description="Opcoes de combo dos objetos Smart View customizados")
User Function svFatOptions() as logical

    Local jPath   := oRest:getPathParamsRequest() as json
    Local jRet    := JsonObject():New() as json
    Local jItem   := Nil as json
    Local aOpcoes := {} as array
    Local aItens  := {} as array
    Local cFuncao := "" as character
    Local cOpcao  := "" as character
    Local nX      := 0  as numeric

    cFuncao := Upper(AllTrim(cValToChar(jPath["funcao"])))
    cOpcao  := AllTrim(cValToChar(jPath["opcao"]))

    If cFuncao == "SVOPT01"
        aOpcoes := U_SVOPT01(cOpcao)
    Else
        FWLogMsg("WARN", , "svFatOptions", , , , "Funcao de opcoes nao reconhecida: " + cFuncao, , , )
    EndIf

    For nX := 1 To Len(aOpcoes)
        jItem := JsonObject():New()
        jItem["key"]   := cValToChar(nX)
        jItem["label"] := aOpcoes[nX]
        aAdd(aItens, jItem)
    Next nX

    jRet["data"] := aItens

    oRest:setKeyHeaderResponse("Content-Type", "application/json")

Return oRest:setStatusResponse(200, jRet:toJson())
```

A função de opções, num `.prw` **sem namespace**:

```advpl
#include "totvs.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} SVOPT01
Opções de combo servidas ao endpoint svFatOptions.

@param cOpcao, character, identificador do combo

@return array: labels das opções, na ordem (a chave é o índice)
/*/
//-------------------------------------------------------------------
User Function SVOPT01(cOpcao)

    Local aRet := {} as array

    Do Case
        Case AllTrim(cOpcao) == "1"
            aRet := {"Ambos", "Somente vendas", "Somente devoluções"}
        Case AllTrim(cOpcao) == "2"
            aRet := {"Emissão", "Vencimento"}
    EndCase

Return aRet
```

E a amarração no `getSchema`:

```tlpp
self:setCustomURL("MV_PAR09", "api/custom/smartview/v1/options/SVOPT01/1", 1)
```

### Contrato da resposta

Capturado do retorno real da rota padrão:

```json
{ "data": [ { "key": "1", "label": "Emissão" } ] }
```

O `key` é o **índice da opção, base 1**. A função ADVPL devolve só o array de labels; quem monta
o resto é o endpoint. Por isso a função de opções de um relatório legado migra sem alteração —
o array que ela já devolvia serve como está.

No `getData`, o valor que chega é o `key`:

```tlpp
nMovto := Val(cValToChar(oParams["MV_PAR09", 1]))
If nMovto <= 0
    nMovto := 1
EndIf
```

### Duas armadilhas de ciclo

**URL inválida derruba a tela inteira.** Não degrada para "combo vazio": o conector estoura
`ConnectorException` em `DeserializeAsync`, a tela de parâmetros responde 500 e o objeto fica
inutilizável. **Valide o endpoint no Postman antes de amarrá-lo ao objeto.**

**O Smart View faz cache da URL de opções.** O log diz "A url ... foi recuperada do cache".
Recompilar e reiniciar o AppServer **não** invalida esse cache — ele vive do lado do Smart
View. O ciclo de teste de combo é:

```text
compilar -> reiniciar o AppServer -> reiniciar o serviço do Smart View -> abrir a tela
```

Sem o terceiro passo você testa a URL antiga e conclui errado.

## Lendo os parâmetros no `getData`

```tlpp
Local oParams := oFilter:getParameters() as json
```

O acesso é por nome e índice: `oParams["MV_PAR01", 1]`.

### Faixas "até" — o bug silencioso

No relatório legado, `Pergunte` devolvia o valor **preenchido com brancos** até o tamanho do
SX1, e `Replicate("Z", Len(MV_PAR04))` funcionava. Vindo do JSON do Smart View o valor chega
**sem padding**: `Len("")` é zero, o `Replicate` devolve string vazia e o
`BETWEEN '' AND ''` não traz nada.

O tamanho tem de vir do **dicionário**, nunca do conteúdo:

```tlpp
//-------------------------------------------------------------------
/*/{Protheus.doc} rangeTo
Limite superior de uma faixa, com tamanho vindo do dicionário.

@param cValor, character, valor informado (pode vir vazio)
@param cCampo, character, campo do SX3 que define o tamanho

@return character: valor informado ou o teto da faixa
/*/
//-------------------------------------------------------------------
Method rangeTo(cValor as character, cCampo as character) as character Class SvTools

    Local cRet := AllTrim(cValToChar(cValor)) as character
    Local nTam := TamSX3(cCampo)[1] as numeric

    If Empty(cRet)
        cRet := Replicate("Z", nTam)
    Else
        cRet := PadR(cRet, nTam)
    EndIf

Return cRet
```

O limite inferior segue a mesma lógica com `PadR(..., nTam)` sobre valor vazio.

### Datas de parâmetro

Parâmetro do tipo `date` chega como timestamp. Converta para o formato do banco antes de usar:

```tlpp
cDataDe := DtoS(FwDateTimeToLocal(oParams["MV_PAR01", 1])[1])
```

### Listas

Não há tipo "lista" no `addParameter`. Quando o parâmetro precisa aceitar vários valores
(filiais, por exemplo), receba texto e expanda por separador, aceitando `;` e `,`:

```tlpp
aCodes := StrTokArr(StrTran(AllTrim(cFiliais), ",", ";"), ";")
```

Documente o separador no `cHelp` do parâmetro — o usuário não tem como adivinhar.

## Checklist

- [ ] `setIsLookUp(.T.)` no `new()` quando há busca avançada
- [ ] Todo `setCustomURL` vem **depois** do `addParameter` correspondente
- [ ] Nenhum combo depende de `X1_GSC` do SX1
- [ ] Endpoint de opções resolve a função por **lista explícita**, nunca por macro
- [ ] URL do combo validada no Postman antes de amarrar ao objeto
- [ ] Ciclo de teste de combo inclui reiniciar o serviço do Smart View
- [ ] Faixas "até" usam `TamSX3`, não `Len()` sobre o conteúdo
- [ ] Todo parâmetro "obrigatório" tem tratamento de valor ausente no `getData`
- [ ] Separador de lista documentado no help do parâmetro
