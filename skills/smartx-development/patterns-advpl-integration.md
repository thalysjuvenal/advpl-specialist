## Quando Usar

- Quando for necessário executar funções ADVPL diretamente pela interface do Smart X, através de `pageActions`, `tableActions` ou eventos (como `onChange`) — inclusive funções com elementos gráficos ADVPL (ex.: `cGetFile`).
- Quando se deseja aproveitar o retorno de uma função ADVPL em outra action da interface (ex.: exibir uma mensagem ou preencher um campo com o valor retornado).
- Quando dados capturados pela interface (linha selecionada, resposta de uma action anterior, dados do modelo) precisam ser usados como parâmetro de uma função ADVPL — isso dá flexibilidade na migração de rotinas existentes para o Smart X sem reescrever a lógica de negócio.
- Quando é preciso implementar regras de negócio nas operações de inclusão, alteração e deleção (validar dados, desabilitar campos, abortar a transação, alterar mensagens de sucesso/erro) sem alterar o padrão da rotina — usando os Pontos de Entrada (PEs) específicos do Smart X.

Para as ações gerais de interface (`BuildDataView`, `BuildShowMessageAction`, `BuildSetFieldsAction`, `BuildEvents`, etc.) que aparecem nos exemplos abaixo, ver `patterns-interface.md` — este arquivo cobre apenas a integração com ADVPL (`BuildAdvplAction`) e os Pontos de Entrada.

## Exemplo de Script

### BuildAdvplAction em tableAction

Classe de apoio: `totvs.framework.structure.interface.BuildAdvplAction`.

```advpl
local oAdvplAction   as object
local oActionMessage as object

oActionMessage := totvs.framework.structure.interface.BuildShowMessageAction():new()
oActionMessage:setLabel( "_message" )
oActionMessage:setIdentifier( "_message" )
oActionMessage:setMessage( "{{$response.title}} : {{$response.code}}" )
oActionMessage:setSupportMessage( "{{$response.code}}" )
oActionMessage:setMessageType( "warning" )

oAdvplAction := totvs.framework.structure.interface.BuildAdvplAction():new()
oAdvplAction:setLabel("Botão de Ação")
oAdvplAction:setRoutine("totvs.protheus.health.specialties.interface.plsa370Teste")
oAdvplAction:setParams({"{{$selectedRow.BAQ_CODESP}}"})
oAdvplAction:setHasResponse(.f.)
oAdvplAction:setAction(oActionMessage:getAction())

self:oDataView := totvs.framework.structure.interface.BuildDataView():new("plsa370View", cModelId)
self:oDataView:setTitle("Especialidades")
self:oDataView:addTableAction(oAdvplAction:getAction())
self:oDataView:assignInvisibleFields()
```

Função ADVPL chamada — deve retornar um JSON em formato string:

```advpl
function plsa370Teste(cCode)
return '{"title": "Código", "code": "'+cCode+'"}'
```

Refresh da view após a ação (quando necessário): `oDataView:addPageAction( oAction:getAction(), lRefreshView )` ou `oDataView:addTableAction( oAction:getAction(), , , lRefreshView )`.

### BuildAdvplAction em evento onChange usando o retorno da função

Exemplo que preenche o campo `BAQ_DESCRI` com o valor de `{{$response.code}}` retornado pela função ADVPL:

```advpl
local oAdvplAction  as object
local oSetFields    as object
local oStructFields as object
local oEvents       as object

oStructFields := totvs.framework.structure.interface.BuildTargetFieldStructure():new()
oStructFields:setIdentifier("BAQ_DESCRI")
oStructFields:setValue("{{$response.code}}")

oSetFields := totvs.framework.structure.interface.BuildSetFieldsAction():new()
oSetFields:setLabel("_descri")
oSetFields:setIdentifier("_descri")
oSetFields:addTargetField(oStructFields:getStructure())

oAdvplAction := totvs.framework.structure.interface.BuildAdvplAction():new()
oAdvplAction:setLabel("Botão de Ação")
oAdvplAction:setRoutine("totvs.protheus.health.specialties.interface.plsa370Teste")
oAdvplAction:setParams({})
oAdvplAction:setHasResponse(.t.)
oAdvplAction:setAction(oSetFields:getAction())

oEvents := totvs.framework.structure.interface.BuildEvents():new()
oEvents:addOnChange({"dataNew"}, {"BAQ_CODESP"}, oAdvplAction:getAction())
self:oInterface:setEvents( oEvents:getEvents() )
```

Neste exemplo, `plsa370Teste()` usa `cGetFile( "*.*", "cGetFile - SmartX", , 'c:\', .t., , .t.)` — uma função com interface gráfica ADVPL — e retorna `'{"title": "Código", "code": "'+cTeste+'"}'`.

### Pontos de Entrada disponíveis

O Smart X implementa PEs em locais específicos, disparados nas operações de inclusão, alteração e deleção. Todos permitem alterar mensagens padrão de sucesso/erro, obter definições do modelo e obter/alterar dados do conjunto de dados.

| PE | Momento | Pode abortar? |
|---|---|---|
| `formPre` | Carregamento do formulário (create/update); permite desabilitar entidades/campos | — (retorno é array) |
| `formPos` | Confirmação do formulário (insert/update/delete), antes da transação | Sim |
| `beforeCommit` | Antes da persistência, FORA da transação | Não |
| `beforeCommitInTransaction` | Antes da persistência, DENTRO da transação | Sim |
| `afterCommitInTransaction` | Após a persistência, DENTRO da transação | Sim |
| `afterCommit` | Após a persistência, FORA da transação | Não |

**Namespace do PE:** o namespace deve ser o mesmo do modelo, substituindo o prefixo por `custom.entrypoint`.

- namespace do Model: `totvs.protheus.faturamento.model`
- namespace do PE: `custom.entrypoint.protheus.faturamento.model`

Criar User Functions com o NOME de cada PE; elas retornam um valor lógico indicando se a transação será abortada (nos PEs que podem abortar).

### Exemplo fiel — beforeCommitInTransaction

> Sobre os includes (`totvs.ch` no lugar de `protheus.ch`, `Interface.th` em minúsculas), veja a nota em `reference.md` desta skill.

```advpl
#include "fw-tlpp-core.th"
#include "totvs.ch"
#include "totvs.framework.structure.model.th"

namespace custom.entrypoint.protheus.faturamento.model

/*/{Protheus.doc} beforeCommitInTransaction
    Ponto de entrada antes do commit na transação
    @type Function
    @author marco.fritsch
    @since 29/09/2025
/*/
User Function beforeCommitInTransaction()
    local oDataset := PARAMIXB[2] as object
    local oError   := PARAMIXB[3] as object
    local lReturn  := .t. as logical

    if oDataset:getFieldValue("SC5", "C5_NUM") == "000098"
        oError:set(403, "Erro", "Registro não pode ser deletado")
        lReturn := .f.
    endIf
Return lReturn
```

### Exemplo fiel — formPre

`formPre` não interrompe o fluxo; permite desabilitar entidades ou campos da view na inclusão/alteração. `oDataset` NÃO está disponível no contexto de inclusão (create). Retorno: array de objetos json no formato `{ {"entity": "SA1", "fields":{"A1_DDD"}}, {"entity": "AI0"} }` — informar apenas `entity` desabilita todos os campos daquela entidade; informar `fields` desabilita apenas os campos indicados.

```advpl
#include 'fw-tlpp-core.th'
#include "totvs.ch"

namespace custom.entrypoint.protheus.faturamento

User Function formPre()
local cOperation := PARAMIXB[5] as character
local aReturn as array
local oDataset := PARAMIXB[2] as object

if cOperation == "insert"
    aReturn := {{"entity": "SA1", "fields":{"A1_DDI"}} }
elseif cOperation == "update"
    if oDataset:getFieldValue("SA1", "A1_PESSOA") == "J"
        aReturn := {{"entity": "SA1", "fields":{"A1_DDD"}}, {"entity": "AI0"} }
    endif
endif
return aReturn
```

### Exemplo fiel — formPos

`formPos` tem acesso ao dataset para validações; retorno lógico; mensagem de negativa é definida via `oError:set()`. `oError` e `oSuccess` NÃO estão disponíveis no `formPre`.

```advpl
User Function formPos()
local cOperation := PARAMIXB[5] as character
local lRet as logical
local oDataset := PARAMIXB[2] as object
local oError   := PARAMIXB[3] as object

if cOperation == "update"
    lRet := !Empty(oDataset:getFieldValue("SA1", "A1_DDD"))
    if !lRet
        oError:set(400, "FormPos", "Registro não pode ser atualizado pois DDD não foi preenchido.")
    endif
endif
return lRet
```

Em ambos os PEs, `cOperation` é recebido em `PARAMIXB[5]`.

### Objetos recebidos via PARAMIXB

| Posição/objeto | Classe |
|---|---|
| oModelPropertyManager | `totvs.framework.structure.model.PropertyManager` |
| oDataset (PARAMIXB[2]) | `framework.model.events.ContextManager` |
| oError (PARAMIXB[3]) | `totvs.framework.rest.manager.Error` |
| oSuccess | `totvs.framework.rest.manager.Success` |
| cOperation | "update", "insert" ou "delete" |

### Geração automática de contratos

Para análise detalhada e investigação de inconsistências, é possível gerar os arquivos de contrato da rotina automaticamente:

1. Obrigatório RPO D-1.
2. No `appserver.ini`, na seção do ambiente: `FWTRACELOG=1`.
3. Acessar a rotina Smart X desejada.
4. No `rootPath` será criada a pasta `smartx` com os arquivos JSON nomeados de acordo com a rotina.

## Métodos Relevantes

- `BuildAdvplAction():new()` — instancia a action de chamada de função ADVPL.
- `:setRoutine(cNamespaceFuncao)` — define o namespace completo + nome da função ADVPL a ser chamada.
- `:setParams(aParams)` — define os parâmetros enviados à função, podendo usar interpolações como `{{$selectedRow.CAMPO}}`.
- `:setHasResponse(lHasResponse)` — indica se a função retorna um valor a ser aproveitado por outra action (via `{{$response.*}}`).
- `:setAction(oAction:getAction())` — define a action a ser executada com base no retorno da função (ex.: exibir mensagem, preencher campo).
- Interpolações disponíveis nos parâmetros e nas actions encadeadas: `{{$selectedRow.*}}` (dados da linha selecionada na tabela), `{{$response.*}}` (retorno da função ADVPL, quando `setHasResponse(.t.)`), `{{$model.*}}` (dados do modelo).
- `oDataset:getFieldValue("ALIAS", "CAMPO")` — obtém o valor de um campo do conjunto de dados dentro dos PEs.
- `oError:set(nCodigo, cTitulo, cMensagem)` — define o erro que será retornado quando o PE aborta a operação.

## Boas Práticas Específicas

- Pontos de Entrada do Smart X manipulam dados (via `oDataset`, `oModelPropertyManager`, `oError`, `oSuccess`) — NÃO manipulam componentes visuais da interface; a manipulação de interface é feita pelas actions descritas em `patterns-interface.md`.
- Toda função ADVPL chamada via `BuildAdvplAction` deve retornar um JSON válido em formato string, para que possa ser consumido por `{{$response.*}}` nas actions encadeadas.
- O namespace do Ponto de Entrada deve seguir o namespace do modelo, substituindo o prefixo do modelo pelo prefixo `custom.entrypoint` (ex.: `totvs.protheus.faturamento.model` → `custom.entrypoint.protheus.faturamento.model`).
- Os eventos `beforeCommitInTransaction` e `afterCommitInTransaction` podem abortar a transação; `beforeCommit` e `afterCommit` (fora da transação) não podem abortar — usar o PE correto conforme a necessidade de bloquear ou não a operação.
- `formPre` não tem acesso a `oDataset` no contexto de inclusão, nem a `oError`/`oSuccess` em nenhum contexto — validações que dependem desses objetos devem ser feitas em `formPos` ou nos PEs de commit.
