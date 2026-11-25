# Smart X — Padrão de Interface

## Quando Usar

A Interface é a classe TLPP que descreve como será apresentada a tela inicial de uma rotina Smart X e as opções disponíveis. Comumente apresenta a visão de uma tabela principal e ações CRUD (podendo ou não estar relacionadas à linha posicionada). No Smart X essa visão chama-se **dataView**. A interface deve sempre referenciar um **modelo** (ver `patterns-model.md`), que define entidades, relacionamentos e campos. Recurso em fase de prototipação — confirme a versão do release-alvo antes de gerar código novo.

Use o padrão de Interface descrito aqui quando precisar:

- Declarar o browse (dataView) de uma rotina e seus formulários de inclusão (dataNew), alteração (dataEdit) e visualização (dataDetail);
- Disparar processos a partir do frontend através de ações de interface (botões padrão, eventos, componentes, botões customizados, widgets etc.);
- Configurar legendas de status no browse a partir de valores constantes de campos;
- Adicionar totalizadores (aggregates) recalculados automaticamente no grid;
- Vincular o Banco de Conhecimento a ações de tabela, de página ou a eventos.

A classe de Interface é marcada com a annotation `@totvsFrameworkStructureInterface(lookup=..., country=..., description=...)`, em que `lookup` indica se a rotina é a principal ou um lookup, `country` define o país de disponibilidade e `description` é a descrição da rotina. A classe deve possuir obrigatoriamente 3 métodos:

- `new()` — construtor;
- `setInterface()` — monta o contrato de interface (dataView, dataNew, dataEdit, dataDetail, ações, legendas, aggregates);
- `getContract()` — retorna o contrato JSON da interface.

## Exemplo de Script

### Interface simplificada baseada no dicionário

Quando não há necessidade de modificações de eventos, a interface pode ser construída em duas linhas a partir do dicionário:

```advpl
#include "fw-tlpp-core.th"
#include "totvs.ch"
#include "totvs.framework.structure.interface.th"

namespace totvs.faturamento.cliente.Interface

@totvsFrameworkStructureInterface(lookup=.F., country="ALL", description="Cliente")

class crma980 from totvs.framework.structure.interface.BuildContract
EndClass

Method new() as object class crma980
    _Super:new("crma980")
Return self

method setInterface() class crma980
    self:setModelId("totvs.faturamento.cliente.model.crma980")
    self:buildStardardView()
return
```

> **Nota de grafia/divergência:** o raw do TDN grafa o método como `buildStardardView()` (sic) neste exemplo de interface simplificada; a grafia correta em outros trechos é `buildStandardView()`. Como o TDN é a fonte primária, este trecho mantém a grafia exatamente como publicada (`buildStardardView`) — confirme a grafia vigente no ambiente-alvo (TDS/IDE) antes de usar em produção. Para as notas sobre includes, ver `reference.md`.

### Exemplo completo (cadastro de clientes, não oficial)

Quando a rotina exige dataView, dataNew, dataEdit e dataDetail configurados individualmente:

```advpl
#include 'fw-tlpp-core.th'
#include "totvs.ch"
#include "totvs.framework.structure.interface.th"

namespace totvs.faturamento.cliente.Interface

@totvsFrameworkStructureInterface(lookup=.F., country="ALL", description="Cliente")

class crma980

    private data oInterface as object
    private data oDataNew   as object
    private data oDataEdit  as object
    private data oDataDetail as object
    private data oDataView  as object

    public method new() as object
    public method setInterface()
    public method getContract() as json

EndClass

Method new() as object class crma980
Return self

method setInterface() class crma980

    ::oInterface := totvs.framework.structure.interface.BuildContract():new( "crma980" )
    ::oInterface:setTitle( "Clientes" )
    ::oInterface:setModelId( "totvs.faturamento.cliente.model.crma980", .t.)
    ::oInterface:setVersion( "2.0" )

    ::oDataNew := totvs.framework.structure.interface.BuildDataNew():new("crma980New")
    ::oDataNew:setTitle("Incluir Cliente")

    ::oDataEdit := totvs.framework.structure.interface.BuildDataEdit():new("crma980Edit")
    ::oDataEdit:setTitle("Editar Cliente")

    ::oDataDetail := totvs.framework.structure.interface.BuildDataDetail():new("crma980Detail")
    ::oDataDetail:setTitle("Visualizar Cliente")

    ::oDataView := totvs.framework.structure.interface.BuildDataView():new("crma980View")
    ::oDataView:setModelId( "totvs.faturamento.cliente.model.crma980" )
    ::oDataView:setTitle("Clientes")
    ::oDataView:setInvisibleFields( {"AI0"} )
    ::oDataView:assignInvisibleFields()

    ::oInterface:setDataNew(::oDataNew:getDataNew())
    ::oInterface:setDataEdit(::oDataEdit:getDataEdit())
    ::oInterface:setDataDetail(::oDataDetail:getDataDetail())
    ::oInterface:setDataView(::oDataView:getDataView())
return

method getContract() as json class crma980
return ::oInterface:getContract( )
```

`assignInvisibleFields()` aplica a visibilidade de campos conforme o parâmetro **X3_BROWSE** do dicionário de dados — os campos listados em `setInvisibleFields` são ocultados do browse independentemente do X3_BROWSE.

### Ações de interface

Ações de interface executam processos a partir do frontend. São disparadas por botões padrão, eventos, componentes, botões customizados, widgets etc. Existem 7 tipos disponíveis, cada um com uma classe de apoio TLPP:

| Tipo | Classe de apoio |
|---|---|
| `setFields` | `totvs.framework.structure.interface.BuildSetFieldsAction` |
| `showMessage` | `totvs.framework.structure.interface.BuildShowMessageAction` |
| `submit` | `totvs.framework.structure.interface.BuildSubmitAction` |
| `navigate` | `totvs.framework.structure.interface.BuildNavigateAction` |
| `apiCall` | `totvs.framework.structure.interface.BuildApiCallAction` |
| `routine` | `totvs.framework.structure.interface.BuildRoutineAction` |
| `serverValidate` | `totvs.framework.structure.interface.BuildServerValidateAction` |

Algumas ações são criadas automaticamente na construção de modelos/interfaces: validações do SX3 (`serverValidate`), gatilhos do SX7 (`setFields`) e retorno de lookups. Sempre que possível, prefira descrever validações e gatilhos no dicionário em vez de construir a ação manualmente (ver `patterns-model.md`).

Padrão de uso: construir a ação com a classe de apoio → `getAction()` → injetar no evento disparador. Ações podem ser encadeadas (ex.: `showMessage` no `validError` de um `serverValidate`).

```advpl
oAction := totvs.framework.structure.interface.BuildShowMessageAction():new()
oAction:setLabel( "Atenção" )
oAction:setIdentifier( "userWarning" )
oAction:setMessage( "Essa é a nova rotina de cadastro de clientes" )
oAction:setSupportMessage( "Essa rotina é o novo cadastro de clientes, modernizado utilizando o conceito de Smart X" )
oAction:setMessageType( "warning" )

oDataView:addPageAction( oAction:getAction() ) // injeta no evento "pageAction"
```

**Refresh** do dataView após a execução da ação:

```advpl
local lRefreshView := .T. as logical

oDataView:addPageAction( oAction:getAction(), lRefreshView )
oDataView:addTableAction( oAction:getAction(), , , lRefreshView )
oDataView:addTableActionSubItems( "Outros", {oAction:getAction()}, , , lRefreshView )
```

**Loading overlay** (habilitado por padrão em `addPageAction`/`addTableAction`; pode ser desabilitado):

```advpl
local lRefreshView := .T. as logical
local lShowLoading := .F. as logical

oDataView:addPageAction( oAction:getAction(), lRefreshView, lShowLoading )
oDataView:addTableAction( oAction:getAction(), , , lRefreshView, lShowLoading )
```

### Legendas

Legendas no dataView (browse) usam valores constantes de campos da entidade (campo físico ou virtual iniciado por `X3_INIBRW`).

1. Campo Enum/ComboBox do SX3 — resolução automática de cores:

```advpl
::oDataView:setFieldAsLabel("SA1","A1_TIPO")
```

2. Restringir cores/sequência com a classe `totvs.framework.structure.interface.LabelColors`:

```advpl
local oColors := totvs.framework.structure.interface.LabelColors():new() as object
oColors:setColors({"green1","yellow1"})
::oDataView:setFieldAsLabel("SA1","A1_USADDA", oColors:getObject() )
```

3. Valores e cores manuais via `bindColor`:

```advpl
local oColors := totvs.framework.structure.interface.LabelColors():new() as object
oColors:bindColor('01','Loja 01','purple2')
oColors:bindColor('02','Loja 02','purple1')
::oDataView:setFieldAsLabel("SA1","A1_LOJA", oColors:getObject(), .F. /* .T. move p/ 1ª posição */)
```

Famílias de cores disponíveis em `bindColor`/`setColors` (resumo):

| Família | Variações | Observação |
|---|---|---|
| red | red1 – red5 | mapeadas internamente em `caption-tag-01`..`caption-tag-35` |
| yellow | yellow1 – yellow3 | idem |
| brown | brown1 – brown2 | idem |
| green | green1 – green5 | idem |
| blue | blue1 – blue5 | idem |
| purple | purple1 – purple5 | idem |
| pink | pink1 – pink5 | idem |
| gray | gray1 – gray5 | idem |
| — | `color-01`..`color-12` | grafia antiga, mantida apenas por compatibilidade |

### Totalizadores (aggregates) no grid

Totalizadores em grids são recalculados automaticamente a cada informação inserida. Tipos disponíveis: `sum` (soma), `average` (média), `count` (contagem), `min`, `max`.

**Na Interface — `addAggregates(aFields, cAggregate [, cLabel])`** (browse principal/dataView):

```advpl
::oDataView:addAggregates({"RA_MAT", "RA_NOME"}, "count")
```

Exemplo completo `gpea250` citado na página-fonte: `BuildDataNew`/`BuildDataEdit`/`BuildDataDetail` recebendo o 2º parâmetro `modelId` — ex.: `BuildDataNew():new("gpea250New","totvs.rh.salario.model.gpea250")` — e dataView com `setInvisibleFields({"RA_ADMISSA"})`.

**No Model — `addAggregates(aFields, cAggregate, cObject [, cLabel])`** (grids dataNew/dataEdit/dataDetail — ver também `patterns-model.md`):

```advpl
method setModel() class gpea250
    Local oSRA As Object
    Local oSR7 As Object
    Local oSR3 As Object

    oSRA := totvs.framework.structure.object.ObjectFromMetadata():new( "SRA",{"RA_FILIAL", "RA_MAT","RA_NOME","RA_ADMISSA"}, {"RA_FILIAL", "RA_MAT"} )
    self:setObject(oSRA:getObject(), "SRA" , .T. , .F. , {"RA_FILIAL", "RA_MAT","RA_NOME","RA_ADMISSA"})

    oSR7 := totvs.framework.structure.object.ObjectFromMetadata():new( "SR7",  , )
    self:addArray(oSR7:getObject(), "SR7", {"R7_FILIAL", "R7_MAT"}, {"RA_FILIAL", "RA_MAT"}, "SRA")
    self:addAggregates({"R7_USUARIO"}, "count", "SR7")

    oSR3 := totvs.framework.structure.object.ObjectFromMetadata():new( "SR3",  ,  )
    self:addArray(oSR3:getObject(), "SR3", {"R3_FILIAL", "R3_MAT", "R3_SEQ", "R3_DATA", "R3_TIPO"}, {"R7_FILIAL", "R7_MAT", "R7_SEQ", "R7_DATA", "R7_TIPO"}, "SR7")
    self:addAggregates({"R3_MAT", "R3_SEQ"}, "count", "SR3")
    self:addAggregates({"R3_VALOR"}, "sum", "SR3")

    self:LoadEventsFromMetadata()

    FwFreeObj( oSR3 )
    FwFreeObj( oSR7 )
    FwFreeObj( oSRA )
return
```

Funcionamento: ao adicionar um totalizador a um campo, todas as colunas do grid recebem totalizador; as colunas não configuradas ficam com rótulo "Nenhum" e o usuário pode escolher um agregador compatível em tempo de uso.

> **Nota:** o trecho acima chama `self:LoadEventsFromMetadata()` conforme publicado na página-fonte de totalizadores. Consulte `patterns-model.md` para o breaking change do TDN que descreve o carregamento automático de eventos do dicionário sem necessidade de chamada explícita — confirme qual comportamento vale para o release-alvo antes de replicar este trecho.

### Banco de Conhecimento

A action `totvs.framework.structure.interface.BuildKnowledgeBaseAction` vincula o Banco de Conhecimento a `tableActions`, `pageActions` e eventos — uso idêntico às demais ações:

```advpl
local oKnowledgeBaseAction as object

oKnowledgeBaseAction := totvs.framework.structure.interface.BuildKnowledgeBaseAction():new()
oKnowledgeBaseAction:setLabel("Banco de conhecimento")
// Campos da chave única da tabela para vínculo aos objetos do Banco de Conhecimento
oKnowledgeBaseAction:setParams({"SA1",'{ "A1_COD": "{{$selectedRow.A1_COD}}", "A1_LOJA": "{{$selectedRow.A1_LOJA}}" }'})

self:oDataView := totvs.framework.structure.interface.BuildDataView():new("plsa370View", "plsa370Model")
self:oDataView:setTitle("Especialidades")
self:oDataView:addTableAction(oKnowledgeBaseAction:getAction())
self:oDataView:assignInvisibleFields()
```

## Métodos Relevantes

| Classe | Métodos citados na página-fonte | Finalidade |
|---|---|---|
| `totvs.framework.structure.interface.BuildContract` | `new`, `setTitle`, `setModelId`, `setVersion`, `setDataNew`, `setDataEdit`, `setDataDetail`, `setDataView`, `getContract` | Objeto raiz da interface; monta o contrato final |
| `totvs.framework.structure.interface.BuildDataView` | `new`, `setModelId`, `setTitle`, `setInvisibleFields`, `assignInvisibleFields`, `addPageAction`, `addTableAction`, `addTableActionSubItems`, `addBeforePageAction`, `addBeforeTableAction`, `addFilterConfig`, `setFieldAsLabel`, `addAggregates`, `getDataView` | Browse (dataView) — listagem, ações, legendas, filtros, totalizadores |
| `totvs.framework.structure.interface.BuildDataNew` | `new`, `setTitle`, `getDataNew` | Formulário de inclusão |
| `totvs.framework.structure.interface.BuildDataEdit` | `new`, `setTitle`, `getDataEdit` | Formulário de alteração/exclusão |
| `totvs.framework.structure.interface.BuildDataDetail` | `new`, `setTitle`, `getDataDetail` | Formulário de visualização |
| `totvs.framework.structure.interface.BuildShowMessageAction` | `new`, `setLabel`, `setIdentifier`, `setMessage`, `setSupportMessage`, `setMessageType`, `getAction` | Ação do tipo `showMessage` |
| `totvs.framework.structure.interface.LabelColors` | `new`, `setColors`, `bindColor`, `getObject` | Configuração de cores de legenda |
| `totvs.framework.structure.interface.BuildKnowledgeBaseAction` | `new`, `setLabel`, `setParams`, `getAction` | Vincula Banco de Conhecimento a ações |
| `totvs.framework.structure.object.ObjectFromMetadata` | `new`, `getObject` | Objeto do Model referenciado pelos exemplos de aggregates (ver `patterns-model.md`) |

Classes de apoio das demais ações citadas (tipos, sem detalhamento de métodos na página-fonte): `BuildSetFieldsAction`, `BuildSubmitAction`, `BuildNavigateAction`, `BuildApiCallAction`, `BuildRoutineAction`, `BuildServerValidateAction` (todas em `totvs.framework.structure.interface`).

Classes citadas na página de criação de interface, sem exemplo de uso detalhado na página-fonte (constam no índice de classes Smart X): `BuildComponent`, `BuildElementsFromCode`, `BuildGridSystem`, `BuildPageSlide`, `BuildSectionsFromCode`, `BuildTabsFromCode` (todas em `totvs.framework.structure.interface`).

## Boas Práticas Específicas

- **Títulos com STR de tradução.** `setTitle()` (em `BuildContract`, `BuildDataView`, `BuildDataNew`, `BuildDataEdit`, `BuildDataDetail`) e os rótulos de ações (`setLabel()`, `setMessage()`, `setSupportMessage()`) devem referenciar STR de tradução em vez de literais fixos, para que a rotina fique disponível em múltiplos idiomas.
- **Validações e gatilhos preferencialmente no dicionário.** A página-fonte recomenda descrever validações (`serverValidate`) e gatilhos (`setFields`) no dicionário de dados (SX3/SX7) sempre que possível, em vez de construir a ação manualmente na Interface — o framework as cria automaticamente a partir do dicionário.
- **Eventos ficam no Modelo — exceção `onKeyDown`.** A definição de eventos (validações, gatilhos, inicializadores, eventos genéricos) é feita exclusivamente no Modelo (ver `patterns-model.md`). Na Interface, o único evento suportado é `onKeyDown`, através do método `addInterfaceEvents` (ver `patterns-model.md` para a tabela completa de eventos e a exceção documentada).
- **`assignInvisibleFields` segue o X3_BROWSE.** Ao chamar `assignInvisibleFields()` no `BuildDataView`, a visibilidade padrão dos campos é aplicada conforme o parâmetro `X3_BROWSE` do dicionário de dados; use `setInvisibleFields()` apenas para ocultar campos adicionais além do que já está definido no dicionário.
- **Confirme o release-alvo antes de usar `buildStardardView`/`buildStandardView`.** A grafia do método difere entre a página-fonte do TDN (exemplo simplificado) e o material de validação cruzada — valide a grafia correta no ambiente de destino antes de gerar código de produção.
