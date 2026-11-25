# Smart X

## Conceito

Smart X é um framework TOTVS que gera telas com interface moderna automaticamente a partir de metadados. O desenvolvedor descreve **o quê** (estrutura de dados, regras de negócio, layout de tela) e o framework gera e renderiza a interface, eliminando a necessidade de construir componentes visuais manualmente através de linguagens Web (Angular).

### Principais benefícios

| Benefício | Descrição |
|---|---|
| Produtividade | Telas geradas automaticamente com interface web, sem necessidade de programação web |
| Flexibilidade | Mudanças na interface sem alterar código front-end |
| Padronização | Todas as telas seguem o padrão definido nos metadados; comportamento consistente |
| Redução de erros | Minimiza inconsistências de layout e problemas de validação manual de campos |

O caminho **metadados → telas** funciona assim: a estrutura de uma tabela do dicionário de dados (SX2/SX3) é lida e transformada em um contrato JSON (Objeto); esse contrato alimenta uma classe TLPP (Modelo) que define entidades, relacionamentos e regras de negócio; uma segunda classe TLPP (Interface) declara o contrato de UI (browse, formulários de inclusão/edição/visualização); e uma função de menu (Launcher) abre a rotina apontando para essa Interface. Nenhuma dessas etapas exige escrever componentes visuais à mão — o PO-UI é renderizado automaticamente a partir do contrato.

## Arquitetura (Objeto, Modelo, Interface e Launcher)

Toda rotina Smart X é composta por três artefatos, mais o launcher que a registra no menu:

| Artefato | O que é | Arquivo típico |
|---|---|---|
| Objeto | Contrato JSON representando uma tabela. Pode ser construído a partir do Dicionário de Dados via `ObjectFromMetadata()` ou declarado via código com `BuildFromCode()` | gerado em runtime pelo framework |
| Modelo | Classe TLPP que representa a entidade de negócio: define atributos, relacionamentos entre tabelas e regras de negócio | `namespace.model.tlpp` |
| Interface | Classe TLPP que define o contrato de UI (browse, formulários de inclusão/edição/visualização) | `namespace.interface.tlpp` |
| Launcher | Função ADVPL/TLPP registrada no menu Protheus que instancia `totvs.framework.application.smartx.launcher()` e abre a rotina apontando para a Interface | função de menu (ex.: `FINA050SM()`, `MATA110SX()`) |

**Fluxo:** Objeto → Modelo → Interface → Launcher. O Launcher referencia a Interface pelo namespace; a Interface referencia o Modelo via `setModelId()`; o Modelo cria Objetos via `ObjectFromMetadata()` (ou `BuildFromCode()`) passando o alias da tabela. É o Launcher que se cadastra no menu Protheus.

### Includes e annotation

Os três artefatos usam este conjunto de includes:

```advpl
#include 'fw-tlpp-core.th'
#include "totvs.ch"
#include "totvs.framework.structure.model.th"      // no Modelo
#include "totvs.framework.structure.interface.th"   // na Interface
```

O Modelo é marcado com a annotation `@totvsFrameworkStructureModel(lookup=.F., country="ALL", description="...")` e estende `totvs.framework.structure.model.data`. A Interface é marcada com `@totvsFrameworkStructureInterface(lookup=.F., country="ALL", description="...")`. O Launcher não exige annotation — é uma função ADVPL/TLPP simples que instancia `totvs.framework.application.smartx.launcher()`.

> **Notas sobre includes:** o `totvs.ch` inclui o `protheus.ch`; o TDN ainda grafa `protheus.ch` nos exemplos de Smart X. O TDN também grafa `Interface.th` (maiúsculo); aqui o include vai em minúsculas (`totvs.framework.structure.interface.th`) e a diferenciação de caixa na compilação em Linux está a confirmar (TDN — "Construindo uma rotina do zero com Smart X", https://tdn.totvs.com/display/framework/Construindo+uma+rotina+do+zero+com+Smart+X). O `fw-tlpp-core.th` é o include oficial dos fontes Smart X.
>
> A chamada do Launcher segue os exemplos reais `FINA050SM`/`MATA110SX`/`MATA120SX` do TDN: `launcher():new():setInterface(cNamespace):open()`.

## Exemplo Mínimo

Exemplo baseado no fonte real `backoffice.fin.fina050sm` (Contas a Pagar), fiel ao raw do TDN.

### Modelo (`model.tlpp`)

```advpl
#include 'fw-tlpp-core.th'
#include "totvs.ch"
#include "totvs.framework.structure.model.th"

namespace totvs.backoffice.fin.fina050sm

@totvsFrameworkStructureModel(lookup=.F., country="ALL", description="Contas a Pagar")

Class Model From totvs.framework.structure.model.data
    Public Method new() As Object
    Public Method setModel()
EndClass

method new() as Object class Model
    _Super:new(,,.t.)
return self

method setModel() class Model
    local oSE2 as object

    // Cria objeto a partir do dicionário de dados (alias SE2)
    // Terceiro parâmetro: campos que compõem a chave do objeto
    oSE2 := totvs.framework.structure.object.ObjectFromMetadata():new("SE2",, {"E2_PREFIXO", "E2_NUM", "E2_PARCELA", "E2_TIPO", "E2_FORNECE", "E2_LOJA"})

    // Define SE2 como objeto principal do modelo
    self:setObject(oSE2:getObject(), "SE2")

    // Carrega valids e gatilhos do dicionário automaticamente
    self:loadEventsFromMetadata()
return
```

> Exemplo publicado assim no TDN; segundo o breaking change #3 (ver `patterns-model.md`), os eventos do dicionário passam a ser carregados automaticamente, sem chamada de método.

### Interface (`interface.tlpp`)

```advpl
#include 'fw-tlpp-core.th'
#include "totvs.ch"
#include "totvs.framework.structure.interface.th"

namespace totvs.backoffice.fin.fina050sm

@totvsFrameworkStructureInterface(lookup=.F., country="ALL", description="Contas a Pagar")

class Interface
    private data oInterface  as object
    private data oDataView   as object
    private data oDataNew    as object
    private data oDataEdit   as object
    private data oDataDetail as object

    public method new()         as object
    public method setInterface()
    public method getContract() as json
endClass

method new() as object class Interface
return self

method setInterface() class Interface
    local cIdentifier := "fina050" as Character

    // Contrato principal: identificador único da interface
    ::oInterface := totvs.framework.structure.interface.BuildContract():new(cIdentifier)
    ::oInterface:setTitle("Contas a Pagar")
    // Referencia o namespace do modelo
    ::oInterface:setModelId("totvs.backoffice.fin.fina050sm.model", .F.)
    ::oInterface:setVersion("2.0")

    // Browse (listagem)
    ::oDataView := totvs.framework.structure.interface.BuildDataView():new("fina050View", "totvs.backoffice.fin.fina050sm.model")
    ::oDataView:setModelId("totvs.backoffice.fin.fina050sm.model", .T.)

    // Formulário de inclusão
    ::oDataNew := totvs.framework.structure.interface.BuildDataNew():new("fina050New", "totvs.backoffice.fin.fina050sm.model")
    ::oDataNew:setTitle("Incluir")

    // Formulário de edição
    ::oDataEdit := totvs.framework.structure.interface.BuildDataEdit():new("fina050Edit", "totvs.backoffice.fin.fina050sm.model")
    ::oDataEdit:setTitle("Editar")

    // Formulário de visualização
    ::oDataDetail := totvs.framework.structure.interface.BuildDataDetail():new("fina050Detail", "totvs.backoffice.fin.fina050sm.model")
    ::oDataDetail:setTitle("Visualizar")

    // Monta contrato final
    ::oInterface:setDataView(::oDataView:getDataView())
    ::oInterface:setDataNew(::oDataNew:getDataNew(), .F.)
    ::oInterface:setDataEdit(::oDataEdit:getDataEdit())
    ::oInterface:setDataDetail(::oDataDetail:getDataDetail(), .F.)
return

method getContract() as json class Interface
return ::oInterface:getContract()
```

### Launcher (função de menu)

```advpl
#include "totvs.ch"

// Função registrada no menu Protheus
function FINA050SM()
    local oLauncher as object

    oLauncher := totvs.framework.application.smartx.launcher():new()
    // Aponta para o namespace da interface
    oLauncher:setInterface("totvs.backoffice.fin.fina050sm.interface")
    oLauncher:open()
Return
```

Relação entre os artefatos: o Launcher referencia a Interface pelo namespace; a Interface referencia o Modelo via `setModelId()`; o Modelo cria Objetos via `ObjectFromMetadata()` passando o alias da tabela.

## Quando Usar

Use Smart X quando a rotina puder ser descrita inteiramente por metadados de uma ou mais tabelas do dicionário de dados e a interface desejada for um CRUD padrão (browse + inclusão + edição + visualização) — os quatro benefícios da tabela em **Conceito** (produtividade, flexibilidade, padronização, redução de erros) só se concretizam quando o Objeto pode ser derivado via `ObjectFromMetadata()` ou, em casos de campos com regras específicas, via `BuildFromCode()`.

O MVC clássico (ModelDef/ViewDef/MenuDef) continua sendo a base sobre a qual rotinas legadas foram construídas e exige a construção manual da camada de apresentação. O TDN não documenta, na página de referência, uma comparação estruturada linha a linha entre Smart X e MVC clássico além do que já está expresso nos benefícios — a mensagem central é que o Smart X **elimina a necessidade de construir componentes visuais manualmente através de linguagens Web (Angular)**, o que é justamente a etapa que o MVC clássico exige (ViewDef/HTML/Angular custom). Ao planejar uma nova rotina, avalie primeiro se a estrutura de dados se encaixa no modelo Objeto → Modelo → Interface → Launcher; funcionalidades muito específicas de UI que fujam do contrato de browse/formulário podem exigir mais investigação nos guias avançados de Interface (abas customizadas, componentes PO-UI, ações de linha) antes de descartar o Smart X.

## Estado da Documentação

A documentação oficial do Smart X no TDN é ativa e vem evoluindo — a própria página "Construindo uma Rotina CRUD do Zero com SmartX" lista pré-requisitos de versão explícitos (Protheus P12 release **12.1.2510** ou superior; essa versão refere-se ao desenvolvimento de rotinas Smart X nativas — a conversão de browse legado via `SetSmartX` e o campo Valid Smart X do dicionário exigem 12.1.2610, ver `patterns-launcher-browse.md` e `patterns-model.md`) e remete a diversos guias complementares ainda em expansão:

- Configurando a Interface
- Trabalhando com Formulários: Campos e Propriedades
- Criando e Configurando o Modelo SmartX
- Trabalhando com o Browse — FWMBrowse + DataView
- Ações de Interface — SmartX
- Criando Expressões no Smart X
- Validações e Regras de Negócio — SmartX
- Eventos no Modelo SmartX

A API do Smart X pode variar entre releases. Antes de gerar código novo, confirme a versão do release-alvo e consulte as **Release Notes** do Protheus para eventuais mudanças na API `totvs.framework.structure.*` e `totvs.framework.application.smartx.*`.
