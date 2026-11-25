# Smart X — Padrão de Modelo de Dados

## Quando Usar

O Modelo é a camada que cuida de como os dados são definidos, validados e processados dentro da aplicação Smart X — espinha dorsal para a lógica de negócio e manipulação das entidades. O restante do sistema (View e Interface) confia que o Modelo tem a lógica correta para manipular, buscar e salvar informações, mantendo a integridade.

Use o padrão de Modelo descrito aqui quando precisar:

- Declarar uma entidade principal a partir do dicionário de dados (`ObjectFromMetadata`) e vinculá-la via `setObject`;
- Relacionar entidades 1:1 (`addObject`) ou 1:N/grid (`addArray`);
- Redefinir propriedades de campo (`setProperty`), obrigatórios e excluídos (`addRequired`/`addExclude`);
- Definir eventos de campo (validações, gatilhos, inicializadores) exclusivamente no Modelo;
- Criar expressões matemáticas/lógicas para actions (cálculos e validações visuais no frontend);
- Definir validação de campo exclusiva do Smart X via contrato SX3 ("Valid Smart X");
- Validar uma linha de grid na inclusão/alteração (`addLineValidation`).

> **Importante:** este recurso está em fase de prototipação — a API pode mudar entre releases. Confirme sempre a versão do release-alvo antes de gerar código novo.

## Exemplo de Script

### Passo 1 — Fonte base e annotation

Arquivo de exemplo `compras.produto.model.mata010.tlpp`, namespace pela padronização TLPP:

```advpl
#include 'fw-tlpp-core.th'
#include "totvs.ch"
#include "totvs.framework.structure.model.th"

namespace totvs.compras.produto.model

@totvsFrameworkStructureModel(lookup=.F., country="ALL", description="Cadastro de produtos")

class MATA010 from totvs.framework.structure.model.data
    public method new() as object
    public method setModel()
EndClass
```

Parâmetros do annotation `@totvsFrameworkStructureModel`:

- `lookup` (Lógico): se o modelo será utilizado em um lookup;
- `country` (Caractere): país; `All` para todos, senão ISO 3166-1 alpha-3;
- `description` (Caractere): descrição do modelo.

O include `totvs.framework.structure.model.th` é obrigatório para a tipagem do annotation. A classe estende `totvs.framework.structure.model.data` e expõe o método público `setModel`.

### Passo 2 — Entidades, relacionamentos, propriedades e obrigatórios

```advpl
method setModel() class mata010
    Local oSB1  as Object
    Local oSB5  as Object
    Local oSA5  as Object

    // Objeto principal a partir do dicionário
    oSB1 := totvs.framework.structure.object.ObjectFromMetadata():new( "SB1",, {"B1_FILIAL", "B1_COD"} )
    self:setObject(oSB1:getObject(), "SB1" )

    // Objeto relacionado 1 para 1
    oSB5 := totvs.framework.structure.object.ObjectFromMetadata():new( "SB5",, {"B5_FILIAL", "B5_COD"} )
    self:addObject( oSB5:getObject(), "SB5", {"B5_FILIAL", "B5_COD"}, {"B1_FILIAL", "B1_COD"}, "SB1")

    // Array de objetos 1 para N (ordem filho → pai)
    oSA5 := totvs.framework.structure.object.ObjectFromMetadata():new( "SA5",, {"A5_FILIAL", "A5_PRODUTO"} )
    self:addArray( oSA5:getObject(), "SA5", {"A5_FILIAL", "A5_PRODUTO"}, {"B1_FILIAL", "B1_COD"}, "SB1")

    // 4º passo — redefinição de propriedades permitidas
    // ("description", "format", "readOnly", "pattern", "title" e "hidden")
    self:setProperty("B5_COD", "hidden", .t., "SB5")

    // 5º passo — obrigatórios e excluídos (normalmente automáticos pelo dicionário)
    self:addRequired({"B1_COD", "B1_DESC"})
    self:addExclude({"B1_DESC1", "B1_DESC2"})
return
```

Notas do TDN:

- Triggers e Valids: é realizado um parser para o novo padrão de descrição de eventos; são instanciados em memória apenas os campos do formulário explícitos no registro da trigger e na coluna valid.
- Campos requeridos/excluídos já são definidos automaticamente pelo dicionário; a definição manual acima é uma **redefinição**.

### Breaking changes desta versão da API (destaque obrigatório)

1. **Filial explícita no identificador manual.** Ao informar o identificador (`aFinder`) manualmente em `ObjectFromMetadata`, é preciso incluir o campo de filial:
   - Antes: `oSB1 := totvs.framework.structure.object.ObjectFromMetadata():new( "SB1",, {"B1_COD"} )`
   - Novo: `oSB1 := totvs.framework.structure.object.ObjectFromMetadata():new( "SB1",, {"B1_FILIAL", "B1_COD"} )`

2. **Ordem filho → pai ao relacionar entidades** (`addObject`/`addArray`):
   - Antes: `self:addArray( oSA5:getObject(), "SA5", {"B1_FILIAL", "B1_COD"}, {"A5_FILIAL", "A5_PRODUTO"}, "SB1")`
   - Novo: `self:addArray( oSA5:getObject(), "SA5", {"A5_FILIAL", "A5_PRODUTO"}, {"B1_FILIAL", "B1_COD"}, "SB1")`

3. **Eventos do dicionário carregados automaticamente, sem método.** Não é mais necessário chamar `self:setOnChange()`, `self:setOnBeforeInsert()`, `self:setOnLoad()` ou `self:loadEventsFromMetaData()` — triggers, valids e inicializadores do dicionário passam a ser carregados automaticamente pelo framework.

> Segundo o breaking change #3 do TDN, **não é necessário chamar método algum** (nem `loadEventsFromMetadata`) para carregar eventos do dicionário na versão descrita aqui.

### Eventos no Modelo

A definição e o envio de eventos são realizados **exclusivamente através do Modelo** (padrão MVC / reuso). Envio de eventos via Interface (ex.: `setEvents`) gera mensagem de erro. Exceção: apenas `onKeyDown` fica disponível na interface, via método `addInterfaceEvents`.

| Método | Eventos relacionados | Finalidade |
|---|---|---|
| `addValidators` | `addOnChange` | Validações de campo |
| `addTriggers` | `addOnChange` | Gatilhos de preenchimento |
| `addInitializers` | `addOnActionEdit` / `addOnLoad` | Valores iniciais do campo |
| `addEvents` | eventos genéricos (ex.: `addOnEnter`) | Eventos genéricos |

**addValidators** — validação de campo `B1_DESBSE3`:

```advpl
/*/{Protheus.doc} addValid
    Método que cria a validação do campo B1_DESBSE3
/*/
method addValid() class mata010
    local oAction as object
    local oEvents as object
    local jPayLoad as json

    jPayLoad := jsonObject():new()
    jPayLoad["identifier"] := "totvs.custom.produto.model.valid_B1_DESBSE3"
    jPayLoad["function"] := "totvs.custom.produto.model.validField"
    jPayLoad["field"] := "B1_DESBSE3"
    jPayLoad["value"] := "{{$model.B1_DESBSE3}}"

    oAction := totvs.framework.structure.interface.BuildServerValidateAction():new()
    oAction:setLabel( "valid_B1_DESBSE3" )
    oAction:setIdentifier( "valid_B1_DESBSE3" )
    oAction:setHTTPMethod( "POST" )
    oAction:setEndPoint( "validateB1_DESBSE3" )
    oAction:setPayload( jPayload )

    oEvents := totvs.framework.structure.interface.BuildEvents():new()
    oEvents:addOnChange({"dataNew", "dataEdit"}, {"B1_DESBSE3"}, oAction:getAction())

    self:addValidators(oEvents:getEvents())
return
```

**addTriggers** — gatilho que obtém texto de `B1_GRPTIDC` ao alterar `B1_GRPTI`:

```advpl
method addTrigger() class mata010
    Local oEvents as object
    Local oSetFields as object
    Local oAdvplAct as object
    Local oFieldSB1 as object

    oFieldSB1 := totvs.framework.structure.interface.BuildTargetFieldStructure():new()
    oFieldSB1:setIdentifier("B1_GRPTIDC")
    oFieldSB1:setValue("{{$response.B1_GRPTIDC}}")
    oFieldSB1:setProperty("readOnly", .F.)

    oSetFields := totvs.framework.structure.interface.BuildSetFieldsAction():new()
    oSetFields:setLabel("B1_GRPTIDC")
    oSetFields:setIdentifier("B1_GRPTIDC")
    oSetFields:addTargetField(oFieldSB1:getStructure())

    oAdvplAct := totvs.framework.structure.interface.BuildAdvplAction():new()
    oAdvplAct:setLabel('getText')
    oAdvplAct:setRoutine("totvs.custom.produto.model.getValueB1_GRPTIDC")
    oAdvplAct:setParams({"{{$model.B1_GRPTI}}"})
    oAdvplAct:setHasResponse(.T.)
    oAdvplAct:setAction(oSetFields:getAction())

    oEvents := totvs.framework.structure.interface.BuildEvents():new()
    oEvents:addOnChange({"dataNew","dataEdit","dataDetail"},{"B1_GRPTI"}, oAdvplAct:getAction())

    self:addTriggers(oEvents:getEvents())
```

**addInitializers** — mesma estrutura do trigger acima (`BuildTargetFieldStructure` + `BuildSetFieldsAction` + `BuildAdvplAction`), definindo o valor inicial de `B1_VM_PROC`, mas encerrando com:

```advpl
oEvents:addOnLoad({"dataNew"},, oAdvplAct:getAction())
oEvents:addOnActionEdit({"dataNew"},, oAdvplAct:getAction())
self:addInitializers(oEvents:getEvents())
```

**addEvents** — eventos genéricos; mesmo padrão do `addValidators`, porém com:

```advpl
oEvents:addOnEnter({"dataNew", "dataEdit"}, {"B1_DESBSE3"}, oAction:getAction())
self:addEvents(oEvents:getEvents())
```

**Desativar eventos padrão do dicionário:**

```advpl
self:disableDefaultValidators()   // desativa validações do dicionário
self:disableDefaultTriggers()     // desativa gatilhos
self:disableDefaultInitializers() // desativa inicializadores
```

### Expressões

Expressões usadas nas actions permitem validações (operações lógicas) e cálculos (operações matemáticas) explícitos, com representação visual no frontend. Classe: `totvs.framework.structure.interface.BuildExpression`.

**Expressão matemática** — gera `(C6_QTDE * C6_VALOR) * ((100 - C5_DESCONT) / 100)`:

```advpl
Local oExpressionMath as object
oExpressionMath := totvs.framework.structure.interface.BuildExpression():new()

oExpressionMath:addParenthesisOpen()
oExpressionMath:addValueFromSelectedRow( "SC6.C6_QTDE" )   // campo de grid (array): cadeia entidade.campo
oExpressionMath:addOperatorMath(3)   // Soma-1 / Subtração-2 / Multiplicação-3 / Divisão-4
oExpressionMath:addValueFromSelectedRow( "SC6.C6_VALOR" )
oExpressionMath:addParenthesisClose()
oExpressionMath:addOperatorMath(3)
oExpressionMath:addParenthesisOpen()
oExpressionMath:addParenthesisOpen()
oExpressionMath:addValueFromLiteral("100")                 // valor literal/fixo
oExpressionMath:addOperatorMath(2)
oExpressionMath:addValueFromModel( "C5_DESCONT" )          // propriedade de um form (Object)
oExpressionMath:addParenthesisClose()
oExpressionMath:addOperatorMath(4)
oExpressionMath:addValueFromLiteral("100")
oExpressionMath:addParenthesisClose()
```

**Expressão lógica** — `SE C6_TOTAL > 500,00 E C6_PARCELA == 1`:

```advpl
oExpressionLog := totvs.framework.structure.interface.BuildExpression():new()
oExpressionLog:addValueFromSelectedRow( "SC6.C6_TOTAL" )
oExpressionLog:addOperatorComparison(1) // Maior-1 / Menor-2 / Maior ou igual-3 / Menor ou igual-4 / Igual-5 / Diferente-6
oExpressionLog:addValueFromLiteral("500.00")
oExpressionLog:addOperatorLogical(1)    // AND-1 / OR-2
oExpressionLog:addValueFromSelectedRow( "SC6.C6_PARCELA" )
oExpressionLog:addOperatorComparison(5)
oExpressionLog:addValueFromLiteral("1")
```

**Ação conditional** (`BuildConditionalAction`) — executa ações com base em uma expressão lógica (`actionTrue`/`actionFalse`):

```advpl
Local oBuildConditionalAction as object
Local oBuildSetFieldAction    as object
Local oFieldStructure         as object

oFieldStructure := totvs.framework.structure.interface.BuildTargetFieldStructure():new()
oFieldStructure:setIdentifier( "C6_COMISSA" )
oFieldStructure:setValue( oExpressionMath:getExpression() )

oBuildSetFieldAction := totvs.framework.structure.interface.BuildSetFieldsAction():new()
oBuildSetFieldAction:setLabel( "AlteraCampo" )
oBuildSetFieldAction:setIdentifier( "chgfields" )
oBuildSetFieldAction:addTargetField( oFieldStructure:getStructure() )

oBuildConditionalAction := totvs.framework.structure.interface.BuildConditionalAction():new()
oBuildConditionalAction:setLabel( "MinhaActionConditional" )
oBuildConditionalAction:setIdentifier( "conditional" )
oBuildConditionalAction:setActionTrue(oBuildSetFieldAction:getAction())
oBuildConditionalAction:setExpression(oExpressionLog:getExpression())
// Vincular a um evento, ex. onChange de C6_VALOR/C6_QTDE
```

**Ação validate** (`BuildValidateAction`) — validação no frontend sem chamada de API; expressão lógica verdadeira = válido; falha impede gravação e exibe mensagem no componente:

```advpl
Local oValidate as object
oValidate := totvs.framework.structure.interface.BuildValidateAction():new()
oExpressionLog := totvs.framework.structure.interface.BuildExpression():new()
oExpressionLog:addValueFromSelectedRow( "SC6.C6_VALOR" )
oExpressionLog:addOperatorComparison(1)
oExpressionLog:addValueFromLiteral("0.00")
oValidate:setLabel( "MinhaLabel" )
oValidate:setIdentifier( "validate" )
oValidate:setExpression(oExpressionLog:getExpression())
// Vincular ao onChange; a classe permite também ações de sucesso/falha da validação
```

### Validação de campos exclusiva do Smart X (SX3)

É possível definir validação específica do Smart X no dicionário SX3. Se preenchida, tem prioridade sobre `X3_VALID` e `X3_VLDUSER` (que deixam de ser interpretadas). É definida por um contrato JSON, conceito **stateless** — tudo que a execução precisa vai na requisição (valor, nome do campo, contexto).

Contrato de validação (exemplo):

```advpl
{"type":"serverValidate",
 "function":"MyValidateFunction",
 "contextInfo":["{{$model.A1_EST}}"]
}
```

Propriedades do contrato:

- `type`: sempre `"serverValidate"`;
- `function`: nome completo da função ADVPL/TLPP com namespace, sem parâmetros;
- `contextInfo`: array de conteúdos do client, com interpolações resolvidas em runtime, passadas como payload.

Preenchimento: campo **"Valid Smart X"** no ATUSX (grid de detalhes do campo), disponível em pacotes com versão de metadado **≥ 12.1.2610**. Atualização no Protheus via fluxo tradicional (pacote → SDF*.TXT → UPDDISTR).

A função de validação recebe `xValue` (valor), `cField` (nome do campo) e `aContextInfo` (array); retorna um JSON com `return` (lógico) e `notValidMessage`:

```advpl
#include "totvs.ch"

Function MyValidateFunction( xValue, cField, aContextInfo )
Local jRet as json
jRet := JsonObject():new()

If xValue == "1"
    jRet['return'] := .t.
    jRet['notValidMessage'] := ""
ElseIf xValue == "2"
    If aContextInfo[1] == "SP"
        jRet['return'] := .f.
        jRet['notValidMessage'] := "Prezado usuário, se o estado for 'SP' tem que ser 1"
    Else
        jRet['return'] := .t.
        jRet['notValidMessage'] := ""
    EndIf
Else
    jRet['return'] := .f.
    jRet['notValidMessage'] := "Valores válidos 1 ou 2"
EndIf
Return jRet
```

### Validação na linha do grid

O método `addLineValidation` valida a inclusão/alteração de uma linha no grid. Parâmetros: `cIdentifier` (identificador do grid — alias do objeto) e `cFunction` (função executada na validação da linha).

Uso no Modelo:

```advpl
method setModel() class su5Test
    Local oHeader As Object
    Local oItem   As Object

    oHeader := totvs.framework.structure.object.ObjectFromMetadata():new( "SU5")
    self:setObject(oHeader:getObject(), "SU5")

    oItem := totvs.framework.structure.object.ObjectFromMetadata():new( "AGA")
    self:addArray(oItem:getObject(), "AGA", {"AGA_FILIAL", "AGA_CODENT"}, {"U5_FILIAL", "U5_CODCONT"}, "SU5")

    self:addLineValidation("AGA", "totvs.framework.example.modelo.valids.validLinePos")

    FwFreeObj( oHeader )
return
```

A função de validação recebe `cIdentifier` (caractere) e `jFields` (json com os valores da linha); retorna lógico; em caso de erro, usar `Help` para exibir a mensagem:

```advpl
#include 'fw-tlpp-core.th'
#include "totvs.ch"

namespace totvs.framework.example.modelo.valids

function validLinePos(cIdentifier as character, jFields as json)
    local lRet as logical
    lRet := .T.
    if cIdentifier == "AGA" .and. jFields["AGA_PADRAO"] == "1"
        Help(,,"Teste",,"Campo AGA_PADRAO não pode ser preenchido com o valor 'Sim'",1,0)
        lRet := .F.
    endif
return lRet
```

## Métodos Relevantes

| Método / Classe | Camada | Finalidade |
|---|---|---|
| `totvs.framework.structure.model.data` | Modelo | Classe base que todo Modelo Smart X estende |
| `totvs.framework.structure.object.ObjectFromMetadata():new(cAlias,, aFinder)` | Objeto | Cria o objeto (contrato JSON) de uma entidade a partir do dicionário de dados |
| `setObject(jObject, cAlias)` | Modelo | Define a entidade principal do Modelo |
| `addObject(jObject, cAlias, aChildKeys, aParentKeys, cParentAlias)` | Modelo | Relaciona uma entidade 1:1 (filho → pai) |
| `addArray(jObject, cAlias, aChildKeys, aParentKeys, cParentAlias)` | Modelo | Relaciona um array de entidades 1:N / grid (filho → pai) |
| `setProperty(cField, cSubProperty, xValue, cObject)` | Modelo | Redefine propriedade de campo (`description`, `format`, `readOnly`, `pattern`, `title`, `hidden`) |
| `addRequired(aFields, cObject)` | Modelo | Redefine campos obrigatórios (normalmente automático pelo dicionário) |
| `addExclude(aFields, cObject)` | Modelo | Exclui campos do modelo |
| `addValidators(oEvents)` | Modelo (eventos) | Registra validações de campo (`addOnChange`) |
| `addTriggers(oEvents)` | Modelo (eventos) | Registra gatilhos de preenchimento (`addOnChange`) |
| `addInitializers(oEvents)` | Modelo (eventos) | Registra valores iniciais de campo (`addOnLoad`/`addOnActionEdit`) |
| `addEvents(oEvents)` | Modelo (eventos) | Registra eventos genéricos (ex.: `addOnEnter`) |
| `disableDefaultValidators()` / `disableDefaultTriggers()` / `disableDefaultInitializers()` | Modelo (eventos) | Desativa o carregamento automático dos respectivos eventos do dicionário |
| `addInterfaceEvents` | Interface | Única forma de registrar evento na Interface (`onKeyDown`); demais eventos exclusivamente no Modelo |
| `totvs.framework.structure.interface.BuildServerValidateAction` | Interface (evento) | Constrói action de validação server-side vinculada a um `onChange` |
| `totvs.framework.structure.interface.BuildEvents` | Interface (evento) | Constrói o conjunto de eventos (`addOnChange`, `addOnLoad`, `addOnActionEdit`, `addOnEnter`) |
| `totvs.framework.structure.interface.BuildTargetFieldStructure` | Interface (evento) | Define campo alvo de uma action (`setIdentifier`, `setValue`, `setProperty`) |
| `totvs.framework.structure.interface.BuildSetFieldsAction` | Interface (evento) | Action que altera valor de campo(s) alvo |
| `totvs.framework.structure.interface.BuildAdvplAction` | Interface (evento) | Action que executa rotina ADVPL/TLPP e opcionalmente encadeia outra action com a resposta |
| `totvs.framework.structure.interface.BuildExpression` | Expressão | Monta expressões matemáticas/lógicas (`addValueFromSelectedRow`, `addValueFromLiteral`, `addValueFromModel`, `addOperatorMath`, `addOperatorComparison`, `addOperatorLogical`, `addParenthesisOpen`/`Close`) |
| `totvs.framework.structure.interface.BuildConditionalAction` | Expressão | Executa `actionTrue`/`actionFalse` conforme resultado de uma expressão lógica |
| `totvs.framework.structure.interface.BuildValidateAction` | Expressão | Validação client-side baseada em expressão lógica, sem chamada de API |
| Contrato SX3 `{"type":"serverValidate","function":...,"contextInfo":[...]}` (campo "Valid Smart X") | Validação de campo | Validação stateless exclusiva do Smart X, com prioridade sobre `X3_VALID`/`X3_VLDUSER` (ATUSX ≥ 12.1.2610) |
| `addLineValidation(cIdentifier, cFunction)` | Modelo (grid) | Valida inclusão/alteração de linha de grid; função recebe `cIdentifier`/`jFields` e retorna lógico |

## Boas Práticas Específicas

- **Eventos exclusivamente via Modelo.** Toda definição e envio de eventos deve ser feita no Modelo; enviar eventos pela Interface (ex.: `setEvents`) gera erro. A única exceção é `onKeyDown`, disponível na Interface via `addInterfaceEvents`.
- **Prefira validações e gatilhos já definidos no dicionário de dados** (SX3/SX7) em vez de recriá-los manualmente com `addValidators`/`addTriggers`/`addInitializers` — segundo o breaking change #3, esses eventos já são carregados automaticamente pelo framework, sem necessidade de método explícito. Use os métodos manuais apenas para eventos que não existem no dicionário ou que precisam de lógica adicional (ex.: `BuildAdvplAction` chamando rotina customizada).
- **Atenção aos três breaking changes documentados nesta versão da API:** (1) filial explícita ao informar identificador manual em `ObjectFromMetadata`; (2) ordem filho → pai em `addObject`/`addArray`; (3) eventos do dicionário carregados automaticamente, sem chamar método. Código escrito para versões anteriores da API não é compatível sem ajuste.
- **Este recurso está em fase de prototipação** — reavalie a sintaxe e o comportamento a cada nova release do Protheus antes de gerar ou migrar código de Modelo Smart X.
- Ao redefinir `addRequired`/`addExclude`/`setProperty`, lembre-se de que o comportamento padrão já vem do dicionário — use essas chamadas apenas quando precisar **sobrepor** o que já está definido em SX3.
- Para validação de campo com regra específica do Smart X (independente de `X3_VALID`), use o contrato SX3 "Valid Smart X" em vez de lógica embutida na Interface — a validação é stateless e roda no servidor com o contexto explícito em `contextInfo`.
- Para regras de negócio na linha do grid (ex.: impedir combinação de valores em colunas), use `addLineValidation` no Modelo em vez de tentar reproduzir a regra na Interface.
